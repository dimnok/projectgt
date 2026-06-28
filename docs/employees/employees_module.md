# Модуль Employees (Сотрудники)

**Дата актуализации:** 28 июня 2026 года

**Изменения в этой версии (28.06.2026, заявление об увольнении):**
- **Новый тип:** `EmployeeApplicationType.resignation` (`application_type = 'resignation'` в БД); миграция [`20260628140000_employee_applications_resignation_type.sql`](../../supabase/migrations/20260628140000_employee_applications_resignation_type.sql)
- **PDF:** [`ProfilePdfGenerator.generateResignationPdf`](../../lib/features/profile/utils/profile_pdf_generator.dart) — «Прошу уволить меня по собственному желанию с … г.»; шапка — ООО «ГТ Инжиниринг»
- **Карточка сотрудника:** пункт «Увольнение» в [`employee_applications_section.dart`](../../lib/features/employees/presentation/widgets/employee_applications_section.dart); форма [`showEmployeeResignationApplicationForm`](../../lib/features/employees/presentation/widgets/employee_application_forms.dart) — дата последнего рабочего дня (default +14 дней), печать PDF, загрузка скана
- **Список:** подпись «Увольнение с dd.MM.yyyy» (без «на N дней»)
- **Profile (self-service):** [`ResignationForm`](../../lib/features/profile/presentation/screens/resignation_form_bottom_sheet.dart) + пункт в [`ApplicationsScreen`](../../lib/features/profile/presentation/screens/applications_screen.dart)

**Предыдущая версия (28.06.2026, UX заявлений + PDF):**
- **Список заявлений (`_ApplicationListTile`):** компактная **однострочная** карточка — слева иконка и текст, справа **icon-only** действия (просмотр, скачивание, удаление); при busy — `CupertinoActivityIndicator` вместо кнопок
- **Подписи в строке:** верхняя — «{тип} на N день/дня/дней с dd.MM.yyyy по dd.MM.yyyy»; нижняя — «{автор} · dd.MM.yyyy HH:mm»; имя файла и размер **не отображаются** (хранятся в БД для download/preview)
- **Переключатель вкладок:** уменьшенная высота сегмента (`padding: 2`, `vertical: 5`, `fontSize: 12`); **`IndexedStack`** в [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) и mobile sheet — высота модалки не «схлопывается» при смене «Обзор» ↔ «Заявления»
- **PDF-шаблоны:** в [`ProfilePdfGenerator`](../../lib/features/profile/utils/profile_pdf_generator.dart) работодатель в шапке — **`ООО «ГТ Инжиниринг»`** (константа `_employerOrganization`; ранее было «ООО "Грандтелеком"»); директор в шаблоне — «Тельнову Д.А.»

**Предыдущая версия (28.06.2026, вкладка «Заявления»):**
- **Карточка сотрудника — вкладки «Обзор» / «Заявления»:** [`CustomSlidingSegmentedControl`](../../lib/presentation/widgets/custom_sliding_segmented_control.dart) в [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) (desktop) и [`employees_mobile_employee_details_sheet.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart) (mobile bottom sheet)
- **Блок заявлений:** [`EmployeeApplicationsSection`](../../lib/features/employees/presentation/widgets/employee_applications_section.dart) — формирование PDF (отпуск, отпуск без содержания), загрузка подписанного скана, список с просмотром и скачиванием
- **Формы:** [`employee_application_forms.dart`](../../lib/features/employees/presentation/widgets/employee_application_forms.dart) — переиспользуют [`ProfilePdfGenerator`](../../lib/features/profile/utils/profile_pdf_generator.dart), [`ApplicationDurationChip`](../../lib/features/profile/presentation/widgets/application_form_widgets.dart), [`PdfPreviewScreen`](../../lib/features/profile/presentation/screens/pdf_preview_screen.dart); ФИО берётся из [`Employee.fullName`](../../lib/domain/entities/employee.dart)
- **Data layer:** таблица `employee_applications`, bucket Storage `employee_applications` (приватный); [`SupabaseEmployeeApplicationDataSource`](../../lib/data/datasources/supabase_employee_application_data_source.dart) — `uploadBinary` (Web-safe); миграции [`20260628120000_employee_applications.sql`](../../supabase/migrations/20260628120000_employee_applications.sql), [`20260628120100_employee_applications_rls_hardening.sql`](../../supabase/migrations/20260628120100_employee_applications_rls_hardening.sql)
- **Riverpod:** [`employeeApplicationsProvider(employeeId)`](../../lib/features/employees/presentation/providers/employee_applications_provider.dart), `employeeApplicationRepositoryProvider` / `employeeApplicationDataSourceProvider` в [`providers.dart`](../../lib/core/di/providers.dart)
- **RBAC в UI:** формирование и загрузка сканов — `employees.update` (`canManage`); просмотр списка и скачивание — при `employees.read`; удаление записи — `employees.update` + `GTConfirmationDialog`

**Предыдущая версия (28.06.2026, табель → карточка):**
- **Открытие из табеля:** клик по ФИО в модуле Timesheet → `EmployeeDetailsModal` / `EmployeesMobileEmployeeDetailsSheet` (только `employees.read`); часы в табеле — отдельная иконка, не карточка
- **`EmployeeNotifier.ensureEmployeeCardDetails(known)`** — подготовка карточки из справочника без `getEmployeesCatalog`: 0–1 запрос `getCurrentHourlyRate`; кэш `_employeeDetailsCache`
- **`EmployeeRepository.getCurrentHourlyRate` / `SupabaseEmployeeDataSource`:** выборка одной текущей ставки; `getEmployee(id)` — параллельный `.wait` на `employees` + `employee_rates`
- **`getEmployee(id, {forceRefresh})`:** при попадании в кэш — без повторной сети; `refreshEmployee` → `forceRefresh: true`
- **Карточка слушает `employeeProvider.employee`:** [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart), [`employees_mobile_employee_details_sheet.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart) — обновление ставки после `ensureEmployeeCardDetails`
- **Sync с табелем:** `timesheetEmployeeCatalogChanged` — `reloadEmployeesCatalog()` только при смене полей справочника (не ставки); см. [`docs/timesheet/timesheet_module.md`](../timesheet/timesheet_module.md)

**Предыдущая версия (31.05.2026, табель):**
- **`employees.include_in_timesheet`** (миграция [`20260531120000_employees_include_in_timesheet.sql`](../../supabase/migrations/20260531120000_employees_include_in_timesheet.sql), default `true`): **чекбокс** «Учитывать в табеле» под блоком «Работа» в [`employee_edit_form.dart`](../../lib/features/employees/presentation/widgets/employee_edit_form.dart) и в мобильном редакторе ([`employees_mobile_employee_edit_blocks.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_edit_blocks.dart)). Редактирование — при `employees.update`. Правила видимости — [`timesheet_employee_visibility`](../../lib/features/timesheet/domain/timesheet_employee_visibility.dart) (экран + Excel).
- **Связь с табелем:** при смысловом изменении справочника модуль Timesheet вызывает `reloadEmployeesCatalog()` ([`timesheet_employees_catalog_sync.dart`](../../lib/features/timesheet/presentation/providers/timesheet_employees_catalog_sync.dart) + `timesheetEmployeeCatalogChanged`) — перезапуск приложения не нужен

**Предыдущая версия (29.05.2026, UX: индикаторы загрузки и кнопка редактирования):**
- **Индикаторы загрузки:** во всём presentation-слое модуля `employees` вместо `CircularProgressIndicator` используется **`CupertinoActivityIndicator`** (списки table/mobile, экран деталей по URL, аватар в карточке, история ставок, фильтр объектов в toolbar, кнопки сохранения в [`form_widgets.dart`](../../lib/features/employees/presentation/widgets/form_widgets.dart) и [`employee_edit_form.dart`](../../lib/features/employees/presentation/widgets/employee_edit_form.dart)). Кнопки `GTPrimaryButton` / `GTSecondaryButton` с `isLoading: true` — через Design System ([`gt_buttons.dart`](../../lib/core/widgets/gt_buttons.dart), уже Cupertino).
- **Карточка сотрудника (desktop):** в секции «Личные данные» вместо иконки карандаша — текстовая кнопка **`GTTextButton` «Редактировать»** ([`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart)); видна только при `employees.update`. На mobile в bottom sheet по-прежнему компактные иконки «изменить» у секций ([`_sectionEditButton`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart)).

**Предыдущая версия (29.05.2026, UX: фото на Web и уведомления):**
- **Фото сотрудника на Flutter Web:** [`EmployeeAvatarController.uploadAvatar`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart) при `kIsWeb` использует `PhotoService.pickImageBytes` + `uploadPhotoBytes` (без `dart:io` `File`). На mobile/desktop — прежний путь `pickImage` + `uploadPhoto`. Устранена ошибка `Unsupported operation: _Namespace` при загрузке аватара в браузере.
- **Единые уведомления:** во всём модуле `employees` только [`AppSnackBar`](../../lib/core/widgets/app_snackbar.dart) (`success` / `error` / `warning`). Удалены вызовы `SnackBarUtils` и `ScaffoldMessenger.showSnackBar` в presentation-слое модуля (таблица, формы, диалоги, мобильные блоки, аватар).

**Предыдущая версия (29.05.2026, жизненный цикл экранов / Flutter Web):**
- **Исправление `EngineFlutterView disposed` (web):** убраны отложенные обновления провайдеров после `dispose` (`Future` + `setSearchQuery`); сброс поиска перенесён на **вход** в модуль (`initState` → первый кадр), а не на уход с экрана.
- **Фильтры без `addPostFrameCallback` в `build`:** сброс фильтра по объекту — `ref.listen(employeesModuleObjectsProvider)` в [`employees_table_screen.dart`](../../lib/features/employees/presentation/screens/employees_table_screen.dart); сброс чипа статуса на mobile — `ref.listen(employeeProvider)` в [`employees_list_mobile_screen.dart`](../../lib/features/employees/presentation/screens/employees_list_mobile_screen.dart).
- **Карточка сотрудника:** синхронизация данных и выход из режима редактирования при отзыве `employees.update` — через `ref.listen` в [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) (без побочных эффектов в `build`).
- **Форма редактирования:** флаг `_hasChanges` обновляется синхронно в [`employee_edit_form.dart`](../../lib/features/employees/presentation/widgets/employee_edit_form.dart).
- **Экран деталей по URL:** [`employee_details_screen.dart`](../../lib/features/employees/presentation/screens/employee_details_screen.dart) — только загрузка `getEmployee` + `loadObjects`; сброс поиска при закрытии **не выполняется** (не ломает фильтр списка при возврате «назад»).

**Предыдущая версия (29.05.2026, picklist объектов без `objects.read`):**
- **RLS [`20260529190000_employees_objects_picklist_rls.sql`](../../supabase/migrations/20260529190000_employees_objects_picklist_rls.sql):** `objects_select` допускает чтение справочника при `employees.read` / `create` / `update` (экран «Объекты» по-прежнему только при `objects.read`).
- **Клиент:** [`employeesModuleObjectsProvider`](../../lib/features/employees/presentation/providers/employees_module_objects_provider.dart) — единый список объектов для фильтров и форм модуля (с учётом `profiles.object_ids`, если заданы).

**Предыдущая версия (29.05.2026, RBAC карточки сотрудника):**
- **Карточка сотрудника (read-only):** элементы изменения скрываются без права `employees` + `update` — desktop [`EmployeeDetailsModal`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart), mobile [`EmployeesMobileEmployeeDetailsSheet`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart); кнопка «+» ставки — флаг [`EmployeeRateSummaryWidget.canManageRates`](../../lib/features/employees/presentation/widgets/employee_rate_summary_widget.dart); суточные — коллбэки `onAddBusinessTrip` / `onEditBusinessTrip` только при `update`.
- **Защита сохранения в UI:** перед записью проверка `PermissionService` в [`EmployeeEditForm`](../../lib/features/employees/presentation/widgets/employee_edit_form.dart) и [`_persistEmployeeUpdate`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_edit_blocks.dart) (мобильные редакторы).
- **RLS (миграция [`20260529180000_tighten_employees_card_rls.sql`](../../supabase/migrations/20260529180000_tighten_employees_card_rls.sql)):** удалены политики «участник компании может всё» на `employees` / `employee_rates`; на `business_trip_rates` — убраны слабые `authenticated`-политики, CRUD суточных привязан к `employees.read` (SELECT) и `employees.update` (INSERT/UPDATE/DELETE). Канонические политики `employees_*` через `check_permission()` — единственный путь изменения карточки.
- **Storage (фото):** bucket `employees` — UPDATE/DELETE только при `employees.update` ([`20260509000000_add_employees_bucket_policies.sql`](../../supabase/migrations/20260509000000_add_employees_bucket_policies.sql)).

**Предыдущая версия (16.04.2026, perf-аудит запросов):**
- **Индексы по `company_id`** ([`20260416120000_employees_company_id_indexes.sql`](../../supabase/migrations/20260416120000_employees_company_id_indexes.sql)): `idx_employees_company_id`, `idx_employees_company_last_name`, `idx_employee_rates_company_id`. До этого планировщик выбирал Seq Scan на `employees` при фильтре по `company_id`, что линейно деградирует с ростом справочника. Дополнительно прогнан `ANALYZE` по двум таблицам.
- **RPC `get_employee_positions(p_company_id uuid)`** ([`20260416120500_get_employee_positions_rpc.sql`](../../supabase/migrations/20260416120500_get_employee_positions_rpc.sql), `SECURITY INVOKER`, `STABLE`): уникальные должности считаются на сервере вместо fetch‑all + клиентский `DISTINCT`. Возвращаемая колонка названа `position_name`, т.к. `position` — зарезервированный идентификатор в контексте `RETURNS TABLE`.
- **`EmployeeRepositoryImpl`** больше **не использует `Supabase.instance.client` напрямую** — метод `getPositions` делегирован в `EmployeeDataSource.getPositions()` (вызов RPC). Конструктор репозитория упрощён: параметр `activeCompanyId` удалён, провайдер `employeeRepositoryProvider` обновлён.
- **`EmployeeNotifier.getEmployees(includeResponsibilityMap: false)`** по умолчанию: дублирующий запрос `getCanBeResponsibleMap()` больше не выполняется при каждой загрузке списка. Поле `state.canBeResponsibleMap` никем в UI не читается, а при переключении флага через `toggleCanBeResponsible` мапа обновляется точечно.

**Предыдущая версия (11.04.2026):**
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
- `employee_applications` — подписанные сканы заявлений сотрудника (отпуск, БС)

Тесные связи:

- `profiles` — `employee_id`, `object_ids` (доступ и привязка пользователя к карточке)
- `objects` — `employees.object_ids`
- `work_hours`, `employee_attendance` — учёт часов
- `work_plan_blocks` — `responsible_id`, `worker_ids`
- `work_plans` — в т.ч. колонка `responsible_id` (FK на `employees`)
- `business_trip_rates` — суточные в карточке сотрудника (owner схемы — модуль **FOT** / объекты; RLS в карточке — `employees.read` / `employees.update`)
- таблицы **FOT** (`payroll_*`, функции расчёта) — чтение ставок и сотрудников

Особенности реализации:

- все запросы к PostgREST фильтруются по **`activeCompanyId`** в datasource
- поиск по ФИО / должности / телефону — **на клиенте** (`EmployeeState.filteredEmployees`)
- **текущая ставка** не хранится в строке `employees`: подгружается из `employee_rates`, где `valid_to IS NULL`, и кладётся в `Employee.currentHourlyRate` / `EmployeeModel.currentHourlyRate` (только на клиенте)
- флаг **`can_be_responsible`** хранится в БД в `employees`, в доменной модели [`Employee`](../../lib/domain/entities/employee.dart) **не** сериализуется; кэш `EmployeeState.canBeResponsibleMap` сейчас никем не читается, обновляется точечно через `toggleCanBeResponsible`; массовая подгрузка `getCanBeResponsibleMap()` по умолчанию **не выполняется** (`includeResponsibilityMap: false`), чтобы убрать дублирующий запрос при каждом открытии списка — подгрузка включается явно только в сценариях, где это потребуется
- **две раскладки списка**: `EmployeesTableScreen` (таблица) и `EmployeesListMobileScreen` (карточки) — выбор по [`EmployeesLayoutUtils.useEmployeesMobileList`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart) (`shortestSide` vs breakpoint планшета)
- **вкладки карточки:** «Обзор» (анкета, ставки, личные данные) и «Заявления» (PDF + сканы); вкладки «Документы» и «Доп. информация» — в roadmap

---

## Описание модуля

Модуль **Employees** закрывает жизненный цикл карточки сотрудника в компании: анкета, паспорт, трудоустройство, объекты, статус, история ставок, фото, **заявления (PDF + подписанные сканы)**, флаг ответственного, участие в **Timesheet**, **Works**, **Work Plans**, **FOT**.

Ключевые функции:

- список сотрудников: **таблица** (desktop / широкий экран) или **мобильный** список с фильтром по статусу, поиском, свайп-действиями и bottom sheet
- создание / редактирование / удаление (права `employees:*`)
- история и текущая ставка (`employee_rates`)
- **заявления:** формирование образца (отпуск / отпуск без содержания / увольнение), печать PDF, загрузка подписанного скана, список с просмотром и скачиванием
- переключение **`can_be_responsible`**
- inline на таблице: **статус**, **объекты** (`object_ids`)
- экспорт XLSX на сервере (**Edge Function** + клиентский сервис)
- фото: загрузка / удаление / сохранение (платформенно) через **Storage** и `PhotoService` (Web — bytes, не `File`)

Архитектура: Clean Architecture (`presentation` / `domain` / `data`), **Riverpod**, **Freezed**, **json_serializable**, транспорт **Supabase PostgREST**, мультитенантность по **`company_id`**.

---

## Зависимости

### Таблицы модуля (owner)

| Таблица                  | Назначение                                      |
|--------------------------|-------------------------------------------------|
| `employees`              | Карточка сотрудника                             |
| `employee_rates`         | История почасовых ставок                        |
| `employee_applications`  | Заявления: метаданные периода + подписанный скан |

### Таблицы и сущности, которые модуль использует

| Объект               | Использование                                      |
|----------------------|----------------------------------------------------|
| `objects`            | Picklist для фильтров и форм (`employeesModuleObjectsProvider`; RLS без `objects.read`) |
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
| [`employees_table_screen.dart`](../../lib/features/employees/presentation/screens/employees_table_screen.dart) | Полноэкранная таблица: sticky header, поиск, фильтр статуса (счётчики), фильтр по объекту (`ref.listen` при устаревании picklist), multi-select, inline `status` / `object_ids`, детали в модалке, права `read` / `create` / `update` / `export`; загрузка списка — `CupertinoActivityIndicator`; при входе — `setSearchQuery('')` + `getEmployees` + `loadObjects` |
| [`employees_list_mobile_screen.dart`](../../lib/features/employees/presentation/screens/employees_list_mobile_screen.dart) | Мобильный список карточек, чипы статусов (`ref.listen` — сброс при пустом пересечении с поиском), bottom sheet объектов и деталей; загрузка — `CupertinoActivityIndicator` + подпись «Загружаем список»; при входе — сброс поиска и загрузка данных |
| [`employee_details_screen.dart`](../../lib/features/employees/presentation/screens/employee_details_screen.dart) | Маршрут по `employeeId`; общий UI с модалкой деталей; `employeesModuleObjectsProvider` для picklist объектов; состояние загрузки — `CupertinoActivityIndicator` |

### Утилиты и сервисы UI

| Файл | Назначение |
|------|------------|
| [`employees_layout_utils.dart`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart) | `useEmployeesMobileList`, `useEmployeesDesktopModal` (shortestSide + ширина) |
| [`employee_application_upload_flow.dart`](../../lib/features/employees/presentation/utils/employee_application_upload_flow.dart) | Выбор файла (`file_selector`) + загрузка подписанного скана через `employeeApplicationsProvider` |
| [`employee_application_download_flow.dart`](../../lib/features/employees/presentation/utils/employee_application_download_flow.dart) | Скачивание и просмотр скана; `saveFileBytesToUserDevice` |
| [`employee_server_excel_export_service.dart`](../../lib/features/employees/presentation/services/employee_server_excel_export_service.dart) | Вызов `export-employees`, сохранение base64 XLSX (веб / десктоп / share) |
| [`employee_avatar_controller.dart`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart) | Загрузка / удаление аватара; Web — `pickImageBytes` / `uploadPhotoBytes`; mobile/desktop — `File`; скачивание: web/desktop — файл, iOS/Android — галерея |

### Виджеты (основные)

| Файл | Назначение |
|------|------------|
| [`employees_table_actions_bar.dart`](../../lib/features/employees/presentation/widgets/employees_table_actions_bar.dart) | Панель действий таблицы |
| [`employees_table_filters_toolbar.dart`](../../lib/features/employees/presentation/widgets/employees_table_filters_toolbar.dart) | Фильтры; индикатор загрузки picklist объектов в триггере dropdown — `CupertinoActivityIndicator`; `EmployeesObjectTableFilterValue.toExportFilterJson()` для экспорта |
| [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) | Детальная карточка (desktop); вкладки **«Обзор» / «Заявления»** (`IndexedStack`, компактный `CustomSlidingSegmentedControl`); вход в редактирование — `GTTextButton` «Редактировать»; загрузка аватара — `CupertinoActivityIndicator`; «+» ставки и суточных только при `employees.update`; `ref.listen` на `employeeProvider` и `permissionServiceProvider` |
| [`employee_applications_section.dart`](../../lib/features/employees/presentation/widgets/employee_applications_section.dart) | **Вкладка «Заявления»:** типы заявлений, компактный список сканов (одна строка + icon actions), просмотр / скачивание / удаление |
| [`employee_application_forms.dart`](../../lib/features/employees/presentation/widgets/employee_application_forms.dart) | Формы отпуска и БС для карточки сотрудника (PDF + загрузка скана) |
| [`employee_application_scan_preview.dart`](../../lib/features/employees/presentation/widgets/employee_application_scan_preview.dart) | Просмотр PDF (`printing`) и изображений в диалоге |
| [`employee_edit_form.dart`](../../lib/features/employees/presentation/widgets/employee_edit_form.dart) | Форма редактирования; кнопка «Сохранить» при отправке — `CupertinoActivityIndicator`; `_saveChanges` — guard `employees.update` |
| [`add_employee_simple_dialog.dart`](../../lib/features/employees/presentation/widgets/add_employee_simple_dialog.dart) | Быстрое добавление |
| [`add_employee_rate_dialog.dart`](../../lib/features/employees/presentation/widgets/add_employee_rate_dialog.dart) | Добавление ставки |
| [`employee_rate_summary_widget.dart`](../../lib/features/employees/presentation/widgets/employee_rate_summary_widget.dart) | Сводка по ставкам; `canManageRates` — кнопка добавления ставки; история ставок (`FutureBuilder`) — `CupertinoActivityIndicator` |
| [`employee_business_trip_summary_widget.dart`](../../lib/features/employees/presentation/widgets/employee_business_trip_summary_widget.dart) | Сводка по суточным; add/edit через опциональные коллбэки (передаются только при `update`) |
| [`employee_trip_editor_form.dart`](../../lib/features/employees/presentation/widgets/employee_trip_editor_form.dart) | Редактор поездок |
| [`form_widgets.dart`](../../lib/features/employees/presentation/widgets/form_widgets.dart) | Общие блоки формы; кнопка «Сохранить» в состоянии загрузки — `CupertinoActivityIndicator` |
| [`editable_inline_text_row.dart`](../../lib/features/employees/presentation/widgets/editable_inline_text_row.dart) | Inline-редактирование |
| [`employees_mobile_atmosphere.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_atmosphere.dart) | Визуальный фон мобильного списка |
| [`employees_mobile_search_field.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_search_field.dart) | Поиск на мобильном |
| [`employees_mobile_add_employee_button.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_add_employee_button.dart) | FAB / кнопка добавления |
| [`employees_mobile_employee_card.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_card.dart) | Карточка в списке |
| [`employees_mobile_swipeable_employee_card.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_swipeable_employee_card.dart) | Свайп по карточке |
| [`employees_mobile_employee_details_sheet.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart) | Bottom sheet деталей; вкладки **«Обзор» / «Заявления»** (`IndexedStack`, компактный сегмент); загрузка аватара — `CupertinoActivityIndicator`; кнопки «Изменить» (иконка у секций) — при `employees.update` |
| [`employees_mobile_employee_edit_blocks.dart`](../../lib/features/employees/presentation/widgets/employees_mobile_employee_edit_blocks.dart) | Блоки редактирования на мобильном; `_persistEmployeeUpdate` — guard `employees.update` |

### Design System (`lib/core/widgets/`)

Модуль опирается на общие компоненты вместо «голого» Material там, где есть обёртки проекта:

| Виджет / API | Файл в core | Где используется в модуле (примеры) |
|--------------|-------------|-------------------------------------|
| `GTTextField` | [`gt_text_field.dart`](../../lib/core/widgets/gt_text_field.dart) | диалоги добавления/ставки, мобильные блоки редактирования, поиск |
| `GTDropdown` | [`gt_dropdown.dart`](../../lib/core/widgets/gt_dropdown.dart) | формы, редактор поездок, мобильные блоки |
| `GTPrimaryButton` / `GTSecondaryButton` / `GTTextButton` | [`gt_buttons.dart`](../../lib/core/widgets/gt_buttons.dart) | диалоги, bottom sheet, мобильный список; **«Редактировать»** в desktop-карточке (`EmployeeDetailsModal`); `isLoading` на кнопках — встроенный `CupertinoActivityIndicator` |
| `CupertinoActivityIndicator` | `package:flutter/cupertino.dart` | загрузка списков, карточки, аватара, фильтра объектов, inline-кнопок сохранения в формах модуля (не Material `CircularProgressIndicator`) |
| `DesktopDialogContent` | [`desktop_dialog_content.dart`](../../lib/core/widgets/desktop_dialog_content.dart) | детали, добавление сотрудника/ставки, формы на desktop |
| `MobileBottomSheetContent` | [`mobile_bottom_sheet_content.dart`](../../lib/core/widgets/mobile_bottom_sheet_content.dart) | те же сценарии на mobile / узкой ширине |
| `AppSnackBar` | [`app_snackbar.dart`](../../lib/core/widgets/app_snackbar.dart) | **Весь модуль:** таблица, mobile-список, формы, диалоги, заявления, [`EmployeeAvatarController`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart) |
| `GTContextMenu` | [`gt_context_menu.dart`](../../lib/core/widgets/gt_context_menu.dart) | [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart) |
| `GTConfirmationDialog` | [`gt_confirmation_dialog.dart`](../../lib/core/widgets/gt_confirmation_dialog.dart) | удаление заявления в [`employee_applications_section.dart`](../../lib/features/employees/presentation/widgets/employee_applications_section.dart) |
| `CustomSlidingSegmentedControl` | [`custom_sliding_segmented_control.dart`](../../lib/presentation/widgets/custom_sliding_segmented_control.dart) | переключатель вкладок «Обзор» / «Заявления» в карточке |

Табличный экран построен на кастомной вёрстке (`Table` / `LayoutBuilder` и т.д.), без внешних grid-библиотек — в духе правил проекта (см. [`flutter.mdc`](../../.cursor/rules/flutter.mdc)).

### Навигация и меню

- Маршруты: `AppRoutes.employees = '/employees'`, `employee_details` — `${AppRoutes.employees}/:employeeId` ([`app_router.dart`](../../lib/core/common/app_router.dart))
- Список: при `employees` + `read` показывается таблица или мобильный список в зависимости от [`EmployeesLayoutUtils`](../../lib/features/employees/presentation/utils/employees_layout_utils.dart)
- Детали: доступ при `employees` + `read` **или** если `profiles` содержит тот же `employee_id`, что и маршрут
- [`AppDrawer`](../../lib/presentation/widgets/app_drawer.dart): пункт «Сотрудники» через [`PermissionGuard`](../../lib/features/roles/presentation/widgets/permission_guard.dart) (`employees` + `read`)

### RBAC в карточке сотрудника

| Право | Список (таблица / mobile) | Карточка (modal / bottom sheet) |
|-------|---------------------------|----------------------------------|
| `read` | Просмотр списка, открытие карточки | Просмотр всех секций; вкладка «Заявления» — список, просмотр и скачивание сканов |
| `create` | «Добавить сотрудника» | — |
| `update` | Inline статус/объекты, свайпы (mobile), редактирование | Desktop: **«Редактировать»** → форма; mobile: иконки «изменить»; «+» ставки, суточные, фото; **формирование заявлений и загрузка сканов**; удаление заявлений |
| `delete` | Удаление выбранных | — |
| `export` | «Экспорт» в toolbar таблицы | — |

Источник прав в UI: [`PermissionService`](../../lib/features/roles/application/permission_service.dart). Роль с одним `read` (например, «Тестирование») видит модуль и карточку **без** элементов изменения; запись в БД дополнительно блокируется RLS (`check_permission`).

### Провайдеры presentation

| Провайдер | Файл | Назначение |
|-----------|------|------------|
| `employeesModuleObjectsProvider` | [`employees_module_objects_provider.dart`](../../lib/features/employees/presentation/providers/employees_module_objects_provider.dart) | Picklist `objects` для фильтров, форм добавления/редактирования, экрана деталей; сортировка по имени; опционально фильтр по `profiles.object_ids` |
| `employeeAvatarControllerProvider` | [`employee_avatar_controller.dart`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart) | Загрузка / удаление / скачивание фото; уведомления через `AppSnackBar` |
| `employeeApplicationsProvider(employeeId)` | [`employee_applications_provider.dart`](../../lib/features/employees/presentation/providers/employee_applications_provider.dart) | Список заявлений, upload/delete/download сканов; autoDispose family |
| `employeeApplicationBusyIdsProvider(employeeId)` | там же | Индикация загрузки при скачивании / просмотре |

### Жизненный цикл экранов (Riverpod / Web)

Правила, применённые с 29.05.2026 для стабильности **Flutter Web**:

| Правило | Реализация |
|---------|------------|
| Не вызывать `setState` / менять провайдеры из `build` через `addPostFrameCallback` | Фильтры и права — `ref.listen` в `build` (срабатывает только при смене провайдера) |
| Не обновлять глобальный `employeeProvider` после `dispose` экрана | Убран `Future(() => setSearchQuery(''))` в `dispose`; поиск сбрасывается при **открытии** списка (table / mobile) |
| Загрузка данных при входе | Один `addPostFrameCallback` в `initState`: `setSearchQuery('')` (только списки), `getEmployees` / `getEmployee`, `objectProvider.loadObjects()` |
| Синхронизация карточки с списком | `ref.listen(employeeProvider)` в модалке — обновление локального `_employee` при изменении в notifier |

Типичная причина ошибки `Trying to render a disposed EngineFlutterView`: асинхронное завершение `loadObjects()` / перерисовка **после** ухода с маршрута; исправление — не планировать кадры и не трогать провайдеры, когда виджет уже снят с дерева.

### Вспомогательный UI вне фичи

- [`employee_ui_utils.dart`](../../lib/core/utils/employee_ui_utils.dart) — общие подписи/статусы для списков и таблицы

---

## Слой Domain / Data

### Domain

| Файл | Содержимое |
|------|------------|
| [`employee.dart`](../../lib/domain/entities/employee.dart) | Сущность сотрудника, enum `EmploymentType`, `EmployeeStatus` (отдельно от `EmployeeState` в Riverpod) |
| [`employee_application.dart`](../../lib/domain/entities/employee_application.dart) | Заявление сотрудника; enum `EmployeeApplicationType` (`vacation`, `unpaidLeave`) |
| [`employee_rate.dart`](../../lib/domain/entities/employee_rate.dart) | Сущность ставки с периодом |
| [`employee_repository.dart`](../../lib/domain/repositories/employee_repository.dart) | Контракт репозитория сотрудников |
| [`employee_application_repository.dart`](../../lib/domain/repositories/employee_application_repository.dart) | Контракт заявлений: список, upload scan, download, delete |
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
| [`employee_application_model.dart`](../../lib/data/models/employee_application_model.dart) | DTO `employee_applications`; join `creator:profiles(full_name)` |
| [`employee_rate_model.dart`](../../lib/data/models/employee_rate_model.dart) | DTO `employee_rates` |
| [`employee_data_source.dart`](../../lib/data/datasources/employee_data_source.dart) | Supabase: CRUD, `getResponsibleEmployees`, `can_be_responsible`, пакетная мапа флага, обогащение текущей ставкой |
| [`supabase_employee_application_data_source.dart`](../../lib/data/datasources/supabase_employee_application_data_source.dart) | PostgREST + Storage `employee_applications`; `uploadBinary`; rollback Storage при ошибке insert |
| [`employee_rate_data_source.dart`](../../lib/data/datasources/employee_rate_data_source.dart) | История ставок |
| [`employee_repository_impl.dart`](../../lib/data/repositories/employee_repository_impl.dart) | Маппинг модель ↔ сущность |
| [`employee_application_repository_impl.dart`](../../lib/data/repositories/employee_application_repository_impl.dart) | Репозиторий заявлений; `created_by` = текущий `auth.uid()` |
| [`employee_rate_repository_impl.dart`](../../lib/data/repositories/employee_rate_repository_impl.dart) | Репозиторий ставок |

### Состояние (Riverpod)

| Файл | Назначение |
|------|------------|
| [`employee_state.dart`](../../lib/presentation/state/employee_state.dart) | `EmployeeNotifier`: список, выбранный сотрудник, кэш деталей, `searchQuery`, `canBeResponsibleMap`, локальные обновления списка, `getEmployees(includeResponsibilityMap: ...)`, сохранение ставки при `updateEmployee`, **удаление фото** при `deleteEmployee` |

Провайдеры datasources / repositories / use cases: [`lib/core/di/providers.dart`](../../lib/core/di/providers.dart) (`employeeDataSourceProvider`, `employeeRateDataSourceProvider`, `employeeApplicationDataSourceProvider`, `employeeApplicationRepositoryProvider`, …).

### Фото (Storage)

[`PhotoService`](../../lib/core/services/photo_service.dart): `entity: 'employee'`, bucket `employees`, путь `{employee_id}/avatar_{timestamp}.{ext}`.

| Платформа | Выбор | Загрузка |
|-----------|--------|----------|
| **Web** | `pickImageBytes` | `uploadPhotoBytes` |
| **iOS / Android / desktop** | `pickImage` → `File` | `uploadPhoto` (внутри — `readAsBytes` + `uploadPhotoBytes`) |

Точка входа в UI: [`EmployeeAvatarController`](../../lib/features/employees/presentation/providers/employee_avatar_controller.dart) (контекстное меню в [`employee_details_modal.dart`](../../lib/features/employees/presentation/widgets/employee_details_modal.dart), mobile sheet). Удаление — `deletePhotoByUrl` + `deletePhoto`; при `deleteEmployee` в notifier — очистка Storage.

> **Не использовать** `File` / `pickImage` на Web: `dart:io` недоступен, ошибка `Unsupported operation: _Namespace`.

---

## Дерево файлов

```text
lib/
├── core/
│   ├── di/providers.dart                    # employees, employee_rates, employee_applications
│   ├── services/photo_service.dart          # фото сотрудника (entity: employee)
│   └── utils/employee_ui_utils.dart
├── data/
│   ├── datasources/
│   │   ├── employee_data_source.dart
│   │   ├── employee_rate_data_source.dart
│   │   ├── employee_application_data_source.dart
│   │   └── supabase_employee_application_data_source.dart
│   ├── models/
│   │   ├── employee_model.dart
│   │   ├── employee_rate_model.dart
│   │   └── employee_application_model.dart
│   └── repositories/
│       ├── employee_repository_impl.dart
│       ├── employee_rate_repository_impl.dart
│       └── employee_application_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── employee.dart
│   │   ├── employee_rate.dart
│   │   └── employee_application.dart
│   ├── repositories/
│   │   ├── employee_repository.dart
│   │   ├── employee_rate_repository.dart
│   │   └── employee_application_repository.dart
│   └── usecases/
│       ├── employee/
│       └── employee_rate/
├── features/employees/
│   └── presentation/
│       ├── providers/
│       │   ├── employee_avatar_controller.dart
│       │   ├── employee_applications_provider.dart
│       │   └── employees_module_objects_provider.dart
│       ├── screens/
│       │   ├── employees_table_screen.dart
│       │   ├── employees_list_mobile_screen.dart
│       │   └── employee_details_screen.dart
│       ├── services/
│       │   └── employee_server_excel_export_service.dart
│       ├── utils/
│       │   ├── employees_layout_utils.dart
│       │   ├── employee_application_upload_flow.dart
│       │   └── employee_application_download_flow.dart
│       └── widgets/
│           ├── employee_applications_section.dart
│           ├── employee_application_forms.dart
│           ├── employee_application_scan_preview.dart
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

**RLS:** ✅ Включён.

**Политики (актуально на проде, `check_permission`):**

| Имя | Операция | Суть |
|-----|----------|------|
| `employees_select` | SELECT | `employees.read` **или** своя карточка (`profiles.employee_id`) **или** пересечение `object_ids` с профилем |
| `employees_insert` | INSERT | `employees.create` |
| `employees_update` | UPDATE | `employees.update` |
| `employees_delete` | DELETE | `employees.delete` |

Удалены обходные политики «участник компании» и legacy `profiles.role = 'admin'` ([`20260529180000_tighten_employees_card_rls.sql`](../../supabase/migrations/20260529180000_tighten_employees_card_rls.sql)). Исторические имена — в [`20251015_fix_rls_performance_auth_initplan.sql`](../../supabase/migrations/20251015_fix_rls_performance_auth_initplan.sql) (заменены на проде).

> **RBAC:** UI ([`PermissionService`](../../lib/features/roles/application/permission_service.dart)) и PostgREST согласованы через `check_permission(uid(), 'employees', …)`.

**Индексы** (упоминания в миграциях):

- `employees_pkey` (подразумевается PK)
- `idx_employees_status`, `idx_employees_position` — из [`20240101000002_employees_migration.sql`](../../supabase/migrations/20240101000002_employees_migration.sql)
- `idx_employees_name` — **удалён** в [`20251015_optimize_indexes.sql`](../../supabase/migrations/20251015_optimize_indexes.sql)
- `idx_employees_company_id`, `idx_employees_company_last_name` — из [`20260416120000_employees_company_id_indexes.sql`](../../supabase/migrations/20260416120000_employees_company_id_indexes.sql) (покрытие фильтра `company_id` и `ORDER BY last_name`)

#### Триггеры (`employees`)

В отслеживаемых миграциях репозитория **триггеров на таблице `public.employees` не объявлено**.

#### Функции (SQL), использующие `employees`

Таблица читается и джойнится вне модуля, в первую очередь в **FOT** и отчётах, например (имена из миграций; не исчерпывающий список):

- `calculate_employee_balances()` — баланс к выплате по сотрудникам
- функции расчёта зарплаты за месяц / срезы payroll (используют `employees`, `employee_rates`, `work_hours`, `employee_attendance`)
- `get_payroll_report_data` и связанные RPC в миграциях ФОТ
- `get_month_employees_summary` — агрегат по числу сотрудников в сменах за месяц

**Собственные RPC модуля:**

- `get_employee_positions(p_company_id uuid) RETURNS TABLE (position_name text)` — уникальные должности сотрудников активной компании (SECURITY INVOKER, RLS employees применяется). Вызывается из [`SupabaseEmployeeDataSource.getPositions`](../../lib/data/datasources/employee_data_source.dart) и далее из форм добавления/редактирования. Миграция: [`20260416120500_get_employee_positions_rpc.sql`](../../supabase/migrations/20260416120500_get_employee_positions_rpc.sql).

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

**Политики (актуально на проде):**

| Имя | Операция | Суть |
|-----|----------|------|
| `employee_rates_select` | SELECT | `payroll.read` **или** ставки своего `employee_id` из `profiles` |
| `employee_rates_insert` | INSERT | `payroll.create` |
| `employee_rates_update` | UPDATE | `payroll.update` |
| `employee_rates_delete` | DELETE | `payroll.delete` |
| `Users can view employee rates of their companies` | SELECT | `company_id IN get_my_company_ids()` (дополнительный путь чтения в компании) |

Кнопка «+» ставки в карточке сотрудника скрыта без `employees.update`; запись в `employee_rates` на сервере требует прав модуля **payroll** (см. [`AddEmployeeRateDialog`](../../lib/features/employees/presentation/widgets/add_employee_rate_dialog.dart)).

Удалена политика `Users can manage employee rates of their companies` ([`20260529180000_tighten_employees_card_rls.sql`](../../supabase/migrations/20260529180000_tighten_employees_card_rls.sql)).

**Индексы / изменения в миграциях:**

- [`20251015_optimize_indexes.sql`](../../supabase/migrations/20251015_optimize_indexes.sql): `CREATE INDEX IF NOT EXISTS idx_employee_rates_created_by ON employee_rates(created_by)`; удалены `idx_employee_rates_employee_id`, `idx_employee_rates_active`.
- [`20260416120000_employees_company_id_indexes.sql`](../../supabase/migrations/20260416120000_employees_company_id_indexes.sql): добавлен `idx_employee_rates_company_id` — покрытие фильтра по `company_id` в массовых выборках.
- Частичный уникальный индекс `idx_employee_rates_active_unique (employee_id) WHERE valid_to IS NULL` уже присутствует в БД (гарантирует «одна активная ставка» на сотрудника).

**Инвариант «одна активная ставка»:** в коде и экспорте используется фильтр `valid_to IS NULL`. Явный **partial unique** в отслеживаемых миграциях не найден — при необходимости жёсткой уникальности её стоит добавить отдельной миграцией на проде.

#### Триггеры (`employee_rates`)

В отслеживаемых миграциях репозитория **триггеров на таблице `public.employee_rates` не объявлено**.

#### Функции (SQL), использующие `employee_rates`

Те же зоны, что и для `employees`: расчёты ФОТ, балансы, отчёты по часам и ставкам (`calculate_employee_balances`, payroll-RPC, `get_payroll_report_data` и др. в `supabase/migrations/`).

### Таблица `employee_applications`

**Назначение:** метаданные заявления сотрудника (тип, период) и ссылка на **подписанный скан** в Storage. Запись создаётся **при загрузке скана** (PDF не сохраняется на сервере — только локальная генерация через `ProfilePdfGenerator`).

**Колонки (audit prod, [`EmployeeApplicationModel`](../../lib/data/models/employee_application_model.dart)):**

| Колонка | Тип | Примечание |
|---------|-----|------------|
| `id` | UUID | PK |
| `company_id` | UUID | FK → `companies` |
| `employee_id` | UUID | FK → `employees` ON DELETE CASCADE |
| `application_type` | TEXT | `vacation` \| `unpaid_leave` \| `resignation` |
| `start_date` | DATE | начало периода |
| `end_date` | DATE | nullable; для отпуска заполняется |
| `duration_days` | INTEGER | > 0 |
| `scan_name` | TEXT | имя файла для UI |
| `scan_path` | TEXT | путь в bucket `employee_applications` |
| `scan_size` | BIGINT | байты |
| `scan_type` | TEXT | MIME, default `application/pdf` |
| `created_by` | UUID | FK → `profiles` |
| `created_at`, `updated_at` | TIMESTAMPTZ | |

**RLS:** ✅ Включён.

**Политики (актуально на проде):**

| Имя | Операция | Суть |
|-----|----------|------|
| `employee_applications_select` | SELECT | `company_id IN get_my_company_ids()` AND (`employees.read` OR свой `employee_id` из `profiles`) |
| `employee_applications_insert` | INSERT | `company_id IN get_my_company_ids()` AND `employee_id` принадлежит той же `company_id` AND (`employees.update` OR свой `employee_id`) |
| `employee_applications_delete` | DELETE | `company_id IN get_my_company_ids()` AND `employees.update` |

UPDATE-политики **нет** — записи не редактируются, только удаление HR.

**Индексы** ([`20260628120000_employee_applications.sql`](../../supabase/migrations/20260628120000_employee_applications.sql)):

- `idx_employee_applications_employee_id`
- `idx_employee_applications_company_employee` — `(company_id, employee_id, created_at DESC)`

#### Триггеры (`employee_applications`)

В отслеживаемых миграциях **триггеров не объявлено**.

#### Storage path

Bucket **`employee_applications`** (private, `public: false`):

```text
{company_id}/{employee_id}/{application_type}/{timestamp}_{safeName}
```

Политики Storage ([`20260628120100_employee_applications_rls_hardening.sql`](../../supabase/migrations/20260628120100_employee_applications_rls_hardening.sql)): SELECT/INSERT — `employees.read`/`update` или свой каталог `{employee_id}`; сегмент `{company_id}` должен быть в `get_my_company_ids()`; DELETE — `employees.update`.

### Таблица `business_trip_rates` (суточные в карточке)

**Назначение:** ставки суточных по объекту / сотруднику; UI в модуле Employees, доменная схема — **FOT** (см. [`fot_module.md`](../fot/fot_module.md)).

**RLS:** ✅ Включён.

**Политики (актуально на проде, [`20260529180000_tighten_employees_card_rls.sql`](../../supabase/migrations/20260529180000_tighten_employees_card_rls.sql)):**

| Имя | Операция | Суть |
|-----|----------|------|
| `business_trip_rates_select` | SELECT | `company_id IN get_my_company_ids()` AND (`employees.read` OR `payroll.read`) |
| `business_trip_rates_insert` | INSERT | `company_id IN get_my_company_ids()` AND `employees.update` |
| `business_trip_rates_update` | UPDATE | то же для USING / WITH CHECK |
| `business_trip_rates_delete` | DELETE | `company_id IN get_my_company_ids()` AND `employees.update` |

Удалены политики «любой authenticated» и «manage trip rates of their companies» без `check_permission`.

### Связанные таблицы (кратко)

| Таблица | RLS в миграциях | Комментарий |
|---------|-----------------|-------------|
| `profiles` | да | `employee_id`, `object_ids` |
| `employee_attendance` | да | FK на `employees` — [`20251005000000_create_employee_attendance.sql`](../../supabase/migrations/20251005000000_create_employee_attendance.sql) |
| `work_hours` | да | `employee_id` |
| `work_plan_blocks` | да | `responsible_id`, `worker_ids`; индекс `idx_work_plan_blocks_responsible_id` в [`20251015_optimize_indexes.sql`](../../supabase/migrations/20251015_optimize_indexes.sql) |

### Storage

| Bucket / политика | Суть |
|-------------------|------|
| `employees` (аватар) | [`20260509000000_add_employees_bucket_policies.sql`](../../supabase/migrations/20260509000000_add_employees_bucket_policies.sql): UPDATE/DELETE при `employees.update`; публичный URL |
| `employee_applications` | Приватный bucket подписанных сканов заявлений; [`20260628120000_employee_applications.sql`](../../supabase/migrations/20260628120000_employee_applications.sql) + hardening [`20260628120100`](../../supabase/migrations/20260628120100_employee_applications_rls_hardening.sql) |
| Исторические политики | [`20240101000005_storage_policy_migration.sql`](../../supabase/migrations/20240101000005_storage_policy_migration.sql) — bucket `employees` |

---

## Бизнес-логика

### Формулы и инварианты

- **Текущая почасовая ставка в UI:** для сотрудника `e` выбираются строки `employee_rates` с `employee_id = e.id` и `valid_to IS NULL`; значение `hourly_rate` попадает в `Employee.currentHourlyRate` / `EmployeeModel.currentHourlyRate` (поле не колонка `employees` в API-модели).
- **Список ответственных по объекту** (`getResponsibleEmployees`): `status = 'working'` AND `can_be_responsible = true` AND `object_ids` содержит `objectId` (семантика «содержит» — как в PostgREST / клиентском фильтре).
- **Поиск в списке (client-side):** совпадение подстроки в нижнем регистре с конкатенацией ФИО, `position`, `phone` (`EmployeeState.filteredEmployees`).
- **Сохранение ставки при правке анкеты:** после `updateEmployee` в notifier выполняется `copyWith(currentHourlyRate: result.currentHourlyRate ?? employee.currentHourlyRate)`, чтобы не потерять ставку, не пришедшую из одного ответа `employees`.

Денежные расчёты начислений (часы × ставка за период, командировочные, премии) **не входят в модуль Employees** — см. модуль **FOT** и SQL-функции в миграциях.

1. После первого кадра экраны **списка** (`EmployeesTableScreen`, `EmployeesListMobileScreen`) сбрасывают `searchQuery` в `''`, вызывают `getEmployees()` и `objectProvider.notifier.loadObjects()`. Экран деталей по URL — только `getEmployee(id)` и `loadObjects()` (поиск списка не трогается).
2. `EmployeeNotifier.getEmployees()` не перезагружает список, если уже `success` и список не пуст; параметр `includeResponsibilityMap` по умолчанию `false` — отдельный запрос за картой `can_be_responsible` не выполняется (поле в UI не потребляется; при смене флага мапа обновляется точечно).
3. `SupabaseEmployeeDataSource.getEmployees()` читает `employees` по `company_id`, затем одним запросом — текущие ставки (`employee_rates`, `valid_to IS NULL`) и обогащает `currentHourlyRate`.
4. Поиск: `EmployeeState.filteredEmployees` (ФИО, должность, телефон).
5. Таблица: дополнительно фильтр по статусу, объекту, сортировка по фамилии, счётчики по статусам — на клиенте. Если выбранный объект исчез из picklist (смена прав / профиля), фильтр сбрасывается в «Все объекты» через `ref.listen(employeesModuleObjectsProvider)`.
6. Inline: `Employee.copyWith` + `updateEmployee` для `status` и `object_ids`.
7. `can_be_responsible`: отдельные вызовы datasource + обновление `canBeResponsibleMap` (не через полную перезагрузку карточки из одного JSON).
8. Ответственный по объекту для планов: `getResponsibleEmployees` — `status = working`, `can_be_responsible = true`, объект в `object_ids`.
9. При удалении сотрудника — удаление файла фото в Storage и строки в БД.
10. Экспорт: те же фильтры, что UI, плюс проверка членства в `company_members` на Edge.
11. **Карточка сотрудника:** `PermissionService.can('employees', 'update')` управляет видимостью редактирования; при отсутствии права PostgREST отклоняет UPDATE/INSERT суточных и сотрудника даже при обходе UI.
12. **Аватар:** после выбора изображения — ветка `kIsWeb` в `EmployeeAvatarController`; URL из Storage пишется в `employees.photo_url` через `updateEmployee`.
13. **Уведомления пользователю:** только `AppSnackBar.show(context:, message:, kind:)` — без `SnackBarUtils` и Material `SnackBar` в модуле.
14. **Индикаторы загрузки:** единый стиль **`CupertinoActivityIndicator`** в presentation-слое; Material `CircularProgressIndicator` в модуле не используется.
15. **Заявления (вкладка карточки):**
    1. HR выбирает тип (отпуск / БС / **увольнение**) → форма с датами → **«Просмотр и печать»** (`PdfPreviewScreen` + `ProfilePdfGenerator`; шапка PDF — **ООО «ГТ Инжиниринг»**).
    2. После подписи на бумаге — **«Загрузить подписанный скан»** (`file_selector`: pdf, jpg, png) → `uploadBinary` в Storage → INSERT в `employee_applications`.
    3. **Список на вкладке** ([`_ApplicationListTile`](../../lib/features/employees/presentation/widgets/employee_applications_section.dart)):
       - строка 1: «Отпуск без содержания на 3 дня с 29.06.2026 по 01.07.2026» (склонение «день/дня/дней»);
       - строка 2: «Иванов И. · 28.06.2026 22:12» (`createdByName` из join `profiles`, `formatRuDateTime`);
       - действия: `IconButton` просмотр / скачивание / удаление (без текстовых `GTSecondaryButton`);
       - `scan_name` / `scan_size` в UI списка не показываются.
    4. Удаление — только при `employees.update`; каскад: строка БД + файл Storage.
    5. При ошибке INSERT после upload — best-effort удаление объекта из Storage ([`SupabaseEmployeeApplicationDataSource`](../../lib/data/datasources/supabase_employee_application_data_source.dart)).

---

## Интеграции

### UI / Router / RBAC

- [`app_router.dart`](../../lib/core/common/app_router.dart): `/employees`, детали, `_canViewEmployee` для «своей» карточки
- [`PermissionService`](../../lib/features/roles/application/permission_service.dart): `employees` → `read`, `create`, `update`, `delete`, `export`; карточка и список — см. раздел **RBAC в карточке сотрудника**
- Модуль в матрице ролей: код `employees` (единый, без `employees_table`; миграция [`20260411140000_remove_employees_table_rbac_module.sql`](../../supabase/migrations/20260411140000_remove_employees_table_rbac_module.sql))

### Объекты

- [`employeesModuleObjectsProvider`](../../lib/features/employees/presentation/providers/employees_module_objects_provider.dart) — единый picklist для UI модуля (источник — `objectProvider`, RLS `objects_select` с веткой `employees.read` / `create` / `update`)
- `objectProvider.notifier.loadObjects()` при входе на экраны списка и деталей

### Works / Work Plans

- `work_hours.employee_id`
- `work_plan_blocks.responsible_id`, `worker_ids`
- `work_plans.responsible_id`

### Timesheet и FOT

- справочник сотрудников и ставок для табеля и расчётов (функции вроде `calculate_employee_balances`, `get_payroll_report_data` и др. в миграциях ФОТ)

### Profile (заявления)

- Модуль **Profile** содержит self-service заявления ([`ApplicationsScreen`](../../lib/features/profile/presentation/screens/applications_screen.dart)) для **текущего пользователя** (`Profile`).
- Карточка **Employees** переиспользует PDF-шаблоны ([`ProfilePdfGenerator`](../../lib/features/profile/utils/profile_pdf_generator.dart), [`application_form_widgets`](../../lib/features/profile/presentation/widgets/application_form_widgets.dart)) для **любого** сотрудника по `Employee.fullName` — сценарий HR.
- **Работодатель в PDF:** `ООО «ГТ Инжиниринг»` (`ProfilePdfGenerator._employerOrganization`); адресат — «Генеральному директору … Тельнову Д.А.» (общий шаблон Profile + Employees).

### Edge Functions

| Функция | Назначение |
|---------|------------|
| **`export-employees`** | POST: `companyId`, `status`, `objectFilter`, `searchQuery`; **service role** + `ensureCompanyAccess` (JWT + `company_members`); ExcelJS; отдача base64 XLSX |

Клиент: [`EmployeeServerExcelExportService`](../../lib/features/employees/presentation/services/employee_server_excel_export_service.dart).

---

## Roadmap

### Реализовано

- Табличный и мобильный списки, адаптивный выбор раскладки
- Inline статус / объекты, фильтры, экспорт, аватар, детали и редактирование (с RBAC в UI и RLS)
- Кэш деталей, `canBeResponsibleMap`, сохранение ставки при обновлении анкеты
- Серверный Excel через `export-employees`
- Read-only карточка: скрытие edit-контролов и `check_permission` на `employees` / `business_trip_rates`
- Picklist объектов без `objects.read`; корректный жизненный цикл экранов на Flutter Web (`ref.listen`, без отложенного `dispose`)
- Загрузка фото сотрудника на Web (`pickImageBytes` / `uploadPhotoBytes`)
- Единый `AppSnackBar` во всём presentation-слое модуля
- Единые индикаторы загрузки (`CupertinoActivityIndicator`) в списках, карточке и формах
- Desktop-карточка: кнопка «Редактировать» вместо иконки карандаша в секции «Личные данные»
- **Вкладка «Заявления»:** PDF (отпуск, БС), загрузка сканов, компактный список (icon actions), просмотр/скачивание; таблица `employee_applications` + bucket Storage
- **UX карточки:** `IndexedStack` для вкладок без смены высоты окна; компактный переключатель «Обзор» / «Заявления»
- **PDF:** работодатель «ООО «ГТ Инжиниринг»» в шапке заявлений

### Известные баги (приоритет)

| Приоритет | Описание |
|-----------|----------|
| 🟡 | **`export-employees`:** проверяется только членство в `company_members`, не `employees.export` (кнопка в UI скрыта без права). |
| 🟢 | Обход RLS «участник компании может менять employees» и слабые политики `business_trip_rates` — исправлено 29.05.2026. |
| 🟢 | **`EngineFlutterView disposed` на web** при быстром уходе с «Сотрудников» после подгрузки объектов — исправлено 29.05.2026 (жизненный цикл экранов). |
| 🟢 | **Загрузка фото на Web** (`Unsupported operation: _Namespace`) — исправлено 29.05.2026 (bytes вместо `File`). |
| 🟢 | **Два стиля снекбаров** в модуле (`SnackBarUtils` + `AppSnackBar`) — унифицировано 29.05.2026. |
| 🟢 | **Разные индикаторы загрузки** (Material vs Cupertino) — унифицировано 29.05.2026 (`CupertinoActivityIndicator` в модуле). |

При появлении регрессий строки выше заменяются конкретикой: 🔴 критичный, 🟡 средний, 🟢 низкий / косметика.

### Ограничения

- Поиск и фильтры списка без server-side pagination
- `object_ids` как `text[]` в БД
- Добавление **ставки** в UI карточки требует прав **payroll** на уровне БД, хотя кнопка привязана к `employees.update`
- Схема `employee_rates` и часть индексов не воспроизводятся из одного `CREATE` в репозитории
- **Заявления:** типы «отпуск», «отпуск без содержания», **«увольнение»**; PDF на сервер не сохраняется; workflow согласования не реализован
- Вкладки **«Документы»** (файлы) и **«Доп. информация»** (журнал записей) — запланированы, не реализованы

### Возможные шаги

- Вкладки «Документы» и «Доп. информация» в карточке
- Дополнительные типы заявлений (перевод, …)
- Workflow согласования заявлений
- Серверная пагинация и фильтрация PostgREST
- Проверка `employees.export` в Edge Function `export-employees`
- Явный partial unique index на «активную» ставку в миграции
- Audit trail изменений карточки и ставок
