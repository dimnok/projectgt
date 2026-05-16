FROM ghcr.io/cirruslabs/flutter:3.38.5 AS build
WORKDIR /app

# Копируем исходный код
COPY . .

# Получаем зависимости и собираем web-версию
RUN flutter pub get
RUN flutter build web --release

# Этап 2: Раздача статики через непривилегированный Nginx (для облака)
FROM nginxinc/nginx-unprivileged:alpine

# Копируем наш кастомный конфиг
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Копируем собранные файлы (в Nginx Unprivileged папка по умолчанию /usr/share/nginx/html)
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]