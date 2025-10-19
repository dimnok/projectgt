#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# Скрипт автоматизации обновления версии приложения
# Синхронизирует версию в 3 местах одновременно:
# 1. pubspec.yaml
# 2. lib/core/constants/app_constants.dart
# 3. Supabase БД (app_versions.current_version) через Edge Function
# ════════════════════════════════════════════════════════════════════════════════

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Определяем корневую папку проекта
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${YELLOW}🔄 Скрипт обновления версии приложения${NC}"
echo "Проект: $PROJECT_ROOT"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# ШАГ 1: Извлечение текущей версии из pubspec.yaml
# ════════════════════════════════════════════════════════════════════════════════

PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
if [ ! -f "$PUBSPEC" ]; then
    echo -e "${RED}❌ Ошибка: pubspec.yaml не найден!${NC}"
    exit 1
fi

# Получаем версию из pubspec.yaml (например: 1.0.3+23 → 1.0.3)
FULL_VERSION=$(grep "^version:" "$PUBSPEC" | awk '{print $2}')
NEW_VERSION=$(echo "$FULL_VERSION" | cut -d'+' -f1)

echo -e "${GREEN}✅ Найдена версия в pubspec.yaml: $NEW_VERSION${NC}"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# ШАГ 2: Обновление lib/core/constants/app_constants.dart
# ════════════════════════════════════════════════════════════════════════════════

CONSTANTS_FILE="$PROJECT_ROOT/lib/core/constants/app_constants.dart"

if [ ! -f "$CONSTANTS_FILE" ]; then
    echo -e "${RED}❌ Ошибка: app_constants.dart не найден!${NC}"
    exit 1
fi

# Заменяем версию (macOS и Linux совместимо)
sed -i '' "s/static const String appVersion = '[^']*';/static const String appVersion = '$NEW_VERSION';/" "$CONSTANTS_FILE"

echo -e "${GREEN}✅ Обновлено: lib/core/constants/app_constants.dart${NC}"
echo "   Новая версия: $NEW_VERSION"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# ШАГ 3: Обновление БД через Supabase Edge Function
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}📊 Обновление БД через Edge Function...${NC}"

# Читаем Supabase конфиг
SUPABASE_CONFIG="$PROJECT_ROOT/supabase/config.toml"
SUPABASE_URL=$(grep "^api_url" "$SUPABASE_CONFIG" 2>/dev/null | sed "s/api_url = \"\(.*\)\"/\1/" || echo "")
PROJECT_ID=$(grep "^project_id" "$SUPABASE_CONFIG" 2>/dev/null | sed "s/project_id = \"\(.*\)\"/\1/" || echo "")

if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  Не найдены Supabase конфиги${NC}"
    echo "   Пожалуйста, обновите версию в БД вручную:"
    echo "   UPDATE app_versions SET current_version = '$NEW_VERSION', updated_at = now();"
else
    # Конструируем URL Edge Function
    EDGE_FUNCTION_URL="https://${PROJECT_ID}.supabase.co/functions/v1/update_app_version"
    
    # Получаем ANON ключ из .env или config
    SUPABASE_KEY=$(grep "SUPABASE_ANON_KEY\|anon.*key" "$PROJECT_ROOT/.env" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | head -1)
    
    if [ -z "$SUPABASE_KEY" ]; then
        echo -e "${YELLOW}⚠️  SUPABASE_ANON_KEY не найден в .env${NC}"
        echo "   Установите переменную окружения и попробуйте снова"
    else
        # Вызываем Edge Function
        RESPONSE=$(curl -s -X POST "$EDGE_FUNCTION_URL" \
          -H "Authorization: Bearer $SUPABASE_KEY" \
          -H "Content-Type: application/json" \
          -d "{\"version\": \"$NEW_VERSION\"}" 2>/dev/null || echo "")
        
        if echo "$RESPONSE" | grep -q "success"; then
            echo -e "${GREEN}✅ Обновлено: app_versions.current_version в БД${NC}"
            echo "   Новая версия: $NEW_VERSION"
        else
            echo -e "${YELLOW}⚠️  Не удалось обновить БД через API${NC}"
            echo "   Ответ сервера: $RESPONSE"
            echo "   Обновите вручную:"
            echo "   UPDATE app_versions SET current_version = '$NEW_VERSION', updated_at = now();"
        fi
    fi
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Версия синхронизирована: $NEW_VERSION${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "📋 Обновлено:"
echo "   1. ✅ pubspec.yaml: $FULL_VERSION"
echo "   2. ✅ app_constants.dart: $NEW_VERSION"
echo "   3. 🔄 app_versions (БД): $NEW_VERSION (через Edge Function)"
echo ""
