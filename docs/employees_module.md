# Модуль Employees (Сотрудники)

---

## Детальное описание модуля

Модуль **Employees** отвечает за управление сотрудниками компании: создание, просмотр, редактирование, удаление, фильтрация, поиск, а также интеграцию с объектами и ролями. Используется для кадрового учёта, распределения по объектам, расчёта ставок и статусов. Реализован по принципам Clean Architecture с разделением на data/domain/presentation/features, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение списка сотрудников
- Создание, редактирование, удаление сотрудника
- Просмотр детальной информации о сотруднике
- Поиск и фильтрация по ФИО, должности, телефону
- Привязка сотрудников к объектам
- Управление статусами (работает, отпуск, уволен и др.)
- Адаптивный мастер-детейл UI (desktop/mobile)
- Валидация и обработка ошибок
- Интеграция с Supabase (таблица employees, RLS)

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation/features
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- Иммутабельные модели, строгая типизация
- Вся работа с БД — через Supabase DataSource
- RLS и безопасность на уровне БД

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/employees/presentation/screens/employees_list_screen.dart` — Экран списка сотрудников: мастер-детейл, поиск, фильтрация, детали, модальные окна.
- `lib/features/employees/presentation/screens/employee_form_screen.dart` — Экран формы создания/редактирования сотрудника: валидация, адаптивность, обработка ошибок.
- `lib/features/employees/presentation/screens/employee_details_screen.dart` — Экран детальной информации о сотруднике.
- `lib/features/employees/presentation/widgets/employee_card.dart` — Виджет карточки сотрудника для списка.
- `lib/features/employees/presentation/widgets/search_field.dart` — Виджет поиска по сотрудникам.
- `lib/features/employees/presentation/widgets/master_detail_layout.dart` — Виджет мастер-детейл layout для desktop.
- `lib/features/employees/presentation/widgets/form_widgets.dart` — Вспомогательные виджеты для форм сотрудников.
- `lib/presentation/state/employee_state.dart` — StateNotifier и состояние сотрудников: хранит список, выбранного сотрудника, статусы загрузки, ошибки, поисковый запрос.

### Domain (бизнес-логика)
- `lib/domain/entities/employee.dart` — Доменная сущность сотрудника (Freezed), отражает структуру таблицы employees.
- `lib/domain/repositories/employee_repository.dart` — Абстракция репозитория для DI и тестирования.
- `lib/domain/usecases/employee/get_employee_usecase.dart` — UseCase для получения сотрудника по id.
- `lib/domain/usecases/employee/get_employees_usecase.dart` — UseCase для получения списка сотрудников.
- `lib/domain/usecases/employee/create_employee_usecase.dart` — UseCase для создания сотрудника.
- `lib/domain/usecases/employee/update_employee_usecase.dart` — UseCase для обновления сотрудника.
- `lib/domain/usecases/employee/delete_employee_usecase.dart` — UseCase для удаления сотрудника.

### Data (работа с БД/Supabase)
- `lib/data/models/employee_model.dart` — Data-модель сотрудника для сериализации/десериализации, преобразование в доменную модель.
- `lib/data/models/employee_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/data/models/employee_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/data/datasources/employee_data_source.dart` — Абстракция и реализация источника данных для сотрудников (Supabase).
- `lib/data/repositories/employee_repository_impl.dart` — Имплементация репозитория: преобразует модели, делегирует data source.
- `lib/data/migrations/employees_migration.sql` — SQL-миграция для создания и настройки таблицы сотрудников, RLS, индексы.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, usecase, провайдер состояния.

### Utils
- `lib/core/utils/employee_ui_utils.dart` — Вспомогательные утилиты для отображения статусов, типов занятости и др.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── employees/
│       └── presentation/
│           ├── screens/
│           │   ├── employees_list_screen.dart
│           │   ├── employee_form_screen.dart
│           │   └── employee_details_screen.dart
│           └── widgets/
│               ├── employee_card.dart
│               ├── search_field.dart
│               ├── master_detail_layout.dart
│               └── form_widgets.dart
├── presentation/
│   └── state/
│       └── employee_state.dart
├── domain/
│   ├── entities/
│   │   └── employee.dart
│   ├── repositories/
│   │   └── employee_repository.dart
│   └── usecases/
│       └── employee/
│           ├── get_employee_usecase.dart
│           ├── get_employees_usecase.dart
│           ├── create_employee_usecase.dart
│           ├── update_employee_usecase.dart
│           └── delete_employee_usecase.dart
├── data/
│   ├── models/
│   │   ├── employee_model.dart
│   │   ├── employee_model.g.dart
│   │   └── employee_model.freezed.dart
│   ├── datasources/
│   │   └── employee_data_source.dart
│   ├── repositories/
│   │   └── employee_repository_impl.dart
│   └── migrations/
│       └── employees_migration.sql
├── core/
│   ├── di/
│   │   └── providers.dart
│   └── utils/
│       └── employee_ui_utils.dart
```

---

## Связи и интеграции
- **Supabase:** таблица employees, связь с объектами (object_ids), интеграция с профилями и ролями
- **RLS:** любой аутентифицированный пользователь может просматривать сотрудников, только admin может создавать, изменять и удалять
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Валидация:** все формы используют встроенную валидацию и обработку ошибок
- **Доступность:** поддержка Semantics, адаптивность, alt text

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблицы `employees`

| Колонка                | Тип                   | Описание                                              |
|------------------------|----------------------|-------------------------------------------------------|
| id                     | UUID, PK             | Уникальный идентификатор сотрудника                   |
| photo_url              | TEXT                 | URL фотографии сотрудника                             |
| last_name              | TEXT                 | Фамилия                                               |
| first_name             | TEXT                 | Имя                                                   |
| middle_name            | TEXT                 | Отчество                                              |
| birth_date             | TIMESTAMPTZ          | Дата рождения                                         |
| birth_place            | TEXT                 | Место рождения                                        |
| citizenship            | TEXT                 | Гражданство                                           |
| phone                  | TEXT                 | Телефон                                               |
| clothing_size          | TEXT                 | Размер одежды                                         |
| shoe_size              | TEXT                 | Размер обуви                                          |
| height                 | TEXT                 | Рост                                                  |
| employment_date        | TIMESTAMPTZ          | Дата приёма на работу                                 |
| employment_type        | TEXT                 | Тип занятости (`official`, `contract`)                |
| position               | TEXT                 | Должность                                             |
| hourly_rate            | NUMERIC              | Почасовая ставка                                      |
| status                 | TEXT                 | Статус сотрудника (`working`, `dismissed`)            |
| passport_series        | TEXT                 | Серия паспорта                                        |
| passport_number        | TEXT                 | Номер паспорта                                        |
| passport_issued_by     | TEXT                 | Кем выдан паспорт                                     |
| passport_issue_date    | TIMESTAMPTZ          | Дата выдачи паспорта                                  |
| passport_department_code| TEXT                | Код подразделения                                     |
| registration_address   | TEXT                 | Адрес регистрации                                     |
| inn                    | TEXT                 | ИНН                                                   |
| snils                  | TEXT                 | СНИЛС                                                 |
| created_at             | TIMESTAMPTZ          | Дата и время создания записи (UTC)                    |
| updated_at             | TIMESTAMPTZ          | Дата и время последнего обновления записи (UTC)       |
| object_ids             | ARRAY(TEXT)          | Список id объектов, связанных с сотрудником            |

**RLS-политики:**
- Любой аутентифицированный пользователь может просматривать сотрудников
- Только пользователи с ролью `admin` могут создавать, изменять и удалять сотрудников
- Индексы: по ФИО, статусу, должности

--- 