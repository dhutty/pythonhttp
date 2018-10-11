pipeline {
    //options {}
    agent any
    triggers {
        issueCommentTrigger('.*test.*please.*')
    }
    //parameters {}
    //environment {}
    stages {
        stage('setup') {
            steps {
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
        stage('build') {
            steps {
                //pullRequest.comment("Running Pipeline stage: build")
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dhutty-github-token',
                        usernameVariable: 'GITLAB_USER',
                        passwordVariable: 'GITLAB_TOKEN'
                        ),
                        ]) {
                            sh "source venv/bin/activate; pylint pythonhttpserver.py"
                        }
            }

            /* post { */
            /*     failure { */
            /*     } */
            /*     success { */
            /*     } */
            /*     aborted { */
            /*     } */
            /*     always { */
            /*         cleanWs skipWhenFailed: true, notFailBuild: true, deleteDirs: true */
            /*     } */
            /* } */

        }

        stage('test') {
            steps {
                //pullRequest.comment("Running Pipeline stage: test")
                sh "pylint pythonhttpserver.py"
            }
        }
    }
}
