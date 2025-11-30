pipeline {
    agent {
        kubernetes {
            label 'kaniko'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: git
    image: alpine/git:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-config
    emptyDir: {}
"""
        }
    }
    
    environment {
        AWS_REGION = 'us-west-2'
        ECR_REPO = "${ECR_REPOSITORY_URL}"
        IMAGE_TAG = "${BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/Sopizhenko/Neo_DevOps.git'
        GIT_BRANCH = 'lesson-7'
        HELM_VALUES_PATH = 'charts/django-app/values.yaml'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                container('git') {
                    script {
                        echo "Клонування репозиторію..."
                        git branch: "${GIT_BRANCH}", 
                            url: "${GIT_REPO}"
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        echo "Побудова Docker образу з тегом: ${IMAGE_TAG}"
                        
                        // Get AWS ECR login credentials
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            /kaniko/.docker/config.json
                        """
                        
                        // Build and push image using Kaniko
                        sh """
                            /kaniko/executor \
                                --context=\${WORKSPACE} \
                                --dockerfile=\${WORKSPACE}/Dockerfile \
                                --destination=${ECR_REPO}:${IMAGE_TAG} \
                                --destination=${ECR_REPO}:latest \
                                --cache=true \
                                --cache-ttl=24h
                        """
                    }
                }
            }
        }
        
        stage('Update Helm Values') {
            steps {
                container('git') {
                    script {
                        echo "Оновлення values.yaml з новим тегом образу..."
                        
                        withCredentials([usernamePassword(
                            credentialsId: 'github-credentials',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_PASSWORD'
                        )]) {
                            sh """
                                # Configure git
                                git config --global user.email "jenkins@example.com"
                                git config --global user.name "Jenkins CI"
                                
                                # Update image tag in values.yaml
                                sed -i 's|tag:.*|tag: "${IMAGE_TAG}"|g' ${HELM_VALUES_PATH}
                                
                                # Commit and push changes
                                git add ${HELM_VALUES_PATH}
                                git commit -m "Update image tag to ${IMAGE_TAG} [skip ci]"
                                
                                # Push to repository
                                git push https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/Sopizhenko/Neo_DevOps.git ${GIT_BRANCH}
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline успішно завершено! Образ ${ECR_REPO}:${IMAGE_TAG} опубліковано."
            echo "Argo CD автоматично синхронізує зміни..."
        }
        failure {
            echo "Pipeline завершився з помилкою."
        }
        always {
            cleanWs()
        }
    }
}
