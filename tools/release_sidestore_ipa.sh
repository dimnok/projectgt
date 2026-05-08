#!/usr/bin/env bash
#
# Сборка IPA для SideStore, загрузка в GitHub Releases и обновление sidestore/source.json.
#
# Требования: Flutter, GitHub CLI (gh) с авторизацией, рабочая подпись для
# `flutter build ipa --export-method development`.
#
# Запуск из корня репозитория:
#   ./tools/release_sidestore_ipa.sh
#
# Опции:
#   --no-git     только сборка + gh release upload + локальный source.json (без commit/push)
#   --help       справка
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

NO_GIT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-git) NO_GIT=true ;;
    --help|-h)
      grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Неизвестный аргумент: $1. Используйте --help." >&2
      exit 1
      ;;
  esac
  shift || true
done

for cmd in flutter gh git python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Не найдено в PATH: $cmd" >&2
    exit 1
  fi
done

PUBSPEC="$ROOT/pubspec.yaml"
if [[ ! -f "$PUBSPEC" ]]; then
  echo "❌ Нет pubspec.yaml в $ROOT" >&2
  exit 1
fi

VERSION_LINE=$(grep -E '^version:' "$PUBSPEC" | head -n1 | awk '{print $2}')
APP_VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
TAG="v${APP_VERSION}"

REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "$REMOTE_URL" ]]; then
  echo "❌ Нет git remote origin — не удалось определить owner/repo для GitHub." >&2
  exit 1
fi

# github.com:dimnok/projectgt.git или https://github.com/dimnok/projectgt.git
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  GH_OWNER="${BASH_REMATCH[1]}"
  GH_REPO="${BASH_REMATCH[2]%.git}"
else
  echo "❌ Не удалось разобрать URL origin: $REMOTE_URL" >&2
  exit 1
fi
FULL_REPO="${GH_OWNER}/${GH_REPO}"

echo "📦 Версия из pubspec: ${APP_VERSION}+${BUILD_NUMBER}, тег Release: ${TAG}"
echo "🔗 Репозиторий GitHub: ${FULL_REPO}"

echo "📥 flutter pub get..."
flutter pub get

echo "🔨 flutter build ipa (export-method development)..."
flutter build ipa --release --export-method development

IPA="$ROOT/build/ios/ipa/projectgt.ipa"
if [[ ! -f "$IPA" ]]; then
  echo "❌ Не найден IPA: $IPA" >&2
  exit 1
fi

if stat -f%z "$IPA" &>/dev/null; then
  IPA_SIZE="$(stat -f%z "$IPA")"
else
  IPA_SIZE="$(stat -c%s "$IPA")"
fi

echo "📐 Размер IPA: $IPA_SIZE байт"

echo "📝 Обновление sidestore/source.json..."
python3 <<PY
import json
from datetime import datetime, timezone
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
versions = [
    v for v in versions
    if not (v.get("version") == app_ver and str(v.get("buildVersion")) == str(build))
]
versions.insert(0, new_entry)
app["versions"] = versions[:20]

with path.open("w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "☁️  GitHub Release ${TAG}..."
if gh release view "$TAG" -R "$FULL_REPO" &>/dev/null; then
  gh release upload "$TAG" "$IPA" -R "$FULL_REPO" --clobber
else
  gh release create "$TAG" "${IPA}#projectgt.ipa" -R "$FULL_REPO" \
    --title "ProjectGT ${APP_VERSION} (build ${BUILD_NUMBER})" \
    --notes "SideStore: IPA \`projectgt.ipa\`, manifest в \`sidestore/source.json\`."
fi

if [[ "$NO_GIT" == true ]]; then
  echo "✅ Готово (--no-git: без commit/push). Проверьте sidestore/source.json и при необходимости закоммитьте вручную."
  exit 0
fi

echo "📤 git commit + push (только sidestore/source.json)..."
BRANCH="$(git branch --show-current)"
git add sidestore/source.json
if git diff --cached --quiet; then
  echo "⚠️  Нет изменений в sidestore/source.json — возможно, версия не менялась."
else
  git commit -m "chore(sidestore): publish IPA ${APP_VERSION} (${BUILD_NUMBER})"
  git push origin "$BRANCH"
fi

echo "✅ Готово: IPA на GitHub, source.json в репозитории."
