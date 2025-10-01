pipeline {
    agent any

    environment {
        NEXUS_DOCKER_REGISTRY = "localhost:8083"
        NEXUS_URL = "http://localhost:8081"
        SONARQUBE_URL = "http://localhost:9000"
        GRAFANA_URL = "http://localhost:3000"
    }

    stages {
        stage('Clone from GitHub') {
            steps {
                git branch: 'main', url: 'https://github.com/Goldenboy666/docker-spring-boot-git.git'
                sh 'chmod +x ./mvnw'
                echo "✅ Code successfully pulled from GitHub"
            }
        }

        stage('Build Application') {
            steps {
                sh './mvnw clean package -DskipTests'
                echo "✅ Application built successfully"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}")
                }
                echo "✅ Docker image built for Nexus"
            }
        }

        stage('Push to Nexus') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'nexus-docker-creds',
                        usernameVariable: 'NEXUS_USER', 
                        passwordVariable: 'NEXUS_PASSWORD'
                    )]) {
                        sh """
                            docker login ${env.NEXUS_DOCKER_REGISTRY} -u $NEXUS_USER -p $NEXUS_PASSWORD
                            docker push ${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}
                        """
                    }
                }
                echo "✅ Docker image pushed to Nexus Repository"
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
                echo "✅ Application deployed from Nexus on port 8085"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "Application URL: http://localhost:8085"
            echo "Nexus: http://localhost:8081" 
            echo "Check Nexus: http://localhost:8081 → Browse → docker-internal"
        }
        failure {
            echo "❌ Pipeline failed - check logs above"
        }
    }
}
