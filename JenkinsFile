pipeline {
    agent any
    
    tools {
        kubectl 'kubectl'
    }
    
    environment {
        // Настройки Docker
        DOCKER_IMAGE = 'myapp'
        DOCKER_TAG = "${BUILD_NUMBER}"
        
        // Или используйте Docker Hub
        // DOCKER_REGISTRY = 'docker.io/ваш-username'
        // DOCKER_IMAGE = "${DOCKER_REGISTRY}/myapp"
        
        // Настройки Kubernetes
        K8S_NAMESPACE = 'default'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }
    
    triggers {
        // Запуск при пуше в main ветку
        pollSCM('H/5 * * * *')
        // Или через GitHub/GitLab webhook
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        // Этап 1: Получение кода
        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    echo "📦 Репозиторий: ${GIT_URL}"
                    echo "📝 Ветка: ${GIT_BRANCH}"
                    echo "📋 Коммит: $(git log --oneline -1)"
                '''
            }
        }
        
        // Этап 2: Тестирование
        stage('Test') {
            steps {
                script {
                    // Пример тестов для Node.js
                    if (fileExists('package.json')) {
                        sh 'npm install'
                        sh 'npm test'
                    }
                    // Пример для Python
                    if (fileExists('requirements.txt')) {
                        sh 'pip install -r requirements.txt'
                        sh 'pytest'
                    }
                }
            }
        }
        
        // Этап 3: Сборка Docker образа
        stage('Build Docker Image') {
            when {
                anyOf {
                    expression { return fileExists('Dockerfile') }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🐳 Сборка Docker образа..."
                    
                    // Собираем образ
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    
                    // Если используете Docker Hub или другой registry
                    // withCredentials([usernamePassword(
                    //     credentialsId: 'docker-hub',
                    //     usernameVariable: 'DOCKER_USER',
                    //     passwordVariable: 'DOCKER_PASS'
                    // )]) {
                    //     sh "docker login -u $DOCKER_USER -p $DOCKER_PASS"
                    //     sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    //     sh "docker push ${DOCKER_IMAGE}:latest"
                    // }
                    
                    // Сохраняем имя образа в файл
                    writeFile file: 'image.txt', text: "${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        // Этап 4: Деплой в Kubernetes
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "🚀 Начинаем деплой в Kubernetes..."
                    
                    // Обновляем образ в Kubernetes манифестах
                    sh '''
                        IMAGE=$(cat image.txt)
                        echo "Используем образ: $IMAGE"
                        
                        # Вариант 1: Через kustomize (рекомендуется)
                        if [ -f "kubernetes/kustomization.yaml" ]; then
                            cd kubernetes
                            kustomize edit set image myapp=$IMAGE
                            kustomize build . | kubectl apply -f -
                            
                        # Вариант 2: Прямое обновление deployment
                        elif [ -f "kubernetes/deployment.yaml" ]; then
                            sed -i "s|image: .*|image: $IMAGE|g" kubernetes/deployment.yaml
                            kubectl apply -f kubernetes/
                            
                        # Вариант 3: Через kubectl set image
                        else
                            kubectl set image deployment/myapp myapp=$IMAGE -n ${K8S_NAMESPACE} || \
                            kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: $IMAGE
        ports:
        - containerPort: 3000
EOF
                        fi
                    '''
                    
                    // Ждем rollout
                    sh '''
                        echo "⏳ Ожидаем rollout..."
                        kubectl rollout status deployment/myapp -n ${K8S_NAMESPACE} --timeout=300s
                        echo "✅ Rollout завершен успешно!"
                    '''
                }
            }
        }
        
        // Этап 5: Проверка деплоя
        stage('Verify Deployment') {
            steps {
                script {
                    echo "🔍 Проверяем деплой..."
                    
                    sh '''
                        # Проверяем поды
                        echo "📊 Статус подов:"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=myapp
                        
                        # Проверяем deployment
                        echo "📈 Статус deployment:"
                        kubectl get deployment myapp -n ${K8S_NAMESPACE}
                        
                        # Проверяем сервис
                        echo "🔗 Статус сервиса:"
                        kubectl get svc myapp -n ${K8S_NAMESPACE}
                        
                        # Проверяем логи (первые 5 строк)
                        echo "📝 Логи приложения:"
                        kubectl logs -n ${K8S_NAMESPACE} deployment/myapp --tail=5 2>/dev/null || echo "Логи пока недоступны"
                        
                        # Smoke test (если есть endpoint)
                        # kubectl port-forward svc/myapp 8080:80 -n ${K8S_NAMESPACE} &
                        # sleep 5
                        # curl -f http://localhost:8080/health && echo "✅ Smoke test пройден" || echo "❌ Smoke test не пройден"
                        # pkill -f "port-forward"
                    '''
                }
            }
        }
        
        // Этап 6: Создание Git tag (опционально)
        stage('Create Git Tag') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        git config user.email "jenkins@ci"
                        git config user.name "Jenkins"
                        git tag -a "v${BUILD_NUMBER}" -m "Deployed build ${BUILD_NUMBER} to production"
                        git push origin "v${BUILD_NUMBER}"
                    '''
                    echo "🏷️ Создан Git tag v${BUILD_NUMBER}"
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Деплой выполнен успешно!'
            // Уведомления
            // slackSend(color: 'good', message: "✅ Deployed ${env.JOB_NAME} #${env.BUILD_NUMBER}")
            // emailext to: 'team@example.com', subject: 'Deployment Successful'
        }
        failure {
            echo '❌ Деплой не удался!'
            
            // Автоматический откат
            script {
                echo "🔄 Пытаемся выполнить откат..."
                sh '''
                    kubectl rollout undo deployment/myapp -n ${K8S_NAMESPACE}
                    echo "Откат к предыдущей версии выполнен"
                '''
            }
            
            // Уведомления об ошибке
            // slackSend(color: 'danger', message: "❌ Deployment failed for ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        always {
            cleanWs() // Очистка workspace
            echo '🧹 Workspace очищен'
            
            // Сохраняем артефакты
            archiveArtifacts artifacts: 'image.txt', fingerprint: true
        }
    }
}