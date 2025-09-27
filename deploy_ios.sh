#!/bin/bash

# Скрипт для деплоя iOS приложения ProjectGT
# Использование: ./deploy_ios.sh [option]
# Опции: dev, archive, store

echo "🍎 Начинаю процесс деплоя iOS приложения..."

# Проверяем, установлен ли Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден. Пожалуйста, установите Flutter."
    exit 1
fi

# Читаем версию и номер сборки из pubspec.yaml
PUBSPEC_DIR=$(cd "$(dirname "$0")" && pwd)
PUBSPEC_FILE="$PUBSPEC_DIR/pubspec.yaml"
if [ ! -f "$PUBSPEC_FILE" ]; then
    # если скрипт запущен не из корня
    PUBSPEC_FILE="$(pwd)/pubspec.yaml"
fi

if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "❌ Не найден pubspec.yaml"
    exit 1
fi

VERSION_LINE=$(grep -E '^version:' "$PUBSPEC_FILE" | head -n1 | awk '{print $2}')
APP_VERSION=${VERSION_LINE%%+*}
BUILD_NUMBER=${VERSION_LINE##*+}

# Получаем опцию деплоя
DEPLOY_TYPE=${1:-dev}

case $DEPLOY_TYPE in
    "dev")
        echo "🔨 Создаю development сборку..."
        flutter build ios --debug --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"
        if [ $? -eq 0 ]; then
            echo "✅ Development сборка создана!"
            echo "📁 Путь: build/ios/iphoneos/Runner.app"
            echo "📱 Для установки на устройство используйте Xcode или iOS App Installer"
        else
            echo "❌ Ошибка при создании development сборки"
            exit 1
        fi
        ;;
    
    "release")
        echo "🔨 Создаю release сборку..."
        flutter build ios --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"
        if [ $? -eq 0 ]; then
            echo "✅ Release сборка создана!"
            echo "📁 Путь: build/ios/iphoneos/Runner.app"
            echo "📱 Для установки используйте Xcode"
        else
            echo "❌ Ошибка при создании release сборки"
            exit 1
        fi
        ;;
        
    "archive")
        echo "🔨 Создаю архив для деплоя..."
        flutter build ios --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"
        if [ $? -eq 0 ]; then
            echo "📦 Открываю Xcode для создания архива..."
            open ios/Runner.xcworkspace
            echo "✅ Xcode открыт!"
            echo ""
            echo "📋 Дальнейшие шаги в Xcode:"
            echo "1. Выберите 'Any iOS Device' в качестве цели"
            echo "2. Product → Archive"
            echo "3. Выберите архив и нажмите 'Distribute App'"
            echo "4. Выберите метод распространения:"
            echo "   - App Store Connect (для App Store)"
            echo "   - Ad Hoc (для тестирования)"
            echo "   - Enterprise (для корпоративного распространения)"
            echo "   - Development (для разработки)"
        else
            echo "❌ Ошибка при создании iOS сборки"
            exit 1
        fi
        ;;
        
    "store")
        echo "🏪 Попытка создания IPA для App Store..."
        flutter build ipa --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"
        if [ $? -eq 0 ]; then
            echo "✅ IPA файл создан!"
            echo "📁 Путь: build/ios/ipa/*.ipa"
        else
            echo "⚠️  Ошибка создания IPA (возможно, нужны сертификаты)"
            echo "📦 Открываю архив в Xcode..."
            if [ -d "build/ios/archive/Runner.xcarchive" ]; then
                open build/ios/archive/Runner.xcarchive
                echo "✅ Используйте Xcode Organizer для загрузки в App Store"
            else
                echo "❌ Архив не найден"
                exit 1
            fi
        fi
        ;;
        
    *)
        echo "❌ Неизвестная опция: $DEPLOY_TYPE"
        echo "Доступные опции:"
        echo "  dev     - Development сборка"
        echo "  release - Release сборка"
        echo "  archive - Создание архива в Xcode"
        echo "  store   - Попытка создания IPA для App Store"
        exit 1
        ;;
esac

echo ""
echo "📊 Информация о приложении:"
echo "  Название: ProjectGT"
echo "  Bundle ID: dev.projectgt.projectgt"
echo "  Версия: $APP_VERSION"
echo "  Build: $BUILD_NUMBER"
echo "  Deployment Target: iOS 12.0+"
echo ""
echo "🎉 Готово!"