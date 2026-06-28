## FCM: чек‑лист PUSH для админов и владельцев (iOS / Android / PWA)

**Статус:** ✅ АКТИВНО (июнь 2026)  
**Последний успешный тест:** PWA iPhone — open/close смены, tap без 403, multi-device (phone + PC).

---

### Кому отправляется

- [x] **Владельцы** компании (`company_members.is_owner = true`)
- [x] **Админы** (роли: Администратор, Админ, Супер-админ)
- [x] Фильтр: `profiles.status !== false`
- [x] Клиент передаёт `notify_all: false` (не всем участникам компании)

### Платформы

- [x] **PWA iPhone / iPad** (iOS 16.4+, platform=`web`, «На экран Домой»)
- [x] **Web-браузер** (Chrome, Edge, Safari desktop — platform=`web`)
- [x] **Native iOS** (platform=`ios`)
- [x] **Native Android** (platform=`android`)

---

### Примеры уведомлений

**Открытие:**
```text
🔓 Смена - ОТКРЫТА
📍 Объект: …
👤 Пользователь: …
👥 Сотрудников: N
```

**Закрытие:**
```text
🔒 Смена - ЗАКРЫТА
📍 Объект: …
👤 Пользователь: …
💰 Сумма: 125 000 ₽
⚙️ Выработка: 25 000 ₽
```

---

### Клиент (Flutter + Web)

- [x] `FcmTokenService` — регистрация токена, VAPID на Web
- [x] `admin_work_notification_service.dart` — вызов Edge Function
- [x] `work_form_screen` → open; `work_data_tab` → close
- [x] `firebase-messaging-sw.js` — без дубля баннера
- [x] Deep link `/?work_id=` (не `/works/:id`)
- [x] Multi-device: телефон + ПК не вытесняют друг друга
- [x] Refresh token при возврате в приложение

### Edge Function `send_admin_work_event`

- [x] JWT обязателен (`verify_jwt=true`)
- [x] Платформы: `ios`, `android`, `web`
- [x] Dedup по `installation_id`, не по platform целиком
- [x] Web payload: `webpush` only (без top-level `notification`)
- [x] CORS включён

### Секреты (Supabase → Edge Functions)

- [x] `SERVICE_ACCOUNT` — Firebase service account JSON
- [x] `SERVICE_ROLE_KEY` — чтение токенов админов

### Деплой (self-hosted)

- [ ] **PWA** на Timeweb — после каждого изменения `web/` или Flutter web build
- [ ] **Edge Function** `send_admin_work_event` — вручную на `api.progt.ru`

---

### PWA iPhone — чек-лист для пользователя

1. [ ] iOS 16.4+
2. [ ] Safari → Поделиться → **На экран Домой**
3. [ ] Запуск **с иконки**, не из вкладки
4. [ ] Разрешить уведомления
5. [ ] После входа с ПК — **открыть PWA на телефоне** (обновит токен)

---

### Диагностика

| Симптом | Проверка |
|---------|----------|
| `tokens_total: 0` | owner/admin в company_members; active user_tokens |
| Push не на телефон после ПК | multi-device fix задеплоен; открыть PWA на телефоне |
| Два баннера | SW не дублирует showNotification |
| 403 при tap | link = `/?work_id=`, PWA задеплоен |
| «from Стройка PRO» | ограничение iOS, норма |

**Тест curl:**
```bash
curl -X POST 'https://api.progt.ru/functions/v1/send_admin_work_event' \
  -H 'Content-Type: application/json' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -d '{"action":"open","work_id":"<UUID>","notify_all":false}'
```

---

### Связанные документы

- [admin_notifications.md](./admin_notifications.md) — полная документация PWA push
- [FCM_INTEGRATION_STATUS.md](./FCM_INTEGRATION_STATUS.md) — статус интеграции

**Актуализация:** 28 июня 2026
