pipeline {
    agent any

    stages {
        stage('Maven Install') {
            agent{
                docker {
                    image 'maven:3.5.0'
                }
            }

            steps{
                sh 'mvn clean install'
            }
        }
        stage('Docker Build') {
            agent {label "Java"}
            steps {
                sh 'docker build -t myrepo:imagename:version .'
            }
        }
    }
}