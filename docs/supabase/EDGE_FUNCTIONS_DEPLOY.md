# Публикация Edge Functions (self-hosted)

**Дата:** 23.08.2026

На self-hosted Supabase нет команды `supabase functions deploy`. Функции лежат на сервере в `volumes/functions` и публикуются скриптом из репозитория.

## Правило

После любого изменения кода в `supabase/functions/` функцию **сразу публиковать** на сервер:

```bash
./scripts/deploy-function.sh <имя-функции>
```

Локального сохранения недостаточно: приложение ходит на `https://api.progt.ru/functions/v1/`.

## Команды

| Задача | Команда |
|---|---|
| Одна функция | `./scripts/deploy-function.sh export-employees` |
| Все изменённые | `./scripts/deploy-function.sh --changed` |
| Все функции | `./scripts/deploy-function.sh --all` |
| Проверка без выкладки | `./scripts/deploy-function.sh --dry-run export-employees` |
| После смены секретов | `./scripts/deploy-function.sh --recreate export-employees` |

Проверка: `https://api.progt.ru/functions/v1/<имя-функции>`.

## Настройка один раз

1. Скопировать `scripts/deploy-function.env.example` → `scripts/deploy-function.env`.
2. Указать SSH-доступ к серверу и путь к ключу.
3. Файл `.env` в git не коммитить.

Официальная схема Supabase: скопировать папку функции в `volumes/functions` и перезапустить сервис `functions`.  
Документ: [Self-Hosted Functions](https://supabase.com/docs/guides/self-hosting/self-hosted-functions).

## Очистка 23.08.2026

С сервера сняты неиспользуемые функции: `hello`, `get-daily-tip`, `xls_to_xlsx`, `analyze-contract-plan`.  
Из репозитория удалена тестовая `hello-world`.  
`generate_vor` и `generate_vor_pdf` в git приведены к версии с сервера.  
`generate_vor_v2` на сервере выровнена с git (пересборка Excel для черновика).  
`bank_parse` сверена с git: логика совпадает, на сервере рабочая, код не выкладывался.
