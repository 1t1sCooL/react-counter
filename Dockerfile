# Сборка
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Nginx
FROM nginx:alpine
# 1. Удаляем дефолтный конфиг
RUN rm /etc/nginx/conf.d/default.conf

# 2. Создаем папку, соответствующую URL
RUN mkdir -p /usr/share/nginx/html/react-counter

# 3. Копируем наш конфиг
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 4. ВАЖНО: Копируем файлы ВНУТРЬ папки react-counter
COPY --from=build /app/dist /usr/share/nginx/html/react-counter/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]