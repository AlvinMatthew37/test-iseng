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

        stage('run') {
            steps {
                echo "finish ${REPO_BRANCH_PARAM}"
            }
        }

        stage('Approval Process'){
            parallel{
                stage('Sending Approval') {
                    steps {
                        script {
                            emailext (
                                subject: "GG - Jenkins - Pipeline Approval Needed - Deployment Application AMPER #${env.BUILD_NUMBER}",
                                mimeType: 'text/html',
                                body: """
                                <html>
                                    <body>
                                        <p>Hello Team,</p>
                                        <p><strong>A Jenkins deployment requires your approval.</strong></p>
                                        <ul>
                                            <li><strong>Application:</strong> Test Email</li>
                                            <li><strong>Pipeline:</strong> ${env.JOB_NAME}</li>
                                            <li><strong>Build Number:</strong> ${env.BUILD_NUMBER}</li>
                                        </ul>
                                        <p>
                                            Please click the link below to <strong>approve or reject</strong> the deployment:
                                        </p>
                                        <p>
                                            <a href="${env.BUILD_URL}/input" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                                                Review & Approve Build
                                            </a>
                                        </p>
                                        <p>Regards,<br>Jenkins CI</p>
                                    </body>
                                </html>
                                """,
                                to: 'alvinmatthew370z@gmail.com'
                            )
                        }
                    }
                }
                stage('Waiting for Approval') {
                    steps {
                        timeout(time: 2, unit: 'HOURS') {
                            input message: 'Approve the deployment?', ok: 'Approve', submitter: 'ictdev'
                        }
                    }
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