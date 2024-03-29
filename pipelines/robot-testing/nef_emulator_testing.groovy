
String runCapifLocal(String nginxHost) {
    return nginxHost.matches('^(http|https)://localhost.*') ? 'true' : 'false'
}

def getAgent(deployment) {
    String var = deployment
    if ('openshift'.equals(var)) {
        return 'evol5-openshift'
    }else if ('kubernetes-athens'.equals(var)) {
        return 'evol5-athens'
    }else {
        return 'evol5-slave'
    }
}

pipeline{

    agent { node { label getAgent("${params.DEPLOYMENT }") == 'any' ? '' : getAgent("${params.DEPLOYMENT }") } }

    parameters{
        choice(name: 'DEPLOYMENT', choices: ['openshift', 'kubernetes-athens', 'kubernetes-uma'], description: 'Environment where tests will run')
        string(name: 'NGINX_HOSTNAME', defaultValue: 'https://localhost:4443', description: 'nginx hostname')        // nginx-evolved5g.apps-dev.hi.inet
        string(name: 'ROBOT_DOCKER_IMAGE_VERSION', defaultValue: '3.1.1', description: 'Robot Docker image version')
        string(name: 'ADMIN_USER', defaultValue: 'admin@my-email.com', description: 'NEF Admin username')
        password(name: 'ADMIN_PASS', defaultValue: 'pass', description: 'NEF Admin password')
    }

    environment {
        NEF_EMULATOR_DIRECTORY = "${WORKSPACE}/nef-emulator"
        ROBOT_TESTS_DIRECTORY = "${WORKSPACE}/tests"
        ROBOT_RESULTS_DIRECTORY = "${WORKSPACE}/results"
        NGINX_HOSTNAME = "${params.NGINX_HOSTNAME}"
        ROBOT_VERSION = "${params.ROBOT_DOCKER_IMAGE_VERSION}"
        ROBOT_IMAGE_NAME = 'dockerhub.hi.inet/dummy-netapp-testing/robot-test-image'
        AWS_DEFAULT_REGION = 'eu-central-1'
        OPENSHIFT_URL= 'https://openshift-epg.hi.inet:443'
        RUN_LOCAL_NEF = runCapifLocal("${params.NGINX_HOSTNAME}")
    }

    stages{
        
        stage('Login to Artifactory') {
            steps {
                dir ("${env.WORKSPACE}") {
                    withCredentials([usernamePassword(
                       credentialsId: 'docker_pull_cred',
                       usernameVariable: 'USER',
                       passwordVariable: 'PASS'
                   )]) {
                        sh '''
                            docker login --username ${USER} --password ${PASS} dockerhub.hi.inet
                           '''
                   }
                }
            }
        }

        stage("Run Nef locally."){

            when {
                expression { RUN_LOCAL_NEF == 'true' }
            }

            stages{
                stage("Checkout"){
                    steps{
                        checkout([$class: 'GitSCM',
                            branches: [[name: 'main']],
                            doGenerateSubmoduleConfigurations: false,
                            extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'nef-emulator']], 
                            gitTool: 'Default',
                            submoduleCfg: [],
                            userRemoteConfigs: [[url: 'https://github.com/EVOLVED-5G/NEF_emulator.git', credentialsId: 'github_token']]
                        ])
                    }
                }
                stage("Set up NEF services"){
                    steps {
                        dir ("${NEF_EMULATOR_DIRECTORY}") {
                            sh """
                                sed -i 's+EXTERNAL_NET=true+EXTERNAL_NET=false+g' env-file-for-local.dev
                                sed -i 's+USE_PUBLIC_KEY_VERIFICATION=true+USE_PUBLIC_KEY_VERIFICATION=false+g' env-file-for-local.dev
                                make prepare-dev-env
                                make build
                                make upd
                                sleep 30s
                            """
                        }
                    }
                }
            }

        }
        stage ("Setup Robot FW && Run tests"){
            stages{
                stage("Setup RobotFramwork container"){
                    steps{
                        dir ("${WORKSPACE}") {
                            sh """
                                docker pull ${ROBOT_IMAGE_NAME}:${ROBOT_VERSION} 
                                docker run --rm -d -t \
                                    --name robot \
                                    --network="host" \
                                    -v ${WORKSPACE}/tests:/opt/robot-tests/tests/ \
                                    -v ${WORKSPACE}/libraries:/opt/robot-tests/libraries/ \
                                    -v ${WORKSPACE}/resources:/opt/robot-tests/resources/ \
                                    -v ${WORKSPACE}/results:/opt/robot-tests/results/ \
                                    --env NEF_URL=${NGINX_HOSTNAME} \
                                    --env NGINX_HOSTNAME=${NGINX_HOSTNAME} \
                                    --env ADMIN_USER=${ADMIN_USER} \
                                    --env ADMIN_PASS=$ADMIN_PASS \
                                    ${ROBOT_IMAGE_NAME}:${ROBOT_VERSION} \
                            """
                        }
                    }
                }
                stage("Run test cases."){
                    steps{
                        sh """
                            docker exec -t robot bash \
                            -c "pabot --processes 1 --outputdir /opt/robot-tests/results/ /opt/robot-tests/tests/; \
                                rebot --outputdir /opt/robot-tests/results --output output.xml --merge /opt/robot-tests/results/output.xml;"
                        """
                    }
                }
            }
        }
    }

    post{
        always{
            script {
                if(env.RUN_LOCAL_NEF == 'true'){
                    dir ("${env.NEF_EMULATOR_DIRECTORY}") {
                        sh """
                            docker-compose --profile debug down -v --rmi all
                        """
                    }
                }
                sh """
                    docker kill robot
                """
            }
            publishHTML([allowMissing: true,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'results',
                    reportFiles: 'report.html',
                    reportName: 'Robot Framework Tests Report NEF',
                    reportTitles: '',
                    includes:'**/*'])
            junit allowEmptyResults: true, testResults: 'results/xunit.xml'
            script {
                echo "Deleting directories."
                cleanWs deleteDirs: true
            }
        }
        success{
            echo "Test ran successfully."
        }
    }

}
