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