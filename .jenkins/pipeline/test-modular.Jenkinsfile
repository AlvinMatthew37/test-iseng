@Library('jenkins-lib') _

pipeline {
    agent any

    environment {
        GIT_REPO_URL = 'http://172.16.100.210:9300/effct/Iseng.git'
        PROJECT_NAME = 'test-modular'
        APP_IMAGE_NAME = 'test-modular'
        NEXUS_DOCKER_REGISTRY_PUSH = '192.168.150.203:1234'
        NEXUS_DOCKER_REGISTRY_PULL = '10.0.80.192:1234'
        NEXUS_DOCKER_CREDS_ID = 'NEXUS_DOCKER_CREDS'
        VM_IP = '172.16.100.210'
        VM_SSH_CREDS_ID = 'ICTDEV_SSH_CRED_ID'
        SONARQUBE_TOKEN = credentials('SONARQUBE_TOKEN')
        VM_PATH = '/home/ictdev/env/pipeline-management/pipeline-management-fe/.env'

        TARGET_IP = '172.16.100.210'
    }

    parameters {
        string(name: 'REPO_BRANCH_NAME', defaultValue: 'main', description: 'Branch to build')
    }

    // options {
    //     timestamps()
    //     ansiColor('xterm')
    //     disableConcurrentBuilds()
    //     buildDiscarder(logRotator(numToKeepStr: '10'))
    // }

    stages {
        stage('Ping') {
            steps {
                testPing(
                    repoUrl: env.TARGET_IP,
                )
            }
        }
        stage('Fetch Source') {
            steps {
                fetchSource(
                    repoUrl: env.GIT_REPO_URL,
                    branch: params.REPO_BRANCH_NAME,
                    credentialsId: 'GITEA_PAT',
                    appImageName: env.APP_IMAGE_NAME
                )
            }
        }

        // stage('Code Scan') {
        //     steps {
        //         sonarScan(
        //             sonarEnvName: 'SonarQube',
        //             sonarUrl: 'http://172.16.100.210:9700',
        //             appImageName: env.APP_IMAGE_NAME,
        //             sonarToken: env.SONARQUBE_TOKEN
        //         )
        //     }
        // }

        stage('Build Docker Image') {
            steps {
                buildDockerImage(
                    dockerCredsId: env.NEXUS_DOCKER_CREDS_ID,
                    registryPush: env.NEXUS_DOCKER_REGISTRY_PUSH
                )
            }
        }

        // stage('Security Scan') {
        //     steps {
        //         trivyScan()
        //     }
        // }

        stage('Push Image') {
            steps {
                pushDockerImage(
                    dockerCredsId: env.NEXUS_DOCKER_CREDS_ID,
                    registryPush: env.NEXUS_DOCKER_REGISTRY_PUSH,
                    projectName: env.PROJECT_NAME
                )
            }
        }

        stage('Clear Local Images') {
            steps {
                clearLocalImages(
                    registryPush: env.NEXUS_DOCKER_REGISTRY_PUSH,
                    projectName: env.PROJECT_NAME
                )
            }
        }

        stage('Deploy to VM') {
            steps {
                deployToVM(
                    registryPull: env.NEXUS_DOCKER_REGISTRY_PULL,
                    dockerCredsId: env.NEXUS_DOCKER_CREDS_ID,
                    projectName: env.PROJECT_NAME,
                    vmIp: env.VM_IP,
                    vmPath: env.VM_PATH,
                    vmSshCredsId: env.VM_SSH_CREDS_ID
                )
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Build failed."
        }
        always {
            cleanWs()
        }
    }
}
