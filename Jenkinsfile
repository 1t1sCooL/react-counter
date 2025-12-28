pipeline {
    agent any
    
    environment {
        // Настройки Docker
        DOCKER_IMAGE = 'react-counter'
        DOCKER_TAG = "${BUILD_NUMBER}"
        
        // Настройки Kubernetes
        K8S_NAMESPACE = 'default'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }
    
    stages {
        // Этап 1: Получение кода
        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    echo "📦 Репозиторий: ${GIT_URL}"
                    echo "📝 Ветка: ${GIT_BRANCH}"
                    echo "📋 Последний коммит:"
                    git log --oneline -1
                    echo "📁 Содержимое:"
                    ls -la
                '''
            }
        }
        
        // Этап 2: Установка зависимостей
        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "📦 Устанавливаем зависимости Node.js..."
                    if [ -f "package.json" ]; then
                        npm install || npm ci
                        echo "✅ Зависимости установлены"
                    else
                        echo "❌ Файл package.json не найден"
                        exit 1
                    fi
                '''
            }
        }
        
        // Этап 3: Сборка React приложения
        stage('Build React App') {
            steps {
                sh '''
                    echo "🔨 Собираем React приложение..."
                    npm run build
                    echo "📁 Содержимое папки dist:"
                    ls -la dist/
                '''
            }
        }
        
        // Этап 4: Создание Docker образа
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Создаем Docker образ..."
                    
                    // Создаем Dockerfile если его нет
                    sh '''
                        if [ ! -f "Dockerfile" ]; then
                            echo "📝 Создаем Dockerfile..."
                            cat > Dockerfile << "DOCKERFILE"
# Stage 1: Build React app
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine
COPY --from=dist /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE
                        fi
                    '''
                    
                    // Собираем Docker образ
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    
                    // Сохраняем имя образа
                    writeFile file: 'image.txt', text: "${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        // Этап 5: Деплой в Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "🚀 Деплоим в Kubernetes..."
                    
                    sh '''
                        IMAGE=$(cat image.txt)
                        echo "Используем образ: $IMAGE"
                        
                        // Создаем Kubernetes манифест
                        cat > k8s-deployment.yaml << "K8S_YAML"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: react-counter
  namespace: default
  labels:
    app: react-counter
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
        image: IMAGE_PLACEHOLDER
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: react-counter
  namespace: default
spec:
  selector:
    app: react-counter
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
K8S_YAML
                        
                        // Заменяем плейсхолдер на реальный образ
                        sed -i "s|IMAGE_PLACEHOLDER|$IMAGE|g" k8s-deployment.yaml
                        
                        echo "📋 Применяем Kubernetes манифест:"
                        cat k8s-deployment.yaml
                        
                        // Применяем манифест
                        kubectl apply -f k8s-deployment.yaml
                        
                        // Ждем rollout
                        echo "⏳ Ожидаем запуск подов..."
                        sleep 10
                        kubectl rollout status deployment/react-counter --timeout=180s
                    '''
                }
            }
        }
        
        // Этап 6: Проверка деплоя
        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Проверяем деплой..."
                    echo ""
                    echo "📊 Deployment:"
                    kubectl get deployment react-counter
                    echo ""
                    echo "🐳 Pods:"
                    kubectl get pods -l app=react-counter
                    echo ""
                    echo "🔗 Service:"
                    kubectl get svc react-counter
                    echo ""
                    echo "📝 Логи (первые 5 строк):"
                    kubectl logs deployment/react-counter --tail=5 2>/dev/null || echo "Логи пока недоступны"
                    echo ""
                    echo "✅ Деплой завершен!"
                '''
            }
        }
    }
    
    post {
        success {
            echo '🎉 React приложение успешно задеплоено в Kubernetes!'
            // Можно добавить уведомления
            // slackSend(color: 'good', message: "✅ React app deployed successfully!")
        }
        failure {
            echo '❌ Деплой не удался'
            // Автоматический откат
            sh '''
                echo "🔄 Пытаемся выполнить откат..."
                kubectl rollout undo deployment/react-counter
            '''
        }
        always {
            cleanWs()
            echo '🧹 Workspace очищен'
        }
    }
}