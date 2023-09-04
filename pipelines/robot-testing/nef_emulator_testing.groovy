package pipelines;

String runNefLocal(String nginxHost) {
    return nginxHost.matches('^(http|https)://localhost.*') ? 'true' : 'false'
}

String runCapifLocal(String capif_host) {
    return capif_host.matches('capifcore') ? 'true' : 'false'
}

def getAgent(deployment) {
    String var = deployment
    if ('openshift'.equals(var)) {
        return 'evol5-openshift'
    } else if ('kubernetes-athens'.equals(var)) {
        return 'evol5-athens'
    } else if ('kubernetes-cosmote'.equals(var)) {
        return 'evol5-cosmote'
    } else {
        return 'evol5-slave'
    }
}

pipeline{

    agent { node { label getAgent("${params.DEPLOYMENT }") == 'any' ? '' : getAgent("${params.DEPLOYMENT }") } }

    parameters{
        choice(name: 'DEPLOYMENT', choices: ['kubernetes-uma', 'kubernetes-athens', 'kubernetes-cosmote', 'openshift'], description: 'Environment where tests will run')
        string(name: 'ROBOT_DOCKER_IMAGE_VERSION', defaultValue: '3.1.1', description: 'Robot Docker image version')
        string(name: 'CAPIF_HOST', defaultValue: 'capifcore', description: 'CAPIF host')
        string(name: 'CAPIF_HTTP_PORT', defaultValue: '8080', description: 'CAPIF http port')
        string(name: 'CAPIF_HTTPS_PORT', defaultValue: '443', description: 'CAPIF https port')
        string(name: 'NEF_API_HOSTNAME', defaultValue: 'https://localhost:4443', description: 'NEF Emulator api hostname')
        string(name: 'ADMIN_USER', defaultValue: 'admin@my-email.com', description: 'NEF Admin username')
        password(name: 'ADMIN_PASS', defaultValue: 'pass', description: 'NEF Admin password')
    }

    environment {
        NEF_EMULATOR_DIRECTORY = "${WORKSPACE}/nef-emulator"
        ROBOT_TESTS_DIRECTORY = "${WORKSPACE}/tests"
        ROBOT_RESULTS_DIRECTORY = "${WORKSPACE}/results"
        NGINX_HOSTNAME = "${params.NEF_API_HOSTNAME}"
        ROBOT_VERSION = "${params.ROBOT_DOCKER_IMAGE_VERSION}"
        ROBOT_IMAGE_NAME = 'dockerhub.hi.inet/dummy-netapp-testing/robot-test-image'
        RUN_LOCAL_NEF = runNefLocal("${params.NEF_API_HOSTNAME}")
        LOCAL_CAPIF = runCapifLocal("${params.CAPIF_HOST}")
    }


    stages{
        stage("Checkout nef services"){
            when {
                expression { RUN_LOCAL_NEF == 'true' }
            }
            steps{
                checkout([$class: 'GitSCM',
                          branches: [[name: 'main']],
                          doGenerateSubmoduleConfigurations: false,
                          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "nef-services"]],
                          gitTool: 'Default',
                          submoduleCfg: [],
                          userRemoteConfigs: [[url: 'https://github.com/EVOLVED-5G/NEF_emulator.git']]
                ])
            }
        }
        stage("Checkout capif services"){
            when {
                expression { RUN_LOCAL_NEF == 'true' && CAPIF_HOST == 'capifcore' }
            }
            steps{
                checkout([$class: 'GitSCM',
                          branches: [[name: 'develop']],
                          doGenerateSubmoduleConfigurations: false,
                          extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "capif-services"]],
                          gitTool: 'Default',
                          submoduleCfg: [],
                          userRemoteConfigs: [[url: 'https://github.com/EVOLVED-5G/CAPIF_API_Services.git']]
                ])
            }
        }

        stage("Set up environment."){
            stages{
                stage("Set up capif services."){
                    when {
                        expression { RUN_LOCAL_NEF == 'true' && CAPIF_HOST == 'capifcore'}
                    }
                    steps {
                        dir ("./capif-services") {
                            sh """
                                ls -la && cd services
                                sed -i "s/image: mongo:6.0.2/image: mongo:4.4.17/g" docker-compose.yml
                                ./run.sh
                            """
                        }
                    }
                }
                stage("Set up nef services."){
                    when {
                        expression { RUN_LOCAL_NEF == 'true' }
                    }
                    steps {
                        dir ("./nef-services") {
                            sh """
                                sed -i "s/CAPIF_HOST=capifcore/CAPIF_HOST=${CAPIF_HOST}/g" env-file-for-local.dev
                                sed -i "s/CAPIF_HTTP_PORT=8080/CAPIF_HTTP_PORT=${CAPIF_HTTP_PORT}/g" env-file-for-local.dev
                                sed -i "s/CAPIF_HTTPS_PORT=443/CAPIF_HTTPS_PORT=${CAPIF_HTTPS_PORT}/g" env-file-for-local.dev
                                sed -i "s/EXTERNAL_NET=true/EXTERNAL_NET=${LOCAL_CAPIF}/g" env-file-for-local.dev
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
                stage("Substitute registration values"){
                    steps{
                        dir ("${WORKSPACE}") {
                            sh """
                                sed -i "s/CAPIF_HOST/${CAPIF_HOST}/g" ${WORKSPACE}/tools/capif-registration/capif-registration.json
                                sed -i "s/CAPIF_HTTP_PORT/${CAPIF_HTTP_PORT}/g" ${WORKSPACE}/tools/capif-registration/capif-registration.json
                                sed -i "s/CAPIF_HTTPS_PORT/${CAPIF_HTTPS_PORT}/g" ${WORKSPACE}/tools/capif-registration/capif-registration.json
                                sed -i "s/CAPIF_HOST/${CAPIF_HOST}/g" ${WORKSPACE}/tools/capif-registration/register.sh
                                sed -i "s/CAPIF_HTTP_PORT/${CAPIF_HTTP_PORT}/g" ${WORKSPACE}/tools/capif-registration/register.sh
                            """
                        }
                    }
                }
                stage("Setup RobotFramwork container"){
                    steps{
                        script{
                            if(env.LOCAL_CAPIF == 'true'){
                                dir ("${WORKSPACE}") {
                                    sh """
                                        docker pull ${ROBOT_IMAGE_NAME}:${ROBOT_VERSION} 
                                        docker run --rm -d -t \
                                            --name robot \
                                            --network="host" \
                                            --add-host=capifcore=127.0.0.1 \
                                            -v ${WORKSPACE}/tests:/opt/robot-tests/tests/ \
                                            -v ${WORKSPACE}/libraries:/opt/robot-tests/libraries/ \
                                            -v ${WORKSPACE}/resources:/opt/robot-tests/resources/ \
                                            -v ${WORKSPACE}/results:/opt/robot-tests/results/ \
                                            -v ${WORKSPACE}/tools/capif-registration:/opt/robot-tests/capif-registration \
                                            --env NEF_URL=${NGINX_HOSTNAME} \
                                            --env BUILD_NUMBER=$BUILD_NUMBER \
                                            --env NGINX_HOSTNAME=${NGINX_HOSTNAME} \
                                            --env ADMIN_USER=${ADMIN_USER} \
                                            --env ADMIN_PASS=$ADMIN_PASS \
                                            --env CERTS_PATH=/opt/robot-tests/capif-registration/capif_onboarding \
                                            --env CAPIF_HOST=${CAPIF_HOST} \
                                            --env CAPIF_HTTPS_PORT=${CAPIF_HTTPS_PORT} \
                                            ${ROBOT_IMAGE_NAME}:${ROBOT_VERSION} 
                                    """
                                }
                            }else{
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
                                            -v ${WORKSPACE}/tools/capif-registration:/opt/robot-tests/capif-registration \
                                            --env NEF_URL=${NGINX_HOSTNAME} \
                                            --env BUILD_NUMBER=$BUILD_NUMBER \
                                            --env NGINX_HOSTNAME=${NGINX_HOSTNAME} \
                                            --env ADMIN_USER=${ADMIN_USER} \
                                            --env ADMIN_PASS=$ADMIN_PASS \
                                            --env CERTS_PATH=/opt/robot-tests/capif-registration/capif_onboarding \
                                            --env CAPIF_HOST=${CAPIF_HOST}:${CAPIF_HTTPS_PORT}  \
                                            --env CAPIF_HTTPS_PORT=${CAPIF_HTTPS_PORT} \
                                            ${ROBOT_IMAGE_NAME}:${ROBOT_VERSION} 
                                    """
                                }
                            }
                        }
                    }
                }
                stage("Register to Capif"){
                    steps{
                        sh """
                            docker exec -t robot bash /opt/robot-tests/capif-registration/register.sh
                        """
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
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS'){
                    sh """
                        docker kill robot
                    """
                }
                if(env.RUN_LOCAL_NEF == 'true'){
                    dir ("./nef-services") {
                        echo 'Shutdown all nef services'
                        catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS'){
                            sh """
                                ls -la
                                docker-compose --profile debug down -v --rmi all
                            """
                        }
                    }
                    
                }
                if(env.RUN_LOCAL_NEF == 'true' && env.LOCAL_CAPIF == 'true'){
                    dir ("./capif-services") {
                        echo 'Shutdown all capif services'
                        catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS'){
                            sh """
                                cd services
                                ./clean_capif_docker_services.sh
                            """
                        }
                    }
                }
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
            echo "Done."
        }
        success{
            echo "Test ran successfully."
        }
    }

}