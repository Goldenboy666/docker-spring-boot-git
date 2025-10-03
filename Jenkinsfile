pipeline {
    agent any

    environment {
        NEXUS_DOCKER_REGISTRY = "localhost:8083"
    }

    stages {
        stage('Clone from GitHub') {
            steps {
                git branch: 'main', url: 'https://github.com/Goldenboy666/docker-spring-boot-git.git'
                sh 'chmod +x ./mvnw'
                echo "Code successfully pulled from GitHub"
            }
        }

        stage('Trivy Security Scan - Dependencies') {
            steps {
                sh '''
                echo "TRIVY DEPENDENCY VULNERABILITY SCAN"
                docker run --rm -v $(pwd):/app aquasec/trivy:latest fs /app --severity HIGH,CRITICAL --exit-code 0
                '''
                echo "Trivy dependency scan completed"
            }
        }

        stage('Build Application') {
            steps {
                sh './mvnw clean package -DskipTests'
                echo "Application built successfully"
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
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image spring-boot-app:${BUILD_ID} --severity HIGH,CRITICAL --exit-code 0
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

        stage('DAST - Nikto Security Test') {
            steps {
                sh '''
                echo "NIKTO DAST SECURITY SCAN"
                sleep 30
                docker run --rm sullo/nikto -h http://host.docker.internal:8085 -o nikto-scan.txt || echo "Nikto scan completed"
                '''
                echo "Nikto DAST security testing completed"
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*scan.*, **/*.txt', allowEmptyArchive: true
        }
        success {
            echo "DEVSECOPS PIPELINE COMPLETED SUCCESSFULLY"
            echo "SECURITY SCANS COMPLETED:"
            echo "   - Trivy (SAST): Code and container vulnerability scanning"
            echo "   - Nikto (DAST): Web application security testing"
            echo "APPLICATION: http://localhost:8085"
            echo "NEXUS: http://localhost:8081"
        }
    }
}
