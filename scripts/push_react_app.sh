#!/usr/bin/env bash
#
# Отправить веб-приложение (папка react_app) в GitHub-репозиторий
#   https://github.com/dimnok/projectgt_react
#
# Flutter-репозиторий origin (projectgt) НЕ трогает.
#
# Запуск из корня projectgt:
#   ./scripts/push_react_app.sh
#   ./scripts/push_react_app.sh -m "сообщение коммита"
#   ./scripts/push_react_app.sh --files src/layouts/desktop/header.tsx docs/README.md
#   ./scripts/push_react_app.sh --dry-run
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REMOTE_NAME="react"
REMOTE_URL="https://github.com/dimnok/projectgt_react.git"
SRC_DIR="$ROOT/react_app"
BRANCH="main"
DRY_RUN=false
COMMIT_MSG=""
FILES=()

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    -m|--message)
      COMMIT_MSG="${2:-}"
      if [[ -z "$COMMIT_MSG" ]]; then
        echo "❌ Нужен текст после -m" >&2
        exit 1
      fi
      shift 2
      ;;
    --files)
      shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        FILES+=("$1")
        shift
      done
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "❌ Неизвестный аргумент: $1 (см. --help)" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$SRC_DIR" ]]; then
  echo "❌ Нет папки react_app: $SRC_DIR" >&2
  exit 1
fi

if ! git rev-parse --git-dir &>/dev/null; then
  echo "❌ Не git-репозиторий." >&2
  exit 1
fi

current_url="$(git remote get-url "$REMOTE_NAME" 2>/dev/null || true)"
if [[ -z "$current_url" ]]; then
  git remote add "$REMOTE_NAME" "$REMOTE_URL"
  echo "ℹ️  Добавлен remote $REMOTE_NAME → $REMOTE_URL"
elif [[ "$current_url" != "$REMOTE_URL" && "$current_url" != "${REMOTE_URL%.git}" && "$current_url" != "${REMOTE_URL}.git" ]]; then
  echo "❌ Remote «$REMOTE_NAME» смотрит не туда: $current_url" >&2
  echo "   Ожидается: $REMOTE_URL" >&2
  exit 1
fi

echo "⬇️  Fetch $REMOTE_NAME..."
git fetch "$REMOTE_NAME" "$BRANCH"

WT="$(mktemp -d "${TMPDIR:-/tmp}/projectgt_react_push.XXXXXX")"
PUSH_BRANCH="projectgt-react-push"
cleanup() {
  git -C "$ROOT" worktree remove --force "$WT" 2>/dev/null || true
  git -C "$ROOT" branch -D "$PUSH_BRANCH" 2>/dev/null || true
  rm -rf "$WT"
}
trap cleanup EXIT

git branch -D "$PUSH_BRANCH" 2>/dev/null || true
git worktree add -B "$PUSH_BRANCH" "$WT" "$REMOTE_NAME/$BRANCH" >/dev/null

rel_from_react_app() {
  local raw="$1"
  raw="${raw#./}"
  if [[ "$raw" == react_app/* ]]; then
    printf '%s\n' "${raw#react_app/}"
  else
    printf '%s\n' "$raw"
  fi
}

copy_one_file() {
  local rel="$1"
  local src="$SRC_DIR/$rel"
  local dest="$WT/$rel"
  if [[ ! -e "$src" ]]; then
    if [[ -e "$dest" ]]; then
      rm -rf "$dest"
      echo "   удалить: $rel"
    else
      echo "❌ Нет файла: react_app/$rel" >&2
      exit 1
    fi
    return
  fi
  mkdir -p "$(dirname "$dest")"
  rsync -a "$src" "$dest"
  echo "   файл: $rel"
}

if [[ ${#FILES[@]} -gt 0 ]]; then
  echo "📦 Только указанные файлы поверх текущей ветки $REMOTE_NAME/$BRANCH:"
  for item in "${FILES[@]}"; do
    copy_one_file "$(rel_from_react_app "$item")"
  done
else
  echo "📦 Полный снимок папки react_app → корень $REMOTE_NAME..."
  rsync -a --delete \
    --filter 'P .git' \
    --filter 'P .git/***' \
    --filter=':- '"$SRC_DIR"'/.gitignore' \
    --exclude '.env' \
    --exclude '.env.local' \
    "$SRC_DIR/" "$WT/"
fi

cd "$WT"

changed_names="$(git status --porcelain | awk '{print $NF}')"
if printf '%s\n' "$changed_names" | grep -E '(^|/)\.env($|\.local)|credentials|\.pem$' >/dev/null; then
  echo "❌ Похоже на секреты в статусе. Пуш отменён." >&2
  git status --short >&2
  exit 1
fi

if printf '%s\n' "$changed_names" | grep -E '^(lib/|android/|ios/|pubspec)' >/dev/null; then
  echo "❌ В снимок попали файлы Flutter. Пуш отменён." >&2
  git status --short >&2
  exit 1
fi

git add -A

if git diff --cached --quiet; then
  echo "✅ В $REMOTE_NAME/$BRANCH уже то же самое. Пушить нечего."
  exit 0
fi

echo "==== изменения ===="
git diff --cached --stat
echo "==================="

if [[ "$DRY_RUN" == true ]]; then
  echo "ℹ️  --dry-run: коммит и пуш пропущены."
  exit 0
fi

if [[ -z "$COMMIT_MSG" ]]; then
  if [[ ${#FILES[@]} -gt 0 ]]; then
    COMMIT_MSG="chore(web): update selected react_app files"
  else
    COMMIT_MSG="chore(web): sync react_app snapshot"
  fi
fi

git commit -m "$COMMIT_MSG"
git push "$REMOTE_NAME" "HEAD:$BRANCH"

sha="$(git rev-parse --short HEAD)"
echo "✅ Отправлено в $REMOTE_URL ($BRANCH @ $sha)"
echo "🔗 https://github.com/dimnok/projectgt_react"
echo "ℹ️  Репозиторий projectgt (origin) не обновлялся."
