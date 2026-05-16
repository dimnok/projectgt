FROM ghcr.io/cirruslabs/flutter:3.38.5 AS build
WORKDIR /app

# Копируем исходный код
COPY . .

# Получаем зависимости и собираем web-версию
RUN flutter pub get
RUN flutter build web --release

# Этап 2: Раздача статики через непривилегированный Nginx
FROM nginxinc/nginx-unprivileged:alpine

# Копируем наш конфиг с поддержкой IPv4 и IPv6
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Копируем собранные файлы
COPY --from=build /app/build/web /usr/share/nginx/html

# Жестко указываем порт для парсера Timeweb
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]