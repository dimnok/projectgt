#!/bin/bash

# Настройки
APP_NAME=$(find build/macos/Build/Products/Release/ -maxdepth 1 -name "*.app" | head -n 1)
APP_BASENAME=$(basename "$APP_NAME")
DMG_NAME="StroykaPRO_macOS.dmg"
DMG_PATH="build/macos/Build/Products/Release/${DMG_NAME}"
VOL_NAME="Stroyka PRO Installer"
TMP_DIR="build/macos/dmg_tmp"

echo "📦 Начинаю создание DMG для ${APP_BASENAME}..."

# Проверка наличия сборки
if [ -z "$APP_NAME" ] || [ ! -d "$APP_NAME" ]; then
    echo "❌ Ошибка: Сборка .app не найдена в build/macos/Build/Products/Release/"
    echo "Сначала запустите: flutter build macos --release"
    exit 1
fi

# Очистка предыдущих попыток
rm -rf "$TMP_DIR"
rm -f "$DMG_PATH"

# Создание временной папки
mkdir -p "$TMP_DIR"

# Копирование приложения
cp -R "$APP_NAME" "$TMP_DIR/"

# Создание симлинка на Applications
ln -s /Applications "$TMP_DIR/Applications"

# Создание DMG
echo "инфо: Создаю образ диска..."
hdiutil create -volname "$VOL_NAME" -srcfolder "$TMP_DIR" -ov -format UDZO "$DMG_PATH"

# Очистка
rm -rf "$TMP_DIR"

echo "--------------------------------------------------"
echo "✅ DMG успешно создан!"
echo "📍 Путь: $DMG_PATH"
echo "--------------------------------------------------"

