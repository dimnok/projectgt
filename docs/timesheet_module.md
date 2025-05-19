# Модуль Timesheet (Табель рабочего времени)

---

## Важное замечание о структуре данных

> **Внимание:**
> Модуль "Табель" не имеет собственной таблицы в базе данных.
> Все данные для расчёта табеля агрегируются на лету из таблиц других модулей:
> - `work_hours` (модуль "Работы")
> - `works` (модуль "Работы")
> - `employees` (модуль "Сотрудники")
> - `objects` (модуль "Объекты")
>
> Таблица `work_hours` принадлежит модулю "Работы" и используется здесь только для аналитики и построения отчёта.

---

## Детальное описание модуля

Модуль **Timesheet** отвечает за учёт, отображение и анализ рабочих часов сотрудников по объектам и сменам. Позволяет фильтровать, группировать и агрегировать данные по различным срезам (сотрудник, объект, дата, должность). Интегрируется с модулями сотрудников, объектов и смен, реализован по принципам Clean Architecture с разделением на data/domain/presentation, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Просмотр и фильтрация часов сотрудников по периоду, объекту, должности
- Группировка данных по сотрудникам или по датам
- Агрегированная сводка по часам (по датам, по объектам, total)
- Адаптивный UI: календарь, таблица, фильтры
- Интеграция с Supabase (таблицы work_hours, works, employees, objects)
- Поддержка RLS и политик безопасности

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation/features
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Иммутабельные модели, строгая типизация
- Вся работа с БД — через Supabase DataSource
- Легко расширяется (экспорт, inline-редактирование, печать)

---

## Используемые таблицы и зависимости

Модуль **Timesheet** агрегирует данные из следующих таблиц (и модулей):
- **work_hours** — хранит отработанные часы (модуль "Работы")
- **works** — информация о сменах, датах, объектах (модуль "Работы")
- **employees** — справочник сотрудников (модуль "Сотрудники")
- **objects** — справочник объектов (модуль "Объекты")

> Модуль не владеет ни одной из этих таблиц, а только использует их для построения аналитики и отчётов.

---

## Структура и файлы модуля

### Presentation/UI

- `lib/features/timesheet/presentation/screens/timesheet_screen.dart` — Основной экран табеля: фильтры, календарь, обработка ошибок, загрузка.
- `lib/features/timesheet/presentation/widgets/timesheet_filter_widget.dart` — Виджет фильтрации: период, сотрудники, объекты, должности.
- `lib/features/timesheet/presentation/widgets/timesheet_calendar_view.dart` — Календарное представление табеля: дни, сотрудники, часы.
- `lib/features/timesheet/presentation/widgets/timesheet_table_widget.dart` — Табличное представление данных табеля (альтернативный вид).
- `lib/features/timesheet/presentation/providers/timesheet_provider.dart` — StateNotifier и состояние табеля: хранит записи, сводки, фильтры, ошибки, загрузку.
- `lib/features/timesheet/presentation/providers/repositories_providers.dart` — Провайдеры зависимостей: dataSource, repository, интеграция с core DI.

### Domain (бизнес-логика)

- `lib/features/timesheet/domain/entities/timesheet_entry.dart` — Доменная сущность записи табеля (Freezed), отражает структуру work_hours + enrich.
- `lib/features/timesheet/domain/entities/timesheet_summary.dart` — Доменная сущность агрегированной сводки по сотруднику (Freezed).
- `lib/features/timesheet/domain/repositories/timesheet_repository.dart` — Абстракция репозитория для DI и тестирования.

### Data (работа с БД/Supabase)

- `lib/features/timesheet/data/datasources/timesheet_data_source.dart` — Абстракция источника данных для табеля.
- `lib/features/timesheet/data/datasources/timesheet_data_source_impl.dart` — Реализация источника данных: Supabase, join с works, фильтрация.
- `lib/features/timesheet/data/repositories/timesheet_repository_impl.dart` — Имплементация репозитория: enrich данными сотрудников/объектов, агрегация.
- `lib/features/timesheet/data/models/timesheet_entry_model.dart` — Data-модель записи табеля для сериализации/десериализации.
- `lib/features/timesheet/data/models/timesheet_summary_model.dart` — Data-модель сводки по сотруднику для сериализации/десериализации.
- `lib/features/timesheet/data/models/timesheet_entry_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/features/timesheet/data/models/timesheet_entry_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/features/timesheet/data/models/timesheet_summary_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/features/timesheet/data/models/timesheet_summary_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).

### Документация

- `lib/features/timesheet/README.md` — Описание модуля, архитектуры, сущностей, особенностей реализации.

---

## Дерево структуры модуля

```
lib/
└── features/
    └── timesheet/
        ├── README.md
        ├── data/
        │   ├── datasources/
        │   │   ├── timesheet_data_source.dart
        │   │   └── timesheet_data_source_impl.dart
        │   ├── models/
        │   │   ├── timesheet_entry_model.dart
        │   │   ├── timesheet_entry_model.g.dart
        │   │   ├── timesheet_entry_model.freezed.dart
        │   │   ├── timesheet_summary_model.dart
        │   │   ├── timesheet_summary_model.g.dart
        │   │   └── timesheet_summary_model.freezed.dart
        │   └── repositories/
        │       └── timesheet_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── timesheet_entry.dart
        │   │   ├── timesheet_entry.g.dart
        │   │   ├── timesheet_entry.freezed.dart
        │   │   ├── timesheet_summary.dart
        │   │   ├── timesheet_summary.g.dart
        │   │   └── timesheet_summary.freezed.dart
        │   └── repositories/
        │       └── timesheet_repository.dart
        └── presentation/
            ├── screens/
            │   └── timesheet_screen.dart
            ├── widgets/
            │   ├── timesheet_filter_widget.dart
            │   ├── timesheet_calendar_view.dart
            │   └── timesheet_table_widget.dart
            └── providers/
                ├── timesheet_provider.dart
                └── repositories_providers.dart
```

---

## Связи и интеграции

- **Supabase:** таблицы work_hours (основная, модуль "Работы"), works (даты, объекты, модуль "Работы"), employees, objects (enrich).
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router).
- **Фильтрация:** по периоду, сотрудникам, объектам, должностям.
- **RLS:** поддержка политик безопасности на уровне БД.
- **Интеграция:** тесная связь с модулями Employees, Objects, Works.

---

## Примечания

- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.
- Возможности для расширения: экспорт, печать, inline-редактирование, оптимизация фильтрации на сервере.

---

## Структура таблицы `work_hours` (используется модулем "Работы")

> **Примечание:**
> Таблица `work_hours` принадлежит модулю "Работы" и используется в модуле "Табель" только для аналитики и построения отчёта. Модуль timesheet не владеет этой таблицей и не изменяет её структуру.

| Колонка      | Тип         | Описание                                                        |
|--------------|-------------|-----------------------------------------------------------------|
| id           | UUID, PK    | Уникальный идентификатор записи                                 |
| work_id      | UUID, FK    | Ссылка на смену (works.id)                                      |
| employee_id  | UUID, FK    | Ссылка на сотрудника (employees.id)                             |
| hours        | NUMERIC     | Количество отработанных часов                                   |
| comment      | TEXT        | Комментарий (опционально)                                       |
| created_at   | TIMESTAMP   | Дата и время создания записи (UTC)                              |
| updated_at   | TIMESTAMP   | Дата и время последнего обновления записи (UTC)                 |

**Связи:**
- work_id → works.id (FK)
- employee_id → employees.id (FK)
- Через works.object_id → objects.id (FK)

**RLS-политики:**
- Только авторизованные пользователи могут просматривать и изменять work_hours (через модуль "Работы")

--- 