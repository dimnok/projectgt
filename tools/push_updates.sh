#!/usr/bin/env bash
#
# Отправить уже закоммиченные коммиты на GitHub (без релиза, без сборок).
# Рабочее дерево должно быть чистым — сначала закоммитьте изменения.
#
# Запуск из корня репозитория:
#   ./tools/push_updates.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --git-dir &>/dev/null; then
  echo "❌ Не git-репозиторий." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Есть незакоммиченные изменения. Сделайте commit или stash:" >&2
  git status --short >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"

if git rev-parse --abbrev-ref "@{upstream}" &>/dev/null; then
  git push origin "$BRANCH"
else
  echo "ℹ️  Upstream не задан, выполняю: git push -u origin $BRANCH"
  git push -u origin "$BRANCH"
fi

echo "✅ Отправлено в origin/$BRANCH"
