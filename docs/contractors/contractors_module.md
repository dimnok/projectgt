# Модуль Contractors (Контрагенты)

---

## Детальное описание модуля

Модуль **Contractors** отвечает за управление контрагентами (заказчики, подрядчики, поставщики): создание, просмотр, редактирование, удаление, поиск и фильтрация. Используется для хранения юридических лиц и ИП, участвующих в проектах, с поддержкой всех необходимых реквизитов и контактов. Реализован по принципам Clean Architecture с разделением на data/domain/presentation/features, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение списка контрагентов (мастер-детейл, поиск, фильтрация)
- Создание нового контрагента
- Редактирование существующего контрагента
- Удаление контрагента
- Просмотр деталей контрагента (контакты, реквизиты, адреса)
- Адаптивный UI (desktop/mobile)
- Валидация и обработка ошибок
- Интеграция с Supabase (таблица contractors)
- Загрузка/удаление логотипа через Supabase Storage

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
- `lib/features/contractors/presentation/screens/contractors_list_screen.dart` — Экран списка контрагентов: мастер-детейл, поиск, фильтрация, детали, модальные окна.
- `lib/features/contractors/presentation/screens/contractor_details_screen.dart` — Экран подробной информации о контрагенте.
- `lib/features/contractors/presentation/screens/contractor_form_screen.dart` — Экран формы создания/редактирования контрагента: валидация, адаптивность, обработка ошибок.
- `lib/presentation/state/contractor_state.dart` — StateNotifier и состояние контрагентов: хранит список, выбранного контрагента, статусы загрузки, ошибки. Управляет логикой загрузки/обновления/удаления.

### Domain (бизнес-логика)
- `lib/domain/entities/contractor.dart` — Доменная сущность контрагента (Freezed), отражает структуру таблицы contractors.
- `lib/domain/repositories/contractor_repository.dart` — Абстракция репозитория для DI и тестирования.
- `lib/domain/usecases/contractor/get_contractors_usecase.dart` — UseCase для получения списка контрагентов.
- `lib/domain/usecases/contractor/get_contractor_usecase.dart` — UseCase для получения одного контрагента по id.
- `lib/domain/usecases/contractor/create_contractor_usecase.dart` — UseCase для создания контрагента.
- `lib/domain/usecases/contractor/update_contractor_usecase.dart` — UseCase для обновления контрагента.
- `lib/domain/usecases/contractor/delete_contractor_usecase.dart` — UseCase для удаления контрагента.

### Data (работа с БД/Supabase)
- `lib/data/models/contractor_model.dart` — Data-модель контрагента для сериализации/десериализации, преобразование в доменную модель.
- `lib/data/models/contractor_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/data/models/contractor_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/data/datasources/contractor_data_source.dart` — Абстракция и реализация источника данных для контрагентов (Supabase).
- `lib/data/repositories/contractor_repository_impl.dart` — Имплементация репозитория: преобразует модели, делегирует data source.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, usecase, провайдер состояния.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── contractors/
│       └── presentation/
│           └── screens/
│               ├── contractors_list_screen.dart
│               ├── contractor_details_screen.dart
│               └── contractor_form_screen.dart
├── presentation/
│   └── state/
│       └── contractor_state.dart
├── domain/
│   ├── entities/
│   │   └── contractor.dart
│   ├── repositories/
│   │   └── contractor_repository.dart
│   └── usecases/
│       └── contractor/
│           ├── get_contractors_usecase.dart
│           ├── get_contractor_usecase.dart
│           ├── create_contractor_usecase.dart
│           ├── update_contractor_usecase.dart
│           └── delete_contractor_usecase.dart
├── data/
│   ├── models/
│   │   ├── contractor_model.dart
│   │   ├── contractor_model.g.dart
│   │   └── contractor_model.freezed.dart
│   ├── datasources/
│   │   └── contractor_data_source.dart
│   └── repositories/
│       └── contractor_repository_impl.dart
└── core/
    └── di/
        └── providers.dart
```

---

## Связи и интеграции
- **Supabase:** таблица contractors, связь с договорами (contracts), объекты (objects)
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Валидация:** все формы используют встроенную валидацию и обработку ошибок
- **Доступность:** поддержка Semantics, адаптивность, alt text

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблицы `contractors`

| Колонка         | Тип         | Описание                                                        |
|-----------------|-------------|-----------------------------------------------------------------|
| id              | UUID, PK    | Уникальный идентификатор контрагента                            |
| logo_url        | TEXT        | URL логотипа                                                    |
| full_name       | TEXT        | Полное наименование                                             |
| short_name      | TEXT        | Сокращённое наименование                                        |
| inn             | TEXT        | ИНН организации                                                 |
| director        | TEXT        | ФИО директора                                                   |
| legal_address   | TEXT        | Юридический адрес                                               |
| actual_address  | TEXT        | Фактический адрес                                               |
| phone           | TEXT        | Телефон                                                         |
| email           | TEXT        | Email                                                           |
| type            | TEXT        | Тип контрагента (`customer`, `contractor`, `supplier`)          |
| created_at      | TIMESTAMP   | Дата и время создания записи                                    |
| updated_at      | TIMESTAMP   | Дата и время последнего обновления записи                       |

**Связи:**
- id → contracts.contractor_id (FK)
- id → другие таблицы (например, payments, works)

**RLS-политики:**
- Любой аутентифицированный пользователь (auth.role() = 'authenticated') может читать, создавать, обновлять и удалять записи в таблице contractors. 