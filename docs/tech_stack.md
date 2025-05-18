# Технологический стек ProjectGT

## Основные технологии

- **Flutter SDK:** ^3.0.0
- **Dart:** ^3.0.0
- **Supabase:** в качестве Backend-as-a-Service (BaaS)

## Управление состоянием

- **flutter_riverpod (^2.4.9)** - основной инструмент управления состоянием
- **riverpod_annotation (^2.3.3)** - аннотации для кодогенерации
- **hooks_riverpod (^2.4.9)** - интеграция с flutter_hooks

```dart
// Пример определения провайдера
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Пример использования в UI
final authState = ref.watch(authProvider);
final user = authState.user;
```

## Кодогенерация и иммутабельность

- **freezed (^3.0.6)** - иммутабельные классы и pattern matching
- **json_serializable (^6.9.5)** - сериализация/десериализация JSON
- **build_runner (^2.4.8)** - запуск кодогенерации

```dart
// Запуск кодогенерации
// flutter pub run build_runner build --delete-conflicting-outputs
```

## Навигация и маршрутизация

- **go_router (^13.1.0)** - декларативная маршрутизация

```dart
// Пример навигации
context.goNamed('profile');
```

## Интеграция с Supabase

- **supabase_flutter (^2.3.4)** - Flutter клиент для Supabase
  - Аутентификация
  - База данных PostgreSQL
  - Realtime подписки

## UI/UX компоненты

- **flutter_svg (^2.0.9)** - отображение SVG
- **flutter_hooks (^0.20.3)** - React-подобные хуки
- **dropdown_textfield** — мультивыбор объектов в формах (EmployeeFormScreen)
- **ContractorFormContent** — форма создания/редактирования контрагента, реализует ограничения ширины и стиль, унифицированный с сотрудниками и объектами.
- **ContractorFormScreen** — stateful-обёртка для ContractorFormContent, управляет состоянием и сохранением.
- **ContractorsListScreen** — экран списка, поиска, добавления и редактирования контрагентов, модальные окна ограничены по ширине и центрированы на десктопе.

## Работа с данными

- **excel (^2.1.0)** - импорт/экспорт Excel файлов
- **csv (^5.1.1)** - работа с CSV форматом
- **file_picker (^6.1.1)** - выбор файлов

## Утилиты

- **flutter_dotenv (^5.1.0)** - переменные окружения
- **logger (^2.0.2+1)** - структурированное логирование
- **path_provider (^2.1.1)** - доступ к файловой системе

## Окружения и конфигурация

Переменные окружения загружаются из файла `.env` в корне проекта:
```
SUPABASE_URL=https://ваш-проект.supabase.co
SUPABASE_ANON_KEY=ваш-анонимный-ключ
ENV=dev
```

## Система сборки

Настройки сборки для кодогенерации определены в `build.yaml`:
```yaml
targets:
  $default:
    builders:
      freezed:
        generate_for:
          include:
            - lib/domain/entities/**.dart
            - lib/data/models/**.dart
      json_serializable:
        generate_for:
          include:
            - lib/data/models/**.dart
        options:
          explicit_to_json: true
```

- Для сотрудников реализована поддержка загрузки и хранения фото через Supabase Storage (см. PhotoService, bucket 'avatars/employees/'). 