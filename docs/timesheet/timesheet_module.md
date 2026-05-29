# Модуль Timesheet (Табель рабочего времени)

**Дата актуализации:** 29 мая 2026 года

**Изменения в этой версии:**
- **UI загрузки:** виджет [`TimesheetHoursLoadingIndicator`](../../lib/features/timesheet/presentation/widgets/timesheet_hours_loading_indicator.dart) — `CupertinoActivityIndicator` и подпись «Загрузка часов...» (по умолчанию); оверлей на [`timesheet_screen.dart`](../../lib/features/timesheet/presentation/screens/timesheet_screen.dart) при `TimesheetState.isLoading`; центр сетки в [`timesheet_calendar_view.dart`](../../lib/features/timesheet/presentation/widgets/timesheet_calendar_view.dart), пока `_allEmployees` пуст; блок календаря в [`employee_attendance_dialog.dart`](../../lib/features/timesheet/presentation/widgets/employee_attendance_dialog.dart) при `_isLoading`. На кнопке «Сохранить» в диалоге посещаемости — только компактный спиннер (`radius: 7`), без подписи. Material `CircularProgressIndicator` в модуле не используется
- **RLS [`20260529200000_timesheet_read_without_works.sql`](../../supabase/migrations/20260529200000_timesheet_read_without_works.sql):** `timesheet.read` даёт SELECT закрытых смен (`works.status = closed`) без `works.read` и без `profiles.object_ids`; picklist объектов — через обновлённую политику `objects_select` + `timesheet.read` (аналог «Сотрудники / Объекты»)
- **Производительность загрузки:** параллельная выборка в `TimesheetRepositoryImpl.loadTimesheet()` (`work_hours`, `employee_attendance`, `employees`, `objects` через `.wait`); параллельная загрузка `employees` + `employee_rates` в `SupabaseEmployeeDataSource.getEmployees()`
- **Единая загрузка сотрудников:** сущность [`TimesheetLoadResult`](../../lib/features/timesheet/domain/entities/timesheet_load_result.dart) (`entries` + `employees`); `TimesheetState.employees`; сетка табеля не вызывает повторный `getEmployees()`
- **Клиентский фильтр объектов:** `setSelectedObjects()` без перезапроса; `filterTimesheetByObjects()` в [`timesheet_filter_widget.dart`](../../lib/features/timesheet/presentation/widgets/timesheet_filter_widget.dart); цепочка фильтров в [`timesheet_screen.dart`](../../lib/features/timesheet/presentation/screens/timesheet_screen.dart)
- **Riverpod:** синхронизация строк сетки через `addPostFrameCallback` (`_scheduleSyncEmployeeRows`) — без модификации провайдеров во время build
- **UI:** уведомления через `AppSnackBar` (диалог посещаемости, Excel, сетка); виджеты `TimesheetObjectsBarDropdown`, `TimesheetEmployeeListScopeSegment`, `TimesheetHoursLoadingIndicator`
- **Picklist объектов:** [`availableObjectsForTimesheetProvider`](../../lib/features/timesheet/presentation/providers/timesheet_filters_providers.dart) — типизированный список объектов компании без сужения по `profiles.object_ids`

**Предыдущая версия (04.05.2026):**
- удалён клиентский экспорт табеля в PDF (`timesheet_pdf_action`, `timesheet_pdf_service`)
- удалена неиспользуемая data-модель `timesheet_entry_model` (маппинг строк из `work_hours` остаётся через `Map` в репозитории)
- Excel-экспорт (`export-timesheet`): постраничная выборка через `.range()` для обхода лимита PostgREST `max-rows` (~1000 строк на ответ); стабильный порядок сортировки и нормализация даты для ключей ячеек
- добавлен серверный Excel-экспорт табеля через Supabase Edge Function `export-timesheet`
- подтверждено использование `employee_attendance` как второго источника часов помимо `work_hours`
- зафиксирован текущий формат Excel: только ФИО без должности, числовые ячейки часов, заливка по объектам и легенда внизу файла

---

## Важное замечание

Модуль `Timesheet` не владеет основной производственной таблицей часов. Отчёт собирается из нескольких источников:
- `work_hours` — часы из смен
- `employee_attendance` — ручной ввод часов вне смен
- `works` — дата смены, объект, статус
- `employees` — ФИО, статус, должность
- `objects` — названия объектов
- `company_members` — RBAC-проверка доступа для серверного Excel-экспорта

Ключевой принцип:
- в табеле отображаются только часы из закрытых смен (`works.status = 'closed'`)
- ручные часы из `employee_attendance` подмешиваются в общий поток записей
- активные сотрудники отображаются даже без часов
- уволенные сотрудники отображаются только если в периоде есть часы
- роль с `timesheet.read` без `works.read` видит табель по закрытым сменам (RLS `timesheet_read_closed_works_select`)

---

## Описание модуля

Модуль `Timesheet` отвечает за отображение и экспорт рабочего времени сотрудников по дням и объектам. UI построен на календарной таблице, состояние управляется через `Riverpod`, данные обогащаются в `repository`-слое за счёт связей с модулями сотрудников, объектов и ручной посещаемости.

Ключевые функции:
- поиск по ФИО сотрудников
- фильтрация по году, месяцу и объектам (объекты — на клиенте, без перезапроса)
- сегмент «Все / С часами / Без часов» для списка строк
- календарное представление часов по дням
- просмотр деталей записи по клику
- ручной ввод часов вне смен
- экспорт в Excel с генерацией файла на стороне сервера
- чекбоксы выбора сотрудников (для экспорта и будущих действий)

Архитектурные особенности:
- Clean Architecture: `presentation` / `domain` / `data`
- DI через `Riverpod`
- иммутабельные сущности через `Freezed`
- Supabase как источник данных
- отдельная Edge Function для тяжёлой генерации Excel
- параллельная загрузка независимых источников данных

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
- `profiles` (косвенно — `object_ids` для других модулей; для табеля picklist объектов не сужается)

### Связанные модули
- `works` — источник сменных часов
- `employees` — ФИО, статус, должность
- `objects` — названия объектов
- `company` — активная компания
- `roles` — permission guard (`timesheet.read`, `timesheet.update` и др.)

---

## Presentation

| Файл | Назначение |
|------|------------|
| `screens/timesheet_screen.dart` | Основной экран: шапка, фильтры, цепочка клиентских фильтров (объекты → ФИО), календарная сетка; оверлей `TimesheetHoursLoadingIndicator` при `isLoading` |
| `widgets/timesheet_hours_loading_indicator.dart` | Единый индикатор загрузки: Cupertino-спиннер + подпись (по умолчанию «Загрузка часов...»); параметр `message` для переопределения текста |
| `widgets/timesheet_calendar_view.dart` | Календарная таблица; строки сотрудников из `TimesheetState.employees`; синхронизация через `addPostFrameCallback`; `TimesheetHoursLoadingIndicator`, пока список строк сотрудников не собран |
| `widgets/timesheet_filter_widget.dart` | Поиск по ФИО; утилиты `filterTimesheetByObjects`, `filterTimesheetByEmployeeName` |
| `widgets/timesheet_objects_bar_dropdown.dart` | Мультивыбор объектов; вызывает `setSelectedObjects()` |
| `widgets/timesheet_employee_list_scope_segment.dart` | Сегмент «Все / С часами / Без часов» |
| `widgets/timesheet_excel_action.dart` | Действие Excel в `AppBar` |
| `widgets/employee_attendance_dialog.dart` | Ручной ввод часов вне смен; `TimesheetHoursLoadingIndicator` при загрузке календаря; на «Сохранить» — `CupertinoActivityIndicator(radius: 7)`; ошибки через `AppSnackBar` |
| `services/timesheet_excel_export_service.dart` | Вызов Edge Function `export-timesheet`, сохранение `.xlsx` |
| `providers/timesheet_provider.dart` | `TimesheetState` (`entries`, `employees`, фильтры); `loadTimesheet()`, `setSelectedObjects()` |
| `providers/timesheet_filters_providers.dart` | `availableObjectsForTimesheetProvider` — picklist объектов |
| `providers/repositories_providers.dart` | DI data/repository слоя |
| `providers/timesheetGridSelectedEmployeeIdsProvider` | Выбранные чекбоксами сотрудники |

### Состояния загрузки (UI)

| Место | Условие | Отображение |
|-------|---------|-------------|
| `timesheet_screen` | `timesheetProvider.isLoading` | Полупрозрачный `ColoredBox` поверх сетки + `TimesheetHoursLoadingIndicator` |
| `timesheet_calendar_view` | `_allEmployees.isEmpty` (данные ещё не синхронизированы в сетку) | `TimesheetHoursLoadingIndicator` по центру области таблицы |
| `employee_attendance_dialog` | `_isLoading` после выбора объекта / при открытии | `TimesheetHoursLoadingIndicator` вместо календаря |
| `employee_attendance_dialog` | `_isSaving` | Только спиннер в `FilledButton` «Сохранить», без подписи |

Стиль подписи: `bodyMedium`, цвет `onSurface` с `alpha: 0.65`, отступ под спиннером 12 px. Соответствует паттерну модулей «Сметы» / «ФОТ» (Cupertino + текст при блокирующей загрузке).

---

## Domain / Data

### Domain
- `domain/entities/timesheet_entry.dart` — единая доменная сущность записи табеля
- `domain/entities/timesheet_load_result.dart` — результат загрузки: `entries` + `employees`
- `domain/entities/employee_attendance_entry.dart` — ручная запись часов вне смен
- `domain/repositories/timesheet_repository.dart` — контракт: `loadTimesheet()` → `TimesheetLoadResult`
- `domain/repositories/employee_attendance_repository.dart` — контракт ручного ввода

### Data
- `data/datasources/timesheet_data_source_impl.dart` — `work_hours` + join `works`; фильтр `works.status = 'closed'`
- `data/datasources/employee_attendance_data_source_impl.dart` — `employee_attendance`
- `data/repositories/timesheet_repository_impl.dart` — параллельная загрузка 4 источников, обогащение, фильтр активных/уволенных
- `data/repositories/employee_attendance_repository_impl.dart` — CRUD ручных записей
- `data/models/employee_attendance_model.dart` — DTO для `employee_attendance`

Строки табеля из `work_hours` маппятся из `Map` в домен в репозитории без отдельной data-модели.

### Внешний data-слой (модуль «Сотрудники»)
- `lib/data/datasources/employee_data_source.dart` — `getEmployees()` параллельно загружает `employees` и `employee_rates` (`.wait`)

---

## Дерево файлов

```text
lib/
└── features/
    └── timesheet/
        ├── data/
        │   ├── datasources/
        │   │   ├── employee_attendance_data_source.dart
        │   │   ├── employee_attendance_data_source_impl.dart
        │   │   ├── timesheet_data_source.dart
        │   │   └── timesheet_data_source_impl.dart
        │   ├── models/
        │   │   └── employee_attendance_model.dart
        │   └── repositories/
        │       ├── employee_attendance_repository_impl.dart
        │       └── timesheet_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── employee_attendance_entry.dart
        │   │   ├── timesheet_entry.dart
        │   │   └── timesheet_load_result.dart
        │   └── repositories/
        │       ├── employee_attendance_repository.dart
        │       └── timesheet_repository.dart
        └── presentation/
            ├── providers/
            │   ├── repositories_providers.dart
            │   ├── timesheet_filters_providers.dart
            │   └── timesheet_provider.dart
            ├── screens/
            │   └── timesheet_screen.dart
            ├── services/
            │   └── timesheet_excel_export_service.dart
            └── widgets/
                ├── employee_attendance_dialog.dart
                ├── timesheet_calendar_view.dart
                ├── timesheet_employee_list_scope_segment.dart
                ├── timesheet_excel_action.dart
                ├── timesheet_filter_widget.dart
                ├── timesheet_hours_loading_indicator.dart
                └── timesheet_objects_bar_dropdown.dart

supabase/
├── migrations/
│   └── 20260529200000_timesheet_read_without_works.sql
└── functions/
    └── export-timesheet/
        └── index.ts
```

---

## База данных (Audit)

> Объёмы — `pg_stat_user_tables` / `COUNT(*)` на 29.05.2026 (self-hosted `api.progt.ru`).

### Таблица `work_hours`

Назначение: хранение часов сотрудников внутри смен.

Ключевые колонки: `id`, `work_id`, `employee_id`, `hours`, `comment`, `created_at`, `updated_at`, `company_id`.

RLS: ✅ включён (~5453 строк).

### Таблица `works`

Назначение: смены, даты, объекты, статусы.

Ключевые колонки: `id`, `date`, `object_id`, `opened_by`, `status`, `photo_url`, `evening_photo_url`, `total_amount`, `items_count`, `employees_count`, `telegram_message_id`, `company_id`.

RLS: ✅ включён (~624 строки).

### Таблица `employee_attendance`

Назначение: ручные записи часов вне смен.

Ключевые колонки: `id`, `employee_id`, `object_id`, `date`, `hours`, `attendance_type`, `comment`, `created_by`, `created_at`, `updated_at`, `company_id`.

RLS: ✅ включён (~45 строк).

### Таблица `employees`

Назначение: ФИО, статус, должность.

Ключевые колонки: `id`, `last_name`, `first_name`, `middle_name`, `position`, `status`, `object_ids`, `company_id`.

RLS: ✅ включён (~118 строк).

### Таблица `objects`

Назначение: названия объектов.

Ключевые колонки: `id`, `name`, `address`, `description`, `company_id`.

RLS: ✅ включён (~7 строк).

### Таблица `company_members`

Назначение: RBAC; Edge Function `export-timesheet` проверяет участие пользователя в `companyId`.

RLS: ✅ включён.

### Связи

```text
work_hours ──> works ──> objects
     │
     └──────> employees

employee_attendance ──> employees
employee_attendance ──> objects

company_members ──> companies
company_members ──> profiles
```

### Политики RLS (аудит `pg_policies`, 29.05.2026)

**`work_hours`**
- `Strict SELECT/INSERT/UPDATE/DELETE for work_hours`
- `work_hours_select/insert/update/delete`
- `Users can manage/view work_hours of their companies`
- функции: `check_work_access(work_id)`, `check_work_editable(work_id, auth.uid())`

**`works`**
- `Strict SELECT/INSERT/UPDATE/DELETE for works`
- **`timesheet_read_closed_works_select`:** при `check_permission(uid(), 'timesheet', 'read')` — SELECT только `status = 'closed'` в компаниях пользователя; **без** `works.read` и **без** `profiles.object_ids`

**`employee_attendance`**
- `Users can manage/view attendance of their companies`
- `employee_attendance_select/insert/update/delete`
- проверка: `check_permission(auth.uid(), 'timesheet', <action>)`

**`employees`**
- доступ через `get_my_company_ids()` и права модуля `employees`

**`objects`**
- `objects_select` допускает чтение при `timesheet.read` (без `objects.read`) — picklist фильтра табеля
- также: `objects.read`, `employees.read/create/update`, `profiles.object_ids`

**`company_members`**
- чтение ограничено компаниями пользователя (критично для `export-timesheet`)

### Миграция `20260529200000_timesheet_read_without_works.sql`

1. Политика `timesheet_read_closed_works_select` на `works`
2. Пересоздание `objects_select` с веткой `timesheet.read`

---

## Бизнес-логика

### Формирование табеля

1. `TimesheetNotifier.loadTimesheet()` вызывает `TimesheetRepository.loadTimesheet(startDate, endDate)`.
2. `TimesheetRepositoryImpl.loadTimesheet()` **параллельно** (`.wait`):
   - `dataSource.getTimesheetEntries()` — `work_hours` + join `works`, только `status = 'closed'`
   - `attendanceRepository.getAttendanceRecords()` — `employee_attendance`
   - `employeeRepository.getEmployees()` — все сотрудники компании (внутри — параллельно `employees` + `employee_rates`)
   - `objectRepository.getObjects()` — справочник объектов
3. Репозиторий объединяет источники, обогащает ФИО и названия объектов, формирует список сотрудников:
   - все активные
   - уволенные — только если в периоде есть часы (из смен или attendance)
4. Возвращается `TimesheetLoadResult(entries, employees)`.
5. `TimesheetState` сохраняет оба списка; `TimesheetCalendarView` синхронизирует строки из `state.employees` без повторного сетевого запроса.
6. Синхронизация строк — в `addPostFrameCallback` (`_scheduleSyncEmployeeRows`), чтобы не модифицировать провайдеры во время build.

### Фильтрация

| Фильтр | Где применяется | Перезапрос |
|--------|-----------------|------------|
| Период (месяц/год) | `setDateRange` → `loadTimesheet()` | ✅ сервер |
| Объекты | `filterTimesheetByObjects()` в `timesheet_screen` | ❌ клиент |
| Поиск по ФИО | `filterTimesheetByEmployeeName()` | ❌ клиент |
| «Все / С часами / Без часов» | `TimesheetEmployeeListScopeSegment` в сетке | ❌ клиент |
| `employee_id` (точечный) | repository/datasource | ✅ сервер |

Серверная фильтрация: период, `works.status = 'closed'`, опционально `employee_id`.

Клиентская фильтрация: объекты, ФИО, состав видимых строк, сегмент по наличию часов.

### Экспорт в Excel

Компоненты: `TimesheetExcelAction`, `TimesheetExcelExportService`, `supabase/functions/export-timesheet/index.ts`.

Pipeline:
1. Flutter вызывает `export-timesheet` с `companyId`, периодом, `objectIds`, `positions` (сейчас `positions: null` из UI).
2. Edge Function валидирует JWT и membership через `company_members`.
3. Постраничная загрузка (`.range()`, **POSTGREST_PAGE_SIZE**) для обхода `max-rows`:
   - `employees` (`last_name`, `id`)
   - `objects` (`name`, `id`)
   - `work_hours` (`created_at`, `id`)
   - `employee_attendance` (`date`, `id`)
4. Исключаются уволенные без часов.
5. Сборка XLSX через `ExcelJS`: ФИО без должности, числовые ячейки, заливка по объектам, легенда.

---

## Интеграции

### Внутренние модули
- `works` — сменные часы (join в datasource)
- `employees` — список сотрудников и ставки (общий `EmployeeRepository`)
- `objects` — picklist и обогащение названий
- `company` — `activeCompanyId`
- `roles` — `PermissionGuard`, `timesheet.read/update`

### Внешние зависимости
- `supabase_flutter`, `riverpod`, `freezed`, `json_serializable`
- `file_saver`, `file_picker`, `path_provider`, `share_plus`

### Edge Functions
- `export-timesheet` — `ACTIVE`, `verify_jwt = true`

---

## Roadmap

### Реализовано
- ✅ поиск по ФИО
- ✅ фильтрация по месяцу и объектам (объекты — клиент)
- ✅ сегмент «Все / С часами / Без часов»
- ✅ только закрытые смены в отчёте
- ✅ ручные часы из `employee_attendance`
- ✅ активные + уволенные с часами
- ✅ Excel через Edge Function
- ✅ доступ `timesheet.read` без `works.read` (RLS)
- ✅ параллельная загрузка источников
- ✅ единая загрузка сотрудников (`TimesheetLoadResult`)
- ✅ `AppSnackBar` для уведомлений
- ✅ единый индикатор загрузки `TimesheetHoursLoadingIndicator` (Cupertino + «Загрузка часов...»)

### Ограничения
- 🟡 Excel требует корректного `companyId` и membership
- 🟡 фильтр объектов только на клиенте — при очень больших объёмах возможна задержка UI
- 🟡 `getEmployees()` тянет ставки — для табеля избыточно
- 🟡 календарная сетка рендерит все строки × дни (нет виртуализации)
- 🟡 фильтр по должностям в UI не реализован (поле есть в сущности и Excel API)

### Планы
- 🔄 лёгкий запрос сотрудников для табеля (без `employee_rates`)
- 🔄 ленивая отрисовка сетки (ListView / viewport)
- 🔄 RPC «табель за месяц» одним запросом
- 🔄 CSV-экспорт
- 🔄 unit/integration tests для Excel и фильтров

---

## Примечания для разработчиков

- При изменении `employee_attendance` синхронизировать: datasource, repository, `TimesheetRepositoryImpl`, Edge `export-timesheet`.
- При изменении RLS на `works`/`objects` проверять роль «Тестирование» (`timesheet.read` без `works.read`).
- Смена фильтра объектов **не** должна вызывать `loadTimesheet()` — только `setSelectedObjects()`.
- Синхронизация строк сетки и провайдеров — только после кадра (`addPostFrameCallback`).
- Индикаторы загрузки в модуле — только через `TimesheetHoursLoadingIndicator` или `CupertinoActivityIndicator` (кнопки); не возвращать `CircularProgressIndicator`.
- Генерация кода: `flutter pub run build_runner build --delete-conflicting-outputs`

---

## История изменений

**29.05.2026 — Индикаторы загрузки (UI)**
- `TimesheetHoursLoadingIndicator`: Cupertino-спиннер и подпись «Загрузка часов...»
- оверлей экрана табеля, сетка до синхронизации строк, диалог посещаемости

**29.05.2026 — Доступ без модуля «Смены» и оптимизация загрузки**
- RLS `timesheet_read_closed_works_select`, picklist объектов для `timesheet.read`
- `TimesheetLoadResult`, параллельная загрузка, клиентский фильтр объектов
- `AppSnackBar`, новые виджеты фильтра и сегмента списка

**04.05.2026 — Удаление PDF-экспорта**
- экспорт только в Excel через Edge `export-timesheet`

**07.03.2026 — Серверный Excel-экспорт**
- `TimesheetExcelAction`, `TimesheetExcelExportService`, Edge Function `export-timesheet`

**05.10.2025 — Логика активных и уволенных**
- все активные; уволенные — только при наличии часов
