# Модуль Objects (Объекты)

---

## Детальное описание модуля

Модуль **Objects** отвечает за управление строительными и эксплуатационными объектами в системе: создание, просмотр, редактирование, удаление. Используется для привязки сотрудников, начисления командировочных выплат, фильтрации и поиска по объектам. Реализован по принципам Clean Architecture с разделением на data/domain/presentation/features, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение списка объектов
- Создание нового объекта
- Редактирование существующего объекта
- Удаление объекта
- Поиск и фильтрация по наименованию и адресу
- Адаптивный мастер-детейл UI (desktop/mobile)
- Валидация и обработка ошибок
- Интеграция с Supabase (таблица objects)

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation/features
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- Иммутабельные модели, строгая типизация
- Вся работа с БД — через Supabase DataSource

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/objects/presentation/screens/objects_list_screen.dart` — Экран списка объектов: мастер-детейл, поиск, фильтрация, детали, модальные окна.
- `lib/features/objects/presentation/screens/object_form_screen.dart` — Экран формы создания/редактирования объекта: валидация, адаптивность, обработка ошибок.
- `lib/presentation/state/object_state.dart` — StateNotifier и состояние объектов: хранит список объектов, статусы загрузки, ошибки. Управляет логикой загрузки/обновления/удаления.

### Domain (бизнес-логика)
- `lib/domain/entities/object.dart` — Доменная сущность объекта (Freezed), отражает структуру таблицы objects.
- `lib/domain/repositories/object_repository.dart` — Абстракция репозитория для DI и тестирования.
- `lib/domain/usecases/object/get_objects_usecase.dart` — UseCase для получения списка объектов.
- `lib/domain/usecases/object/create_object_usecase.dart` — UseCase для создания объекта.
- `lib/domain/usecases/object/update_object_usecase.dart` — UseCase для обновления объекта.
- `lib/domain/usecases/object/delete_object_usecase.dart` — UseCase для удаления объекта.

### Data (работа с БД/Supabase)
- `lib/data/models/object_model.dart` — Data-модель объекта для сериализации/десериализации, преобразование в доменную модель.
- `lib/data/models/object_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/data/models/object_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/data/datasources/object_data_source.dart` — Абстракция и реализация источника данных для объектов (Supabase).
- `lib/data/repositories/object_repository_impl.dart` — Имплементация репозитория: преобразует модели, делегирует data source.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, usecase, провайдер состояния.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── objects/
│       └── presentation/
│           └── screens/
│               ├── objects_list_screen.dart
│               └── object_form_screen.dart
├── presentation/
│   └── state/
│       └── object_state.dart
├── domain/
│   ├── entities/
│   │   └── object.dart
│   ├── repositories/
│   │   └── object_repository.dart
│   └── usecases/
│       └── object/
│           ├── get_objects_usecase.dart
│           ├── create_object_usecase.dart
│           ├── update_object_usecase.dart
│           └── delete_object_usecase.dart
├── data/
│   ├── models/
│   │   ├── object_model.dart
│   │   ├── object_model.g.dart
│   │   └── object_model.freezed.dart
│   ├── datasources/
│   │   └── object_data_source.dart
│   └── repositories/
│       └── object_repository_impl.dart
└── core/
    └── di/
        └── providers.dart
```

---

## Связи и интеграции
- **Supabase:** таблица objects, связь с другими модулями (например, профили сотрудников, смены, выплаты)
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Валидация:** все формы используют встроенную валидацию и обработку ошибок
- **Доступность:** поддержка Semantics, адаптивность, alt text

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблицы `objects`

| Колонка               | Тип         | Описание                                              |
|-----------------------|-------------|-------------------------------------------------------|
| id                    | UUID, PK    | Уникальный идентификатор объекта                      |
| name                  | TEXT        | Наименование объекта                                  |
| address               | TEXT        | Адрес объекта                                         |
| description           | TEXT        | Описание объекта (опционально)                        |
| business_trip_amount  | NUMERIC     | Сумма командировочных выплат для объекта (по умолч. 0)|
| created_at            | TIMESTAMP   | Дата и время создания записи (UTC)                    |
| updated_at            | TIMESTAMP   | Дата и время последнего обновления записи (UTC)       |

**Связи:**
- id → другие таблицы (например, profiles.object_ids, works.object_id)

**RLS-политики:**
- Только авторизованные пользователи могут просматривать и изменять объекты

--- 