# ProjectGT

Flutter-приложение с Clean Architecture и Supabase.

## Архитектура

Проект организован по принципам Clean Architecture:

- **Domain**: бизнес-сущности, репозитории и use cases
- **Data**: реализация репозиториев и источников данных
- **Presentation**: UI компоненты и состояния

## Используемые технологии

- **Flutter** и **Dart**
- **Riverpod** - управление состоянием
- **Go Router** - декларативная маршрутизация 
- **Freezed** - иммутабельные модели
- **Supabase** - бэкенд как сервис
- **Flutter Dotenv** - переменные окружения

## Инструкции по настройке

### 1. Запуск кодогенерации

Для генерации Freezed и JSON моделей выполните:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Заполнение файла .env

Отредактируйте файл `.env` и укажите реальные данные подключения к Supabase:

```
SUPABASE_URL=https://ваш-суббаза-url.supabase.co
SUPABASE_ANON_KEY=ваш-анонимный-ключ-доступа
```

### 3. Запуск приложения

После этого приложение можно запустить:

```bash
flutter run
```

## Генерация документации по Dart/Flutter

Для генерации актуальной документации по моделям и API выполните:

```sh
./tools/generate_docs.sh
```

Документация появится в папке `docs/api/` (откройте index.html в браузере).

## Известные проблемы

Ошибки в файлах `lib/features/home/presentation/screens/home_screen.dart` и `lib/features/profile/presentation/screens/profile_screen.dart` связаны с тем, что методы Freezed сущности User ещё не сгенерированы. После запуска build_runner эти ошибки исчезнут.

## Структура проекта

```
lib/
├── core/
│   ├── common/ - общие компоненты
│   ├── di/ - dependency injection
│   └── utils/ - утилиты
├── data/
│   ├── datasources/ - источники данных
│   ├── models/ - модели данных
│   └── repositories/ - реализации репозиториев
├── domain/
│   ├── entities/ - бизнес-сущности
│   ├── repositories/ - интерфейсы репозиториев
│   └── usecases/ - бизнес-правила
├── features/
│   ├── auth/ - аутентификация
│   ├── home/ - главный экран
│   └── profile/ - профиль пользователя
└── presentation/
    ├── state/ - управление состоянием
    ├── theme/ - тема приложения
    └── widgets/ - общие виджеты
```
