#!/usr/bin/env bash
#
# Полный релиз ProjectGT для SideStore и Windows:
#   1) поднять версию в pubspec.yaml (patch + build по умолчанию);
#   2) flutter pub get;
#   3) при наличии хоста Windows — сборка desktop Windows + zip в артефакт;
#   4) сборка IPA (development export), GitHub Release, обновление sidestore/source.json;
#   5) один commit: pubspec.yaml + sidestore/source.json и push.
#
# Сборка Windows возможна только на Windows (Flutter). На macOS/Linux шаг пропускается.
#
# Запуск из корня репозитория:
#   ./tools/projectgt_release.sh
#
# Опции:
#   --skip-bump       не менять pubspec (повтор релиза с текущей версией)
#   --build-only-bump только увеличить номер после + в pubspec (без bump patch)
#   --help            справка
#
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

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Рабочее дерево не чистое. Закоммитьте или используйте stash перед релизом." >&2
  git status --short >&2
  exit 1
fi

if [[ "$SKIP_BUMP" != true ]]; then
  echo "📌 Поднятие версии в pubspec.yaml..."
  BUMP_ARGS=(tools/bump_pubspec_version.py --pubspec "$ROOT/pubspec.yaml")
  if [[ "$BUILD_ONLY_BUMP" == true ]]; then
    BUMP_ARGS+=(--build-only)
  fi
  python3 "${BUMP_ARGS[@]}"
else
  echo "⏭️  Пропуск bump (--skip-bump)."
fi

VERSION_LINE=$(grep -E '^version:' "$ROOT/pubspec.yaml" | head -n1 | awk '{print $2}')
APP_VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
TAG="v${APP_VERSION}"

echo "📦 Релиз: ${VERSION_LINE} → GitHub tag ${TAG}"

echo "📥 flutter pub get..."
flutter pub get

# --- Windows (только на хосте Windows) ---
BUILD_WINDOWS=false
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    BUILD_WINDOWS=true
    ;;
esac
if [[ "${OS:-}" == Windows_NT ]]; then
  BUILD_WINDOWS=true
fi

WIN_ZIP=""
if [[ "$BUILD_WINDOWS" == true ]]; then
  echo "🪟 flutter build windows --release..."
  flutter build windows --release
  WIN_OUT="$ROOT/build/windows/x64/runner/Release"
  if [[ -d "$WIN_OUT" ]]; then
    WIN_ZIP="$ROOT/build/projectgt-windows-${APP_VERSION}.zip"
    rm -f "$WIN_ZIP"
    echo "📦 Архив Windows → $(basename "$WIN_ZIP")"
    (cd "$WIN_OUT" && zip -r -q "$WIN_ZIP" .)
  else
    echo "⚠️  Не найдена папка $WIN_OUT после сборки." >&2
  fi
else
  echo "⏭️  Пропуск flutter build windows (нужен хост Windows; артефакт можно добавить в CI или собрать отдельно)."
fi

echo "🍎 IPA + SideStore + GitHub Release..."
"$ROOT/tools/release_sidestore_ipa.sh" --no-git

REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  GH_OWNER="${BASH_REMATCH[1]}"
  GH_REPO="${BASH_REMATCH[2]%.git}"
  FULL_REPO="${GH_OWNER}/${GH_REPO}"
else
  echo "❌ Не удалось разобрать git remote origin." >&2
  exit 1
fi

if [[ -n "$WIN_ZIP" && -f "$WIN_ZIP" ]]; then
  echo "☁️  Загрузка Windows zip в Release ${TAG}..."
  gh release upload "$TAG" "$WIN_ZIP" -R "$FULL_REPO" --clobber
fi

echo "📤 Git: commit pubspec.yaml + sidestore/source.json и push..."
BRANCH="$(git branch --show-current)"
git add pubspec.yaml sidestore/source.json
if git diff --cached --quiet; then
  echo "⚠️  Нечего коммитить." >&2
  exit 1
fi

git commit -m "release: ProjectGT ${APP_VERSION} (${BUILD_NUMBER})"
git push origin "$BRANCH"

echo "✅ Релиз завершён: ${TAG}, ветка origin/${BRANCH}."
