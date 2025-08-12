pipeline {
    agent any

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
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}