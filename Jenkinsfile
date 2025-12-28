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
                    # Ensure dist/ folder exists
                    if [ -d "build" ] && [ ! -d "dist" ]; then
                        cp -r build dist
                    fi
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh """
                    # Создаем Dockerfile если нет
                    if [ ! -f "Dockerfile" ]; then
                        cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
                    fi
                    
                    docker build -t ${FULL_IMAGE} -t ${REGISTRY}/${IMAGE_NAME}:latest .
                    docker push ${FULL_IMAGE} 2>/dev/null || echo "Using local image"
                """
            }
        }
        
        stage('Deploy with GitOps') {
            steps {
                script {
                    echo "🚀 GitOps deployment..."
                    
                    // Если есть манифесты в репозитории - используем их
                    if (fileExists('kubernetes/')) {
                        sh '''
                            echo "📁 Using manifests from repository..."
                            
                            # Обновляем образ в deployment
                            if [ -f "kubernetes/deployment.yaml" ]; then
                                sed -i "s|image: .*|image: ${FULL_IMAGE}|g" kubernetes/deployment.yaml
                            fi
                            
                            # Применяем все манифесты из kubernetes/
                            kubectl apply -f kubernetes/
                            
                            echo "✅ Applied manifests from git repository"
                        '''
                    } else {
                        // Иначе создаем базовые манифесты
                        sh """
                            kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: react-counter
spec:
  replicas: 2
  selector:
    matchLabels:
      app: react-counter
  template:
    metadata:
      labels:
        app: react-counter
    spec:
      containers:
      - name: react-app
        image: ${FULL_IMAGE}
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: react-counter
spec:
  selector:
    app: react-counter
  ports:
  - port: 80
    targetPort: 80
EOF
                        """
                    }
                }
            }
        }
        
        stage('Add Ingress if needed') {
            steps {
                script {
                    // Проверяем, есть ли ingress в репозитории
                    if (fileExists('kubernetes/ingress.yaml')) {
                        echo "✅ Ingress found in repository, applying..."
                        sh 'kubectl apply -f kubernetes/ingress.yaml'
                    } else {
                        echo "⚠️  No ingress in repository. To add external access:"
                        echo "1. Create kubernetes/ingress.yaml in your repo"
                        echo "2. Merge to main"
                        echo "3. Jenkins will automatically apply it"
                    }
                }
            }
        }
    }
}