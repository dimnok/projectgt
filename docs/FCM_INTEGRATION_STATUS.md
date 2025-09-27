## Статус интеграции FCM (Flutter + Supabase, API v1)

Актуально на момент аудита. Источник: `pubspec.yaml`, Gradle/Podfile, `lib/main.dart`, iOS/Android манифесты, документация в `docs/` и миграции в `lib/data/migrations/`.

### 1. Библиотеки Flutter
- [x] firebase_core — установлено (`^4.1.0`)
- [x] firebase_messaging — установлено (`^16.0.1`)
- [x] firebase_app_installations — установлено (installation_id)
- [x] supabase_flutter — есть (`^2.3.4`)

Комментарий: пакеты установлены; Firebase инициализирован через `firebase_options.dart`, фоновый обработчик FCM подключён. Локальные уведомления продолжают использоваться.

### 2. Firebase Console
- [x] Проект создан — `pgtmess` (ACTIVE)
- [x] Добавлено Android‑приложение — пакет `dev.projectgt.projectgt` (ACTIVE)
- [x] Добавлено iOS‑приложение — bundle `dev.projectgt.projectgt`, Team ID `L37HR2KV4M` (ACTIVE)
- [x] Конфиги добавлены в проект:
  - `google-services.json` — есть в `android/app/` (`/Users/dmitrit./projectgt/android/app/google-services.json`)
  - `GoogleService-Info.plist` — есть в `ios/Runner/` (`/Users/dmitrit./projectgt/ios/Runner/GoogleService-Info.plist`)
- [x] Включён Firebase Cloud Messaging API (V1) — включён (подтверждено по скриншоту)
  - Примечание: для повторной проверки/включения при необходимости:
    - Google Cloud Console → APIs & Services → Enabled APIs
    - `gcloud services list --enabled --project pgtmess | grep -i fcm`
    - `gcloud services enable fcm.googleapis.com --project pgtmess`
- [x] Service Account JSON скачан — хранить только в secrets (не в репо)

Комментарий: ранее был откат FCM; на текущий момент конфиги добавлены в проект.

### 3. Android (Gradle)
- [x] Подключён `google-services` — apply false в `android/settings.gradle.kts`
- [x] Плагин `com.google.gms.google-services` в `android/app/build.gradle.kts` — подключён
- [x] minSdkVersion ≥ 19 — фактически `minSdk = 23` (ок)

### 4. iOS (Xcode)
- [x] `GoogleService-Info.plist` — присутствует
- [x] Capabilities → Push Notifications — включено
- [x] Capabilities → Background Modes → Remote Notifications — присутствует ключ `UIBackgroundModes: remote-notification` в `Info.plist`
- [x] Entitlements (release) — `aps-environment: production` (build 17, Ad Hoc)
- [x] APNs Authentication Key (.p8) — загружен в Firebase (Key ID: `TYMLTYTH4P`, Team ID: `L37HR2KV4M`, Scope: Sandbox & Production)
- [x] Podfile платформа iOS — `platform :ios, '15.0'` (выше требуемого)

### 5. Flutter (инициализация)
- [x] `Firebase.initializeApp()` — добавлено в `lib/main.dart`
- [x] `FirebaseMessaging.onBackgroundMessage()` — добавлено в `lib/main.dart`

Комментарий: В `main.dart` явно отмечено «Firebase отключён (FCM удалён)». Используются локальные уведомления + Supabase init.

### 6. Получение токена
- [x] `FirebaseMessaging.instance.getToken()` — реализовано в `FcmTokenService`
- [x] `onTokenRefresh` — реализовано с debounce (1 сек.)
- [x] Привязка к установке — `installation_id` через `firebase_app_installations`
- [x] Сохранение в Supabase — upsert по паре `(installation_id, platform)` с деактивацией старых записей этой установки
- [x] Перепривязка при смене пользователя — выполняется автоматически (без создания новых строк)
- [x] Логаут — помечает текущий токен как `is_active=false`

### 7. Supabase (база)
- [x] Таблица смен — реализована как `works` и связанные таблицы (`work_items`, `work_materials`, `work_hours`) в `lib/data/migrations/works_migration.sql` с RLS
- [x] Таблица для FCM‑токенов — `public.user_tokens` (RLS, индексы)
  - Поля: `user_id`, `token` (UNIQUE глобально), `platform`, `installation_id` (NOT NULL), `is_active`, `created_at`, `updated_at`
  - Уникальность: `UNIQUE (installation_id, platform)` — одна строка на установку/платформу
  - Политики: владелец может CRUD; разрешён rebind при UPDATE с `WITH CHECK (auth.uid() = user_id)`

### 8. Supabase Edge Function (отправка уведомлений)
- [x] Секреты с сервисным JSON — установлен `SERVICE_ACCOUNT` в проекте
- [x] Edge Function `send-fcm` — развернута (FCM v1)
- [x] Edge Function `send_admin_work_event` — развернута (verify_jwt=true)
  - Вход: `{ action: 'open'|'close', work_id: UUID }`
  - Открытие: Title «Смена - ОТКРЫТА», Body: `Объект`, `Пользователь`, `Сотрудников: N`
  - Закрытие: Title «Смена - ЗАКРЫТА», Body: `Объект`, `Пользователь`, `Сумма`, `Выработка` (Сумма / кол-во сотрудников)
  - Data payload: `type, action, work_id, object_id, employees_count?, sum?, production?`

### 9. Проверка доставки (валидирование)
- [x] HTTP v1 тест на iOS (prod) — 200 OK (`projects/pgtmess/messages/...`)
- [x] Уведомление о закрытии смены доставлено на iOS (Ad Hoc build 17)

### Дополнительно: текущее решение по уведомлениям
- [x] Локальные уведомления через `flutter_local_notifications` настроены, см. `lib/core/notifications/notification_service.dart`
- [x] Таймзоны через `timezone` и `flutter_timezone`
- [x] Интеграция с UI: обработка нажатий ведёт на роут `'/works/{shiftId}'`
- [x] Документация: `docs/notifications_integration.md` описывает работу локальных уведомлений

### Поведение записи токенов (важно)
- Одна запись на установку: `(installation_id, platform)` — уникально
- При смене токена/пользователя строка обновляется (не создаётся новая)
- Старые записи той же установки автоматически помечаются `is_active=false`

### Вывод
FCM интеграция завершена и подтверждена:
- Клиент: инициализация Firebase/FCM, фоновые обработчики, получение/сохранение токена — готовы
- Бэкенд: `send-fcm` и `send_admin_work_event` — развернуты, секрет `SERVICE_ACCOUNT` установлен
- iOS: prod‑entitlements, APNs .p8 (Sandbox & Production) загружен, доставка подтверждена (200 OK, пуши приходят)
- Web: сервис‑воркер `web/firebase-messaging-sw.js`, `vapidKey` подключён в `FcmTokenService`


