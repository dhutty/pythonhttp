pipeline {
    //options {}
    agent any
    triggers {
        issueCommentTrigger('.*test.*please.*')
    }
    parameters {
        string(defaultValue: 'registry.gitlab.com', description: 'URL for Docker Registry', name: 'DOCKER_REGISTRY')
    }
    //environment {}
    stages {
        stage('setup') {
            steps {
                setBuildStatus("${env.GIT_URL}", "Pipeline", "Running", "PENDING")
                checkout([$class: 'GitSCM',
                    branches: [[name: env.GIT_COMMIT]],
                    userRemoteConfigs: [[
                      credentialsId: 'dhutty-github-token',
                      url: env.GIT_URL
                    ]]
                ])
                sh "virtualenv -p python3 venv"
                sh "source venv/bin/activate; pip install -r test-requirements.txt"
            }
        }
        stage('test') {
            steps {
                setBuildStatus("${env.GIT_URL}", "Test", "Running", "PENDING")
                sh "source venv/bin/activate; pylint -E pythonhttpserver.py"
                sh "source venv/bin/activate; yapf -d pythonhttpserver.py"
            }

            post {
                failure {
                    setBuildStatus("${env.GIT_URL}", "Test", "Test Failure", "FAILURE")
                }
                success {
                    setBuildStatus("${env.GIT_URL}", "Test", "Test Success", "SUCCESS")
                }
                aborted {
                    setBuildStatus("${env.GIT_URL}", "Test", "Test Aborted", "ERROR")
                }
            }
        }
        stage('build') {
            steps {
                script {docker.build("${params.DOCKER_REGISTRY}/dhutty/pythonhttp")}
            }
        }
        stage('publish') {
            steps {
                withDockerRegistry(credentialsId: 'dhutty-gitlab-username-password', url: "${params.DOCKER_REGISTRY}") {
                    script {docker.image("${params.DOCKER_REGISTRY}/dhutty/pythonhttp").push()}
                }
            }
        }
    }

    post {
        failure {
            setBuildStatus("${env.GIT_URL}", "Pipeline", "Pipeline Failure", "FAILURE")
        }
        success {
            setBuildStatus("${env.GIT_URL}", "Pipeline", "Pipeline Success", "SUCCESS")
        }
        aborted {
            setBuildStatus("${env.GIT_URL}", "Pipeline", "Pipeline Aborted", "ERROR")
        }
    }
}

void setBuildStatus(String url, String context, String message, String state) {
    if (env.CHANGE_ID && "${env.CHANGE_TARGET}" == "master") {
        step([
            $class: "GitHubCommitStatusSetter",
            reposSource: [$class: "ManuallyEnteredRepositorySource", url: url],
            contextSource: [$class: "ManuallyEnteredCommitContextSource", context: context],
            errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
            statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
        ]);
    }
}

