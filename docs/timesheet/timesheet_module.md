# Модуль Timesheet (Табель рабочего времени)

**Дата актуализации:** 07 марта 2026 года

**Изменения в этой версии:**
- добавлен серверный Excel-экспорт табеля через Supabase Edge Function `export-timesheet`
- подтверждено использование `employee_attendance` как второго источника часов помимо `work_hours`
- актуализирован audit по таблицам, RLS-политикам и Edge Functions
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

---

## Описание модуля

Модуль `Timesheet` отвечает за отображение и экспорт рабочего времени сотрудников по дням, объектам и должностям. UI построен на календарной таблице, состояние управляется через `Riverpod`, а данные обогащаются в `repository`-слое за счёт связей с модулями сотрудников, объектов и ручной посещаемости.

Ключевые функции:
- поиск по ФИО сотрудников
- фильтрация по году, месяцу, объектам и должностям
- календарное представление часов по дням
- просмотр деталей записи по клику
- ручной ввод часов вне смен
- экспорт в PDF
- экспорт в Excel с генерацией файла на стороне сервера

Архитектурные особенности:
- Clean Architecture: `presentation` / `domain` / `data`
- DI через `Riverpod`
- иммутабельные сущности через `Freezed`
- Supabase как источник данных
- отдельная Edge Function для тяжёлой генерации Excel

---

## Зависимости

### Основные таблицы
- `work_hours`
- `works`
- `employee_attendance`
- `employees`
- `objects`

### Таблицы безопасности и доступа
- `company_members`

### Связанные модули
- `works`
- `employees`
- `objects`
- `company`
- `roles`

---

## Presentation

- `lib/features/timesheet/presentation/screens/timesheet_screen.dart`
  Основной экран табеля. Содержит поиск, фильтры, кнопку Excel и кнопку PDF.

- `lib/features/timesheet/presentation/widgets/timesheet_calendar_view.dart`
  Календарная таблица по сотрудникам и дням месяца. Загружает всех активных сотрудников и уволенных с часами.

- `lib/features/timesheet/presentation/widgets/timesheet_filter_widget.dart`
  Панель фильтров и поиск по ФИО.

- `lib/features/timesheet/presentation/widgets/timesheet_pdf_action.dart`
  Действие `AppBar` для PDF-экспорта.

- `lib/features/timesheet/presentation/widgets/timesheet_excel_action.dart`
  Действие `AppBar` для Excel-экспорта.

- `lib/features/timesheet/presentation/widgets/employee_attendance_dialog.dart`
  Диалог ручного ввода часов вне смен.

- `lib/features/timesheet/presentation/services/timesheet_pdf_service.dart`
  Клиентская генерация PDF.

- `lib/features/timesheet/presentation/services/timesheet_excel_export_service.dart`
  Вызов Edge Function `export-timesheet`, обработка ответа и сохранение `.xlsx` на устройство.

- `lib/features/timesheet/presentation/providers/timesheet_provider.dart`
  Состояние, загрузка, фильтры, ошибки.

- `lib/features/timesheet/presentation/providers/timesheet_filters_providers.dart`
  Данные для фильтров.

- `lib/features/timesheet/presentation/providers/repositories_providers.dart`
  DI-провайдеры для `data` и `repository` слоя.

---

## Domain / Data

### Domain
- `lib/features/timesheet/domain/entities/timesheet_entry.dart`
  Единая доменная сущность записи табеля.

- `lib/features/timesheet/domain/entities/employee_attendance_entry.dart`
  Сущность ручной записи часов вне смен.

- `lib/features/timesheet/domain/repositories/timesheet_repository.dart`
  Контракт основного репозитория табеля.

- `lib/features/timesheet/domain/repositories/employee_attendance_repository.dart`
  Контракт репозитория ручного ввода часов.

### Data
- `lib/features/timesheet/data/datasources/timesheet_data_source.dart`
- `lib/features/timesheet/data/datasources/timesheet_data_source_impl.dart`
  Получение часов из `work_hours` + `works`, фильтрация закрытых смен.

- `lib/features/timesheet/data/datasources/employee_attendance_data_source.dart`
- `lib/features/timesheet/data/datasources/employee_attendance_data_source_impl.dart`
  Получение ручных записей из `employee_attendance`.

- `lib/features/timesheet/data/repositories/timesheet_repository_impl.dart`
  Объединяет `work_hours` и `employee_attendance`, обогащает объектами и сотрудниками, фильтрует активных/уволенных.

- `lib/features/timesheet/data/repositories/employee_attendance_repository_impl.dart`
  Репозиторий для ручных записей.

- `lib/features/timesheet/data/models/timesheet_entry_model.dart`
- `lib/features/timesheet/data/models/employee_attendance_model.dart`
  DTO-уровень для сериализации и маппинга.

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
        │   │   ├── employee_attendance_model.dart
        │   │   └── timesheet_entry_model.dart
        │   └── repositories/
        │       ├── employee_attendance_repository_impl.dart
        │       └── timesheet_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── employee_attendance_entry.dart
        │   │   └── timesheet_entry.dart
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
            │   ├── timesheet_excel_export_service.dart
            │   └── timesheet_pdf_service.dart
            └── widgets/
                ├── employee_attendance_dialog.dart
                ├── timesheet_calendar_view.dart
                ├── timesheet_excel_action.dart
                ├── timesheet_filter_widget.dart
                └── timesheet_pdf_action.dart

supabase/
└── functions/
    └── export-timesheet/
        └── index.ts
```

---

## База данных (Audit)

### Таблица `work_hours`

Назначение:
- хранение часов сотрудников внутри смен

Ключевые колонки:
- `id UUID`
- `work_id UUID`
- `employee_id UUID`
- `hours NUMERIC`
- `comment TEXT`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`
- `company_id UUID`

RLS:
- ✅ включён

Оценка объёма:
- ~2504 строк (`pg_stat_user_tables`)

### Таблица `works`

Назначение:
- хранение смен, дат, объектов и статусов

Ключевые колонки:
- `id UUID`
- `date DATE`
- `object_id UUID`
- `opened_by UUID`
- `status TEXT`
- `photo_url TEXT`
- `evening_photo_url TEXT`
- `total_amount NUMERIC`
- `items_count INTEGER`
- `employees_count INTEGER`
- `telegram_message_id INTEGER`
- `company_id UUID`

RLS:
- ✅ включён

Оценка объёма:
- ~325 строк

### Таблица `employee_attendance`

Назначение:
- хранение ручных записей часов вне смен

Ключевые колонки:
- `id UUID`
- `employee_id UUID`
- `object_id UUID`
- `date DATE`
- `hours NUMERIC`
- `attendance_type TEXT`
- `comment TEXT`
- `created_by UUID`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`
- `company_id UUID`

RLS:
- ✅ включён

Оценка объёма:
- ~302 строки

### Таблица `employees`

Назначение:
- источник ФИО, статуса, должности

Ключевые колонки:
- `id UUID`
- `last_name TEXT`
- `first_name TEXT`
- `middle_name TEXT`
- `position TEXT`
- `status TEXT`
- `object_ids TEXT[]`
- `company_id UUID`

RLS:
- ✅ включён

Оценка объёма:
- ~73 строки

### Таблица `objects`

Назначение:
- источник названий объектов

Ключевые колонки:
- `id UUID`
- `name TEXT`
- `address TEXT`
- `description TEXT`
- `company_id UUID`

RLS:
- ✅ включён

Оценка объёма:
- ~6 строк

### Таблица `company_members`

Назначение:
- RBAC-таблица участия пользователей в компаниях
- используется Edge Function `export-timesheet` для дополнительной серверной проверки доступа к `companyId`

Ключевые колонки:
- `id UUID`
- `company_id UUID`
- `user_id UUID`
- `role_id UUID`
- `is_owner BOOLEAN`
- `is_active BOOLEAN`
- `joined_at TIMESTAMPTZ`
- `system_role TEXT`

RLS:
- ✅ включён

Оценка объёма:
- ~12 строк

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

### Политики RLS

По результатам аудита `pg_policies`:

- `work_hours`
  - активны строгие политики `Strict SELECT/INSERT/UPDATE/DELETE for work_hours`
  - используются функции `check_work_access(work_id)` и `check_work_editable(work_id, auth.uid())`
  - также есть компании-ориентированные политики `Users can manage/view work_hours of their companies`

- `works`
  - активны строгие политики `Strict SELECT/INSERT/UPDATE/DELETE for works`
  - используются `get_my_company_ids()`, permission-проверки модуля `works` и доступ к объектам через `profiles.object_ids`

- `employee_attendance`
  - активны компании-ориентированные политики `Users can manage/view attendance of their companies`
  - активны модульные политики `employee_attendance_select/insert/update/delete`
  - проверка идёт через `check_permission(auth.uid(), 'timesheet', <action>)`

- `employees`
  - доступ ограничен `get_my_company_ids()` и permission-правами модуля `employees`

- `objects`
  - доступ ограничен `get_my_company_ids()` и permission-правами модуля `objects`

- `company_members`
  - чтение ограничено компаниями пользователя
  - это критично для безопасной работы `export-timesheet`

---

## Бизнес-логика

### Формирование табеля

1. `TimesheetNotifier.loadTimesheet()` передаёт фильтры в `TimesheetRepository`.
2. `TimesheetDataSourceImpl` получает часы из `work_hours` и делает join с `works`.
3. На уровне `dataSource` применяется фильтр `works.status = 'closed'`.
4. `EmployeeAttendanceRepository` подмешивает ручные записи из `employee_attendance`.
5. `TimesheetRepositoryImpl`:
   - загружает сотрудников и объекты
   - обогащает записи именами и названиями объектов
   - оставляет всех активных сотрудников
   - добавляет уволенных только если в периоде есть часы
6. `TimesheetCalendarView` рендерит итоговую календарную таблицу.

### Фильтрация

Поддерживаются:
- период: `startDate`, `endDate`
- объекты: `selectedObjectIds`
- должности: `selectedPositions`
- поиск по ФИО

Модель фильтрации гибридная:
- серверная: `employee_id`, `works.status = 'closed'`
- клиентская: диапазон дат, список объектов, список должностей

### Экспорт в PDF

`TimesheetPdfService` формирует календарный PDF на клиенте:
- данные берутся из текущего состояния
- учитываются все активные сотрудники и уволенные с часами
- сохраняется структура таблицы по дням месяца

### Экспорт в Excel

Компоненты:
- `TimesheetExcelAction`
- `TimesheetExcelExportService`
- `supabase/functions/export-timesheet/index.ts`

Pipeline:
1. Flutter вызывает `export-timesheet` и передаёт `companyId`, период и фильтры.
2. Edge Function валидирует JWT.
3. Edge Function дополнительно проверяет участие пользователя в компании через `company_members`.
4. Загружаются:
   - сотрудники
   - объекты
   - сменные часы из `work_hours`
   - ручные часы из `employee_attendance`
5. Из набора сотрудников исключаются уволенные без часов.
6. На сервере через `ExcelJS` собирается XLSX-файл:
   - колонка сотрудника содержит только ФИО
   - отдельная колонка на каждый день месяца
   - ячейки часов и итогов остаются числовыми
   - для целых значений используется формат `0`
   - для дробных значений используется формат `0.###`
   - ячейки получают заливку по объектам
   - внизу файла строится легенда цветов объектов
7. Файл возвращается в base64 и сохраняется на устройстве пользователя.

Важно:
- UI самой таблицы табеля не менялся под Excel-раскраску
- цветовая кодировка применяется только внутри XLSX-файла

---

## Интеграции

### Внутренние модули
- `works` — источник сменных часов
- `employees` — источник ФИО, статуса и должностей
- `objects` — источник названий объектов
- `company` — активная компания
- `roles` — permission guard на экспорт и редактирование

### Внешние зависимости
- `supabase_flutter`
- `riverpod`
- `freezed`
- `json_serializable`
- `pdf`
- `file_saver`
- `file_picker`
- `path_provider`
- `share_plus`

### Edge Functions

По аудиту `project-0-projectgt-supabase-list_edge_functions` для модуля релевантна:
- `export-timesheet` — `ACTIVE`, `verify_jwt = true`

---

## Roadmap

### Реализовано
- ✅ поиск по ФИО
- ✅ фильтрация по месяцу, объектам и должностям
- ✅ отображение только закрытых смен
- ✅ подмешивание ручных часов из `employee_attendance`
- ✅ показ всех активных сотрудников
- ✅ показ уволенных сотрудников только при наличии часов
- ✅ экспорт в PDF
- ✅ экспорт в Excel с серверной генерацией
- ✅ платформа-специфичное сохранение файла на Web/Desktop/Mobile

### Ограничения
- 🟡 Excel генерируется отдельной Edge Function и требует корректного `companyId`
- 🟡 формат таблицы Excel ориентирован на календарное представление месяца, а не на плоский реестр записей
- 🟡 клиентская часть всё ещё зависит от корректной работы локального сохранения файла на конкретной платформе

### Планы
- 🔄 CSV-экспорт
- 🔄 unit/integration tests для Excel-экспорта
- 🔄 вынос общей логики экспорта табличных отчётов в reusable слой

---

## Примечания для разработчиков

- Модуль использует Clean Architecture и `Riverpod DI`.
- При изменениях в структуре `employee_attendance` необходимо синхронно обновлять:
  - `employee_attendance_data_source_*`
  - `employee_attendance_repository_*`
  - `TimesheetRepositoryImpl`
  - Excel/PDF export services
- При изменениях в серверном Excel-экспорте необходимо проверять:
  - формат числовых ячеек
  - RBAC-проверку через `company_members`
  - совместимость с русской локалью Excel
- Для генерации кода:
  - `flutter pub run build_runner build --delete-conflicting-outputs`

**Последняя актуализация:** 07 марта 2026 года

**Ключевые обновления:**

**07.03.2026 — Серверный Excel-экспорт табеля**
- добавлен `TimesheetExcelAction` в `AppBar`
- добавлен `TimesheetExcelExportService`
- добавлена Edge Function `export-timesheet`
- реализована серверная RBAC-проверка через `company_members`
- добавлена генерация XLSX с числовыми ячейками часов, без должности в ФИО, с заливкой по объектам и легендой

**05.10.2025 — Логика отображения активных и уволенных сотрудников**
- оставлены все активные сотрудники
- уволенные показываются только при наличии часов
- PDF синхронизирован с логикой экрана