pipeline {
    agent any

    environment {
        GIT_REPO_URL = 'http://172.16.100.210:9300/ict-dev/Iseng.git'
        REPO_BRANCH = 'main'
        PROJECT_NAME = 'dummy'
        APP_IMAGE_NAME = 'dummy-dum'
        NEXUS_DOCKER_REGISTRY = '172.16.100.210:9850'
        NEXUS_DOCKER_CREDS_ID = 'NEXUS_DOCKER_CREDS'

        VM_IP = '172.16.100.210'
        VM_SSH_CREDS_ID = 'ICTDEV_SSH_CRED_ID'
        APP_CONTAINER_NAME = 'dummy-app'
        APP_HOST_PORT = '5150'
        APP_CONTAINER_PORT = '80'
    }

    parameters {
        string(
            name: 'REPO_BRANCH_PARAM',
            defaultValue: 'main',
            description: 'Specify the Git branch to clone'
        )
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage('fetch') {
            steps {
                echo 'Executing fetch stage'
                echo 'Cloning repository using Gitea credentials...'
                script {
                    def checkoutResult = checkout([
                        $class: 'GitSCM',
                        branches: [[name: "${REPO_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: env.GIT_REPO_URL,
                            credentialsId: 'GITEA_PAT',
                        ]],
                    ])

                    def GIT_COMMIT = checkoutResult.GIT_COMMIT
                    REVISION_TAG = "${params.REPO_BRANCH_PARAM}-${GIT_COMMIT.take(8)}"

                    IMAGE_TAG = "${env.APP_IMAGE_NAME}:${REVISION_TAG}"
                    echo "Local image tag will be: ${IMAGE_TAG}"
                }
                echo 'Repository cloned'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_TAG}"
                    sh "docker build -t ${IMAGE_TAG} -f Dockerfile ."
                    echo "Docker image built: ${IMAGE_TAG}"
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                script {
                    echo "Logging into Nexus Docker registry: ${env.NEXUS_DOCKER_REGISTRY}"
                    withCredentials([usernamePassword(credentialsId: env.NEXUS_DOCKER_CREDS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                        def FULL_IMAGE_NAME_FOR_REGISTRY = "${env.NEXUS_DOCKER_REGISTRY}/${env.PROJECT_NAME}/${env.APP_IMAGE_NAME}:${REVISION_TAG}"

                        sh """
                            echo "${NEXUS_PASSWORD}" | docker login -u "${NEXUS_USERNAME}" --password-stdin "${env.NEXUS_DOCKER_REGISTRY}"
                        """
                        echo "Logged in to registry."

                        sh "docker tag ${IMAGE_TAG} ${FULL_IMAGE_NAME_FOR_REGISTRY}"
                        echo "Tagged image for registry: ${FULL_IMAGE_NAME_FOR_REGISTRY}"

                        echo "Pushing Docker image: ${FULL_IMAGE_NAME_FOR_REGISTRY}"
                        sh "docker push ${FULL_IMAGE_NAME_FOR_REGISTRY}"
                        echo "Docker image pushed successfully."

                        sh "docker logout ${env.NEXUS_DOCKER_REGISTRY}"
                        echo "Logged out from registry."
                    }
                }
            }
        }

        stage('Deploy to VM') {
            steps {
                script {
					def FULL_IMAGE_NAME_FOR_REGISTRY = "${env.NEXUS_DOCKER_REGISTRY}/${env.PROJECT_NAME}/${env.APP_IMAGE_NAME}:${REVISION_TAG}"
                    echo "Deploying image ${FULL_IMAGE_NAME_FOR_REGISTRY} to VM ${env.VM_IP}"

                    withCredentials([
                        sshUserPrivateKey(credentialsId: env.VM_SSH_CREDS_ID, keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'VM_SSH_USERNAME_VAR'), // Renamed SSH_KEY to SSH_KEY_PATH for clarity
                        usernamePassword(credentialsId: env.NEXUS_DOCKER_CREDS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')
                    ]) {
                        // 1. Define the content of the script that will run on the remote VM
                        //    Sensitive variables (NEXUS_PASSWORD, NEXUS_USERNAME) are interpolated here.
                        //    This content is destined for a file on the Jenkins agent, NOT for direct 'sh' execution with Groovy interpolation.
                        def deployScriptContent = """#!/bin/bash
                            set -euxo pipefail # -e: exit on error; -u: unset variables are errors; -x: print commands; -o pipefail: catch errors in pipes

                            echo "Logging into Docker registry on VM..."
                            # FIX: Use --password-stdin for security on the VM as well
                            echo "${NEXUS_PASSWORD}" | docker login -u "${NEXUS_USERNAME}" --password-stdin "${NEXUS_DOCKER_REGISTRY}"
                            echo "Logged in to registry on VM."

                            echo "Pulling image ${FULL_IMAGE_NAME_FOR_REGISTRY} on VM..."
                            docker pull ${FULL_IMAGE_NAME_FOR_REGISTRY}
                            echo "Image pulled on VM."

                            echo "Stopping and removing old container '${APP_CONTAINER_NAME}' (if exists) on VM..."
                            docker stop ${APP_CONTAINER_NAME} || true
                            docker rm ${APP_CONTAINER_NAME} || true
                            echo "Old container removed on VM."

                            echo "Running new container '${APP_CONTAINER_NAME}' on VM..."
                            docker run -d \\
                                --name ${APP_CONTAINER_NAME} \\
                                -p ${APP_HOST_PORT}:${APP_CONTAINER_PORT} \\
                                -e SERVICE_HOST="http://172.16.100.210:2113" \\
                                -e PB_SMTP_PASSWORD="pgsxnqstyqzyuiyw" \\
                                -e PB_SMTP_EMAIL="flapp.devacc@gmail.com" \\
                                -e VITE_JWT_SECRET=DAPeo7r8z9GyejePTF196CsWvFC8K3NwCMAPP \\
                                -e VITE_BASE_APP_URL=172.16.100.210:5130 \\
                                -e VITE_PB_BASE_URL="http://172.16.100.210:8090/" \\
                                -e VITE_APP_PB_COOKIE_NAME="__CMAPP_PB_TOKEN" \\
                                -e VITE_APP_COOKIE_NAME="__SESSION" \\
                                --restart always \\
                                ${FULL_IMAGE_NAME_FOR_REGISTRY}
                            echo "New container started on VM."

                            docker logout ${NEXUS_DOCKER_REGISTRY}
                            echo "Logged out from registry on VM."
                        """

                        // 2. Write the script content to a temporary file on the Jenkins agent
                        writeFile(file: "${env.WORKSPACE}/deploy_on_vm.sh", text: deployScriptContent)
                        sh "chmod +x ${env.WORKSPACE}/deploy_on_vm.sh"

                        // 3. Execute the script on the remote VM via SSH
                        //    Crucially, SSH_KEY_PATH (the temporary file path of the key) is passed directly.
                        //    The local script file is securely piped to the remote bash.
                        sh(script: "ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VM_SSH_USERNAME_VAR}@${env.VM_IP} bash -s < ${env.WORKSPACE}/deploy_on_vm.sh",
                           credentials: ['SSH_KEY_PATH'], // Explicitly tell sh to handle this as a secret credential, not a literal string
                           label: 'Execute deploy script on VM')
                    }
                    echo "Deployment to VM completed."
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}