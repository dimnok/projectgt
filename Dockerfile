FROM ghcr.io/cirruslabs/flutter:3.38.5 AS build
WORKDIR /app

# Копируем исходный код
COPY . .

# Получаем зависимости и собираем web-версию
RUN flutter pub get
RUN flutter build web --release

# Этап 2: Раздача статики через непривилегированный Nginx (для облака)
FROM nginxinc/nginx-unprivileged:alpine

# Копируем наш кастомный конфиг-шаблон (nginx сам подставит порт при запуске)
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Копируем собранные файлы
COPY --from=build /app/build/web /usr/share/nginx/html

# Задаем порт по умолчанию (8080), если облако не передаст свой
ENV PORT=8080
EXPOSE $PORT

# Команду CMD не указываем — используем стандартный скрипт от nginxinc,
# который подставит $PORT в шаблон и запустит nginx.