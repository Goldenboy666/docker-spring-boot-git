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
                # Scan the local image instead of Nexus image
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
                            # Tag the local image for Nexus
                            docker tag spring-boot-app:${env.BUILD_ID} ${env.NEXUS_DOCKER_REGISTRY}/spring-boot-app:${env.BUILD_ID}
                            
                            # Push to Nexus
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

        stage('DAST - OWASP ZAP Security Test') {
            steps {
                sh '''
                echo "OWASP ZAP DAST SECURITY SCAN"
                # Wait for app to be ready
                sleep 30
                docker run --rm -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-stable zap-baseline.py \
                  -t http://host.docker.internal:8085 -I -J zap-report.json || echo "ZAP scan completed"
                '''
                echo "OWASP ZAP DAST security testing completed"
            }
        }

        stage('DAST - Nikto Web Scan') {
            steps {
                sh '''
                echo "NIKTO WEB VULNERABILITY SCAN"
                docker run --rm sullo/nikto -h http://host.docker.internal:8085 -o nikto-scan.txt || echo "Nikto scan completed"
                '''
                echo "Nikto web vulnerability scan completed"
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*report.*, **/*scan.*, **/*.json, **/*.txt', allowEmptyArchive: true
        }
        success {
            echo "DEVSECOPS PIPELINE COMPLETED SUCCESSFULLY"
            echo "SECURITY SCANS:"
            echo "   - Trivy (SAST): Dependency & Container scanning"
            echo "   - OWASP ZAP (DAST): Web application security testing"
            echo "   - Nikto (DAST): Web server vulnerability scanning"
            echo "APPLICATION: http://localhost:8085"
            echo "NEXUS: http://localhost:8081"
        }
        failure {
            echo "Pipeline failed - check logs above"
        }
    }
}
