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
                        sshUserPrivateKey(credentialsId: env.VM_SSH_CREDS_ID, keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'VM_SSH_USERNAME_VAR'),
                        usernamePassword(credentialsId: env.NEXUS_DOCKER_CREDS_ID, passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')
                    ]) {
                        // Copy docker-compose.yml to VM
                        sh "scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.WORKSPACE}/docker-compose.yml ${VM_SSH_USERNAME_VAR}@${env.VM_IP}:/tmp/docker-compose.yml"

                        // Compose deploy script
                        def deployScriptContent = """#!/bin/bash
                        set -euxo pipefail

                        echo "${NEXUS_PASSWORD}" | docker login -u "${NEXUS_USERNAME}" --password-stdin "${NEXUS_DOCKER_REGISTRY}"

                        export IMAGE_NAME=${FULL_IMAGE_NAME_FOR_REGISTRY}
                        docker compose -f /tmp/docker-compose.yml pull
                        docker compose -f /tmp/docker-compose.yml up -d

                        docker logout ${NEXUS_DOCKER_REGISTRY}
                        """

                        writeFile(file: "${env.WORKSPACE}/deploy_on_vm.sh", text: deployScriptContent)
                        sh "chmod +x ${env.WORKSPACE}/deploy_on_vm.sh"

                        // Run deploy script on VM
                        sh(script: "ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VM_SSH_USERNAME_VAR}@${env.VM_IP} bash -s < ${env.WORKSPACE}/deploy_on_vm.sh")
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