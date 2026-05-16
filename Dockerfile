FROM ghcr.io/cirruslabs/flutter:3.24.3 AS build
WORKDIR /app

# Копируем исходный код
COPY . .

# Получаем зависимости и собираем web-версию
RUN flutter pub get
RUN flutter build web --release

# Этап 2: Раздача статики через Nginx
FROM nginx:alpine

# Копируем наш кастомный конфиг (для правильной работы роутинга)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Копируем собранные файлы
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]