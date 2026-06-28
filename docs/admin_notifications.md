# Push-уведомления админам и владельцам (Admin Notifications / PWA)

**Дата актуализации:** 28 июня 2026  
**Изменения:** полный аудит PWA push (iOS Safari PWA, Web, Android/iOS native); мультиустройство; deep link `/?work_id=`; получатели — владельцы + админы.

---

## Важное замечание

- **Owner таблиц push-токенов:** `public.user_tokens` (клиент пишет, Edge Function читает через `SERVICE_ROLE_KEY`).
- **PWA на iPhone** использует платформу `web` в `user_tokens`, **не** `ios`. Native iOS-приложение — отдельная платформа `ios`.
- **Self-hosted Supabase:** `https://api.progt.ru`
- **Деплой:** PWA (Timeweb) + Edge Function `send_admin_work_event` обновляются **вручную** на сервере после push в GitHub.

---

## Описание

Система отправляет **push-уведомления** владельцам компании и администраторам при **открытии** и **закрытии** смены.

| Событие | Заголовок | Содержание |
|---------|-----------|------------|
| Открытие | 🔓 Смена - ОТКРЫТА | объект, пользователь, число сотрудников |
| Закрытие | 🔒 Смена - ЗАКРЫТА | объект, пользователь, сумма, выработка |

**Ключевые возможности (июнь 2026):**

- ✅ PWA на iPhone (iOS 16.4+, «На экран Домой»)
- ✅ Web-браузер (Chrome / Edge / Safari desktop)
- ✅ Native Android / iOS
- ✅ Несколько устройств одного пользователя (телефон + ПК)
- ✅ Переход по tap на экран смены без ошибки 403
- ✅ Один баннер (без дублей на PWA)

**Статус:** ✅ работает в production (FCM HTTP v1, проект `pgtmess`).

---

## Зависимости

### Таблицы модуля (usage / owner)

| Таблица | Роль |
|---------|------|
| `user_tokens` | **owner** — FCM-токены устройств |
| `works` | usage — данные смены |
| `objects` | usage — название объекта |
| `profiles` | usage — ФИО, `status` |
| `work_hours` | usage — число сотрудников |
| `work_items` | usage — сумма при закрытии |
| `company_members` | usage — кто админ / владелец |
| `roles` | usage — `role_name` для фильтра админов |

### Edge Functions

| Функция | Назначение |
|---------|------------|
| `send_admin_work_event` | Формирует и отправляет push админам/владельцам |
| `send-fcm` | Низкоуровневая отправка FCM (legacy / тесты) |

### Внешние сервисы

- **Firebase Cloud Messaging** (API v1) — доставка на все платформы
- **Apple Push Notification service** — iOS native и Web Push для PWA (через FCM)

---

## Архитектура

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Flutter Client                                │
│                                                                       │
│  FcmTokenService ──► Firebase (getToken / onTokenRefresh)            │
│       │ save upsert user_tokens (per installation_id)                 │
│       │ refresh on app resume                                         │
│                                                                       │
│  work_form_screen ──► notifyAdminsWorkOpened() ──┐                   │
│  work_data_tab    ──► notifyAdminsWorkClosed()  ──┼──► Edge Function │
│                                                                       │
│  fcm_push_handler + firebase-messaging-sw.js ◄─── push delivery      │
│  push_work_navigation ──► /works/:id (in-app router)                 │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ HTTPS + JWT
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│              Edge Function: send_admin_work_event                     │
│  1. work_id + action (open|close)                                     │
│  2. Данные смены из БД                                                │
│  3. Получатели: owners + admins (notify_all: false)                   │
│  4. Активные токены ios / android / web                               │
│  5. Dedup: один токен на installation_id (не один на всю platform)    │
│  6. FCM payload: web → webpush only; native → notification + apns     │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ FCM API v1
                                ▼
                    Firebase → APNs / Web Push / Android
```

---

## PWA на iPhone — требования и особенности

### Что нужно пользователю

1. **iOS / iPadOS 16.4+**
2. Открыть сайт в **Safari** (или Chrome/Edge на iOS)
3. **«Поделиться» → «На экран Домой»** — установить PWA
4. Запускать приложение **с иконки на домашнем экране**, не из вкладки Safari
5. Разрешить уведомления при запросе внутри PWA

### manifest.json (обязательно)

Файл: `web/manifest.json`

- `display: "standalone"` — без этого Web Push на iOS **не работает**
- `name` / `short_name` — имя на домашнем экране («Стройка PRO»)
- Иконки 192×192 и 512×512

### Service Worker

Файл: `web/firebase-messaging-sw.js`

- Регистрируется Firebase Messaging для Web
- **Не вызывает** `showNotification`, если FCM уже передал `webpush.notification` (иначе **два баннера**)
- Обрабатывает `notificationclick` → открывает `/?work_id=UUID`

### Строка «from Стройка PRO»

На iOS PWA Apple **всегда** показывает подпись `from {имя приложения}` под заголовком. Это **системное ограничение**, убрать нельзя (ни manifest, ни payload). Можно только изменить `short_name` в manifest — слово «from» останется.

### Deep link и ошибка 403

**Проблема:** ссылка `/works/uuid` на статическом хостинге (Timeweb S3) не существует как файл → **403 AccessDenied**.

**Решение (реализовано):**

- FCM `fcm_options.link` = `/?work_id={uuid}`
- Service worker и `lib/core/notifications/push_work_navigation.dart` — тот же формат
- `lib/main.dart` читает query при старте и делает `router.push('/works/$workId')`

---

## Слой Presentation / Client

### Дерево файлов (уведомления о сменах)

```
lib/
├── data/services/
│   ├── fcm_token_service.dart          # регистрация FCM-токена
│   └── admin_work_notification_service.dart  # вызов Edge Function
├── core/notifications/
│   ├── fcm_push_handler.dart           # tap / foreground web
│   ├── push_work_navigation.dart       # ?work_id= deep link
│   ├── push_work_navigation_platform.dart
│   ├── push_work_navigation_web.dart
│   └── web_foreground_notification*.dart
├── features/works/presentation/screens/
│   ├── work_form_screen.dart           # notifyAdminsWorkOpened
│   └── tabs/work_data_tab.dart         # notifyAdminsWorkClosed
└── main.dart                           # init FCM, resume refresh, navigation

web/
├── firebase-messaging-sw.js
├── manifest.json
└── index.html
```

### FcmTokenService — регистрация токена

**Файл:** `lib/data/services/fcm_token_service.dart`

| Шаг | Действие |
|-----|----------|
| Init | `requestPermission`, `getToken` (на Web — с VAPID key) |
| Save | upsert в `user_tokens` по `(installation_id, platform)` |
| Device label | `device_model`, `os_version`, `app_version` — см. `fcm_device_info_*.dart` |
| Multi-device | **не деактивирует** токены других устройств на той же platform `web` |
| Same device | деактивирует только старые записи **этого** `installation_id` |
| Logout | `is_active = false` для текущего token |
| Resume | `refreshCurrentDeviceToken()` при возврате в приложение (`main.dart`) |

**Платформы в БД:**

| Устройство | `platform` |
|------------|------------|
| PWA iPhone / браузер | `web` |
| Native iPhone app | `ios` |
| Native Android | `android` |

### Вызов push при смене

**Файл:** `lib/data/services/admin_work_notification_service.dart`

```dart
await notifyAdminsWorkOpened(client: supabase, workId: workId);
await notifyAdminsWorkClosed(client: supabase, workId: workId);
```

Тело запроса к Edge Function:

```json
{
  "action": "open",
  "work_id": "uuid",
  "notify_all": false
}
```

`notify_all: false` — **только владельцы (`is_owner`) + админы** (роли «Администратор», «Админ», «Супер-админ»).  
Ошибки **не блокируют** UX (try/catch + debugPrint).

### Обработка нажатия на уведомление

1. **Native / FCM data:** `fcm_push_handler.dart` → `onMessageOpenedApp` → `/works/:id`
2. **PWA cold start:** URL `/?work_id=` → `extractWorkIdFromPushUri` → `/works/:id`
3. **Service worker:** `notificationclick` → focus/navigate или `postMessage` → listener в `main.dart`

---

## Edge Function: send_admin_work_event

**Путь:** `supabase/functions/send_admin_work_event/index.ts`  
**Auth:** `verify_jwt=true`, заголовок `Authorization: Bearer <accessToken>`

### Вход

| Поле | Тип | Описание |
|------|-----|----------|
| `action` | `'open' \| 'close'` | событие |
| `work_id` | UUID | смена |
| `notify_all` | boolean? | `false` = только admins+owners; иначе все участники компании |

### Получатели (`notify_all: false`)

1. `company_members.is_owner = true` для `works.company_id`
2. `company_members` с ролями: Администратор, Админ, Супер-админ (глобально)
3. Фильтр `profiles.status !== false`
4. Токены: `user_tokens` где `is_active` и `platform IN ('ios','android','web')`

### Dedup токенов

Один push на **устройство** (ключ `user_id:platform:installation_id`), не один на всю platform `web`.  
Fallback без `installation_id`: ключ включает сам `token`.

### FCM payload

**Web / PWA** — только `data` + `webpush.notification` (без top-level `notification`):

```javascript
{
  message: {
    token,
    data: { type, action, work_id, object_id },
    webpush: {
      notification: { title, body, icon: "/icons/Icon-192.png" },
      fcm_options: { link: "/?work_id={work_id}" }
    }
  }
}
```

**iOS / Android native** — `notification` + `apns` / `android` priority HIGH.

### Ответ

```json
{
  "sent": 2,
  "total": 5,
  "admin_count": 2,
  "notify_all": false,
  "raw_tokens_count": 240,
  "tokens_total": 5
}
```

### Секреты Supabase

| Secret | Назначение |
|--------|------------|
| `SERVICE_ACCOUNT` | JSON service account Firebase (FCM v1) |
| `SERVICE_ROLE_KEY` | чтение `user_tokens` / `company_members` (обход RLS) |

---

## База данных (Audit)

### Таблица `public.user_tokens`

| Колонка | Тип | Описание |
|---------|-----|----------|
| id | uuid | PK |
| user_id | uuid | FK → auth.users |
| token | text | FCM token, UNIQUE |
| platform | text | `ios` \| `android` \| `web` |
| installation_id | text | Firebase Installation ID |
| user_display_name | text | ФИО пользователя (`short_name` или `full_name` из profiles) |
| device_id | text | ID устройства (native) |
| device_model | text | Подпись: «Safari PWA (iPhone)», «Chrome (Windows)» |
| os_version | text | Версия ОС |
| app_version | text | Версия приложения |
| is_active | boolean | default true |
| created_at / updated_at | timestamptz | |

**RLS:** ✅ включён — пользователь CRUD только свои токены. Edge Function читает через service role.

**Уникальность:** `(installation_id, platform)` — одна активная запись на установку.

### Проверочные SQL

```sql
-- Активные токены: ФИО, устройство, ОС
SELECT user_display_name, platform, device_model, os_version, updated_at
FROM user_tokens
WHERE is_active
ORDER BY updated_at DESC;

-- Кому уйдёт push для смены (admins+owners)
SELECT u.email, cm.is_owner, r.role_name
FROM company_members cm
JOIN auth.users u ON u.id = cm.user_id
LEFT JOIN roles r ON r.id = cm.role_id
WHERE cm.company_id = (SELECT company_id FROM works WHERE id = '<work_uuid>')
  AND cm.is_active
  AND (cm.is_owner OR r.role_name IN ('Администратор', 'Супер-админ', 'Админ'));
```

---

## Бизнес-логика (пошагово)

### Открытие смены

1. Пользователь нажимает «Открыть смену» → `work_form_screen`
2. Смена сохраняется в `works`
3. `notifyAdminsWorkOpened(workId)` → Edge Function `action: open`
4. Edge собирает объект, автора, число сотрудников
5. Push всем активным токенам получателей

### Закрытие смены

1. Пользователь закрывает смену → `work_data_tab._closeWork`
2. `updateWork` → `notifyAdminsWorkClosed(workId)`
3. Edge считает сумму (`work_items.total`) и выработку = сумма / число сотрудников
4. Push с форматированными суммами (`245 766 ₽`)

### Форматирование сумм (Edge)

```javascript
// 245766 → "245 766 ₽"
const formatCurrency = (num) => { /* ... */ };
```

---

## Интеграции

| Модуль | Связь |
|--------|-------|
| **works** | триггер open/close из UI смен |
| **profile** | локальные напоминания о смене — отдельно, см. `notifications_integration.md` |
| **Telegram** | параллельный канал через `telegram_outbox`, не заменяет FCM |
| **Firebase** | проект `pgtmess`, VAPID для Web |

**PWA URL (production):** `https://e65ccfca-5800-40ab-b157-ac33d7a5f026.website.twcstorage.ru`

---

## Диагностика проблем

### Push не приходит на телефон после входа с компьютера

**Причина (исправлено 28.06.2026):** раньше при входе с ПК деактивировались **все** `web`-токены, включая iPhone PWA.

**Сейчас:** каждое устройство — свой `installation_id`. После деплика открыть PWA на телефоне (обновит токен).

### Два уведомления сразу (PWA)

**Причина:** дубль `showNotification` в SW + FCM `webpush.notification`.  
**Fix:** SW пропускает show, если payload уже содержит `notification`.

### Ошибка 403 при tap

**Причина:** прямой URL `/works/:id` на S3-хостинге.  
**Fix:** `/?work_id=` + роутинг в приложении. Нужен деплой PWA + Edge Function.

### `tokens_total: 0` / `sent: 0`

1. JWT в заголовке `Authorization: Bearer ...`
2. Пользователь — owner или admin в `company_members`
3. `user_tokens.is_active = true`, platform ∈ {web, ios, android}
4. Секреты `SERVICE_ACCOUNT`, `SERVICE_ROLE_KEY` на сервере
5. PWA: приложение установлено на домашний экран, разрешения выданы

### iOS PWA: push не работает в Safari-вкладке

Web Push на iOS **только** для приложения с домашнего экрана (`display-mode: standalone`).

### Тестовый вызов (curl)

```bash
curl -X POST 'https://api.progt.ru/functions/v1/send_admin_work_event' \
  -H 'Content-Type: application/json' \
  -H 'apikey: <SUPABASE_ANON_KEY>' \
  -H 'Authorization: Bearer <SUPABASE_ANON_KEY>' \
  -d '{"action":"open","work_id":"<UUID>","notify_all":false}'
```

Логи: Supabase Dashboard → Edge Functions → Logs (`send_admin_work_event: start`, `summary`).

---

## Тестирование

| # | Сценарий | Ожидание |
|---|----------|----------|
| 1 | Установить PWA на iPhone, войти как owner/admin, разрешить push | запись в `user_tokens`, platform=web |
| 2 | Другой пользователь открывает смену | один push «ОТКРЫТА» на iPhone |
| 3 | Tap по push | открывается экран смены, без 403 |
| 4 | Закрытие смены | push «ЗАКРЫТА» с суммой и выработкой |
| 5 | Вход с ПК после телефона → событие смены | push приходит **и на телефон, и на ПК** (если разрешения на обоих) |
| 6 | Открыть PWA после долгого простоя | `refreshCurrentDeviceToken` восстанавливает доставку |

---

## Roadmap

### ✅ Реализовано (июнь 2026)

- [x] PWA push iOS 16.4+ (Safari PWA)
- [x] Web FCM + service worker
- [x] Push при open/close смены
- [x] Получатели: owners + admins (`notify_all: false`)
- [x] Dedup без дублей баннера
- [x] Deep link `/?work_id=` (fix 403)
- [x] Multi-device web tokens (phone + desktop)
- [x] Refresh token on app resume
- [x] Подпись устройства в `device_model` (iPhone PWA / Chrome Windows и т.д.)
- [x] Форматирование сумм в push при закрытии

### 🔄 Планируется

- [ ] UI-настройка «кому слать» (`notify_all` из профиля)
- [ ] Деактивация токенов по FCM 410 (UNREGISTERED)
- [ ] SnackBar `{sent}/{total}` для отладки у админов
- [ ] SPA fallback на Timeweb (все пути → index.html) — опционально для прямых URL
- [ ] Статистика доставки push

### 🔴 Известные ограничения iOS PWA

- Нельзя убрать «from Стройка PRO»
- Нет silent push / badge без показа баннера
- `notification.close()` не убирает из центра уведомлений до tap

---

## Связанные документы

- [FCM_ADMIN_NOTIFICATIONS_CHECKLIST.md](./FCM_ADMIN_NOTIFICATIONS_CHECKLIST.md) — чек-лист внедрения и деплоя
- [FCM_INTEGRATION_STATUS.md](./FCM_INTEGRATION_STATUS.md) — статус интеграции FCM
- [notifications_integration.md](./notifications_integration.md) — **локальные** напоминания (слоты времени), не путать с admin push
- [works/works_module.md](./works/works_module.md) — модуль смен

---

**Последний аудит:** код (`lib/data/services/`, `lib/core/notifications/`, `web/firebase-messaging-sw.js`), Edge Function, `user_tokens` / `company_members` / RLS — **28.06.2026**. Документ соответствует production.
