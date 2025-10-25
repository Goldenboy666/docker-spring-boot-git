pipeline {
    agent any

    environment {
        NEXUS_DOCKER_REGISTRY = "192.168.210.110:8083"
        SONARQUBE_URL = "http://devops-project-sonarqube-1:9000"
    }

    stages {
        stage('Clone from GitHub') {
            steps {
                git branch: 'main', url: 'https://github.com/Goldenboy666/docker-spring-boot-git.git'
                sh 'chmod +x ./mvnw'
                echo "Code successfully pulled from GitHub"
            }
        }

        stage('Build Application') {
            steps {
                sh './mvnw clean compile -DskipTests'
                echo "Application compiled successfully"
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    echo "RUNNING SONARQUBE STATIC ANALYSIS"
                    ./mvnw sonar:sonar \
                      -Dsonar.projectKey=spring-boot-app \
                      -Dsonar.host.url=http://devops-project-sonarqube-1:9000 \
                      -Dsonar.login=$SONAR_TOKEN \
                      -Dsonar.java.binaries=target/classes
                    '''
                }
                echo "SonarQube analysis completed"
            }
        }

        stage('Package Application') {
            steps {
                sh './mvnw package -DskipTests'
                echo "Application packaged successfully"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t spring-boot-app:${env.BUILD_ID} ."
                }
                echo "Docker image built successfully"
            }
        }

        stage('Tag and Push to Nexus') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'nexus-docker-creds',
                        usernameVariable: 'NEXUS_USER', 
                        passwordVariable: 'NEXUS_PASSWORD'
                    )]) {
                        sh '''
                            docker tag spring-boot-app:${BUILD_ID} ${NEXUS_DOCKER_REGISTRY}/spring-boot-app:${BUILD_ID}
                            echo "${NEXUS_PASSWORD}" | docker login ${NEXUS_DOCKER_REGISTRY} -u ${NEXUS_USER} --password-stdin
                            docker push ${NEXUS_DOCKER_REGISTRY}/spring-boot-app:${BUILD_ID}
                        '''
                    }
                }
                echo "Docker image pushed to Nexus Repository"
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'nexus-docker-creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )]) {
                        sh '''
                            echo "${NEXUS_PASSWORD}" | docker login ${NEXUS_DOCKER_REGISTRY} -u ${NEXUS_USER} --password-stdin
                            docker stop spring-boot-app || true
                            docker rm spring-boot-app || true
                            docker pull ${NEXUS_DOCKER_REGISTRY}/spring-boot-app:${BUILD_ID}
                            docker run -d --name spring-boot-app -p 8085:8080 ${NEXUS_DOCKER_REGISTRY}/spring-boot-app:${BUILD_ID}
                        '''
                    }
                }
                echo "Application deployed from Nexus on port 8085"
            }
        }
    }

    post {
        success {
            echo "PIPELINE COMPLETED SUCCESSFULLY"
        }
    }
}
