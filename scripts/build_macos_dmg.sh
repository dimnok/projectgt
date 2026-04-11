#!/usr/bin/env bash
# Собирает Release .app и упаковывает в сжатый DMG (HFS+, UDZO).
#
# Почему на чужом Mac не открывается обычная сборка:
# Xcode подписывает Release как «Apple Development» — это не дистрибуция.
# Gatekeeper на машине сотрудника часто не даёт «Открыть» / «Всё равно открыть».
#
# Временная раздача команде (без Developer ID и notarization):
#   ADHOC_FOR_TEAM=1 ./scripts/build_macos_dmg.sh
# На Mac сотрудника после копирования из DMG:
#   xattr -cr /Applications/projectgt.app
# Затем один раз: ПКМ по приложению → «Открыть» → «Открыть».
#
# Для нормальной раздачи: Release с Developer ID Application + notarytool
# (инструкция — в комментариях scripts/notarize_macos_dmg.sh).
#
# Требования: Xcode, CocoaPods, flutter в PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -1)"
VERSION="${VERSION_LINE#version: }"
VERSION="${VERSION%%+*}"
VERSION="${VERSION// /}"

APP_RELEASE="build/macos/Build/Products/Release/projectgt.app"
STAGING="build/dmg_staging"

if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  flutter build macos --release
fi

if [[ ! -d "$APP_RELEASE" ]]; then
  echo "Не найден $APP_RELEASE — сначала выполните flutter build macos --release" >&2
  exit 1
fi

if [[ "${ADHOC_FOR_TEAM:-0}" == "1" ]]; then
  DMG_NAME="projectgt-${VERSION}-macos-adhoc.dmg"
else
  DMG_NAME="projectgt-${VERSION}-macos.dmg"
fi

rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_RELEASE" "$STAGING/"
ln -sf /Applications "$STAGING/Applications"

if [[ "${ADHOC_FOR_TEAM:-0}" == "1" ]]; then
  echo "Ad-hoc переподпись (Signature=adhoc, без Team ID)…"
  codesign --force --deep --sign - --timestamp=none "$STAGING/projectgt.app"
  codesign --verify "$STAGING/projectgt.app"
  echo "Проверка подписи: OK"
fi

OUT="build/$DMG_NAME"
rm -f "$OUT"
hdiutil create -volname "ProjectGT" -srcfolder "$STAGING" -ov -format UDZO -fs HFS+ "$OUT"

echo "Готово: $OUT"
ls -lh "$OUT"

if [[ "${ADHOC_FOR_TEAM:-0}" == "1" ]]; then
  echo ""
  echo "Сотруднику: после установки в /Applications выполнить в Терминале:"
  echo "  xattr -cr /Applications/projectgt.app"
  echo "Затем ПКМ по ProjectGT → «Открыть» (первый запуск)."
fi
