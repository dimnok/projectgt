#!/bin/bash

# Скрипт для деплоя Flutter приложения ProjectGT
# Использование: ./deploy.sh [platform]
# Платформы: web (по умолчанию), ios

PLATFORM=${1:-web}

if [ "$PLATFORM" = "ios" ]; then
    echo "🍎 Перенаправляю на iOS деплой..."
    ./deploy_ios.sh archive
    exit $?
fi

echo "🚀 Начинаю процесс веб-деплоя на Surge..."

# Проверяем, установлен ли Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден. Пожалуйста, установите Flutter."
    exit 1
fi

# Для деплоя используем npx с зафиксированной версией surge
# Установка глобального surge не требуется

echo "🔨 Создаю веб-сборку..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Ошибка при создании веб-сборки"
    exit 1
fi

echo "☁️  Деплою на Surge (домен projectgt.surge.sh)..."
cd build/web && npx -y surge@0.23.0 . projectgt.surge.sh

if [ $? -eq 0 ]; then
    echo "✅ Деплой успешно завершён!"
    echo "🌐 Приложение опубликовано на указанном Surge домене (см. вывод выше)"
else
    echo "❌ Ошибка при деплое"
    exit 1
fi

echo "🎉 Готово!"