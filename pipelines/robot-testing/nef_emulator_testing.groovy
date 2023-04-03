package pipelines

pipeline{

    agent { node { label 'devopsvm' }  }

    parameters{
        string(name: 'ROBOT_DOCKER_IMAGE_NAME', defaultValue: 'robot-framework-image', description: 'Robot Docker image name')
        string(name: 'ROBOT_DOCKER_IMAGE_VERSION', defaultValue: '3.1.1', description: 'Robot Docker image version')
        string(name: 'NEF_URL', defaultValue: 'https://localhost:4443', description: 'Url to test NEF endpoints')
        string(name: 'ADMIN_USER', defaultValue: 'admin@my-email.com', description: 'NEF Admin username')
        password(name: 'ADMIN_PASS', defaultValue: 'pass', description: 'NEF Admin password')
    }

    environment {
        ROOT_DIRECTORY = "${WORKSPACE}/"
        ROBOT_TESTS_DIRECTORY = "${WORKSPACE}/tests"
        ROBOT_RESULTS_DIRECTORY = "${WORKSPACE}/results"
        NEF_SERVICES_ENDPOINT = ""
        RUN_NEF_LOCALLY = "true"
        RUN_CAPIF_LOCALLY = "true"
    }

    stages{
        stage("Checkout nef services"){
            when {
                expression { RUN_NEF_LOCALLY == 'true' }
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
                expression { RUN_NEF_LOCALLY == 'true' }
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
                        expression { RUN_NEF_LOCALLY == 'true' }
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
                        expression { RUN_NEF_LOCALLY == 'true' }
                    }
                    steps {
                        dir ("./nef-services") {
                            sh """
                                sed -i "s/USE_PUBLIC_KEY_VERIFICATION=true/USE_PUBLIC_KEY_VERIFICATION=false/g" env-file-for-local.dev
                                sed -i "s/EXTERNAL_NET=false/EXTERNAL_NET=true/g" env-file-for-local.dev
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
                stage("Set up Robot FW container."){
                    steps {
                        dir ("${ROOT_DIRECTORY}") {
                            sh """
                                docker run --rm -d -t --name netapp_robot \
                                    --network="host" \
                                    -v ${WORKSPACE}/tests:/opt/robot-tests/tests/ \
                                    -v ${WORKSPACE}/libraries:/opt/robot-tests/libraries/ \
                                    -v ${WORKSPACE}/resources:/opt/robot-tests/resources/ \
                                    -v ${WORKSPACE}/results:/opt/robot-tests/results/ \
                                    --env NEF_URL=${NEF_URL} \
                                    --env NGINX_HOSTNAME=${NEF_URL} \
                                    --env ADMIN_USER=${ADMIN_USER} \
                                    --env ADMIN_PASS=$ADMIN_PASS \
                                    ${ROBOT_DOCKER_IMAGE_NAME}:${ROBOT_DOCKER_IMAGE_VERSION}  
                            """
                        }
                    }
                }
                stage("Run test cases."){
                    steps{
                        sh """
                            docker exec -t netapp_robot bash \
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
                if(env.RUN_NEF_LOCALLY == 'true'){
                    dir ("${env.ROOT_DIRECTORY}/nef-services") {
                        echo 'Shutdown all nef services'
                        sh """
                            docker-compose --profile debug down -v --rmi all
                        """
                    }
                    dir ("${env.ROOT_DIRECTORY}/capif-services") {
                        echo 'Shutdown all capif services'
                        sh """
                            cd services
                            ./clean_capif_docker_services.sh
                        """
                    }
                }
                sh """
                    docker kill netapp_robot
                """
            }

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