pipeline {
    agent any
    
    environment {
        REGISTRY = 'localhost:5000'
        IMAGE_NAME = 'react-counter'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build React') {
            steps {
                sh '''
                    npm install
                    npm run build
                '''
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                sh """
                    # Создаем Dockerfile
                    cat > Dockerfile << 'DOCKERFILE'
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE
                    
                    # Собираем образ
                    docker build -t ${FULL_IMAGE} -t ${REGISTRY}/${IMAGE_NAME}:latest .
                    
                    # Пушим в локальный registry
                    docker push ${FULL_IMAGE}
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }
        
        stage('Deploy to Kubernetes') {
    steps {
        script {
            echo "🚀 Деплоим в Kubernetes..."
            
            sh """
                IMAGE=$(cat image.txt)
                echo "Используем образ: $IMAGE"
                
                # Если используете kustomize
                if [ -f "kubernetes/kustomization.yaml" ]; then
                    cd kubernetes
                    kustomize edit set image react-counter=$IMAGE
                    kustomize build . | kubectl apply -f -
                
                # Если отдельные файлы
                else
                    # Обновляем образ в deployment
                    sed -i "s|image: .*|image: $IMAGE|g" kubernetes/deployment.yaml
                    
                    # Применяем все манифесты
                    kubectl apply -f kubernetes/
                fi
                
                echo "✅ Все манифесты применены"
            """
        }
    }
}
        
        stage('Verify') {
            steps {
                sh '''
                    echo "⏳ Waiting for pods..."
                    sleep 10
                    kubectl get pods -l app=react-counter
                    kubectl describe pods -l app=react-counter | grep -A5 Events
                '''
            }
        }
    }
}