# Система Push-уведомлений для администраторов

**Дата актуализации:** 11 октября 2025 года (обновлено: добавлено форматирование сумм с пробелами; 17 апреля 2026: поиск админов через `company_members` + `roles`; исходники в `supabase/functions/send_admin_work_event/` **совпадают по стилю с self-hosted**: `jsr` types, ручной JWT к FCM, тот же FCM payload / CORS)

## Обзор

В ProjectGT реализована система push-уведомлений для администраторов о событиях открытия и закрытия смен. Система построена на Firebase Cloud Messaging (FCM) API v1 и Supabase Edge Functions.

**Статус:** ✅ АКТИВНО. Минимальная схема развернута и работает в production-среде FCM HTTP v1.

**Версия Edge Function:** v32 (с форматированием сумм)

**Последняя сводка:** admin_count=1, raw_tokens_count=1, tokens_total=1, sent=1.

## Ключевые компоненты

### 1. **Flutter-клиент**
- `lib/data/services/fcm_token_service.dart` — управление FCM токенами
- `lib/main.dart` — инициализация Firebase и фоновых обработчиков
- `lib/features/works/presentation/screens/work_form_screen.dart` — отправка уведомлений при открытии смены
- `lib/features/works/presentation/screens/tabs/work_data_tab.dart` — отправка уведомлений при закрытии смены

### 2. **База данных**
- Таблица `public.user_tokens` — хранение FCM токенов пользователей
- Таблицы `public.company_members`, `public.roles` — роль пользователя в компании (источник для «кто админ»)
- Таблица `public.profiles` — ФИО и `status` (фильтр «не слать отключённым»)

### 3. **Backend (Supabase Edge Functions)**
- `send_admin_work_event` — отправка уведомлений админам о событиях смены
- `send-fcm` — низкоуровневая отправка FCM сообщений через API v1

## Архитектура системы

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                            │
│                                                                   │
│  ┌─────────────────┐         ┌──────────────────┐               │
│  │ FcmTokenService │────────▶│  Firebase SDK    │               │
│  │  - init()       │         │  - getToken()    │               │
│  │  - saveToken()  │         │  - onTokenRefresh│               │
│  └─────────────────┘         └──────────────────┘               │
│           │                                                       │
│           │ save token                                           │
│           ▼                                                       │
│  ┌─────────────────────────────────────────────┐                │
│  │  User opens/closes shift                    │                │
│  │  → invoke('send_admin_work_event')          │                │
│  └─────────────────────────────────────────────┘                │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase Backend                            │
│                                                                   │
│  ┌─────────────────────────────────────────────┐                │
│  │    Edge Function: send_admin_work_event     │                │
│  │                                              │                │
│  │  1. Получает work_id и action               │                │
│  │  2. Читает данные смены из БД               │                │
│  │  3. Находит админов по company_members+roles │               │
│  │  4. Получает активные токены админов        │                │
│  │  5. Формирует notification payload          │                │
│  │  6. Отправляет через FCM API v1             │                │
│  └─────────────────────────────────────────────┘                │
│           │                          ▲                           │
│           │                          │                           │
│           ▼                          │                           │
│  ┌─────────────────┐    ┌──────────────────────┐               │
│  │  user_tokens    │    │ company_members,roles│               │
│  │  - token        │    │  - role_name …      │               │
│  │  - platform     │    │  - status = true     │               │
│  │  - is_active    │    └──────────────────────┘               │
│  └─────────────────┘                                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │ FCM API v1
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Firebase Cloud Messaging                       │
│                                                                   │
│  ┌────────────────────────────────────────────┐                 │
│  │  FCM отправляет push-уведомления на        │                 │
│  │  устройства админов (iOS/Android)          │                 │
│  └────────────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

## Детальный процесс работы

### Этап 1: Регистрация FCM токенов

#### 1.1. Инициализация Firebase (при запуске приложения)

**Файл:** `lib/main.dart`

```dart
// Инициализация Firebase с опциями для текущей платформы
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Регистрация фонового обработчика сообщений FCM
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

// Показ уведомлений в форграунде на iOS/macOS
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  alert: true,
  badge: true,
  sound: true,
);
```

#### 1.2. Инициализация FcmTokenService

**Файл:** `lib/main.dart` (внутри MyApp)

```dart
// FCM: регистрируем токен при запуске
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(fcmTokenServiceProvider).initialize();
});
```

#### 1.3. Получение и сохранение токена

**Файл:** `lib/data/services/fcm_token_service.dart`

Процесс:

1. **Запрос разрешений** на push-уведомления (iOS/Android)
   ```dart
   await FirebaseMessaging.instance.requestPermission(
     alert: true,
     badge: true,
     sound: true,
   );
   ```

2. **Получение FCM токена** от Firebase
   ```dart
   final String? token = await FirebaseMessaging.instance.getToken(
     vapidKey: kIsWeb ? 'YOUR_VAPID_KEY' : null,
   );
   ```

3. **Получение Installation ID** для уникальной привязки устройства
   ```dart
   String? installationId = await FirebaseInstallations.instance.getId();
   ```

4. **Сохранение в таблицу `user_tokens`**
   ```dart
   await Supabase.instance.client.from('user_tokens').upsert(
     {
       'user_id': user.id,
       'token': token,
       'platform': platform, // 'ios', 'android', 'web'
       'installation_id': installationId,
       'is_active': true,
       'updated_at': DateTime.now().toIso8601String(),
     },
     onConflict: 'installation_id,platform',
   );
   ```

**Особенности:**
- Одна запись на установку/платформу за счёт `UNIQUE (installation_id, platform)`
- При смене токена строка обновляется (не создаётся новая)
- При смене пользователя токен перепривязывается автоматически
- При выходе из аккаунта токен помечается как `is_active=false`

#### 1.4. Обновление токена

```dart
// Автоматическое обновление при изменении токена (с debounce 1 сек)
FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
  pendingToken = token;
  await Future<void>.delayed(const Duration(seconds: 1));
  _saveToken(token);
});
```

### Этап 2: Отправка уведомлений при событиях смены

#### 2.1. Открытие смены

**Файл:** `lib/features/works/presentation/screens/work_form_screen.dart`

**Триггер:** Пользователь нажимает кнопку "Открыть смену"

```dart
// Отправка PUSH админам о открытии смены через Edge Function
try {
  final supabase = ref.read(supabaseClientProvider);
  final accessToken = supabase.auth.currentSession?.accessToken;
  
  if (accessToken != null) {
    final resp = await supabase.functions.invoke(
      'send_admin_work_event',
      body: {
        'action': 'open',
        'work_id': createdWork.id!,
        // Опционально: `notify_all: false` — только админам (по умолчанию на Edge — всем участникам компании).
      },
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    
    debugPrint('send_admin_work_event(open): status=${resp.status}, data=${resp.data}');
  }
} catch (_) {
  // Не блокируем UX из-за уведомления
}
```

#### 2.2. Закрытие смены

**Файл:** `lib/features/works/presentation/screens/tabs/work_data_tab.dart`

**Триггер:** Пользователь подтверждает закрытие смены

```dart
// Отправка PUSH админам о закрытии смены
try {
  if (updatedWork.id != null) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    
    if (token != null) {
      await Supabase.instance.client.functions.invoke(
        'send_admin_work_event',
        body: {
          'action': 'close',
          'work_id': updatedWork.id!
        },
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
    }
  }
} catch (_) {
  // Не блокируем UX
}
```

### Этап 3: Обработка на сервере (Edge Function)

**Edge Function:** `send_admin_work_event` (v32)

**Настройки:**
- `verify_jwt=true` — требуется JWT токен авторизации
- CORS включён
- Использует `SERVICE_ROLE_KEY` для обхода RLS при чтении БД
- Форматирование сумм с разделителями тысяч (пробелами) и символом ₽

**Алгоритм работы:**

1. **Валидация входных данных**
   ```javascript
   const { action, work_id } = await req.json();
   // action: 'open' | 'close'
   // work_id: UUID
   ```

2. **Чтение данных смены из БД**
   - Получение информации о смене (`works`)
   - Получение объекта (`objects`)
   - Получение пользователя, открывшего смену (`profiles`)
   - Подсчёт сотрудников (`work_hours`)
   - Подсчёт суммы и выработки (для закрытия)

3. **Кому слать push** (логика в Edge; тело запроса может содержать `notify_all`)
   - **По умолчанию** (`notify_all` не передан или не `false`): все активные участники компании смены — `company_members` по `works.company_id`, `is_active`, затем фильтр `profiles.status !== false`, токены `user_tokens` (`ios` / `android`, `is_active`).
   - **`notify_all: false`** (для будущей настройки в UI): только админы — `company_members` + роли `Администратор`, `Админ`, плюс глобальный `Супер-админ` по всем строкам membership, с тем же фильтром профилей и токенов.

4. **Получение активных токенов админов**
   ```sql
   SELECT token, platform 
   FROM user_tokens 
   WHERE user_id IN (admin_ids)
     AND is_active = true
     AND platform IN ('ios', 'android')
   ```

5. **Формирование notification payload**

6. **Отправка через FCM HTTP v1 API**
   ```javascript
   await fetch('https://fcm.googleapis.com/v1/projects/pgtmess/messages:send', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${accessToken}`,
       'Content-Type': 'application/json',
     },
     body: JSON.stringify({ message: fcmMessage }),
   });
   ```

7. **Возврат результата**
   ```json
   {
     "sent": 1,
     "total": 1,
     "admin_count": 1,
     "raw_tokens_count": 1,
     "tokens_total": 1
   }
   ```

### Этап 4: Доставка push-уведомлений

Firebase Cloud Messaging доставляет уведомления на устройства администраторов через:
- **APNs** (Apple Push Notification service) для iOS
- **FCM** (Firebase Cloud Messaging) для Android
- **Web Push** для веб-приложений

## Примеры уведомлений

### Открытие смены

```text
Title: 🔓 Смена - ОТКРЫТА

Body:
📍 Объект: ТЦ "Галерея"
👤 Пользователь: Иван Иванов
👥 Сотрудников: 5
```

**Код формирования (Edge Function):**
```javascript
{
  notification: {
    title: '🔓 Смена - ОТКРЫТА',
    body: `📍 Объект: ${objectName}\n👤 Пользователь: ${userName}\n👥 Сотрудников: ${employeesCount}`
  },
  data: {
    type: 'work_event',
    action: 'open',
    work_id: workId,
    object_id: objectId,
    employees_count: employeesCount.toString()
  },
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1
      }
    }
  },
  android: {
    priority: 'high',
    notification: {
      sound: 'default',
      channelId: 'work_events'
    }
  }
}
```

### Закрытие смены

```text
Title: 🔒 Смена - ЗАКРЫТА

Body:
📍 Объект: ТЦ "Галерея"
👤 Пользователь: Иван Иванов
💰 Сумма: 125 000 ₽
⚙️ Выработка: 25 000 ₽
```

**Форматирование сумм:**
```javascript
// Функция форматирования: 245766 -> "245 766 ₽"
const formatCurrency = (num) => {
  const rounded = Math.round(num);
  const formatted = rounded.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return `${formatted} ₽`;
};
```

**Расчёт выработки:**
```javascript
// Выработка = Сумма / Количество сотрудников
const production = employeesCount > 0 ? sumRaw / employeesCount : 0;
```

**Код формирования (Edge Function):**
```javascript
{
  notification: {
    title: '🔒 Смена - ЗАКРЫТА',
    body: `📍 Объект: ${objectName}\n👤 Пользователь: ${userName}\n💰 Сумма: ${formatCurrency(sum)}\n⚙️ Выработка: ${formatCurrency(production)}`
  },
  data: {
    type: 'work_event',
    action: 'close',
    work_id: workId,
    object_id: objectId,
    employees_count: employeesCount.toString(),
    sum: sum.toString(),
    production: production.toString()
  },
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1
      }
    }
  },
  android: {
    priority: 'high',
    notification: {
      sound: 'default',
      channelId: 'work_events'
    }
  }
}
```

## Структура базы данных

### Таблица `public.user_tokens`

Хранит FCM токены пользователей для push-уведомлений.

**Количество записей:** зависит от количества активных пользователей

**RLS:** ✅ Включён

| Колонка          | Тип          | Описание                                    | Ограничения        |
|------------------|--------------|---------------------------------------------|--------------------|
| id               | uuid         | Уникальный идентификатор записи            | PRIMARY KEY        |
| user_id          | uuid         | ID пользователя                             | FK auth.users(id)  |
| token            | text         | FCM токен устройства                        | NOT NULL, UNIQUE   |
| platform         | text         | Платформа (ios/android/web)                 | NOT NULL, CHECK    |
| installation_id  | text         | ID установки Firebase                       | -                  |
| is_active        | boolean      | Активен ли токен                            | DEFAULT true       |
| device_id        | text         | ID устройства                               | -                  |
| device_model     | text         | Модель устройства                           | -                  |
| os_version       | text         | Версия ОС                                   | -                  |
| app_version      | text         | Версия приложения                           | -                  |
| created_at       | timestamptz  | Дата создания                               | DEFAULT now()      |
| updated_at       | timestamptz  | Дата обновления                             | DEFAULT now()      |

**Индексы:**
```sql
CREATE UNIQUE INDEX user_tokens_token_unique ON user_tokens(token);
CREATE UNIQUE INDEX user_tokens_installation_platform_unique ON user_tokens(installation_id, platform);
CREATE INDEX user_tokens_user_id_idx ON user_tokens(user_id);
CREATE INDEX user_tokens_active_idx ON user_tokens(is_active);
```

**Триггеры:**
```sql
-- Автоматическое обновление updated_at
CREATE TRIGGER user_tokens_set_updated_at
BEFORE UPDATE ON user_tokens
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**RLS Политики:**
```sql
-- Пользователи могут видеть только свои токены
CREATE POLICY "Users can view own tokens"
  ON user_tokens FOR SELECT
  USING (auth.uid() = user_id);

-- Пользователи могут добавлять только свои токены
CREATE POLICY "Users can insert own tokens"
  ON user_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Пользователи могут обновлять только свои токены
CREATE POLICY "Users can update own tokens"
  ON user_tokens FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Пользователи могут удалять только свои токены
CREATE POLICY "Users can delete own tokens"
  ON user_tokens FOR DELETE
  USING (auth.uid() = user_id);
```

**⚠️ Важно:** Edge Function использует `SERVICE_ROLE_KEY` для обхода RLS при чтении токенов всех админов.

### Связь с таблицей `profiles`

```
profiles (1) ──────< user_tokens (N)
  │
  ├── id (PK)
  │
  └── role = 'admin'  ──→ Фильтр для получателей уведомлений
      status = true/NULL
```

## Конфигурация Firebase

### Проект Firebase
- **Project ID:** `pgtmess`
- **Статус:** ACTIVE

### iOS
- **Bundle ID:** `com.projectgt.stroyka`
- **Team ID:** `L37HR2KV4M`
- **APNs Authentication Key:** `.p8` файл загружен
  - **Key ID:** `TYMLTYTH4P`
  - **Scope:** Sandbox & Production
- **Entitlements:** `aps-environment: production`
- **Config:** `ios/Runner/GoogleService-Info.plist`

### Android
- **Package:** `com.projectgt.stroyka`
- **Config:** `android/app/google-services.json`
- **Min SDK:** 23

### Web
- **VAPID Key:** `BGPPZr58sdNUlGT4RFTLiteNdyOxQWI9mJdxnP4ycqEA0qUrGh6sDRKdkvXN6O1jpdmeH1ETcwn8ePeTPocORW4`
- **Service Worker:** `web/firebase-messaging-sw.js`

## Секреты Supabase

Для работы Edge Functions требуются следующие секреты (Supabase Dashboard → Project Settings → Edge Functions → Secrets):

1. **SERVICE_ACCOUNT** — JSON-файл сервисного аккаунта Firebase для FCM HTTP v1 API
   ```json
   {
     "type": "service_account",
     "project_id": "pgtmess",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-...@pgtmess.iam.gserviceaccount.com",
     "client_id": "...",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
     "client_x509_cert_url": "..."
   }
   ```

2. **SERVICE_ROLE_KEY** — Ключ сервера Supabase для обхода RLS при чтении `profiles` и `user_tokens`

## Диагностика проблем

### Проблема: `tokens_total: 0` (токены не найдены)

**Причины и решения:**

1. **Клиент не передаёт Authorization header**
   ```dart
   // ✅ Правильно:
   headers: {
     'Authorization': 'Bearer $accessToken',
   }
   ```

2. **У пользователя нет роли admin**
   ```sql
   -- Проверка в БД:
   SELECT id, email, role, status 
   FROM profiles 
   WHERE role = 'admin';
   ```

3. **Нет активных токенов в user_tokens**
   ```sql
   -- Проверка токенов админа:
   SELECT * 
   FROM user_tokens 
   WHERE user_id = '<admin_user_id>' 
     AND is_active = true;
   ```

4. **Секреты не установлены в Supabase**
   - Проверить наличие `SERVICE_ACCOUNT` и `SERVICE_ROLE_KEY`
   - Перезапустить Edge Functions после установки секретов

5. **iOS: несоответствие среды APNs**
   - Debug build требует Sandbox APNs
   - Ad Hoc/TestFlight/App Store требуют Production APNs
   - Убедиться, что `.p8` ключ поддерживает нужную среду

### Проблема: Уведомления не приходят на устройство

1. **Проверка FCM токена**
   ```dart
   // Добавить логирование:
   final token = await FirebaseMessaging.instance.getToken();
   debugPrint('FCM Token: $token');
   ```

2. **Проверка разрешений на уведомления**
   ```dart
   final settings = await FirebaseMessaging.instance.getNotificationSettings();
   debugPrint('Authorization status: ${settings.authorizationStatus}');
   // AuthorizationStatus.authorized - разрешено
   // AuthorizationStatus.denied - запрещено
   ```

3. **Тест отправки напрямую через FCM**
   - Использовать Firebase Console → Cloud Messaging → Send test message
   - Вставить токен устройства и отправить тестовое сообщение

4. **Проверка логов Edge Function**
   ```bash
   # В Supabase Dashboard → Edge Functions → Logs
   # Искать строки:
   # - "start" - функция запущена
   # - "no_tokens" - токены не найдены
   # - "summary" - итоговая статистика отправки
   ```

### Проблема: Дублирование токенов

**Решение:** Уже реализовано через уникальность `(installation_id, platform)`:
```dart
// При сохранении токена сначала деактивируются старые записи этой установки:
await Supabase.instance.client
  .from('user_tokens')
  .update({'is_active': false})
  .eq('installation_id', installationId)
  .eq('platform', platform)
  .neq('token', token);
```

## Ограничения и особенности

### Область применения
- ✅ Отправляем PUSH **только админам** (`profiles.role='admin'`)
- ✅ Только активным админам (`status=true` или `status IS NULL`)
- ✅ Поддерживаем платформы **iOS** и **Android**
- ⚠️ **Web** токены игнорируются Edge Function (можно добавить при необходимости)

### Производительность
- Отправка уведомлений **не блокирует UX**
- Ошибки отправки **молча игнорируются** (try-catch без re-throw)
- Дебаунс 1 секунда для `onTokenRefresh` предотвращает дубликаты

### Безопасность
- JWT токен **обязателен** (`verify_jwt=true`)
- RLS на `user_tokens` защищает токены пользователей
- Edge Function использует `SERVICE_ROLE_KEY` только для чтения админских токенов

## Планы развития

### ✅ Реализовано
- [x] Базовая отправка уведомлений при открытии/закрытии смены
- [x] FCM токены с автоматической синхронизацией
- [x] Уникальность токенов по `(installation_id, platform)`
- [x] Перепривязка токенов при смене пользователя
- [x] Деактивация токенов при logout
- [x] Фильтрация по ролям (только админы)
- [x] Поддержка iOS (Production APNs) и Android
- [x] Подробное логирование в Edge Function
- [x] Форматирование денежных сумм с пробелами (245 766 ₽)

### 🔄 Планируется
- [ ] Показ SnackBar с результатом отправки (`{sent}/{total}`)
- [ ] Настройки уведомлений для админов (включить/отключить)
- [ ] Группировка уведомлений (если несколько смен за короткое время)
- [ ] Отложенные уведомления (например, напоминание закрыть смену)
- [ ] Богатые уведомления с картинками объектов
- [ ] Действия в уведомлениях ("Открыть смену", "Игнорировать")
- [ ] Уведомления о других событиях (новый сотрудник, материалы и т.д.)
- [ ] Поддержка Web push-уведомлений для админов
- [ ] Статистика доставки уведомлений в админ-панели
- [ ] A/B тестирование текстов уведомлений

### 🟡 Технические улучшения
- [ ] Покрытие тестами (unit + integration)
- [ ] Мониторинг доставляемости FCM
- [ ] Retry механизм для failed отправок
- [ ] Rate limiting для предотвращения спама
- [ ] Аналитика: сколько админов открыли уведомление

## Тестирование

### Сценарий 1: Регистрация токена

1. Установить приложение на устройство
2. Войти под учётной записью админа
3. Дать разрешение на push-уведомления
4. Проверить в БД:
   ```sql
   SELECT * 
   FROM user_tokens 
   WHERE user_id = '<your_user_id>';
   ```
5. Убедиться, что `is_active = true` и `platform` соответствует устройству

### Сценарий 2: Уведомление при открытии смены

1. Войти под учётной записью обычного пользователя (не админа)
2. Открыть смену (выбрать объект, добавить сотрудников)
3. Нажать "Открыть смену"
4. На устройстве админа должно прийти уведомление:
   ```
   🔓 Смена - ОТКРЫТА
   📍 Объект: [название]
   👤 Пользователь: [имя]
   👥 Сотрудников: [N]
   ```

### Сценарий 3: Уведомление при закрытии смены

1. Открыть существующую смену
2. Добавить работы и материалы (общая сумма, например, 345766 ₽)
3. Добавить несколько сотрудников (например, 3 человека)
4. Закрыть смену
5. На устройстве админа должно прийти уведомление:
   ```
   🔒 Смена - ЗАКРЫТА
   📍 Объект: [название]
   👤 Пользователь: [имя]
   💰 Сумма: 345 766 ₽ (с пробелами!)
   ⚙️ Выработка: 115 255 ₽ (345766 / 3, с пробелами!)
   ```
6. **Проверить форматирование:** суммы должны содержать пробелы между тысячами

### Сценарий 4: Смена пользователя

1. Войти под одним пользователем
2. Проверить токен в БД
3. Выйти и войти под другим пользователем
4. Проверить, что токен перепривязан к новому `user_id`
5. Старый токен помечен как `is_active = false`

### Сценарий 5: Logout

1. Войти в приложение
2. Проверить токен в БД (`is_active = true`)
3. Выйти из приложения
4. Проверить, что токен помечен как `is_active = false`

## Примечания для разработчиков

### Общие рекомендации
- Всегда используйте `try-catch` при вызове `send_admin_work_event` — не блокируйте UX
- Используйте `debugPrint` для логирования результатов в dev-режиме
- Не забывайте передавать `Authorization: Bearer $accessToken`
- Проверяйте `accessToken != null` перед вызовом Edge Function

### Безопасность
- Никогда не коммитьте `SERVICE_ACCOUNT` JSON в репозиторий
- Используйте Supabase Secrets для хранения чувствительных данных
- RLS на `user_tokens` защищает токены — не отключайте его

### Производительность
- FCM имеет лимиты: 500 сообщений в секунду на проект
- Используйте batch-отправку для больших групп получателей (будущая оптимизация)
- Кэшируйте списки админов, если запросы частые

### Debugging
- Используйте Firebase Console → Cloud Messaging для тестовых отправок
- Логи Edge Functions доступны в Supabase Dashboard → Functions → Logs
- Используйте `flutter logs` для просмотра FCM событий на устройстве

### Форматирование
- Все денежные суммы в уведомлениях автоматически форматируются с пробелами
- Форматирование происходит на сервере (Edge Function v32)
- Формат: `245 766 ₽` (число с пробелами между тысячами + символ рубля)
- Клиентский код не требует изменений — форматирование прозрачно

## Связанные документы

- [FCM_ADMIN_NOTIFICATIONS_CHECKLIST.md](./FCM_ADMIN_NOTIFICATIONS_CHECKLIST.md) — чек-лист внедрения
- [FCM_INTEGRATION_STATUS.md](./FCM_INTEGRATION_STATUS.md) — статус интеграции FCM
- [notifications_integration.md](./notifications_integration.md) — локальные уведомления
- [works/works_module.md](./works/works_module.md) — модуль смен

## Последняя актуализация

**Дата:** 11 октября 2025 года

**Ключевые обновления:**
- ✅ Создан полный обзор системы уведомлений для админов
- ✅ Описан детальный процесс работы всех компонентов
- ✅ Добавлены примеры кода и уведомлений
- ✅ Задокументирована структура БД и RLS политики
- ✅ Добавлены инструкции по диагностике и тестированию
- ✅ **Обновлено форматирование сумм**: 345766 → 345 766 ₽ (Edge Function v32)

**Статус:** Документация актуальна и соответствует текущей реализации в production.

