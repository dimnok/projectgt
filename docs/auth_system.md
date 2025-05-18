# Система аутентификации и профилей

## Структура аутентификации

### Состояния аутентификации
```dart
enum AuthStatus {
  initial,        // Начальное состояние
  authenticated,  // Аутентифицирован
  unauthenticated, // Не аутентифицирован
  loading,        // Загрузка
  error,          // Ошибка
}
```

### Процесс аутентификации
1. Инициализация Supabase в `main.dart`
2. Проверка состояния аутентификации при запуске (`checkAuthStatus()`)
3. Перенаправление на соответствующие экраны в зависимости от состояния

## Пользовательские роли

- **user** - стандартная роль для обычных пользователей
- **admin** - роль с административными привилегиями

Роли хранятся в таблице profiles в поле `role` и влияют на доступ к разделам приложения.

## Модель пользователя

### User Entity (domain/entities/user.dart)
```dart
class User {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String role; // default: 'user'
}
```

### Profile Entity (domain/entities/profile.dart)
```dart
class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? shortName;
  final String? photoUrl;
  final String? phone;
  final String role; // default: 'user'
  final bool status; // default: true
  final Map<String, dynamic>? object;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

## Схема базы данных

### Таблица profiles
- `id` - UUID, идентичный id пользователя в auth
- `email` - email пользователя
- `full_name` - полное имя
- `short_name` - короткое имя или инициалы
- `photo_url` - ссылка на аватар
- `phone` - телефон
- `role` - роль пользователя
- `status` - активен/неактивен
- `object` - JSON для дополнительных данных
- `created_at` - дата создания
- `updated_at` - дата обновления

## Процесс регистрации

1. Вызов `register()` в AuthNotifier с именем, email и паролем
2. Создание пользователя в Supabase Auth
3. Создание записи в таблице profiles с генерацией shortName
4. Возврат данных пользователя с ролью 'user'

```dart
// Пример регистрации
await ref.read(authProvider.notifier).register(name, email, password);
```

## Процесс входа

1. Вызов `login()` в AuthNotifier с email и паролем
2. Аутентификация через Supabase Auth
3. Получение роли из таблицы profiles
4. Обновление состояния AuthState

```dart
// Пример входа
await ref.read(authProvider.notifier).login(email, password);
```

## Управление профилями

### ProfileState
```dart
enum ProfileStatus {
  initial, loading, success, error,
}

class ProfileState {
  final ProfileStatus status;
  final Profile? profile;
  final List<Profile> profiles;
  final String? errorMessage;
}
```

### Основные операции с профилями
- `getProfile(userId)` - получение профиля пользователя
- `getProfiles()` - получение списка всех профилей
- `updateProfile(profile)` - обновление профиля
- `refreshProfile(userId)` - принудительное обновление профиля
- `refreshProfiles()` - принудительное обновление списка профилей

## Защита маршрутов

Система маршрутизации в `core/common/app_router.dart` обеспечивает:
- Перенаправление неаутентифицированных пользователей на экран входа
- Проверку ролей для доступа к административным маршрутам
- Правильную обработку маршрутов с параметрами 

## Фото сотрудников

- Для сотрудников реализована отдельная загрузка и хранение фото в Supabase Storage (bucket `avatars/employees/`).
- Доступ к операциям загрузки/удаления осуществляется через сервис `PhotoService`.

## Фото контрагентов

- Для контрагентов реализована загрузка и хранение логотипа в Supabase Storage (bucket `avatars/contractors/`).
- Загрузка осуществляется через сервис PhotoService (временно используется uploadEmployeePhoto). 
- UI-ограничение ширины и стилизация формы аналогичны сотрудникам и объектам.

```dart
// Пример регистрации
await ref.read(authProvider.notifier).register(name, email, password);
```

## Процесс входа

1. Вызов `login()` в AuthNotifier с email и паролем
2. Аутентификация через Supabase Auth
3. Получение роли из таблицы profiles
4. Обновление состояния AuthState

```dart
// Пример входа
await ref.read(authProvider.notifier).login(email, password);
```

## Управление профилями

### ProfileState
```dart
enum ProfileStatus {
  initial, loading, success, error,
}

class ProfileState {
  final ProfileStatus status;
  final Profile? profile;
  final List<Profile> profiles;
  final String? errorMessage;
}
```

### Основные операции с профилями
- `getProfile(userId)` - получение профиля пользователя
- `getProfiles()` - получение списка всех профилей
- `updateProfile(profile)` - обновление профиля
- `refreshProfile(userId)` - принудительное обновление профиля
- `refreshProfiles()` - принудительное обновление списка профилей

## Защита маршрутов

Система маршрутизации в `core/common/app_router.dart` обеспечивает:
- Перенаправление неаутентифицированных пользователей на экран входа
- Проверку ролей для доступа к административным маршрутам
- Правильную обработку маршрутов с параметрами 