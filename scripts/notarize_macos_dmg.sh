#!/usr/bin/env bash
# Отправляет готовый .dmg в Apple Notary Service и прикрепляет ticket (staple).
#
# Подготовка (один раз на машине):
# 1. Apple Developer Program (платная подписка).
# 2. Сертификат «Developer ID Application» в связке ключей (Xcode → Settings → Accounts
#    → команда → Manage Certificates → + → Developer ID Application).
# 3. Пароль приложения: https://appleid.apple.com → Вход и безопасность → Пароли приложений.
# 4. Сохранить учётные данные для notarytool:
#      xcrun notarytool store-credentials "notary-projectgt" \
#        --apple-id "you@example.com" \
#        --team-id "L37HR2KV4M" \
#        --password "abcd-efgh-ijkl-mnop"
#
# Использование:
#   ./scripts/build_macos_dmg.sh
#   ./scripts/notarize_macos_dmg.sh build/projectgt-X.Y.Z-macos.dmg
#
# Профиль связки ключей можно переопределить:
#   NOTARY_KEYCHAIN_PROFILE=my-profile ./scripts/notarize_macos_dmg.sh build/foo.dmg
#
set -euo pipefail

DMG="${1:-}"
if [[ -z "$DMG" || ! -f "$DMG" ]]; then
  echo "Укажите путь к .dmg: $0 build/projectgt-1.0.0-macos.dmg" >&2
  exit 1
fi

PROFILE="${NOTARY_KEYCHAIN_PROFILE:-notary-projectgt}"

echo "Отправка на нотаризацию (профиль: $PROFILE)…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait

echo "Staple к образу…"
xcrun stapler staple "$DMG"

echo "Проверка staple…"
xcrun stapler validate "$DMG"

echo "Готово. Раздавайте этот DMG; двойной клик должен проходить без xattr на чистых Mac."
