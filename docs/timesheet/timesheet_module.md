# Модуль Timesheet (Табель рабочего времени)

**Дата актуализации:** 30 мая 2026 года (сетка табеля: виртуализация и вёрстка)

**Изменения в этой версии:**
- **Календарная сетка:** вынесена в `timesheet_calendar_grid.dart` (`TimesheetGridLayout`, `TimesheetGridHeader`, `TimesheetGridEmployeeRow`, `TimesheetGridTotalsRow`)
- **Виртуализация строк:** тело сетки — `ListView.builder` + `itemExtent` (рисуются только видимые строки)
- **Ширина на весь блок:** `TimesheetGridLayout.layoutWidth()` — `max(viewport, minTableWidth)`; лишняя ширина уходит в колонку «Сотрудник» (`Expanded`, min 240 px); дни и «Итого» — фиксированная ширина
- **Скролл:** вертикальный — список сотрудников; горизонтальный — общий для шапки, тела и строки итогов (синхронизация `_horizontalController` / `_headerHorizontalController`)
- **После диалога посещаемости:** `reloadHoursEntries()` (не полный `loadTimesheet()`)
- Исправлены устаревшие формулировки в разделах «Поток на экране» и «Диалог посещаемости»

**Предыдущая версия (30.05.2026 — аудит кода и БД):**
- domain-правила видимости, `getEmployeesCatalog`, Edge Function, Roadmap, «UI vs Excel»
- `timesheet_employee_visibility` (Dart) + `.ts` (Excel); `test/timesheet_employee_visibility_test.dart`
- `timesheet_company_scope.dart`; счётчики БД (self-hosted)

**Предыдущая версия (30.05.2026 — накопительно):**
- синхронизация документации; `TimesheetEntry` без JSON; убран `.where(works != null)` после `works!inner`
- удалён неиспользуемый CRUD посещаемости и `resetFilters`; `TimesheetState` на Freezed
- RPC `upsert_employee_attendance_batch` — миграция [`20260530140000_employee_attendance_batch_upsert.sql`](../../supabase/migrations/20260530140000_employee_attendance_batch_upsert.sql)
- сетка из `TimesheetState.employees`; поиск по ФИО по справочнику; панель фильтров как у «Сотрудники»
- диалог посещаемости: `getShiftHoursForEmployee()` без полной `loadTimesheet()`
- RLS [`20260529200000_timesheet_read_without_works.sql`](../../supabase/migrations/20260529200000_timesheet_read_without_works.sql): `timesheet.read` + закрытые смены
- параллельная загрузка 4 источников; клиентский фильтр объектов; `TimesheetLoadResult`
- Excel через Edge Function `export-timesheet`; единый `TimesheetHoursLoadingIndicator`

**Предыдущая версия (04.05.2026):**
- удалён PDF-экспорт; постраничный Excel на сервере; подтверждён `employee_attendance` как второй источник часов

---

## Важное замечание

Модуль `Timesheet` **не владеет** производственными таблицами часов. Отчёт собирается из нескольких источников:
- `work_hours` — часы из смен
- `employee_attendance` — ручной ввод часов вне смен
- `works` — дата смены, объект, статус
- `employees` — ФИО, статус, должность
- `objects` — названия объектов
- `company_members` — RBAC для серверного Excel-экспорта

Ключевые принципы:
- в табеле учитываются только часы из **закрытых** смен (`works.status = 'closed'`)
- ручные часы из `employee_attendance` объединяются с сменными в общий поток `TimesheetEntry`
- **`TimesheetLoadResult.employees`** — **полный** справочник сотрудников компании (все статусы); репозиторий **не** отсекает уволенных
- **видимость строк** (уволенные с часами, фильтр объектов, сегмент) — **domain** `lib/features/timesheet/domain/timesheet_employee_visibility.dart`; на экране — `_syncEmployeeRows` + фильтры ФИО
- роль с `timesheet.read` без `works.read` видит табель по закрытым сменам (RLS `timesheet_read_closed_works_select`)
- **без активной компании** (`profiles.last_company_id` → `activeCompanyIdProvider`) табель **не запрашивает** `work_hours` / `employee_attendance` с пустым `company_id`; пользователь видит `timesheetNoActiveCompanyMessage` (согласовано с guard в `SupabaseEmployeeDataSource`)

---

## Описание модуля

Модуль `Timesheet` отвечает за отображение и экспорт рабочего времени сотрудников по дням и объектам. UI — календарная таблица; состояние — `Riverpod`; обогащение записей (ФИО, объект) — в `TimesheetRepositoryImpl`.

Ключевые функции:
- поиск по ФИО (телефон: шапка; планшет/ПК: панель фильтров)
- переключатель месяца без перехода в будущие месяцы
- фильтр объектов и сегмент «Все / С часами / Без часов» на клиенте
- календарное представление часов по дням
- ручной ввод часов вне смен (диалог посещаемости)
- экспорт Excel через Edge Function
- чекбоксы выбора сотрудников для экспорта

Архитектурные особенности:
- Clean Architecture: `presentation` / `domain` / `data`
- DI через `Riverpod`
- иммутабельные сущности: **Freezed** (`TimesheetEntry`, `TimesheetState`; JSON — только у `employee_attendance_*`)
- Supabase + Edge Function `export-timesheet`
- параллельная загрузка независимых источников (`.wait`); фильтр `objectIds` на сервере
- календарная сетка: **виртуализированный** список строк + фиксированная шапка и строка «Итого по дням»
- после диалога посещаемости — `reloadHoursEntries()` (без перезагрузки каталога сотрудников)

---

## Зависимости

### Таблицы модуля (usage, не owner)
- `work_hours`
- `works`
- `employee_attendance`
- `employees`
- `objects`

### Таблицы безопасности и доступа
- `company_members`
- `profiles` (для табеля picklist объектов **не** сужается по `profiles.object_ids`)

### Связанные модули
- `works` — сменные часы
- `employees` — справочник сотрудников (`EmployeeRepository.getEmployeesCatalog()`, без `employee_rates`)
- `objects` — названия и picklist фильтра
- `company` — `activeCompanyId`
- `roles` — `timesheet.read`, `timesheet.update`, `PermissionGuard`

---

## Presentation

| Файл | Назначение |
|------|------------|
| `screens/timesheet_screen.dart` | Шапка, цепочка фильтров записей (объекты → ФИО), сетка, оверлей загрузки |
| `widgets/timesheet_calendar_view.dart` | Оркестрация сетки: фильтры над таблицей, `_syncEmployeeRows`, индексы часов, `ListView.builder`, скролл-контроллеры |
| `widgets/timesheet_calendar_grid.dart` | Вёрстка ячеек: `TimesheetGridLayout`, `TimesheetGridHeader`, `TimesheetGridEmployeeRow`, `TimesheetGridTotalsRow`, `_TimesheetGridCells` |
| `widgets/timesheet_filters_toolbar.dart` | `TimesheetCompactMonthSwitcher`, `TimesheetToolbarSearch` |
| `widgets/timesheet_mobile_search_field.dart` | Поиск в шапке (`GTTextField`) |
| `widgets/timesheet_filter_widget.dart` | Провайдеры поиска/сегмента; `filterEmployeesByTimesheetNameSearch` (re-export `TimesheetEmployeeListScope` из domain) |
| `widgets/timesheet_objects_bar_dropdown.dart` | Мультивыбор объектов → `setSelectedObjects()` |
| `widgets/timesheet_employee_list_scope_segment.dart` | Сегмент «Все / С часами / Без часов» |
| `widgets/timesheet_excel_action.dart` | «Скачать табель» (весь / выбранные чекбоксами) |
| `widgets/timesheet_hours_loading_indicator.dart` | Cupertino-спиннер + подпись |
| `widgets/employee_attendance_dialog.dart` | Ручной ввод; batch upsert; сменные часы read-only |
| `services/timesheet_excel_export_service.dart` | Edge Function `export-timesheet` |
| `state/timesheet_state.dart` | Freezed: `entries`, `employees`, `isLoading`, `error`, период, `selectedObjectIds` |
| `providers/timesheet_provider.dart` | `TimesheetNotifier`: `loadTimesheet()`, `reloadHoursEntries()`, `setDateRange()`, `setSelectedObjects()` (серверный фильтр объектов); `timesheetGridEntriesProvider` |
| `providers/timesheet_filters_providers.dart` | `availableObjectsForTimesheetProvider` |
| `providers/repositories_providers.dart` | DI data/repository; `activeCompanyId` передаётся как `String?` (без подстановки `''`) |
| `providers/timesheetGridSelectedEmployeeIdsProvider` | Выбранные в сетке `employeeId` |

### Адаптивная шапка и панель фильтров

Порог «телефон / планшет+»: `EmployeesLayoutUtils.useEmployeesMobileList` (`shortestSide < 600`).

| Зона | Телефон | Планшет / десктоп |
|------|---------|-------------------|
| Шапка | Меню · поиск · тема | Меню · заголовок · тема |
| Панель над сеткой | Месяц · объекты · сегмент · Excel | Месяц · поиск · объекты · сегмент · Excel |

**Поиск (один уровень):**
1. Фильтр объектов — **на сервере** (`objectIds` в datasource); смена объектов → `loadTimesheet()`.
2. `TimesheetCalendarView` — `filterEmployeesByTimesheetNameSearch` по справочнику (`timesheetSearchQueryProvider`); ячейки и итоги — только для видимых строк после поиска.
3. `timesheetGridEntriesProvider` — стабильная ссылка на `state.entries` для сетки (без повторной фильтрации по объектам на клиенте — объекты уже в запросе).

### Календарная сетка (вёрстка и производительность)

Реализация разделена: **логика строк** — `timesheet_calendar_view.dart`; **разметка ячеек** — `timesheet_calendar_grid.dart`.

| Компонент | Назначение |
|-----------|------------|
| `TimesheetGridLayout` | Константы колонок, `minTableWidth(dayCount)`, `layoutWidth(dayCount, viewportWidth)`, `dayKey()`, высоты строк |
| `TimesheetGridHeader` | Закреплённая шапка (чекбокс «все», дни, «Итого») |
| `TimesheetGridEmployeeRow` | Одна строка сотрудника (чекбокс, ФИО, ячейки дней, итог по строке) |
| `TimesheetGridTotalsRow` | Строка «Итого по дням» сразу под последней строкой сотрудника (`SliverToBoxAdapter` в общем вертикальном скролле) |
| `_TimesheetGridCells` | `fixed` — чекбокс, день, «Итого»; `employee` — `Expanded` с `minWidth: 240` |

**Геометрия колонок (px):**

| Колонка | Ширина | Примечание |
|---------|--------|------------|
| Чекбокс | 44 | фиксированная |
| Сотрудник | ≥ 240 | **растягивается** на свободную ширину viewport |
| День | 40 × N | фиксированная, N = число дней в периоде |
| Итого | 52 | фиксированная, компактная |

**Ширина таблицы:** `layoutWidth = max(viewportWidth, minTableWidth)`. На широком экране таблица на всю область; при длинном месяце — горизонтальный скролл (`SingleChildScrollView` + синхронизация шапки/итогов).

**Виртуализация:** `CustomScrollView` + `SliverFixedExtentList` (`dataRowHeight` 42 px) для строк сотрудников; итоги — `SliverToBoxAdapter` сразу после списка (не прижаты к низу экрана). Шапка закреплена над областью скролла.

**Индексация часов (в `TimesheetCalendarView`):** `_entriesByEmployeeDay`, `_entriesByDay` пересчитываются в `_rebuildEntryIndex` только для **видимых** после фильтров сотрудников — итоги по дням согласованы с поиском/сегментом.

### Состояния загрузки (UI)

| Место | Условие | Отображение |
|-------|---------|-------------|
| `timesheet_screen` | `error == timesheetNoActiveCompanyMessage` | Баннер с текстом ошибки над сеткой (без сетевой загрузки) |
| `timesheet_screen` | `isLoading` | Оверлей + `TimesheetHoursLoadingIndicator` |
| `timesheet_calendar_view` | после `_syncEmployeeRows`, пустой `_allEmployees` | Контекстная заглушка |
| `employee_attendance_dialog` | `_isLoading` / `_isSaving` | Индикатор в блоке / на кнопке |
| `timesheet_excel_action` | `!timesheetHasActiveCompany(companyId)` | `AppSnackBar` с `timesheetNoActiveCompanyMessage` |

---

## Domain / Data

### Domain
| Сущность / контракт | Описание |
|---------------------|----------|
| `timesheet_entry.dart` | Запись табеля (**Freezed**, без JSON). `isManualEntry`: attendance vs смена. Для attendance: `workId == id` |
| `timesheet_load_result.dart` | `entries` + `employees` (полный справочник компании) |
| `employee_attendance_entry.dart` | Ручная посещаемость (**Freezed + json_serializable**) |
| `timesheet_repository.dart` | `loadTimesheet()`, `getShiftHoursForEmployee()` |
| `employee_attendance_repository.dart` | `getAttendanceRecords()`, `batchUpsertAttendance()` |
| `timesheet_employee_list_scope.dart` | Enum: `all` / `withHours` / `withoutHours` (**только UI**) |
| `timesheet_hours_index.dart` | `TimesheetHoursIndex.fromEntries()` — суммы часов и id с записями для правил видимости |
| `timesheet_employee_visibility.dart` | `isTimesheetGridEmployeeVisible`, `visibleTimesheetGridEmployees`, `visibleTimesheetExportEmployees` (зеркало логики Excel на Dart) |

### Data
| Компонент | Описание |
|-----------|----------|
| `timesheet_company_scope.dart` | `timesheetHasActiveCompany`, `timesheetNoActiveCompanyMessage`, `TimesheetCompanyNotSelectedException` — единая проверка `activeCompanyId` для модуля |
| `timesheet_data_source_impl.dart` | `String? activeCompanyId`; без компании → `[]`; иначе `work_hours` + `works!inner`, `works.status = closed`, пагинация `.range(1000)`; `getShiftWorkHoursForEmployee` — облегчённый select |
| `employee_attendance_data_source_impl.dart` | `String? activeCompanyId`; без компании → `[]` / `TimesheetCompanyNotSelectedException` при `batchUpsertAttendance`; RPC `upsert_employee_attendance_batch` |
| `timesheet_repository_impl.dart` | Параллельная загрузка 4 источников; маппинг `Map` → `TimesheetEntry`; обогащение через `employeesById` / `objectsById` (**без** фильтра уволенных) |
| `employee_attendance_repository_impl.dart` | Model ↔ domain, batch upsert |
| `employee_attendance_model.dart` | DTO таблицы `employee_attendance` |

Строки из `work_hours` **не** имеют отдельной data-модели — маппинг в репозитории из `Map`.

### Внешний слой (employees)
| API | Назначение |
|-----|------------|
| `EmployeeRepository.getEmployeesCatalog()` | Справочник для табеля — **без** `employee_rates` |
| `EmployeeRepository.getEmployees()` | Сотрудники + текущие ставки (модуль «Сотрудники», ФОТ) |
| `SupabaseEmployeeDataSource._fetchCompanyEmployees()` | Общая выборка `employees` по `company_id`; используется в catalog и в `getEmployees()` |

---

## Дерево файлов

```text
lib/features/timesheet/
├── data/
│   ├── timesheet_company_scope.dart
│   ├── datasources/
│   │   ├── employee_attendance_data_source.dart
│   │   ├── employee_attendance_data_source_impl.dart
│   │   ├── timesheet_data_source.dart
│   │   └── timesheet_data_source_impl.dart
│   ├── models/
│   │   ├── employee_attendance_model.dart
│   │   ├── employee_attendance_model.freezed.dart
│   │   └── employee_attendance_model.g.dart
│   └── repositories/
│       ├── employee_attendance_repository_impl.dart
│       └── timesheet_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── employee_attendance_entry.dart (+ .freezed.dart, .g.dart)
│   │   ├── timesheet_entry.dart (+ .freezed.dart)
│   │   └── timesheet_load_result.dart
│   ├── timesheet_employee_list_scope.dart
│   ├── timesheet_employee_visibility.dart
│   ├── timesheet_hours_index.dart
│   └── repositories/
│       ├── employee_attendance_repository.dart
│       └── timesheet_repository.dart
└── presentation/
    ├── state/          → timesheet_state.dart (+ .freezed.dart)
    ├── providers/
    ├── screens/
    ├── services/
    └── widgets/        → 12 виджетов (см. таблицу Presentation)
        ├── timesheet_calendar_view.dart
        ├── timesheet_calendar_grid.dart
        └── …

supabase/
├── migrations/
│   ├── 20260529200000_timesheet_read_without_works.sql
│   ├── 20260530140000_employee_attendance_batch_upsert.sql
│   └── 20260530160000_timesheet_query_indexes.sql
└── functions/
    └── export-timesheet/
        ├── index.ts
        └── timesheet_employee_visibility.ts

test/
├── timesheet_employee_visibility_test.dart
├── timesheet_export_timesheet_postgrest_limit_test.dart
└── timesheet_name_search_test.dart
```

---

## База данных (Audit)

> Счётчики — `COUNT(*)` на **30.05.2026** (self-hosted `api.progt.ru`). RLS — `pg_policies`.

| Таблица | Строк (≈) | RLS |
|---------|-----------|-----|
| `work_hours` | 5469 | ✅ |
| `works` | 625 | ✅ |
| `employee_attendance` | 535 | ✅ |
| `employees` | 118 | ✅ |
| `objects` | ~2608 (вся таблица; в UI — по RLS компании) | ✅ |
| `company_members` | — | ✅ |

### Функции (RPC)

| Функция | Назначение | Миграция |
|---------|------------|----------|
| `upsert_employee_attendance_batch(p_rows jsonb)` | Пакетный upsert `employee_attendance` по `(employee_id, object_id, date)`; `SECURITY INVOKER`; `GRANT` → `authenticated` | `20260530140000_employee_attendance_batch_upsert.sql` |

Конфликт: constraint `unique_employee_object_date`. При UPDATE: `hours`, `attendance_type`, `comment`, `company_id`; `created_by` — только при INSERT.

### Связи

```text
work_hours ──> works ──> objects
     │
     └──────> employees

employee_attendance ──> employees
employee_attendance ──> objects
```

### Политики RLS (ключевые)

**`works`**
- `timesheet_read_closed_works_select` — `timesheet.read` → SELECT только `status = 'closed'`, без `works.read` и без `profiles.object_ids`

**`employee_attendance`**
- `employee_attendance_select/insert/update/delete`
- `Users can view/manage attendance of their companies`
- проверка `check_permission(..., 'timesheet', ...)`

**`objects`**
- `objects_select` — в т.ч. ветка `timesheet.read` (picklist фильтра)

**`work_hours`**
- политики компании + `check_work_access` / `check_work_editable`

### Миграции модуля

1. **`20260529200000_timesheet_read_without_works.sql`** — RLS табеля без модуля «Смены»; `objects_select` + `timesheet.read`
2. **`20260530140000_employee_attendance_batch_upsert.sql`** — RPC пакетного сохранения посещаемости
3. **`20260530160000_timesheet_query_indexes.sql`** — `work_hours(company_id)`, `employee_attendance(company_id, date)`, `works(company_id, status, date)`

---

## Бизнес-логика

### Активная компания (multi-tenancy)

Источник: `activeCompanyIdProvider` ← `profiles.last_company_id`.

| Слой | Поведение при `!timesheetHasActiveCompany(id)` |
|------|--------------------------------------------------|
| `TimesheetNotifier.loadTimesheet` | `entries = []`, `employees = []`, `error = timesheetNoActiveCompanyMessage`, **без** вызова репозитория |
| `TimesheetDataSourceImpl` / `EmployeeAttendanceDataSourceImpl` (read) | `[]` (защита при прямых вызовах, напр. из диалога) |
| `EmployeeAttendanceDataSourceImpl.batchUpsertAttendance` | `TimesheetCompanyNotSelectedException` → snackbar в диалоге |
| `TimesheetExcelAction` | snackbar, экспорт не стартует |

Правило валидации ID: `null`, пустая строка, `'null'` — компания не выбрана (как в `SupabaseEmployeeDataSource.getEmployees()`).

При смене компании в профиле пересоздаются datasource/repository/`TimesheetNotifier` → повторный `loadTimesheet()`.

### Формирование данных (repository)

1. `TimesheetNotifier.loadTimesheet()` — при валидной компании → `TimesheetRepository.loadTimesheet(startDate, endDate)`.
2. **Параллельно** (`.wait`):
   - `getTimesheetEntries()` — `work_hours` + `works!inner`, только `closed`
   - `getAttendanceRecords()` — `employee_attendance` за период
   - `getEmployeesCatalog()` — **все** сотрудники компании (без ставок)
   - `getObjects()` — справочник объектов
3. Репозиторий:
   - строит `employeesById` / `objectsById` из **полных** списков;
   - маппит сменные и ручные записи в `List<TimesheetEntry>` (ФИО через `formatFullName`);
   - сортирует `entries` по дате.
4. Возвращает `TimesheetLoadResult(entries, employees: allEmployees)` — **без** отсечения уволенных на этом слое.

### Состав строк сетки и Excel (единые правила)

**Источник правды** (при изменении правил — править **оба** файла и прогнать тесты):

| Слой | Файл | Ключевые функции |
|------|------|------------------|
| Dart (UI) | `domain/timesheet_employee_visibility.dart` | `visibleTimesheetGridEmployees`, `isTimesheetGridEmployeeVisible` |
| Dart (индекс) | `domain/timesheet_hours_index.dart` | `TimesheetHoursIndex.fromEntries` |
| TypeScript (Excel) | `export-timesheet/timesheet_employee_visibility.ts` | `buildTimesheetHoursIndex`, `filterTimesheetGridEmployees` |
| Тесты | `test/timesheet_employee_visibility_test.dart` | 6 unit-тестов на правила |

**Базовые правила** (одинаковы на экране и в Excel):

| Условие | Кто виден |
|---------|-----------|
| Фильтр объектов **включён** (`selectedObjectIds` / `objectIds` в запросе) | Только сотрудники с ≥1 записью в наборе часов за период (после фильтра объектов на сервере/клиенте) |
| Фильтр объектов **выключен** | Все **не уволенные** (`status != fired`) + уволенные **только** если есть записи в наборе часов |
| Сортировка | По ФИО (`formatFullName` / `localeCompare('ru')`) |

**Только UI (Excel не применяет):**

| Фильтр | Где |
|--------|-----|
| Сегмент «Все / С часами / Без часов» | `TimesheetEmployeeListScope` → параметр `listScope` в `visibleTimesheetGridEmployees` |
| Поиск по ФИО | `filterEmployeesByTimesheetNameSearch` в `TimesheetCalendarView` |

**Только Excel (дополнительно к базовым правилам):**

| Параметр | Описание |
|----------|----------|
| `employeeIds` | Чекбоксы в сетке → `filterTimesheetGridEmployees(..., onlyEmployeeIds)` |

**Поток на экране:**

1. `timesheet_screen` → `timesheetGridEntriesProvider` → `TimesheetCalendarView(entries: …)` (записи уже с **серверным** фильтром объектов, если выбран).
2. `_syncEmployeeRows` строит `TimesheetHoursIndex.fromEntries(widget.entries)` и вызывает `visibleTimesheetGridEmployees(...)` → `_employeesBase`.
3. Поиск по ФИО (`filterEmployeesByTimesheetNameSearch`) сужает `_allEmployees`; `_rebuildEntryIndex` пересчитывает итоги только для видимых id.
4. `ListView.builder` рендерит `TimesheetGridEmployeeRow` только для `_allEmployees`.

Синхронизация строк — `addPostFrameCallback` (`_scheduleSyncEmployeeRows`), `ref.listenManual` на `timesheetProvider`, сегмент и поиск; без записи в провайдеры из `build`.

### Фильтрация (сводка)

| Фильтр | Слой | Перезапрос |
|--------|------|------------|
| Месяц | `setDateRange` → `loadTimesheet()` | ✅ |
| Объекты | `setSelectedObjects` → `loadTimesheet()` с `objectIds` | ✅ |
| ФИО | `filterEmployeesByTimesheetNameSearch` в сетке (`timesheetSearchQueryProvider`) | ❌ |
| Сегмент часов | `visibleTimesheetGridEmployees` в `_syncEmployeeRows` | ❌ |
| `employee_id` | datasource (диалог, точечные запросы) | ✅ |

Сервер: период, `works.status = closed`, пагинация PostgREST.

### Диалог посещаемости

1. Параллельно: `getAttendanceRecords(employeeId, …)` + `getShiftHoursForEmployee(…)`.
2. Сменные дни — read-only (`_shiftHoursMap`).
3. Сохранение: `batchUpsertAttendance` → RPC `upsert_employee_attendance_batch` (`company_id` из `_scopedCompanyId`).
4. Успех → `TimesheetCalendarView` вызывает `reloadHoursEntries()` (часы + индексы, без повторной загрузки `employees` / `objects`).
5. Нет компании при сохранении → `TimesheetCompanyNotSelectedException` / `timesheetNoActiveCompanyMessage`.

> **Ограничение:** очистка ячейки убирает день из `_hoursMap`, но **не удаляет** строку в БД (в RPC уходят только дни с введёнными часами).

### Экспорт в Excel

`TimesheetExcelAction` → проверка `timesheetHasActiveCompany` → `TimesheetExcelExportService` → Edge `export-timesheet`:

| Этап | Детали |
|------|--------|
| Запрос | `companyId`, `startDate`, `endDate`, `objectIds?`, `employeeIds?` (чекбоксы) |
| Доступ | `ensureCompanyAccess` + JWT |
| Данные | `loadEmployees`, `loadObjects`, `loadTimesheetEntries` (пагинация `fetchAllPages`, лимит 1000) |
| Видимость строк | `buildTimesheetHoursIndex` + `filterTimesheetGridEmployees` — см. `timesheet_employee_visibility.ts` |
| Файл | XLSX: ФИО без должности, заливка по объектам, легенда, frozen panes |

**Соответствие экрану:** те же базовые правила уволенных/объектов; **не** передаются сегмент «С часами / Без часов» и строка поиска по ФИО.

---

## Интеграции

### Внутренние
- `works`, `employees`, `objects`, `company`, `roles`
- UI-паттерны модуля «Сотрудники»: `EmployeesLayoutUtils`, стиль `EmployeesTableFiltersToolbar`

### Пакеты
- `supabase_flutter`, `flutter_riverpod`, `freezed`
- `json_serializable` — **только** `employee_attendance_model` / `employee_attendance_entry`
- `file_saver`, `file_selector`, `path_provider`, `share_plus`

### Edge Functions
| Функция | Файлы | JWT |
|---------|-------|-----|
| `export-timesheet` | `index.ts`, `timesheet_employee_visibility.ts` | `verify_jwt = true` |

---

## Roadmap

### Реализовано
- ✅ guard активной компании (`timesheet_company_scope`, без `company_id = ''` в запросах)
- ✅ `getEmployeesCatalog()` — загрузка справочника без `employee_rates`
- ✅ единые правила видимости строк (Dart + TS) + unit-тесты
- ✅ полный справочник в `TimesheetLoadResult.employees`; фильтр строк — domain + presentation
- ✅ `TimesheetEntry` на Freezed без лишнего JSON
- ✅ batch upsert посещаемости (RPC)
- ✅ поиск, панель фильтров, сегмент, клиентские объекты
- ✅ только закрытые смены; RLS `timesheet.read` без `works.read`
- ✅ Excel через Edge Function; параллельная загрузка; `AppSnackBar`
- ✅ виртуализация строк сетки (`ListView.builder`, `timesheet_calendar_grid.dart`)
- ✅ полная ширина таблицы с гибкой колонкой «Сотрудник» (`TimesheetGridLayout.layoutWidth` + `Expanded`)

### Ограничения
- 🟡 нет удаления ручных часов очисткой ячейки
- 🟡 при очень большом штате (тысячи строк) узкое место — загрузка всех `entries` за месяц в память (не отрисовка); виртуализация снимает нагрузку с UI

### Планы
- 🔄 DELETE / upsert с нулевыми часами для attendance
- 🔄 серверная агрегация часов / пагинация справочника при росте данных
- 🔄 integration tests (видимость покрыта unit-тестами `timesheet_employee_visibility_test.dart`)

---

## Примечания для разработчиков

- **Не подставлять** `activeCompanyId ?? ''` в провайдерах табеля — использовать `String?` и `timesheetHasActiveCompany()`.
- Новые операции с БД в модуле — через `timesheet_company_scope` (или расширять его), не дублировать проверку `isEmpty` / `'null'`.
- **Не дублировать** фильтр уволенных в репозитории — он живёт в `timesheet_employee_visibility.dart` (и зеркале `.ts` для Excel).
- `TimesheetEntry` **не** сериализуется в JSON; не добавлять `part '*.g.dart'` без необходимости.
- Смена объектов → `setSelectedObjects()` → `loadTimesheet()` с серверным `objectIds`.
- Поиск — единый `timesheetSearchQueryProvider`; синхронизация mobile/desktop через `ref.listen`.
- После `works!inner` не нужен фильтр `works != null` в datasource.
- При изменении `employee_attendance` синхронизировать: datasource, repository, RPC, Edge `export-timesheet`.
- При изменении **правил видимости строк** — `timesheet_employee_visibility.dart`, `timesheet_employee_visibility.ts`, `timesheet_employee_visibility_test.dart`.
- `getEmployees()` со ставками — **не** использовать в табеле; только `getEmployeesCatalog()`.
- Индикаторы: `TimesheetHoursLoadingIndicator` / `CupertinoActivityIndicator`, не `CircularProgressIndicator`.
- Генерация: `dart run build_runner build --delete-conflicting-outputs`
- **Сетка:** не менять ширину «Итого» и дней через растягивание `Row` — только колонка «Сотрудник» (`_TimesheetGridCells.employee`). Ширина контейнера — `TimesheetGridLayout.layoutWidth`, не фиксированный `minTableWidth` без viewport.
- **Высота строк:** править `TimesheetGridLayout.dataRowHeight` и `itemExtent` в `ListView.builder` синхронно.
- При правках ячеек — `timesheet_calendar_grid.dart`; при фильтрах/индексах/скролле — `timesheet_calendar_view.dart`.

---

## История изменений

**30.05.2026 — Виртуализация и вёрстка календарной сетки**
- `timesheet_calendar_grid.dart`: `TimesheetGridLayout`, компоненты строк, гибкая колонка ФИО
- `timesheet_calendar_view.dart`: `ListView.builder`, синхронный горизонтальный скролл, footer «Итого по дням»
- документация: раздел «Календарная сетка», исправлен поток `reloadHoursEntries`

**30.05.2026 — Справочник без ставок и единые правила видимости**
- `EmployeeDataSource.getEmployeesCatalog()` / `EmployeeRepository.getEmployeesCatalog()`
- `TimesheetRepositoryImpl` → catalog вместо `getEmployees()`
- `domain/timesheet_employee_visibility.dart`, `timesheet_hours_index.dart`, `timesheet_employee_list_scope.dart`
- Edge: `export-timesheet/timesheet_employee_visibility.ts`
- `test/timesheet_employee_visibility_test.dart`

**30.05.2026 — Guard активной компании**
- `data/timesheet_company_scope.dart`: `timesheetHasActiveCompany`, сообщение UI, исключение при записи
- datasources: `String? activeCompanyId`; ранний выход без Supabase-запросов
- `TimesheetNotifier`: проверка до `repository.loadTimesheet()`; единое сообщение в Excel и диалоге

**30.05.2026 — Синхронизация документации и чистка кода**
- `TimesheetEntry`: только Freezed; репозиторий без дублирующих списков сотрудников
- зафиксировано: `employees` в state = полный справочник; правила строк — в domain visibility
- аудит БД: объёмы таблиц, RPC `upsert_employee_attendance_batch`, миграция в дереве файлов

**29.05.2026 — UI фильтров, RLS, производительность**
- панель фильтров, переключатель месяца, `TimesheetLoadResult`, клиентские фильтры

**04.05.2026 — Excel вместо PDF**

**07.03.2026 — Edge Function `export-timesheet`**

**05.10.2025 — Активные и уволенные в сетке (логика presentation)**
