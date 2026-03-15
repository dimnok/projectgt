# Модуль Employees (Сотрудники)

**Дата актуализации:** 14 марта 2026 года

**Изменения в этой версии:**
- подтвержден новый альтернативный экран `employees_table_screen.dart` с полноэкранной таблицей
- добавлены inline-действия: смена `status` и `object_ids` прямо из таблицы
- подтвержден новый маршрут `/employees-table` и пункт меню `Сотрудники (Таблица)` в `AppDrawer`
- **внедрена система разрешений для `employees_table` (read, create, update, export, import)**
- **добавлен новый модуль `employees_table` в таблицу `app_modules` и матрицу прав `PermissionsMatrix`**
- **экран `EmployeesTableScreen` теперь учитывает права доступа через `PermissionService`**
- актуализирован audit по таблицам `employees`, `employee_rates`, связанным RLS-политикам, индексам и триггерам
- зафиксировано текущее поведение `EmployeeNotifier`: локальный кэш деталей, client-side поиск и кэш `canBeResponsibleMap`
- **исправлена ошибка исчезновения ставки при обновлении объектов/статуса сотрудника в `EmployeeNotifier`**

---

## Важное замечание

Модуль `Employees` владеет двумя основными таблицами:
- `employees`
- `employee_rates`

Дополнительно модуль тесно связан с:
- `profiles` — привязка пользователя к карточке сотрудника через `profiles.employee_id`
- `objects` — связи сотрудника с объектами через `employees.object_ids`
- `work_plan_blocks` — использование сотрудников как `responsible_id` и `worker_ids`
- `work_hours` и `employee_attendance` — использование сотрудников в учёте часов и табеле

Ключевые особенности текущей реализации:
- все основные запросы к сотрудникам жёстко ограничены `activeCompanyIdProvider`
- поиск, фильтрация по строке и сортировка выполняются на клиенте в `EmployeeState.filteredEmployees`
- текущая ставка сотрудника не хранится в `employees`, а догружается из `employee_rates` по записи с `valid_to IS NULL`
- для флага `can_be_responsible` используется отдельный кэш `canBeResponsibleMap`
- табличный экран пока существует как альтернативный view, не заменяя legacy master-detail экран

---

## Описание модуля

Модуль `Employees` отвечает за полный жизненный цикл сотрудника внутри компании: анкетные данные, паспортные реквизиты, трудоустройство, назначение на объекты, текущий статус, ставки, привязку к профилю пользователя и участие в смежных модулях (`Timesheet`, `Works`, `Work Plans`, `FOT`).

Ключевые функции:
- просмотр списка сотрудников в master-detail режиме
- просмотр списка сотрудников в полноэкранной таблице
- создание и редактирование карточки сотрудника
- ведение истории ставок через `employee_rates`
- переключение флага `can_be_responsible`
- inline-редактирование `status` и `object_ids` в табличном view
- отображение связанных объектов, ставок и командировок в деталях сотрудника

Архитектурные особенности:
- Clean Architecture: `presentation` / `domain` / `data`
- состояние через `Riverpod`
- immutable-сущности через `Freezed`
- DTO-маппинг через `json_serializable`
- Supabase PostgREST как транспорт к БД
- Multi-tenancy через `company_id`

---

## Зависимости

### Основные таблицы модуля
- `employees`
- `employee_rates`

### Таблицы, которые модуль использует
- `objects`
- `profiles`
- `work_plan_blocks`
- `work_plans`
- `work_hours`
- `employee_attendance`
- payroll-таблицы модуля `FOT`

### Связанные модули
- `objects`
- `profile`
- `works`
- `work_plans`
- `timesheet`
- `fot`
- `roles` (матрица прав `employees_table`)
- `company`

---

## Presentation

- `lib/features/employees/presentation/screens/employees_list_screen.dart`
  Legacy экран списка сотрудников в формате master-detail. Поддерживает поиск, статистику, действия над выбранным сотрудником и адаптивное поведение для desktop/mobile.

- `lib/features/employees/presentation/screens/employees_table_screen.dart`
  Новый полноэкранный табличный view сотрудников. Поддерживает:
  - sticky header
  - поиск
  - статусные фильтры с counters
  - multi-select через checkbox
  - inline-изменение `status`
  - inline-изменение `object_ids`
  - подсветку активной строки при открытом popup menu
  - быстрые локальные обновления без полной перезагрузки списка
  - **разграничение прав доступа (read, create, update, export)** через `PermissionService`

- `lib/features/employees/presentation/screens/employee_details_screen.dart`
  Детальный экран сотрудника. Использует `employeeProvider`, показывает статус, тип трудоустройства, связанные объекты, summary по ставкам и командировкам, а также action buttons для edit/delete и toggle `can_be_responsible`.

- `lib/features/employees/presentation/screens/employee_form_screen.dart`
  Форма создания/редактирования сотрудника. Содержит персональные данные, паспортные поля, трудовые параметры, выбор объектов, тип трудоустройства, статус и загрузку фотографии. Текущая ставка загружается отдельно через `employeeRateDataSourceProvider`.

- `lib/features/employees/presentation/widgets/employee_card.dart`
  Карточка сотрудника для legacy-списка.

- `lib/features/employees/presentation/widgets/employee_statistics_modal.dart`
  Модальное окно со сводной статистикой по сотрудникам.

- `lib/features/employees/presentation/widgets/employee_rate_summary_widget.dart`
  Summary по ставкам сотрудника.

- `lib/features/employees/presentation/widgets/employee_business_trip_summary_widget.dart`
  Summary по командировкам сотрудника.

- `lib/features/employees/presentation/widgets/employee_trip_editor_form.dart`
  Редактор блока поездок/командировок в контексте деталей сотрудника.

- `lib/features/employees/presentation/widgets/form_widgets.dart`
  Переиспользуемые building blocks для формы сотрудника.

- `lib/features/employees/presentation/widgets/master_detail_layout.dart`
  Layout-обвязка для desktop master-detail view.

- `lib/features/employees/presentation/widgets/search_field.dart`
  Вспомогательный поисковый виджет legacy-экрана.

Дополнительно подтверждено:
- маршрут `AppRoutes.employeesTable = '/employees-table'`
- `GoRoute(name: 'employees_table')`
- пункт в `AppDrawer`: `Сотрудники (Таблица)`

---

## Domain / Data

### Domain

- `lib/domain/entities/employee.dart`
  Основная доменная сущность сотрудника. Содержит:
  - ФИО
  - персональные и паспортные данные
  - `employmentType`
  - `status`
  - `objectIds`
  - `currentHourlyRate`
  - helper `fullName`

- `lib/domain/entities/employee_rate.dart`
  Доменная сущность ставки сотрудника с периодом действия. Поддерживает `isCurrent`, `isActiveOn()` и `periodText`.

- `lib/domain/repositories/employee_repository.dart`
  Контракт CRUD для сотрудников + получение уникальных должностей.

- `lib/domain/repositories/employee_rate_repository.dart`
  Контракт истории ставок.

### Data

- `lib/data/models/employee_model.dart`
  DTO-модель `employees` с `fieldRename: FieldRename.snake`. Поле `currentHourlyRate` не сериализуется напрямую и используется только как enrichment на клиенте.

- `lib/data/models/employee_rate_model.dart`
  DTO-модель ставок.

- `lib/data/datasources/employee_data_source.dart`
  Основной Supabase datasource. Подтвержденные особенности:
  - все CRUD-запросы фильтруются по `company_id`
  - `getEmployees()` сначала грузит сотрудников, затем одним дополнительным запросом подтягивает текущие ставки из `employee_rates`
  - `getResponsibleEmployees(objectId)` фильтрует по `status = 'working'`, `can_be_responsible = true` и `object_ids contains objectId`
  - есть отдельные методы `getCanBeResponsible`, `setCanBeResponsible`, `getCanBeResponsibleMap`

- `lib/data/repositories/employee_repository_impl.dart`
  Простая адаптация `EmployeeModel <-> Employee` и отдельный runtime-запрос unique `position` через Supabase.

- `lib/presentation/state/employee_state.dart`
  `EmployeeNotifier`:
  - держит список сотрудников и выбранного сотрудника
  - кэширует details в `_employeeDetailsCache`
  - хранит поисковую строку `searchQuery`
  - хранит кэш `canBeResponsibleMap`
  - обновляет список локально после `createEmployee`, `updateEmployee`, `deleteEmployee`
  - повторно использует уже загруженный список, если состояние success и список не пуст

---

## Дерево файлов

```text
lib/
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
│   └── repositories/
│       ├── employee_repository.dart
│       └── employee_rate_repository.dart
├── features/
│   └── employees/
│       └── presentation/
│           ├── screens/
│           │   ├── employee_details_screen.dart
│           │   ├── employee_form_screen.dart
│           │   ├── employees_list_screen.dart
│           │   └── employees_table_screen.dart
│           └── widgets/
│               ├── employee_business_trip_summary_widget.dart
│               ├── employee_card.dart
│               ├── employee_rate_summary_widget.dart
│               ├── employee_statistics_modal.dart
│               ├── employee_trip_editor_form.dart
│               ├── form_widgets.dart
│               ├── master_detail_layout.dart
│               └── search_field.dart
└── presentation/
    └── state/
        └── employee_state.dart
```

---

## База данных (Audit)

### Таблица `employees`

Назначение:
- основная карточка сотрудника

Ключевые колонки:
- `id UUID`
- `company_id UUID`
- `photo_url TEXT`
- `last_name TEXT`
- `first_name TEXT`
- `middle_name TEXT`
- `birth_date TIMESTAMPTZ`
- `birth_place TEXT`
- `citizenship TEXT`
- `phone TEXT`
- `clothing_size TEXT`
- `shoe_size TEXT`
- `height TEXT`
- `employment_date TIMESTAMPTZ`
- `employment_type TEXT DEFAULT 'official'`
- `position TEXT`
- `status TEXT DEFAULT 'working'`
- `passport_series TEXT`
- `passport_number TEXT`
- `passport_issued_by TEXT`
- `passport_issue_date TIMESTAMPTZ`
- `passport_department_code TEXT`
- `registration_address TEXT`
- `inn TEXT`
- `snils TEXT`
- `object_ids TEXT[] DEFAULT ARRAY[]::text[]`
- `can_be_responsible BOOLEAN DEFAULT false`
- `created_at TIMESTAMPTZ DEFAULT now()`
- `updated_at TIMESTAMPTZ DEFAULT now()`

RLS:
- ✅ включён

Политики:
- `Users can view employees of their companies`
- `Users can manage employees of their companies`
- `employees_select`
- `employees_insert`
- `employees_update`
- `employees_delete`

Фактическое поведение доступа:
- company-scope через `get_my_company_ids()`
- дополнительный SELECT-разрешитель через `check_permission(...)`
- сотрудник может читать собственную карточку через `profiles.employee_id`
- чтение также допускается при пересечении `employees.object_ids` и `profiles.object_ids`

Индексы:
- `employees_pkey`
- `idx_employees_position`
- `idx_employees_status`

Оценка объёма:
- ~74 строк (`pg_stat_user_tables`)

### Таблица `employee_rates`

Назначение:
- история ставок сотрудника

Ключевые колонки:
- `id UUID`
- `company_id UUID`
- `employee_id UUID`
- `hourly_rate NUMERIC`
- `valid_from DATE`
- `valid_to DATE NULL`
- `created_at TIMESTAMPTZ DEFAULT now()`
- `created_by UUID`

RLS:
- ✅ включён

Политики:
- `Users can view employee rates of their companies`
- `Users can manage employee rates of their companies`
- `employee_rates_select`
- `employee_rates_insert`
- `employee_rates_update`
- `employee_rates_delete`

Особенность:
- активная ставка обеспечивается partial unique index `idx_employee_rates_active_unique` на `employee_id` при `valid_to IS NULL`

Индексы:
- `employee_rates_pkey`
- `idx_employee_rates_active_unique`
- `idx_employee_rates_dates`
- `idx_employee_rates_created_by`

Оценка объёма:
- ~98 строк

### Таблица `profiles`

Использование модулем:
- связка пользователя с карточкой сотрудника через `employee_id`
- хранение `object_ids`, влияющих на доступ к сотрудникам по RLS

Ключевые колонки:
- `id UUID`
- `email TEXT`
- `full_name TEXT`
- `short_name TEXT`
- `photo_url TEXT`
- `phone TEXT`
- `status BOOLEAN`
- `object JSONB`
- `object_ids ARRAY`
- `employee_id UUID`
- `telegram_user_id BIGINT`
- `last_company_id UUID`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`
- `approved_at TIMESTAMPTZ`
- `disabled_at TIMESTAMPTZ`

RLS:
- ✅ включён

Триггеры:
- `before_profiles_insert_update` → `generate_short_name()`
- `profiles_updated_at` → `handle_updated_at()`
- `profiles_status_ts` → `profile_status_timestamps()`
- `on_profile_update_sync_auth` → `sync_profile_to_auth()`

Оценка объёма:
- ~11 строк

### Таблица `employee_attendance`

Использование модулем:
- источник ручных часов для `Timesheet`
- связана с сотрудником через `employee_id`

Ключевые колонки:
- `id UUID`
- `employee_id UUID`
- `object_id UUID`
- `date DATE`
- `hours NUMERIC DEFAULT 8`
- `attendance_type TEXT DEFAULT 'work'`
- `comment TEXT`
- `created_by UUID`
- `company_id UUID`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`

RLS:
- ✅ включён

Индексы:
- `idx_employee_attendance_employee`
- `idx_employee_attendance_employee_date`
- `idx_employee_attendance_object_id`
- `idx_employee_attendance_date`
- `unique_employee_object_date`

Триггеры:
- `update_employee_attendance_updated_at` → `update_updated_at_column()`

Оценка объёма:
- ~352 строки

### Таблица `work_plan_blocks`

Использование модулем:
- сотрудники участвуют как `responsible_id`
- сотрудники участвуют как исполнители в `worker_ids`

RLS:
- ✅ включён

Ключевые колонки:
- `id UUID`
- `work_plan_id UUID`
- `responsible_id UUID`
- `worker_ids UUID[]`
- `system TEXT`
- `section TEXT`
- `floor TEXT`
- `company_id UUID`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`

Триггеры:
- `trg_work_plan_block_responsible_check` → `ensure_responsible_is_allowed()`
- `trg_work_plan_blocks_updated_at` → `set_updated_at()`

Особенно важно:
- `ensure_responsible_is_allowed()` опирается на `employees.status`, `employees.can_be_responsible` и привязку к объектам

Оценка объёма:
- ~817 строк

### Таблица `work_plans`

Использование модулем:
- косвенная связь через `work_plan_blocks`

RLS:
- ✅ включён

Триггеры:
- `handle_work_plans_updated_at`

Оценка объёма:
- ~212 строк

### Таблица `work_hours`

Использование модулем:
- часы сотрудника в сменах
- downstream-зависимость для `Timesheet` и `FOT`

Ключевые колонки:
- `id UUID`
- `work_id UUID`
- `employee_id UUID`
- `hours NUMERIC`
- `comment TEXT`
- `company_id UUID`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`

RLS:
- ✅ включён

Политики:
- старый company-scope слой
- более строгий слой через `check_work_access(work_id)` / `check_work_editable(work_id, auth.uid())`

Триггеры:
- `work_hours_aggregate_trigger` → `trigger_update_work_aggregates_hours()`

Индексы:
- `idx_work_hours_employee_id`
- `idx_work_hours_work_id`

Оценка объёма:
- ~2697 строк

---

## Бизнес-логика

1. `EmployeesListScreen` и `EmployeesTableScreen` вызывают `employeeProvider.notifier.getEmployees()` и `objectProvider.notifier.loadObjects()` после первого `frame`.
2. `EmployeeNotifier.getEmployees()` останавливает повторную загрузку, если список уже успешно получен, и отдельно догружает `canBeResponsibleMap`.
3. `SupabaseEmployeeDataSource.getEmployees()` получает список сотрудников по `company_id`, затем отдельным запросом подтягивает текущие ставки из `employee_rates` и обогащает `currentHourlyRate`.
4. Поиск реализован в `EmployeeState.filteredEmployees` по ФИО, должности и телефону.
5. Табличный view добавляет поверх этого локальную фильтрацию по `status`, client-side counters и сортировку по `last_name`.
6. Inline-изменение статуса и объектов выполняется через `Employee.copyWith(...)` + `employeeProvider.notifier.updateEmployee(...)`.
7. Подсветка строки в табличном view включается, пока открыто popup menu изменения `status` или `object_ids`.
8. Флаг `can_be_responsible` меняется отдельным методом `toggleCanBeResponsible()`, потому что он кешируется отдельно от базового `Employee`.

Логика ответственного в планах работ:
- сотрудник должен быть `status = 'working'`
- сотрудник должен иметь `can_be_responsible = true`
- сотрудник должен быть привязан к нужному объекту

Логика текущей ставки:
- текущей считается запись в `employee_rates`, где `valid_to IS NULL`
- uniqueness поддерживается partial unique index `idx_employee_rates_active_unique`

---

## Интеграции

### UI / Навигация
- `AppDrawer` содержит два входа в модуль: legacy-список и табличный view
- `GoRouter` содержит отдельный route `employees_table`

### Объекты
- `objectProvider` используется в списках, деталях и табличном view для разрешения `objectIds -> object.name`
- табличный экран позволяет менять `object_ids` inline

### Work Plans / Works
- `work_plan_blocks.responsible_id`
- `work_plan_blocks.worker_ids`
- `work_hours.employee_id`

### Timesheet
- модуль табеля использует сотрудников как справочник ФИО, статусов, должностей и объектных привязок

### FOT
- `employee_rates` и `employees` используются в расчётах выплат, бонусов, штрафов и поиске payroll-записей

### Auth / Profile
- `profiles.employee_id` связывает пользователя и сотрудника
- RLS на `employees_select` учитывает и эту связь, и пересечение по `object_ids`

### Edge Functions

Прямой Edge Function, принадлежащий модулю `Employees`, по audit не найден.

Из project-level функций косвенно связаны только profile/user сценарии:
- `update_user_profile`
- `update_own_profile`

То есть модуль `Employees` в текущем состоянии работает преимущественно напрямую через Supabase PostgREST, а не через Edge Functions.

---

## Roadmap

### Уже реализовано
- legacy master-detail экран сотрудников
- альтернативный табличный экран `employees_table_screen.dart`
- inline-смена `status`
- inline-смена `object_ids`
- sticky header таблицы
- counters по статусам
- локальное обновление строки без полной перезагрузки экрана
- кэш `canBeResponsibleMap`
- обогащение текущей ставки через `employee_rates`
- **система разрешений для табличного вида сотрудников**

### Замеченные ограничения
- экспорт из табличного view пока отмечен как `TODO`
- фильтрация по статусам и поиску выполняется на клиенте, без server-side pagination
- для `object_ids` в `employees` используется `text[]`, а не `uuid[]`
- документирование payroll-связей частично вынесено в модуль `FOT`, поэтому в `Employees` хранится только интеграционный срез

### Следующие шаги
- вынести batch-редактирование статусов/объектов в отдельный use case
- при росте объёма данных перевести фильтрацию/поиск в PostgREST слой
- добавить полноценный audit trail изменений сотрудника и ставок
- при необходимости вынести массовые операции в отдельную Edge Function

