## FCM: чек‑лист внедрения PUSH для админов (iOS/Android)

Статус: АКТИВНО. Минимальная схема развернута и работает в прод-среде FCM HTTP v1.

Последняя сводка (успешный вызов): admin_count=1, raw_tokens_count=1, tokens_total=1, sent=1.

### Примеры уведомлений

- Открытие смены:
```text
Title: 🔓 Смена - ОТКРЫТА
Body:
📍 Объект: {objectName}
👤 Пользователь: {userName}
👥 Сотрудников: {employeesCount}
```

- Закрытие смены:
```text
Title: 🔒 Смена - ЗАКРЫТА
Body:
📍 Объект: {objectName}
👤 Пользователь: {userName}
💰 Сумма: 125 000 ₽ (форматировано с пробелами)
⚙️ Выработка: 25 000 ₽ (форматировано с пробелами)
```

### Область и ограничения
- [x] Отправляем PUSH только админам (`profiles.role='admin'`), статус `status=true` или `NULL`.
- [x] Поддерживаем платформы iOS и Android (web без изменений).
- [x] Используем Supabase Edge Function `send_admin_work_event` (v32). CORS включён, `verify_jwt=true`. Форматирование сумм с пробелами.

### Текущее состояние (минимум)
- [x] Клиент: вызов `send_admin_work_event` с заголовком `Authorization: Bearer <accessToken>`; результат логируется через `debugPrint`.
- [x] БД: `public.user_tokens` с RLS и уникальностью `(installation_id, platform)`; `token` глобально уникален; `is_active` поддерживается.
- [x] Edge Function: читает БД через отдельный service‑клиент (обходит RLS), отправляет через FCM HTTP v1.
- [x] iOS: `aps-environment=production` (Ad Hoc/TestFlight), APNs .p8 (Key ID `TYMLTYTH4P`, Team ID `L37HR2KV4M`, Sandbox & Production) загружен в Firebase.
- [x] Android: `google-services.json` подключён, FCM активен.

### Требуемые секреты (Supabase → Secrets)
- `SERVICE_ACCOUNT` — сервисный JSON для FCM HTTP v1.
- `SERVICE_ROLE_KEY` — ключ сервера для Supabase (используется внутри функции для обхода RLS при чтении `profiles`/`user_tokens`).

### Поведение Edge Function `send_admin_work_event`
- Вход: `{ action: 'open' | 'close', work_id: UUID }`, JWT обязателен (`verify_jwt=true`).
- Фильтр получателей: берём `profiles.role='admin'` со `status=true|NULL`; получаем их активные токены из `user_tokens` по платформам iOS/Android.
- Ответ (JSON): включает минимум `{ sent, total, admin_count, raw_tokens_count, tokens_total }`.
- Логи: `start`, `no_tokens` (если не найдено), `summary` с ключами выше.

### Диагностика (если `tokens_total: 0`)
1) Убедиться, что клиент передаёт `Authorization: Bearer <accessToken>` при вызове функции.
2) Проверить в БД:
   - `profiles`: у нужного пользователя `role='admin'` и `status=true` или `NULL`.
   - `user_tokens`: есть строка с его `user_id`, `is_active=true`, `platform in ('ios','android')`.
3) Убедиться, что секреты `SERVICE_ROLE_KEY` и `SERVICE_ACCOUNT` заданы в проекте Supabase.
4) iOS: проверять соответствие сборки и среды APNs (Ad Hoc/TestFlight → production), `.p8` ключ загружен, bundle id корректен.
5) При необходимости отправить тест на конкретный токен через FCM v1 (проверка доставки вне функции).

### Нюансы записи токенов
- Одна запись на установку/платформу за счёт `UNIQUE (installation_id, platform)`.
- Перепривязка при смене пользователя обновляет строку; старые записи помечаются `is_active=false`.
- `onTokenRefresh` обрабатывается с debounce; `token` уникален глобально.

### Минимальные next steps (опционально)
- Показ SnackBar `{sent}/{total}` в клиента при успешном открытии/закрытии смены.
- Единый стиль текстов уведомлений и (по согласованию) эмодзи.

### История
- v29: фикс «невидимых» токенов из-за RLS — чтение `profiles`/`user_tokens` через service‑клиент; оставлены расширенные логи и CORS.
