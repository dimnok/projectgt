# Модуль Employees (Сотрудники)

**Дата актуализации:** 11 апреля 2026 года

**Изменения в этой версии:**
- задокументированы **две поверхности списка**: таблица на широких экранах и **мобильный** `EmployeesListMobileScreen` при узкой стороне окна ([`EmployeesLayoutUtils`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart))
- обновлён раздел **Presentation**: карточки, свайпы, bottom sheet деталей/редактирования, аватар ([`EmployeeAvatarController`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart), [`PhotoService`](../../lib/core/services/photo_service.dart))
- **Навигация и RBAC**: маршрут `/employees`, детали `/employees/:employeeId`, права модуля `employees` (`read`, `create`, `update`, `export`); просмотр «своей» карточки по `profiles` без права на весь справочник
- **База данных (audit по репозиторию)**: актуализированы имена RLS-политик из [`20251015_fix_rls_performance_auth_initplan.sql`](../../supabase/migrations/20251015_fix_rls_performance_auth_initplan.sql); убраны неподтверждённые имена политик и устаревшие оценки `pg_stat`; отмечено отсутствие `CREATE TABLE employee_rates` в текущем наборе миграций
- **Edge Function `export-employees`**: проверка доступа через `company_members` + JWT; фильтры как в UI
- **EmployeeNotifier**: параметр `includeResponsibilityMap`, сохранение `currentHourlyRate` при `updateEmployee`, удаление фото из Storage при `deleteEmployee`
- выравнивание с [`documentation.mdc`](../../.cursor/rules/documentation.mdc): заголовки слоёв, **RLS** в формате ✅, подразделы **Триггеры / Functions**, **Формулы и инварианты**, **Design System**, **Roadmap** с приоритетами багов

---

## Важное замечание

Модуль **владеет** (основной CRUD и бизнес-смысл) таблицами:

- `employees`
- `employee_rates`

Тесные связи:

- `profiles` — `employee_id`, `object_ids` (доступ и привязка пользователя к карточке)
- `objects` — `employees.object_ids`
- `work_hours`, `employee_attendance` — учёт часов
- `work_plan_blocks` — `responsible_id`, `worker_ids`
- `work_plans` — в т.ч. колонка `responsible_id` (FK на `employees`)
- таблицы **FOT** (`payroll_*`, функции расчёта) — чтение ставок и сотрудников

Особенности реализации:

- все запросы к PostgREST фильтруются по **`activeCompanyId`** в datasource
- поиск по ФИО / должности / телефону — **на клиенте** (`EmployeeState.filteredEmployees`)
- **текущая ставка** не хранится в строке `employees`: подгружается из `employee_rates`, где `valid_to IS NULL`, и кладётся в `Employee.currentHourlyRate` / `EmployeeModel.currentHourlyRate` (только на клиенте)
- флаг **`can_be_responsible`** хранится в БД в `employees`, в доменной модели [`Employee`](../../lib/domain/entities/employee.dart) **не** сериализуется; в UI используется кэш `EmployeeState.canBeResponsibleMap` и отдельные методы datasource
- **две раскладки списка**: `EmployeesTableScreen` (таблица) и `EmployeesListMobileScreen` (карточки) — выбор по [`EmployeesLayoutUtils.useEmployeesMobileList`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart) (`shortestSide` vs breakpoint планшета)

---

## Описание модуля

Модуль **Employees** закрывает жизненный цикл карточки сотрудника в компании: анкета, паспорт, трудоустройство, объекты, статус, история ставок, фото, флаг ответственного, участие в **Timesheet**, **Works**, **Work Plans**, **FOT**.

Ключевые функции:

- список сотрудников: **таблица** (desktop / широкий экран) или **мобильный** список с фильтром по статусу, поиском, свайп-действиями и bottom sheet
- создание / редактирование / удаление (права `employees:*`)
- история и текущая ставка (`employee_rates`)
- переключение **`can_be_responsible`**
- inline на таблице: **статус**, **объекты** (`object_ids`)
- экспорт XLSX на сервере (**Edge Function** + клиентский сервис)
- фото: загрузка / удаление / сохранение (платформенно) через **Storage** и `PhotoService`

Архитектура: Clean Architecture (`presentation` / `domain` / `data`), **Riverpod**, **Freezed**, **json_serializable**, транспорт **Supabase PostgREST**, мультитенантность по **`company_id`**.

---

## Зависимости

### Таблицы модуля (owner)

| Таблица          | Назначение                          |
|------------------|-------------------------------------|
| `employees`      | Карточка сотрудника                 |
| `employee_rates` | История почасовых ставок            |

### Таблицы и сущности, которые модуль использует

| Объект               | Использование                                      |
|----------------------|----------------------------------------------------|
| `objects`            | Имена объектов, фильтры, `object_ids`              |
| `profiles`           | Привязка `employee_id`, навигационные проверки     |
| `company_members`    | Проверка доступа к компании в `export-employees`   |
| `work_plan_blocks`   | `responsible_id`, `worker_ids`                     |
| `work_plans`         | `responsible_id`                                   |
| `work_hours`         | `employee_id` в сменах                             |
| `employee_attendance`| ручные часы табеля                                 |
| FOT / payroll        | расчёты, отчёты, балансы                           |

### Связанные модули приложения

- `objects`, `profile`, `works`, `work_plans`, `timesheet`, `fot`, `roles` (матрица прав), `company`

---

## Слой Presentation

### Экраны

| Файл | Назначение |
|------|------------|
| [`employees_table_screen.dart`](../../lib/features/employees/presentation/screens/employees_table_screen.dart) | Полноэкранная таблица: sticky header, поиск, фильтр статуса (счётчики), фильтр по объекту, multi-select, inline `status` / `object_ids`, детали в модалке, права `read` / `create` / `update` / `export` |
| [`employees_list_mobile_screen.dart`](../../lib/features/employees/presentation/screens/employees_list_mobile_screen.dart) | Мобильный список карточек, чипы статусов, bottom sheet объектов и деталей |
| [`employee_details_screen.dart`](../../lib/features/employees/presentation/screens/employee_details_screen.dart) | Маршрут по `employeeId`; общий UI с модалкой деталей |

### Утилиты и сервисы UI

| Файл | Назначение |
|------|------------|
| [`employees_layout_utils.dart`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart) | `useEmployeesMobileList`, `useEmployeesDesktopModal` (shortestSide + ширина) |
| [`employee_server_excel_export_service.dart`](../../lib/features/employees/presentation/services/employee_server_excel_export_service.dart) | Вызов `export-employees`, сохранение base64 XLSX (веб / десктоп / share) |
| [`employee_avatar_controller.dart`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart) | Загрузка / удаление аватара, сохранение в галерею на мобильных |

### Виджеты (основные)

| Файл | Назначение |
|------|------------|
| [`employees_table_actions_bar.dart`](../../lib/features/employees/presentation/widgets/employees_table_actions_bar.dart) | Панель действий таблицы |
| [`employees_table_filters_toolbar.dart`](../../lib/features/employees/presentation/widgets/employees_table_filters_toolbar.dart) | Фильтры; `EmployeesObjectTableFilterValue.toExportFilterJson()` для экспорта |
| [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) | Детальная карточка, действия, `can_be_responsible` |
| [`employee_edit_form.dart`](../../lib/features/employees/presentation/widgets/employee_edit_form.dart) | Форма редактирования |
| [`add_employee_simple_dialog.dart`](../../lib/features/employees/presentation/widgets/add_employee_simple_dialog.dart) | Быстрое добавление |
| [`add_employee_rate_dialog.dart`](../../lib/features/employees/presentation/widgets/add_employee_rate_dialog.dart) | Добавление ставки |
| [`employee_rate_summary_widget.dart`](../../lib/features/employees/presentation/widgets/employee_rate_summary_widget.dart) | Сводка по ставкам |
| [`employee_business_trip_summary_widget.dart`](../../lib/features/employees/presentation/widgets/employee_business_trip_summary_widget.dart) | Сводка по командировкам |
| [`employee_trip_editor_form.dart`](../../lib/features/employees/presentation/widgets/employee_trip_editor_form.dart) | Редактор поездок |
| [`form_widgets.dart`](../../lib/features/employees/presentation/widgets/form_widgets.dart) | Общие блоки формы |
| [`editable_inline_text_row.dart`](../../lib/features/employees/presentation/widgets/editable_inline_text_row.dart) | Inline-редактирование |
| [`employees_mobile_atmosphere.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_atmosphere.dart) | Визуальный фон мобильного списка |
| [`employees_mobile_search_field.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_search_field.dart) | Поиск на мобильном |
| [`employees_mobile_add_employee_button.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_add_employee_button.dart) | FAB / кнопка добавления |
| [`employees_mobile_employee_card.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_card.dart) | Карточка в списке |
| [`employees_mobile_swipeable_employee_card.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_swipeable_employee_card.dart) | Свайп по карточке |
| [`employees_mobile_employee_details_sheet.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart) | Bottom sheet деталей |
| [`employees_mobile_employee_edit_blocks.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_edit_blocks.dart) | Блоки редактирования на мобильном |

### Design System (`lib/core/widgets/`)

Модуль опирается на общие компоненты вместо «голого» Material там, где есть обёртки проекта:

| Виджет / API | Файл в core | Где используется в модуле (примеры) |
|--------------|-------------|-------------------------------------|
| `GTTextField` | [`gt_text_field.dart`](../../lib/core/widgets/gt_text_field.dart) | диалоги добавления/ставки, мобильные блоки редактирования, поиск |
| `GTDropdown` | [`gt_dropdown.dart`](../../lib/core/widgets/gt_dropdown.dart) | формы, редактор поездок, мобильные блоки |
| `GTPrimaryButton` / `GTSecondaryButton` / `GTTextButton` | [`gt_buttons.dart`](../../lib/core/widgets/gt_buttons.dart) | диалоги, bottom sheet, мобильный список |
| `DesktopDialogContent` | [`desktop_dialog_content.dart`](../../lib/core/widgets/desktop_dialog_content.dart) | детали, добавление сотрудника/ставки, формы на desktop |
| `MobileBottomSheetContent` | [`mobile_bottom_sheet_content.dart`](../../lib/core/widgets/mobile_bottom_sheet_content.dart) | те же сценарии на mobile / узкой ширине |
| `AppSnackBar` | [`app_snackbar.dart`](../../lib/core/widgets/app_snackbar.dart) | [`employees_list_mobile_screen.dart`](../../lib/features/employees/presentation/screens/employees_list_mobile_screen.dart) |
| `GTContextMenu` | [`gt_context_menu.dart`](../../lib/core/widgets/gt_context_menu.dart) | [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) |

Табличный экран построен на кастомной вёрстке (`Table` / `LayoutBuilder` и т.д.), без внешних grid-библиотек — в духе правил проекта (см. [`flutter.mdc`](../../.cursor/rules/flutter.mdc)).

### Навигация и меню

- Маршруты: `AppRoutes.employees = '/employees'`, `employee_details` — `${AppRoutes.employees}/:employeeId` ([`app_router.dart`](../../lib/core/common/app_router.dart))
- Список: при `employees` + `read` показывается таблица или мобильный список в зависимости от [`EmployeesLayoutUtils`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart)
- Детали: доступ при `employees` + `read` **или** если `profiles` содержит тот же `employee_id`, что и маршрут
- [`AppDrawer`](../../lib/presentation/widgets/app_drawer.dart): пункт «Сотрудники» (без ограничения «только desktop», в отличие от части других модулей)

### Вспомогательный UI вне фичи

- [`employee_ui_utils.dart`](../../lib/core/utils/employee_ui_utils.dart) — общие подписи/статусы для списков и таблицы

---

## Слой Domain / Data

### Domain

| Файл | Содержимое |
|------|------------|
| [`employee.dart`](../../lib/domain/entities/employee.dart) | Сущность сотрудника, enum `EmploymentType`, `EmployeeStatus` (отдельно от `EmployeeState` в Riverpod) |
| [`employee_rate.dart`](../../lib/domain/entities/employee_rate.dart) | Сущность ставки с периодом |
| [`employee_repository.dart`](../../lib/domain/repositories/employee_repository.dart) | Контракт репозитория сотрудников |
| [`employee_rate_repository.dart`](../../lib/domain/repositories/employee_rate_repository.dart) | Контракт ставок |

### Use cases

| Каталог | Файлы |
|---------|--------|
| `lib/domain/usecases/employee/` | `get_employee`, `get_employees`, `create_employee`, `update_employee`, `delete_employee` |
| `lib/domain/usecases/employee_rate/` | `get_employee_rates`, `get_employee_rate_for_date`, `set_employee_rate` |

### Data

| Файл | Назначение |
|------|------------|
| [`employee_model.dart`](../../lib/data/models/employee_model.dart) | DTO `employees`; `current_hourly_rate` только на клиенте (`includeFromJson: false`) |
| [`employee_rate_model.dart`](../../lib/data/models/employee_rate_model.dart) | DTO `employee_rates` |
| [`employee_data_source.dart`](../../lib/data/datasources/employee_data_source.dart) | Supabase: CRUD, `getResponsibleEmployees`, `can_be_responsible`, пакетная мапа флага, обогащение текущей ставкой |
| [`employee_rate_data_source.dart`](../../lib/data/datasources/employee_rate_data_source.dart) | История ставок |
| [`employee_repository_impl.dart`](../../lib/data/repositories/employee_repository_impl.dart) | Маппинг модель ↔ сущность |
| [`employee_rate_repository_impl.dart`](../../lib/data/repositories/employee_rate_repository_impl.dart) | Репозиторий ставок |

### Состояние (Riverpod)

| Файл | Назначение |
|------|------------|
| [`employee_state.dart`](../../lib/presentation/state/employee_state.dart) | `EmployeeNotifier`: список, выбранный сотрудник, кэш деталей, `searchQuery`, `canBeResponsibleMap`, локальные обновления списка, `getEmployees(includeResponsibilityMap: ...)`, сохранение ставки при `updateEmployee`, **удаление фото** при `deleteEmployee` |

Провайдеры datasources / repositories / use cases: [`lib/core/di/providers.dart`](../../lib/core/di/providers.dart) (`employeeDataSourceProvider`, `employeeRateDataSourceProvider`, …).

### Фото (Storage)

[`PhotoService`](../../lib/core/services/photo_service.dart): `entity: 'employee'`, загрузка в bucket Supabase Storage, используется модулем и при удалении сотрудника.

---

## Дерево файлов

```text
lib/
├── core/
│   ├── di/providers.dart                    # провайдеры employees / employee_rates
│   ├── services/photo_service.dart          # фото сотрудника (entity: employee)
│   └── utils/employee_ui_utils.dart
├── data/
│   ├── datasources/
│   │   ├── employee_data_source.dart
│   │   └── employee_rate_data_source.dart
│   ├── models/
│   │   ├── employee_model.dart
│   │   └── employee_rate_model.dart
│   └── repositories/
│       ├── employee_repository_impl.dart
│       └── employee_rate_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── employee.dart
│   │   └── employee_rate.dart
│   ├── repositories/
│   │   ├── employee_repository.dart
│   │   └── employee_rate_repository.dart
│   └── usecases/
│       ├── employee/
│       └── employee_rate/
├── features/employees/
│   └── presentation/
│       ├── providers/
│       │   └── employee_avatar_controller.dart
│       ├── screens/
│       │   ├── employees_table_screen.dart
│       │   ├── employees_list_mobile_screen.dart
│       │   └── employee_details_screen.dart
│       ├── services/
│       │   └── employee_server_excel_export_service.dart
│       ├── utils/
│       │   └── employees_layout_utils.dart
│       └── widgets/
│           ├── add_employee_rate_dialog.dart
│           ├── add_employee_simple_dialog.dart
│           ├── editable_inline_text_row.dart
│           ├── employee_business_trip_summary_widget.dart
│           ├── employee_details_modal.dart
│           ├── employee_edit_form.dart
│           ├── employee_rate_summary_widget.dart
│           ├── employee_trip_editor_form.dart
│           ├── employees_mobile_*.dart
│           ├── employees_table_actions_bar.dart
│           ├── employees_table_filters_toolbar.dart
│           └── form_widgets.dart
└── presentation/
    └── state/
        └── employee_state.dart
```

---

## База данных (Audit по репозиторию)

> **Источник:** SQL-миграции в `supabase/migrations/` и DTO в `lib/data/models/`. Полный `CREATE TABLE` для `employee_rates` в отслеживаемых миграциях **не найден** (таблица используется в функциях ФОТ, экспорте и клиенте). Имена индексов ниже — только те, что явно фигурируют в миграциях.

### Таблица `employees`

**Назначение:** основная карточка сотрудника в разрезе компании.

**Колонки (по [`EmployeeModel`](../../lib/data/models/employee_model.dart) + колонка флага в БД, используемая datasource):**

| Колонка | Тип (логический) | Примечание |
|---------|------------------|------------|
| `id` | UUID | PK |
| `company_id` | UUID | обязателен в клиенте |
| `photo_url` | TEXT | |
| `last_name`, `first_name`, `middle_name` | TEXT | |
| `birth_date`, `birth_place` | TIMESTAMPTZ / TEXT | |
| `citizenship`, `phone` | TEXT | |
| `clothing_size`, `shoe_size`, `height` | TEXT | |
| `employment_date` | TIMESTAMPTZ | |
| `employment_type` | TEXT | default `official` |
| `position` | TEXT | |
| `status` | TEXT | default `working` |
| `object_ids` | TEXT[] | в приложении `List<String>` |
| `passport_*`, `registration_address`, `inn`, `snils` | TEXT / TIMESTAMPTZ | |
| `can_be_responsible` | BOOLEAN | в клиенте — через `canBeResponsibleMap`, не в JSON модели |
| `created_at`, `updated_at` | TIMESTAMPTZ | |

Ранняя миграция [`20240101000002_employees_migration.sql`](../../supabase/migrations/20240101000002_employees_migration.sql) содержит иные поля (`hourly_rate`, `facility`); **текущая** доменная модель их **не** использует — фактическая схема на деплое должна быть сверена с продакшеном (`pg_dump` / Supabase Studio).

**RLS:** ✅ Включён (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).

**Политики** (файл [`20251015_fix_rls_performance_auth_initplan.sql`](../../supabase/migrations/20251015_fix_rls_performance_auth_initplan.sql)):

| Имя | Операция | Суть |
|-----|----------|------|
| `Users can view employees` | SELECT | `auth.role() = 'authenticated'` |
| `Only admins can create employees` | INSERT | authenticated и `profiles.role = 'admin'` |
| `Only admins can update employees` | UPDATE | то же |
| `Only admins can delete employees` | DELETE | то же |

> **Замечание RBAC:** политики опираются на legacy-поле `profiles.role`. Матрица прав приложения ([`PermissionService`](../../lib/features/roles/application/permission_service.dart), ключ `employees`) задаёт UX, но **PostgREST** ограничен политиками выше.

**Индексы** (упоминания в миграциях):

- `employees_pkey` (подразумевается PK)
- `idx_employees_status`, `idx_employees_position` — из [`20240101000002_employees_migration.sql`](../../supabase/migrations/20240101000002_employees_migration.sql)
- `idx_employees_name` — **удалён** в [`20251015_optimize_indexes.sql`](../../supabase/migrations/20251015_optimize_indexes.sql)

#### Триггеры (`employees`)

В отслеживаемых миграциях репозитория **триггеров на таблице `public.employees` не объявлено**.

#### Функции (SQL), использующие `employees`

Таблица читается и джойнится вне модуля, в первую очередь в **FOT** и отчётах, например (имена из миграций; не исчерпывающий список):

- `calculate_employee_balances()` — баланс к выплате по сотрудникам
- функции расчёта зарплаты за месяц / срезы payroll (используют `employees`, `employee_rates`, `work_hours`, `employee_attendance`)
- `get_payroll_report_data` и связанные RPC в миграциях ФОТ
- `get_month_employees_summary` — агрегат по числу сотрудников в сменах за месяц

### Таблица `employee_rates`

**Назначение:** история ставок; «текущая» строка с `valid_to IS NULL`.

**Колонки (по [`EmployeeRateModel`](../../lib/data/models/employee_rate_model.dart)):**

| Колонка | Назначение |
|---------|------------|
| `id` | PK |
| `company_id` | компания |
| `employee_id` | сотрудник |
| `hourly_rate` | NUMERIC |
| `valid_from`, `valid_to` | период; `valid_to NULL` — действующая ставка |
| `created_at`, `created_by` | аудит |

**RLS:** ✅ Включён.

**Политики** ([`20251015_fix_rls_performance_auth_initplan.sql`](../../supabase/migrations/20251015_fix_rls_performance_auth_initplan.sql)):

| Имя | Операция | Суть |
|-----|----------|------|
| `Users can view employee rates` | SELECT | authenticated |
| `Only admins can modify employee rates` | ALL | authenticated + `profiles.role = 'admin'` |

**Индексы / изменения в миграциях:**

- [`20251015_optimize_indexes.sql`](../../supabase/migrations/20251015_optimize_indexes.sql): `CREATE INDEX IF NOT EXISTS idx_employee_rates_created_by ON employee_rates(created_by)`; удалены `idx_employee_rates_employee_id`, `idx_employee_rates_active`.

**Инвариант «одна активная ставка»:** в коде и экспорте используется фильтр `valid_to IS NULL`. Явный **partial unique** в отслеживаемых миграциях не найден — при необходимости жёсткой уникальности её стоит добавить отдельной миграцией на проде.

#### Триггеры (`employee_rates`)

В отслеживаемых миграциях репозитория **триггеров на таблице `public.employee_rates` не объявлено**.

#### Функции (SQL), использующие `employee_rates`

Те же зоны, что и для `employees`: расчёты ФОТ, балансы, отчёты по часам и ставкам (`calculate_employee_balances`, payroll-RPC, `get_payroll_report_data` и др. в `supabase/migrations/`).

### Связанные таблицы (кратко)

| Таблица | RLS в миграциях | Комментарий |
|---------|-----------------|-------------|
| `profiles` | да | `employee_id`, `object_ids` |
| `employee_attendance` | да | FK на `employees` — [`20251005000000_create_employee_attendance.sql`](../../supabase/migrations/20251005000000_create_employee_attendance.sql) |
| `work_hours` | да | `employee_id` |
| `work_plan_blocks` | да | `responsible_id`, `worker_ids`; индекс `idx_work_plan_blocks_responsible_id` в [`20251015_optimize_indexes.sql`](../../supabase/migrations/20251015_optimize_indexes.sql) |

### Storage

[`20240101000005_storage_policy_migration.sql`](../../supabase/migrations/20240101000005_storage_policy_migration.sql): политики для префикса bucket `employees/` (исторически под роль admin в storage).

---

## Бизнес-логика

### Формулы и инварианты

- **Текущая почасовая ставка в UI:** для сотрудника `e` выбираются строки `employee_rates` с `employee_id = e.id` и `valid_to IS NULL`; значение `hourly_rate` попадает в `Employee.currentHourlyRate` / `EmployeeModel.currentHourlyRate` (поле не колонка `employees` в API-модели).
- **Список ответственных по объекту** (`getResponsibleEmployees`): `status = 'working'` AND `can_be_responsible = true` AND `object_ids` содержит `objectId` (семантика «содержит» — как в PostgREST / клиентском фильтре).
- **Поиск в списке (client-side):** совпадение подстроки в нижнем регистре с конкатенацией ФИО, `position`, `phone` (`EmployeeState.filteredEmployees`).
- **Сохранение ставки при правке анкеты:** после `updateEmployee` в notifier выполняется `copyWith(currentHourlyRate: result.currentHourlyRate ?? employee.currentHourlyRate)`, чтобы не потерять ставку, не пришедшую из одного ответа `employees`.

Денежные расчёты начислений (часы × ставка за период, командировочные, премии) **не входят в модуль Employees** — см. модуль **FOT** и SQL-функции в миграциях.

1. После первого кадра экраны списка вызывают `employeeProvider.notifier.getEmployees()` и загрузку объектов (`objectProvider`).
2. `EmployeeNotifier.getEmployees()` не перезагружает список, если уже `success` и список не пуст; опционально догружает `canBeResponsibleMap` (`includeResponsibilityMap`).
3. `SupabaseEmployeeDataSource.getEmployees()` читает `employees` по `company_id`, затем одним запросом — текущие ставки (`employee_rates`, `valid_to IS NULL`) и обогащает `currentHourlyRate`.
4. Поиск: `EmployeeState.filteredEmployees` (ФИО, должность, телефон).
5. Таблица: дополнительно фильтр по статусу, объекту, сортировка по фамилии, счётчики по статусам — на клиенте.
6. Inline: `Employee.copyWith` + `updateEmployee` для `status` и `object_ids`.
7. `can_be_responsible`: отдельные вызовы datasource + обновление `canBeResponsibleMap` (не через полную перезагрузку карточки из одного JSON).
8. Ответственный по объекту для планов: `getResponsibleEmployees` — `status = working`, `can_be_responsible = true`, объект в `object_ids`.
9. При удалении сотрудника — удаление файла фото в Storage и строки в БД.
10. Экспорт: те же фильтры, что UI, плюс проверка членства в `company_members` на Edge.

---

## Интеграции

### UI / Router / RBAC

- [`app_router.dart`](../../lib/core/common/app_router.dart): `/employees`, детали, `_canViewEmployee` для «своей» карточки
- [`PermissionService`](../../lib/features/roles/application/permission_service.dart): `employees` → `read`, `create`, `update`, `export`

### Объекты

- `objectProvider` для имён и фильтров

### Works / Work Plans

- `work_hours.employee_id`
- `work_plan_blocks.responsible_id`, `worker_ids`
- `work_plans.responsible_id`

### Timesheet и FOT

- справочник сотрудников и ставок для табеля и расчётов (функции вроде `calculate_employee_balances`, `get_payroll_report_data` и др. в миграциях ФОТ)

### Edge Functions

| Функция | Назначение |
|---------|------------|
| **`export-employees`** | POST: `companyId`, `status`, `objectFilter`, `searchQuery`; **service role** + `ensureCompanyAccess` (JWT + `company_members`); ExcelJS; отдача base64 XLSX |

Клиент: [`EmployeeServerExcelExportService`](../../lib/features/employees/presentation/services/employee_server_excel_export_service.dart).

---

## Roadmap

### Реализовано

- Табличный и мобильный списки, адаптивный выбор раскладки
- Inline статус / объекты, фильтры, экспорт, аватар, детали и редактирование
- Кэш деталей, `canBeResponsibleMap`, сохранение ставки при обновлении анкеты
- Серверный Excel через `export-employees`

### Известные баги (приоритет)

| Приоритет | Описание |
|-----------|----------|
| 🟢 | Зарегистрированных багов, специфичных для модуля Employees, в документе не зафиксировано. |

При появлении регрессий строки выше заменяются конкретикой: 🔴 критичный, 🟡 средний, 🟢 низкий / косметика.

### Ограничения

- Поиск и фильтры списка без server-side pagination
- `object_ids` как `text[]` в БД
- RLS на `employees` / `employee_rates` завязан на `profiles.role`, не на матрицу `PermissionService`
- Схема `employee_rates` и часть индексов не воспроизводятся из одного `CREATE` в репозитории

### Возможные шаги

- Серверная пагинация и фильтрация PostgREST
- Выравнивание RLS с `company_members` + матрицей прав
- Явный partial unique index на «активную» ставку в миграции
- Audit trail изменений карточки и ставок
