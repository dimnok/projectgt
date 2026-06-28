## Статус интеграции FCM (Flutter + Supabase + PWA)

**Актуально:** 28 июня 2026

---

### Общий статус

| Компонент | Статус |
|-----------|--------|
| Firebase проект `pgtmess` | ✅ ACTIVE |
| Native iOS / Android push | ✅ работает |
| **PWA iPhone (Web Push)** | ✅ работает (iOS 16.4+) |
| **Web desktop push** | ✅ работает |
| Admin push open/close смены | ✅ работает |
| Multi-device (phone + PC) | ✅ исправлено 28.06.2026 |
| Tap → экран смены | ✅ `/?work_id=` (fix 403) |

---

### 1. Flutter-пакеты

- [x] `firebase_core`, `firebase_messaging`, `firebase_app_installations`
- [x] `supabase_flutter`

---

### 2. Клиент

| Файл | Назначение |
|------|------------|
| `lib/data/services/fcm_token_service.dart` | токены, VAPID, multi-device |
| `lib/data/services/admin_work_notification_service.dart` | invoke Edge Function |
| `lib/core/notifications/fcm_push_handler.dart` | tap / foreground |
| `lib/core/notifications/push_work_navigation*.dart` | deep link |
| `lib/main.dart` | init, resume refresh |
| `web/firebase-messaging-sw.js` | SW для PWA |
| `web/manifest.json` | standalone PWA |

- [x] `Firebase.initializeApp()` — Android, iOS, Web
- [x] Background handler — native (Web: SW)
- [x] Upsert `user_tokens` по `(installation_id, platform)`
- [x] Logout → `is_active=false`
- [x] Resume → `refreshCurrentDeviceToken()`

---

### 3. База данных

**Таблица `public.user_tokens`**

- RLS ✅
- `platform`: `ios` | `android` | `web`
- UNIQUE `(installation_id, platform)`, UNIQUE `token`

---

### 4. Edge Functions

- [x] `send_admin_work_event` — admin/owner push, FCM v1
- [x] `send-fcm` — низкоуровневая отправка

**Получатели:** owners + admins при `notify_all: false`  
**Платформы отправки:** ios, android, web  
**Секреты:** `SERVICE_ACCOUNT`, `SERVICE_ROLE_KEY`

---

### 5. Firebase / платформы

**iOS native**

- Bundle `com.projectgt.stroyka`, APNs .p8, production entitlements

**Android**

- `google-services.json`, minSdk 23

**Web / PWA**

- VAPID: `BGPPZr58sdNUlGT4RFTLiteNdyOxQWI9mJdxnP4ycqEA0qUrGh6sDRKdkvXN6O1jpdmeH1ETcwn8ePeTPocORW4`
- Service Worker: `web/firebase-messaging-sw.js`
- PWA: `display: standalone` в manifest

---

### 6. Локальные уведомления (отдельно)

Напоминания по слотам времени — **не FCM**. См. [notifications_integration.md](./notifications_integration.md).

Admin push при open/close смены — см. [admin_notifications.md](./admin_notifications.md).

---

### 7. Production PWA

- URL: `https://e65ccfca-5800-40ab-b157-ac33d7a5f026.website.twcstorage.ru`
- Backend: `https://api.progt.ru`

---

### Вывод

FCM интеграция **завершена** для native и PWA. Критичные фиксы июня 2026:

1. Web-токены в Edge Function
2. Owners в списке получателей
3. Один баннер (webpush-only)
4. Deep link `/?work_id=`
5. Multi-device tokens

**Полная документация:** [admin_notifications.md](./admin_notifications.md)
