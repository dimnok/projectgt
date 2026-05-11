#!/usr/bin/env bash
#
# Полный релиз ProjectGT:
#   1) Поднятие версии в pubspec.yaml
#   2) Сборка IPA (development export) для SideStore
#   3) Обновление sidestore/source.json
#   4) Коммит, создание тега и пуш на GitHub
#   5) Создание GitHub Release и загрузка IPA
#
# ВАЖНО: Сборка Windows (.exe) происходит автоматически в облаке 
# (GitHub Actions) после публикации релиза. iOS и macOS собираются локально.
#
# Запуск: ./tools/projectgt_release.sh
# Опции:
#   --skip-bump       не менять версию (пересобрать текущую)
#   --build-only-bump увеличить только номер сборки (build)
#   --help            справка

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SKIP_BUMP=false
BUILD_ONLY_BUMP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-bump) SKIP_BUMP=true ;;
    --build-only-bump) BUILD_ONLY_BUMP=true ;;
    --help|-h)
      grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "❌ Неизвестный аргумент: $1. Используйте --help." >&2
      exit 1
      ;;
  esac
  shift || true
done

# 1. Базовые проверки
for cmd in flutter gh git python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Не найдено в PATH: $cmd" >&2
    exit 1
  fi
done

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Рабочее дерево не чистое. Закоммитьте или удалите изменения перед релизом." >&2
  git status --short >&2
  exit 1
fi

REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  FULL_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
else
  echo "❌ Не удалось определить репозиторий GitHub из origin." >&2
  exit 1
fi

# 2. Обновление версии
if [[ "$SKIP_BUMP" != true ]]; then
  echo "📌 Поднятие версии в pubspec.yaml..."
  BUMP_ARGS=("tools/bump_pubspec_version.py" "--pubspec" "$ROOT/pubspec.yaml")
  if [[ "$BUILD_ONLY_BUMP" == true ]]; then
    BUMP_ARGS+=("--build-only")
  fi
  python3 "${BUMP_ARGS[@]}"
else
  echo "⏭️  Пропуск изменения версии (--skip-bump)."
fi

VERSION_LINE=$(grep -E '^version:' "$ROOT/pubspec.yaml" | head -n1 | awk '{print $2}')
APP_VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
TAG="v${APP_VERSION}"

echo "📦 Релиз: ${VERSION_LINE} → GitHub tag ${TAG}"

# 3. Сборка IPA и macOS
echo "📥 Получение зависимостей (flutter pub get)..."
flutter pub get

echo "🍎 Сборка iOS (IPA для SideStore)..."
flutter build ipa --release --export-method development

IPA="$ROOT/build/ios/ipa/projectgt.ipa"
if [[ ! -f "$IPA" ]]; then
  echo "❌ Ошибка: Файл $IPA не найден после сборки!" >&2
  exit 1
fi

IPA_SIZE="$(stat -f%z "$IPA" 2>/dev/null || stat -c%s "$IPA")"

echo "🖥️ Сборка macOS..."
flutter build macos --release

MACOS_ZIP="$ROOT/build/macos/Build/Products/Release/ProjectGT_macOS.zip"
echo "📦 Упаковка macOS в ZIP..."
(cd "$ROOT/build/macos/Build/Products/Release" && zip -r ProjectGT_macOS.zip projectgt.app)

if [[ ! -f "$MACOS_ZIP" ]]; then
  echo "❌ Ошибка: Файл $MACOS_ZIP не найден после сборки!" >&2
  exit 1
fi

# 4. Обновление source.json
echo "📝 Обновление sidestore/source.json..."
python3 <<PY
import json
from datetime import datetime
from pathlib import Path

root = Path("${ROOT}")
path = root / "sidestore" / "source.json"
app_ver = "${APP_VERSION}"
build = "${BUILD_NUMBER}"
ipa_size = int("${IPA_SIZE}")
tag = "${TAG}"
repo = "${FULL_REPO}"
download_url = f"https://github.com/{repo}/releases/download/{tag}/projectgt.ipa"

now = datetime.now().astimezone()
iso = now.isoformat(timespec="seconds")

with path.open(encoding="utf-8") as f:
    data = json.load(f)

app = data["apps"][0]
app["version"] = app_ver
app["buildVersion"] = build
app["versionDate"] = iso
app["downloadURL"] = download_url
app["size"] = ipa_size

new_entry = {
    "version": app_ver,
    "buildVersion": build,
    "date": iso,
    "downloadURL": download_url,
    "size": ipa_size,
}

versions = app.get("versions") or []
versions = [v for v in versions if not (v.get("version") == app_ver and str(v.get("buildVersion")) == str(build))]
versions.insert(0, new_entry)
app["versions"] = versions[:20]

with path.open("w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

# 5. Коммит, Тег и Пуш
echo "📤 Отправка изменений в Git..."
BRANCH="$(git branch --show-current)"
git add pubspec.yaml sidestore/source.json

if ! git diff --cached --quiet; then
  git commit -m "release: ProjectGT ${APP_VERSION} (${BUILD_NUMBER})"
fi

# Создаем тег локально (если его еще нет)
if ! git rev-parse "$TAG" >/dev/null 2>&1; then
  git tag "$TAG"
else
  echo "⚠️ Тег $TAG уже существует локально. Пересоздаю..."
  git tag -d "$TAG"
  git tag "$TAG"
fi

echo "🚀 Пуш коммита и тега на GitHub..."
git push origin "$BRANCH"
git push origin "$TAG" --force

# 6. GitHub Release
echo "☁️  Создание GitHub Release и загрузка файлов..."
if gh release view "$TAG" -R "$FULL_REPO" &>/dev/null; then
  echo "Обновление существующего релиза..."
  gh release upload "$TAG" "$IPA" "$MACOS_ZIP" -R "$FULL_REPO" --clobber
else
  gh release create "$TAG" "$IPA" "$MACOS_ZIP" -R "$FULL_REPO" \
    --title "ProjectGT ${APP_VERSION} (build ${BUILD_NUMBER})" \
    --notes "🚀 **ProjectGT ${APP_VERSION}**

### Установка
* **iOS:** Скачайте \`projectgt.ipa\` и установите через SideStore.
* **macOS:** Скачайте \`ProjectGT_macOS.zip\`, распакуйте и запустите.
* **Windows:** Скачайте \`ProjectGT_Setup.exe\` (появится через несколько минут)."
fi

echo "✅ Релиз ${TAG} успешно завершён!"
echo "⏳ GitHub Actions сейчас собирают версии для Windows и macOS. Они появятся в релизе через 5-10 минут."
