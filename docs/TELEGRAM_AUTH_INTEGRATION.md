# Интеграция Telegram Mini App авторизации

**Дата:** 16 ноября 2025  
**Статус:** ✅ Реализована

---

## Архитектура гибридной авторизации

### Методы входа

| Метод | Поток | Статус профиля | Где работает |
|-------|-------|-----------------|--------------|
| **Email OTP** | `requestEmailOtp` → `verifyEmailOtp` | Ожидает одобрения | Везде |
| **Magic Link** | Email → hash → auth | Ожидает одобрения | Везде |
| **Telegram** | `initData` → Edge Function → JWT | Ожидает одобрения | Веб (TMA) |

---

## Компоненты системы

### 1. Edge Function: `telegram-auth`

**Расположение:** Supabase → Edge Functions → `telegram-auth`

**Что делает:**
1. Получает `initData` от Flutter
2. Проверяет подпись по протоколу Telegram Mini App
3. Создаёт/получает пользователя в Supabase Auth
4. Создаёт/получает профиль в таблице `profiles` (status=false)
5. Генерирует JWT токен с твоей SECRET
6. Возвращает `{ jwt, userId }`

**Environment Variables:**
```
JWT_SECRET=3efe2b95f854b740e06b7f25c5bac0b426eaa3942ec310ae18a7b0eb10c57ed0
TELEGRAM_BOT_TOKEN_MINIAPP=8352374794:AAHZRICXsukFfuuVmzC7Ko7s-F6CfhIWiKc
```

---

### 2. Data Layer: `TelegramAuthDataSource`

**Файл:** `lib/data/datasources/telegram_auth_data_source.dart`

**Ответственность:**
- Вызывает Edge Function `telegram-auth`
- Парсит ответ (JWT, userId)
- Устанавливает JWT сессию в Supabase Auth

```dart
final dataSource = TelegramAuthDataSource();
final response = await dataSource.authenticateWithInitData(
  initData: initDataFromTelegram,
);
```

---

### 3. Repository Layer

**Файл:** `lib/data/repositories/auth_repository_impl.dart`

**Метод:**
```dart
@override
Future<User> authenticateWithTelegram({required String initData}) async {
  await telegramAuthDataSource.authenticateWithInitData(initData: initData);
  final userModel = await authDataSource.getCurrentUser();
  return userModel!.toDomain();
}
```

---

### 4. Use Case Layer

**Файл:** `lib/domain/usecases/auth/telegram_authenticate_usecase.dart`

**Использование:**
```dart
final useCase = TelegramAuthenticateUseCase(repository);
final user = await useCase.execute(initData: initData);
```

---

### 5. State Management: `AuthNotifier`

**Файл:** `lib/presentation/state/auth_state.dart`

**Метод:**
```dart
Future<void> loginWithTelegram(String initData) async {
  state = state.copyWith(status: AuthStatus.loading);
  try {
    final user = await _ref
      .read(telegramAuthenticateUseCaseProvider)
      .execute(initData: initData);
    
    // Проверка статуса профиля
    // ...
    
    state = state.copyWith(
      status: statusFlag 
        ? AuthStatus.authenticated 
        : AuthStatus.pendingApproval,
      user: user,
    );
  } catch (e) {
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: e.toString(),
    );
  }
}
```

---

## Использование в UI

### Пример: Кнопка входа через Telegram

```dart
class TelegramLoginButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          // 1. Получить initData от Telegram WebApp JS API
          final initData = await _getTelegramInitData();
          
          if (initData == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Приложение не запущено из Telegram')),
            );
            return;
          }

          // 2. Вызвать loginWithTelegram
          await ref
            .read(authProvider.notifier)
            .loginWithTelegram(initData);
            
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка входа: $e')),
          );
        }
      },
      icon: const Icon(Icons.send),
      label: const Text('Вход через Telegram'),
    );
  }

  Future<String?> _getTelegramInitData() async {
    // Только для веб версии
    if (!kIsWeb) return null;
    
    try {
      // Вызываем JavaScript для получения initData
      final result = await WebAdapter.evaluateJavaScript(
        'window.Telegram?.WebApp?.initData',
      );
      return result as String?;
    } catch (_) {
      return null;
    }
  }
}
```

---

## Поток данных

```
┌─────────────────────────┐
│   Flutter WebApp        │
│ (Telegram Mini App)     │
└───────────┬─────────────┘
            │ 1. initData от Telegram
            │    (подписаны TG ключом)
            ▼
┌─────────────────────────┐
│  _getTelegramInitData() │
│  (JS evaluation)        │
└───────────┬─────────────┘
            │ 2. initData строка
            ▼
┌──────────────────────────────┐
│  ref.read(authProvider      │
│      .notifier)             │
│  .loginWithTelegram(...)    │
└───────────┬──────────────────┘
            │ 3. Вызов use case
            ▼
┌──────────────────────────┐
│  TelegramAuthenticateUC  │
│  .execute(initData)      │
└───────────┬──────────────┘
            │ 4. Вызов repository
            ▼
┌──────────────────────────────┐
│  AuthRepositoryImpl           │
│  .authenticateWithTelegram() │
└───────────┬──────────────────┘
            │ 5. Вызов data source
            ▼
┌─────────────────────────────┐
│  TelegramAuthDataSource     │
│  .authenticateWithInitData()│
└───────────┬─────────────────┘
            │ 6. Вызов Edge Function
            ▼
╔═════════════════════════════════════╗
║  Supabase Edge Function             ║
║  `telegram-auth`                    ║
║                                     ║
║  1. Проверяет подпись               ║
║  2. Создаёт/получает пользователя   ║
║  3. Создаёт/получает профиль        ║
║  4. Генерирует JWT                  ║
║  5. Возвращает { jwt, userId }      ║
╚═════════════════════════────────────╝
            │ 7. { jwt, userId }
            ▼
┌─────────────────────────────┐
│  setSession(jwt)            │
│  (Supabase Auth)            │
└───────────┬─────────────────┘
            │ 8. Сессия установлена
            ▼
┌──────────────────────┐
│  getCurrentUser()    │
│  (Supabase Auth)     │
└───────────┬──────────┘
            │ 9. User объект
            ▼
┌────────────────────────────┐
│  AuthStatus.authenticated │
│  (или pendingApproval)      │
└────────────────────────────┘
```

---

## Локальная разработка

### Запуск Edge Function локально

```bash
# 1. Убедись что переменные в supabase/.env.local установлены
cat supabase/.env.local

# 2. Запусти функцию локально
supabase functions serve telegram-auth

# 3. Функция будет доступна на:
# http://localhost:54321/functions/v1/telegram-auth
```

### Тестирование функции

```bash
# Используя curl
curl -L -X POST 'http://localhost:54321/functions/v1/telegram-auth' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  --data '{"initData":"user_id=123&username=testuser&hash=..."}'
```

---

## Безопасность

### ✅ Реализовано

1. **Проверка подписи Telegram**
   - Edge Function проверяет подпись initData по токену бота
   - Предотвращает подделку данных

2. **JWT с вашей SECRET**
   - Edge Function генерирует JWT с твоей SECRET
   - Не полагается на Supabase встроенный JWT

3. **Профиль требует одобрения**
   - Новые Telegram пользователи создаются с `status=false`
   - Администратор должен одобрить в таблице `profiles`
   - Недобренные пользователи → `pendingApproval`

4. **RLS политики**
   - Все таблицы должны иметь RLS
   - Ограничивают доступ по `auth.uid()`

---

## Ограничения

### ❌ Telegram Mini App — только на веб

- Telegram Bot Token используется только в Edge Function (серверная сторона)
- Flutter может получить `initData` только через JS на веб
- На iOS/Android: Telegram не предоставляет `initData` нативным приложениям

### Решение

Для мобильной версии используй остальные методы:
- ✅ Email OTP
- ✅ Magic Link
- ✅ Другие OAuth (Google, GitHub и т.д.)

---

## Структура файлов

```
lib/
├── data/datasources/
│   └── telegram_auth_data_source.dart      ← Data source для Edge Function
├── domain/
│   ├── repositories/
│   │   └── auth_repository.dart            ← Абстракция (+ новый метод)
│   └── usecases/auth/
│       └── telegram_authenticate_usecase.dart ← Use case
├── data/repositories/
│   └── auth_repository_impl.dart           ← Реализация
├── presentation/state/
│   └── auth_state.dart                     ← AuthNotifier.loginWithTelegram()
└── core/di/
    └── providers.dart                      ← Провайдеры (+ новые)

supabase/
├── functions/telegram-auth/
│   └── index.ts                            ← Edge Function
└── .env.local                              ← Секреты (локально)
```

---

## Провайдеры DI

```dart
// lib/core/di/providers.dart

/// Data Source
final telegramAuthDataSourceProvider = Provider<TelegramAuthDataSource>(...)

/// Repository — использует оба data source (auth + telegram)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authDataSource = ref.watch(authDataSourceProvider);
  final telegramAuthDataSource = ref.watch(telegramAuthDataSourceProvider);
  return AuthRepositoryImpl(
    authDataSource: authDataSource,
    telegramAuthDataSource: telegramAuthDataSource,
  );
})

/// Use Case
final telegramAuthenticateUseCaseProvider = 
    Provider<TelegramAuthenticateUseCase>(...)
```

---

## Проверка списка

- ✅ Edge Function `telegram-auth` создана и задеплоена
- ✅ Секреты (`JWT_SECRET`, `TELEGRAM_BOT_TOKEN_MINIAPP`) добавлены в:
  - `supabase/.env.local` (локально)
  - Supabase Dashboard → Functions → Environment variables (облако)
- ✅ JWT verify отключен для функции (`Verify JWT with legacy secret` = OFF)
- ✅ Data Source `TelegramAuthDataSource` реализован
- ✅ Repository добавлен метод `authenticateWithTelegram()`
- ✅ Use Case `TelegramAuthenticateUseCase` создан
- ✅ AuthNotifier добавлен метод `loginWithTelegram()`
- ✅ Провайдеры DI настроены
- ✅ Нет linter ошибок

---

## Следующие шаги

1. **Добавить кнопку входа через Telegram на экран входа**
   - Файл: `lib/features/auth/presentation/screens/login_screen.dart`
   - Использовать пример выше (`TelegramLoginButton`)

2. **Тестировать на веб-версии в Telegram Mini App**
   - Используй BotFather для создания Mini App
   - Установи URL веб-приложения Flutter
   - Тестируй вход через Telegram

3. **Добавить обработку ошибок и логирование**
   - Обработка случаев когда initData недоступна
   - Логирование попыток входа

4. **Документирование для пользователей**
   - Инструкция по входу через Telegram
   - FAQ

---

## Поддержка

Если возникнут вопросы по интеграции — смотри:
- `@fot/fot_module.md` — пример чистой архитектуры
- `@auth_system.md` — общая информация об авторизации
- Supabase документация по Edge Functions: https://supabase.com/docs/guides/functions

