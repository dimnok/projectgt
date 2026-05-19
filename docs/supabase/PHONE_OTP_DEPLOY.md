# Phone OTP (Supabase Auth + Notisend) — деплой на self-hosted

**Дата:** 19.05.2026

Клиент уже использует `signInWithOtp` / `verifyOTP`. На сервере нужно включить **Send SMS Hook** и задеплоить Edge Function `auth-send-sms`.

## 1. Секрет hook (один раз)

На сервере сгенерировать секрет (пример):

```bash
SECRET=$(openssl rand -base64 32)
echo "v1,whsec_${SECRET}"
```

Сохранить значение `v1,whsec_...` — оно нужно **в двух местах с одинаковым значением**.

## 2. `.env` (docker)

Добавить:

```env
# Send SMS Hook (GoTrue → Edge auth-send-sms)
GOTRUE_HOOK_SEND_SMS_ENABLED=true
# Публичный HTTPS (GoTrue не принимает http:// для не-localhost хостов)
GOTRUE_HOOK_SEND_SMS_URI=https://api.progt.ru/functions/v1/auth-send-sms
GOTRUE_HOOK_SEND_SMS_SECRETS=v1,whsec_<ВАШ_СЕКРЕТ>

# Тот же секрет для Edge Function
SEND_SMS_HOOK_SECRET=v1,whsec_<ВАШ_СЕКРЕТ>

# Тестовый OTP без SMS (опционально)
GOTRUE_SMS_TEST_OTP=70000000000=000000
```

`NOTISEND_*` уже должны быть в `.env` (прокидываются в `functions`).

## 3. `docker-compose.yml` — сервис `auth`

Раскомментировать и привязать к `.env`:

```yaml
GOTRUE_HOOK_SEND_SMS_ENABLED: ${GOTRUE_HOOK_SEND_SMS_ENABLED}
GOTRUE_HOOK_SEND_SMS_URI: ${GOTRUE_HOOK_SEND_SMS_URI}
GOTRUE_HOOK_SEND_SMS_SECRETS: ${GOTRUE_HOOK_SEND_SMS_SECRETS}
```

## 4. `docker-compose.yml` — сервис `functions`

Добавить в `environment`:

```yaml
SEND_SMS_HOOK_SECRET: ${SEND_SMS_HOOK_SECRET}
```

## 5. Edge Function

Скопировать из репозитория:

- `supabase/functions/auth-send-sms/` → `/home/supabase/supabase/docker/volumes/functions/auth-send-sms/`

Или полный деплой functions из CI.

## 6. Перезапуск

```bash
cd /home/supabase/supabase/docker
docker compose up -d auth functions
```

## 7. Проверка

```bash
curl -sS -X POST 'https://api.progt.ru/auth/v1/otp' \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"phone":"+79194108001"}'
```

Ожидаемо: `{}` и HTTP 200 (SMS уходит через Notisend).

Логи:

```bash
docker compose logs auth --tail 20
docker compose logs functions --tail 50 | grep auth-send-sms
```

## 8. Откат

- Выключить `GOTRUE_HOOK_SEND_SMS_ENABLED=false`
- В приложении временно откатить коммит с `signInWithOtp` (или включить старый `otp-notisend` в `auth_data_source`)

## БД (миграции)

- `handle_new_user` — email `{phone}@telegram.gt` для phone-only
- `auth.users.phone` — **только цифры** (`79778062108`), без `+` (формат GoTrue)
- `auth.identities` (phone): `provider_id` = `user.id`, не номер телефона
- `profiles` / `employees`: `normalize_ru_phone_digits`; в API клиент шлёт E.164 с `+`

После деплоя hook применить миграцию `20260519160000_gotrue_phone_digits_format.sql` (MCP или SQL).
