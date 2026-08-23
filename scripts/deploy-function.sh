#!/usr/bin/env bash
#
# Публикация Edge Functions на self-hosted Supabase (Timeweb).
# Официальный способ: скопировать папку функции в volumes/functions и
# перезапустить сервис functions.
# Документация: https://supabase.com/docs/guides/self-hosting/self-hosted-functions
#
# Примеры:
#   ./scripts/deploy-function.sh export-employees
#   ./scripts/deploy-function.sh --changed
#   ./scripts/deploy-function.sh --all
#   ./scripts/deploy-function.sh --dry-run export-employees
#   ./scripts/deploy-function.sh --recreate export-employees
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCAL_FUNCTIONS_DIR="$ROOT/supabase/functions"
ENV_FILE="$ROOT/scripts/deploy-function.env"
EXAMPLE_ENV_FILE="$ROOT/scripts/deploy-function.env.example"

DRY_RUN=0
RECREATE=0
MODE="names"
NAMES=()

usage() {
  cat <<'EOF'
Публикация Edge Function на self-hosted Supabase.

Использование:
  ./scripts/deploy-function.sh <имя-функции>
  ./scripts/deploy-function.sh --changed
  ./scripts/deploy-function.sh --all
  ./scripts/deploy-function.sh --dry-run <имя-функции>
  ./scripts/deploy-function.sh --recreate <имя-функции>

--changed   только функции с локальными изменениями
--all       все функции из supabase/functions
--dry-run   показать, что будет скопировано, без выкладки
--recreate  пересоздать контейнер (нужно после смены секретов)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --recreate)
      RECREATE=1
      shift
      ;;
    --all)
      MODE="all"
      shift
      ;;
    --changed)
      MODE="changed"
      shift
      ;;
    --)
      shift
      NAMES+=("$@")
      break
      ;;
    -*)
      echo "Неизвестный флаг: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      NAMES+=("$1")
      shift
      ;;
  esac
done

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
elif [[ -f "$EXAMPLE_ENV_FILE" ]]; then
  echo "Нет scripts/deploy-function.env — беру значения из примера."
  set -a
  # shellcheck disable=SC1090
  source "$EXAMPLE_ENV_FILE"
  set +a
fi

SSH_HOST="${SUPABASE_SSH_HOST:-}"
SSH_USER="${SUPABASE_SSH_USER:-root}"
SSH_PORT="${SUPABASE_SSH_PORT:-22}"
SSH_IDENTITY="${SUPABASE_SSH_IDENTITY:-}"
REMOTE_FUNCTIONS_DIR="${SUPABASE_FUNCTIONS_REMOTE_DIR:-/home/supabase/supabase/docker/volumes/functions}"
DOCKER_DIR="${SUPABASE_DOCKER_DIR:-/home/supabase/supabase/docker}"

if [[ -z "$SSH_HOST" ]]; then
  echo "Не задан SUPABASE_SSH_HOST. Скопируйте scripts/deploy-function.env.example в scripts/deploy-function.env" >&2
  exit 1
fi

if [[ ! -d "$LOCAL_FUNCTIONS_DIR" ]]; then
  echo "Не найдена папка $LOCAL_FUNCTIONS_DIR" >&2
  exit 1
fi

is_skippable_name() {
  local name="$1"
  [[ -z "$name" || "$name" == "_shared" || "$name" == "main" ]]
}

function_exists() {
  local name="$1"
  [[ -f "$LOCAL_FUNCTIONS_DIR/$name/index.ts" || -f "$LOCAL_FUNCTIONS_DIR/$name/index.js" ]]
}

list_all_functions() {
  local dir name
  for dir in "$LOCAL_FUNCTIONS_DIR"/*/; do
    name="$(basename "$dir")"
    if is_skippable_name "$name"; then
      continue
    fi
    if function_exists "$name"; then
      printf '%s\n' "$name"
    fi
  done | sort
}

list_changed_functions() {
  local files path name
  files="$(
    {
      git diff --name-only -- supabase/functions
      git diff --cached --name-only -- supabase/functions
      git ls-files --others --exclude-standard -- supabase/functions
    } | sort -u
  )"

  if [[ -z "$files" ]]; then
    return 0
  fi

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    name="${path#supabase/functions/}"
    name="${name%%/*}"
    if is_skippable_name "$name"; then
      continue
    fi
    if function_exists "$name"; then
      printf '%s\n' "$name"
    fi
  done <<< "$files" | sort -u
}

case "$MODE" in
  all)
    NAMES=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && NAMES+=("$line")
    done < <(list_all_functions)
    ;;
  changed)
    NAMES=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && NAMES+=("$line")
    done < <(list_changed_functions)
    ;;
  names)
    if [[ ${#NAMES[@]} -eq 0 ]]; then
      echo "Укажите имя функции, --changed или --all" >&2
      usage >&2
      exit 1
    fi
    ;;
esac

if [[ ${#NAMES[@]} -eq 0 ]]; then
  echo "Нет функций для публикации."
  exit 0
fi

UNIQUE_NAMES=()
for name in "${NAMES[@]}"; do
  if is_skippable_name "$name"; then
    echo "Пропускаю служебную папку: $name"
    continue
  fi
  if ! function_exists "$name"; then
    echo "Функция не найдена: supabase/functions/$name/index.ts" >&2
    exit 1
  fi
  duplicate=0
  if [[ ${#UNIQUE_NAMES[@]} -gt 0 ]]; then
    for existing in "${UNIQUE_NAMES[@]}"; do
      if [[ "$existing" == "$name" ]]; then
        duplicate=1
        break
      fi
    done
  fi
  if [[ $duplicate -eq 0 ]]; then
    UNIQUE_NAMES+=("$name")
  fi
done

NAMES=("${UNIQUE_NAMES[@]}")

SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -p "$SSH_PORT")
if [[ -n "$SSH_IDENTITY" ]]; then
  SSH_IDENTITY="${SSH_IDENTITY/#\~/$HOME}"
  if [[ ! -f "$SSH_IDENTITY" ]]; then
    echo "SSH-ключ не найден: $SSH_IDENTITY" >&2
    exit 1
  fi
  SSH_OPTS+=(-i "$SSH_IDENTITY" -o IdentitiesOnly=yes)
fi

ssh_cmd() {
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" "$@"
}

echo "Сервер: ${SSH_USER}@${SSH_HOST}"
echo "Путь на сервере: $REMOTE_FUNCTIONS_DIR"
echo "Функции: ${NAMES[*]}"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Режим: только проверка, без выкладки"
fi

if [[ $DRY_RUN -eq 0 ]]; then
  if ! ssh_cmd "test -d '$REMOTE_FUNCTIONS_DIR'"; then
    echo "Нет доступа к серверу или папка функций не найдена: $REMOTE_FUNCTIONS_DIR" >&2
    echo "Проверьте SSH-ключ и scripts/deploy-function.env" >&2
    exit 1
  fi
fi

RSYNC_SSH="ssh -p $SSH_PORT -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
if [[ -n "$SSH_IDENTITY" ]]; then
  RSYNC_SSH="$RSYNC_SSH -i $SSH_IDENTITY -o IdentitiesOnly=yes"
fi

RSYNC_EXCLUDES=(--exclude '.DS_Store' --exclude '.git' --exclude '*.md')
RSYNC_FLAGS=(-az)
if [[ $DRY_RUN -eq 1 ]]; then
  RSYNC_FLAGS+=(-n -v)
fi

for name in "${NAMES[@]}"; do
  src="$LOCAL_FUNCTIONS_DIR/$name/"
  dest="${SSH_USER}@${SSH_HOST}:${REMOTE_FUNCTIONS_DIR}/${name}/"
  echo "Копирую $name ..."
  rsync "${RSYNC_FLAGS[@]}" "${RSYNC_EXCLUDES[@]}" -e "$RSYNC_SSH" "$src" "$dest"
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Проверка завершена. Для публикации запустите без --dry-run."
  exit 0
fi

if [[ $RECREATE -eq 1 ]]; then
  echo "Пересоздаю сервис functions (секреты/окружение)..."
  RESTART_CMD="if [ -f run.sh ]; then sh run.sh recreate functions; else docker compose up -d --no-deps --force-recreate functions; fi"
else
  echo "Перезапускаю сервис functions..."
  RESTART_CMD="if [ -f run.sh ]; then sh run.sh restart functions; else docker compose restart functions; fi"
fi

ssh_cmd "cd '$DOCKER_DIR' && $RESTART_CMD"

echo "Готово."
for name in "${NAMES[@]}"; do
  echo "Проверка: https://api.progt.ru/functions/v1/${name}"
done
