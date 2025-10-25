pipeline {
    agent any

    environment {
        NEXUS_DOCKER_REGISTRY = "localhost:8083"
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

        stage('Trivy Security Scan - Dependencies') {
            steps {
                sh '''
                echo "TRIVY DEPENDENCY VULNERABILITY SCAN"
                docker run --rm \
                  -v $(pwd):/app \
                  -v /home/saifdevops/.cache/trivy:/root/.cache/trivy \
                  aquasec/trivy:latest fs /app \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  --no-progress \
                  --scanners vuln \
                  --skip-db-update \
                  --skip-java-db-update
                '''
                echo "Trivy dependency scan completed"
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

        stage('Trivy Security Scan - Container') {
            steps {
                sh '''
                echo "TRIVY CONTAINER IMAGE VULNERABILITY SCAN"
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v /home/saifdevops/.cache/trivy:/root/.cache/trivy \
                  aquasec/trivy:latest image spring-boot-app:${BUILD_ID} \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  --no-progress \
                  --scanners vuln \
                  --skip-db-update \
                  --skip-java-db-update
                '''
                echo "Trivy container image scan completed"
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
                        sh """
                            docker tag spring-boot-app:${env.BUILD_ID} ${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}
                            docker login ${env.NEXUS_DOCKER_REGISTRY} -u $NEXUS_USER -p $NEXUS_PASSWORD
                            docker push ${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}
                        """
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
                        sh """
                            docker login ${env.NEXUS_DOCKER_REGISTRY} -u $NEXUS_USER -p $NEXUS_PASSWORD
                            docker stop spring-boot-app || true
                            docker rm spring-boot-app || true
                            docker pull ${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}
                            docker run -d --name spring-boot-app -p 8085:8080 ${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}
                        """
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
