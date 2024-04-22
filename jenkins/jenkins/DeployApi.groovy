pipeline {
    agent java
    
    environment {
        GIT_REPO = 'git@gitlab.com:lloyd.malfliet/FunnyApi.git'
        MAVEN_HOME = tool 'Maven'
        GITHUB_REPO = 'git@github.com:ReC82/ArtefactRepo.git'
        EMAIL_RECIPIENTS = 'lloyd.malfliet@gmail.com'
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                script {
                    git branch: 'master', url: "${GIT_REPO}", dir: 'MultiToolApi'
                }
            }
        }
        
        stage('Compile with Maven') {
            steps {
                sh "${MAVEN_HOME}/bin/mvn -f MultiToolApi/pom.xml clean compile"
            }
        }
        
        stage('Run PMD Tests') {
            steps {
                sh "${MAVEN_HOME}/bin/mvn -f MultiToolApi/pom.xml pmd:pmd"
            }
        }
        
        stage('Run Checkstyle Tests') {
            steps {
                sh "${MAVEN_HOME}/bin/mvn -f MultiToolApi/pom.xml checkstyle:check"
            }
        }
        
        stage('Push Jar to GitHub') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'your_ssh_key_id', keyFileVariable: 'SSH_KEY')]) {
                        sh "ssh-agent bash -c 'ssh-add ${SSH_KEY}; git clone ${GITHUB_REPO} && cp MultiToolApi/target/*.jar ArtefactRepo && cd ArtefactRepo && git add . && git commit -m \"Added new artifact\" && git push'"
                    }
                }
            }
        }
        
        stage('Send Email') {
            steps {
                emailext subject: 'Build Status',
                          body: "${currentBuild.currentResult}: ${currentBuild.fullDisplayName}",
                          to: "${EMAIL_RECIPIENTS}"
            }
        }
    }
}
