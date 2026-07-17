# Модуль ФОТ (Фонд оплаты труда, Payroll)

**Дата актуализации:** 17 июля 2026 года
**Статус:** Актуально (Clean Architecture, Cumulative FIFO Balance, Parallel Batch Processing, Unified Reporting, Hardened Rate Periods, Excel Import/Export Payouts, Timesheet-aligned UI Shell, Stale-while-revalidate Table UX)

> **Изменения 17.07.2026 (правка 3, клик по ФИО → карточка сотрудника):**
> - В таблице ФОТ клик по ФИО сотрудника открывает **карточку сотрудника**: на desktop — `EmployeeDetailsModal`, на mobile — `EmployeesMobileEmployeeDetailsSheet` (как в модуле «Табель»).
> - Доступ по праву `employees` / `read` (`permissionServiceProvider`); при отсутствии права имя отображается как обычный текст без тапа.
> - Подсказка `Tooltip` «Открыть карточку сотрудника» при наведении.
> - Контекстное меню по правому клику сохранено (правка 2).

> **Изменения 17.07.2026 (правка 2, UX контекстного меню):**
> - Контекстное меню строки ФОТ (Премия / Штраф / Выплата / Детали) теперь открывается **только правой кнопкой мыши** (`onRowSecondaryTapDown`).
> - Левый клик по строке больше не вызывает меню (`onRowTapDown` удалён в `payroll_table_view.dart`).
> - Документация `docs/fot/ui_structure.md` и `docs/fot/fot_module.md` актуализирована.

> **Изменения 17.07.2026 (документация и чистка кода):**
> - Актуализирован `docs/fot/ui_structure.md`: удалены ссылки на несуществующие `payroll_search_action.dart` / `payroll_filter_helpers.dart`; таблица миграции на актуальные виджеты и утилиты.
> - Удалён неиспользуемый код: `payrollDataReadyProvider`, `cachedEmployeeBalanceProvider`, `getAllBonuses` / `getAllPenalties`, `buildSimpleBalanceText`, `hasActiveFilters`, `resetFilters`. `employeeBalanceAtDateProvider` сохранён как заготовка.
> - `docs/fot/calculations.md`: исправлено описание провайдеров баланса.

> **Изменения 16.07.2026 (инвалидация кэша и UX пересчёта):**
> - **Централизованная инвалидация после мутаций** в `payroll_providers.dart`:
>   - `invalidatePayrollFotTableDependents` — сброс `filteredPayrollsProvider`, `payoutsByEmployeeAndMonthFIFOProvider`, `employeeAggregatedBalanceProvider` (премии, штрафы, любое изменение начислений/FIFO).
>   - `invalidatePayrollPayoutDependents` — дополнительно `allPayoutsProvider`, `payrollPayoutsByFilterProvider`, `filteredPayrollPayoutsProvider` + вызов `invalidatePayrollFotTableDependents` (создание/правка/удаление выплат, импорт Excel).
> - **Точки вызова:** `PayrollTransactionFormModal`, `PayrollBonusTableView`, `PayrollPenaltyTableView`, `PayrollPayoutFormModal`, `PayrollPayoutAmountModal`, `PayrollPayoutTableView`, `savePayrollPayoutBatch`.
> - **Stale-while-revalidate на вкладке ФОТ:** при фоновом пересчёте таблица **не скрывается**; `PayrollListScreen` — `skipLoadingOnReload: true` для `filteredPayrollsProvider`; `PayrollTableWidget` держит предыдущие данные FIFO.
> - **Индикатор пересчёта:** `PayrollRefreshingAmount` (`payroll_refreshing_amount.dart`) — вместо сумм в колонках «К выплате», «Выплаты», «Остаток», «Баланс» (и в итогах) показывается `CupertinoActivityIndicator`; на mobile — в `PayrollCard` и нижней панели `PayrollMobileView`.
> - **Полноэкранный спиннер** «Расчет выплат и балансов...» — только при **первой** загрузке экрана (`PayrollListScreen` → `filteredPayrollsProvider` без данных).

> **Изменения 16.07.2026 (UI, Presentation):**
> - **Единая панель фильтров** `PayrollFiltersToolbar` внутри `MobileAtmosphereMainSurface`: одна строка — вкладки (ФОТ / Премии / Штрафы / Выплаты), период, поиск, объекты, действия справа. Паттерн выровнен с модулем «Табель» (`TimesheetCompactMonthSwitcher`, `TimesheetObjectsBarDropdown`, `EmployeesLayoutUtils`).
> - **Шапка экрана** `PayrollListScreen`: статичный заголовок «Фонд оплаты труда»; поиск на телефоне — `PayrollMobileSearchField`; на desktop — `PayrollToolbarSearch` в панели.
> - **Общая геометрия** `PayrollToolbarMetrics` (высота `34`, радиус `18`): вкладки, фильтр статуса, кнопки действий, dropdown объектов.
> - **Дедупликация:** панели фильтров удалены из `PayrollTableWidget`, `PayrollBonusTableWidget`, `PayrollPenaltyTableWidget`, `PayrollPayoutTableWidget`.
> - **Удалены устаревшие виджеты:** `GTMonthPicker`, `GTObjectPicker`, `PayrollSearchAction`, `PayrollFilterHelpers`, `payrollSearchVisibleProvider`.
> - **Новые файлы:** `payroll_filters_toolbar.dart`, `payroll_objects_bar_dropdown.dart`, `payroll_mobile_search_field.dart`, `payroll_tab_toolbar_actions.dart`, `payroll_toolbar_metrics.dart`, `payroll_name_search_filters.dart`.
> - Документация UI: `docs/fot/ui_structure.md`.

> **Изменения 09.07.2026:**
> - **Экспорт ведомости ФОТ в Excel** (`export-payroll`): выгрузка приведена к составу таблицы на экране. Дополнительно к строкам RPC `calculate_payroll_for_month` в файл попадают сотрудники **без начислений за месяц**, если они устроены до конца периода и (**ещё в штате** или имеют **ненулевой FIFO-баланс** на конец месяца) — логика `mergeZeroActivityRows` / `shouldIncludeZeroActivityEmployee` зеркалит `_groupPayrolls` в `payroll_table_view.dart`.
> - Режим **«Только выбранные»** (`PayrollExportAction` + `employeeIds` в теле запроса): все отмеченные чекбоксом ID включаются в Excel, в т.ч. «нулевые» строки.
> - Для дополнительных строк: ФИО и статус из `employees`, текущая ставка из `employee_rates` (активный период на дату экспорта), начисления = 0, выплаты и баланс — из той же FIFO-цепочки, что в UI.
> - Клиентское приложение **не менялось**; правка только в Edge Function `supabase/functions/export-payroll/index.ts`.

> **Изменения 26.05.2026:**
> - **Импорт выплат из Excel** на вкладке «Выплаты»: загрузка банковской ведомости `.xlsx` без сохранения файла (парсинг только в памяти на клиенте).
> - Предпросмотр со статусами сопоставления ФИО: `Найден` / `Не найден` / `Неоднозначно`; при расхождениях — предупреждение и импорт только найденных строк (с подтверждением).
> - Сопоставление по справочнику `employees` (включая уволенных); формат ФИО в файле: **Фамилия Имя Отчество**; регистр и «ё» не учитываются.
> - Пакетное создание записей в `payroll_payout` через `savePayrollPayoutBatch` (те же поля, что при ручном вводе).
> - Юнит-тесты матчинга ФИО: `test/features/fot/payroll_payout_excel_import_service_test.dart`.

> **Изменения 19.04.2026:**
> - Восстановлена корректность данных в `employee_rates` (исправлен дубликат для одного сотрудника).
> - Очищен реестр RPC: удалены неиспользуемые/небезопасные функции (`get_employee_bonuses`, `calculate_base_salary_all_time`, `calculate_business_trip_all_time`, `get_payroll_report_data`, старая перегрузка `calculate_payroll_for_month` без `company_id`).
> - Унифицирован приоритет суточных (индивидуальная ставка → общая по объекту) во всех RPC: `calculate_payroll_for_month`, `calculate_employee_balances`, `calculate_employee_balances_before_date`, `calculate_employee_balances_at_date`, `calculate_single_employee_balance`. Новое правило: индивидуальная ставка применяется только если выполнен её `minimum_hours`, иначе — fallback на общую ставку при выполнении её `minimum_hours`.
> - Добавлен `company_id`-фильтр в `calculate_employee_balances_at_date` (превентивно для мультикомпании).
> - Добавлены индексы `(company_id, date)` для `payroll_bonus`/`payroll_penalty`/`payroll_payout` и `(employee_id, company_id, valid_from DESC)` для `employee_rates`.
> - **Защита периодов ставок:** EXCLUDE-constraint на `employee_rates` (`employee_rates_no_overlap`) и `business_trip_rates` (`business_trip_rates_no_overlap`) запрещают пересечения периодов на уровне БД (через расширение `btree_gist`). Старый частичный индекс `idx_employee_rates_active_unique` удалён как избыточный и не учитывавший `company_id`.
> - **UI-форма «Изменение ставки» сотрудника** теперь до сохранения находит все пересекающиеся ставки (включая закрытые в будущем) и показывает диалог подтверждения с описанием действия для каждой (закрыта датой / удалена / заменена). Вся логика разрешения пересечений сосредоточена в `EmployeeRateRepositoryImpl`; data source выполняет «чистый» INSERT.
> - **Логирование ошибок:** в Dart-провайдерах ФОТ (`payroll_providers.dart`, `balance_providers.dart`, `payroll_list_screen.dart`) `catch`-блоки больше не молча проглатывают исключения — пишут в `dart:developer` со стек-трейсом.

---

## 📂 Описание модуля
Модуль **ФОТ** отвечает за динамический расчет заработной платы сотрудников. Он объединяет данные об отработанных часах, ставках, премиях, штрафах и командировочных выплатах.

**Ключевые функции:**
- **Cumulative FIFO Balance:** Реализована продвинутая логика взаиморасчетов. Выплаты закрывают задолженность по методу FIFO (First In, First Out), начиная с самых ранних долгов. Баланс каждого месяца является кумулятивным: `Баланс(М) = Баланс(М-1) + Начислено(М) - Выплачено_FIFO(М)`.
- **Parallel Batch Processing:** Оптимизирован расчет годовых показателей. Запросы к PostgreSQL RPC для всех 12 месяцев года выполняются параллельно через `Future.wait`, что сокращает время загрузки в 10-12 раз.
- **Hybrid-расчет:** Высокопроизводительный расчет на стороне БД (PostgreSQL RPC) с автоматическим переключением на клиентский расчет (Dart) при сбоях.
- **Unified Reporting (Новое):** Годовой PDF-отчет полностью синхронизирован с основной таблицей ФОТ. И в таблице, и в PDF используются одни и те же данные из провайдера FIFO, что гарантирует идентичность цифр («один источник правды»).
- **Mobile-First UX (Timesheet-aligned Shell):** Адаптивное переключение между табличным видом (Desktop/Tablet) и карточками (Mobile).
    - **Atmosphere UI:** `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, круглые chrome-кнопки меню и темы — как в модуле «Табель».
    - **Unified Toolbar:** `PayrollFiltersToolbar` — вкладки, период, поиск, объекты и действия в одной строке (`PayrollToolbarMetrics.height = 34`).
    - **Без дублирования периода:** месяц отображается только в `PayrollCompactMonthSwitcher`, не в заголовке экрана.
    - **Loading States (Stale-while-revalidate):** при пересчёте после премии/штрафа/выплаты таблица остаётся на экране; в денежных ячейках — `CupertinoActivityIndicator` (`PayrollRefreshingAmount`). Полный экран загрузки — только при первом открытии вкладки ФОТ.
- **Импорт выплат из Excel (26.05.2026):** Массовое создание выплат из банковской ведомости на вкладке «Выплаты». Файл не сохраняется на сервере и в Storage.
- **Экспорт ведомости в Excel:** Серверная ведомость за месяц (Edge Function `export-payroll`, ExcelJS). Состав строк синхронизирован с таблицей ФОТ, включая сотрудников без операций за месяц (см. раздел «Экспорт ведомости в Excel»).

---

## ⚠️ Важное замечание
- **Owner таблиц:** `payroll_payout`, `payroll_bonus`, `payroll_penalty`, `employee_rates` — модуль ФОТ; `employees` — модуль «Сотрудники» (используется при импорте для сопоставления ФИО).
- **Мультикомпания:** все операции фильтруются по `activeCompanyId`; RLS на `company_id`.
- **Импорт Excel:** только клиент (`file_picker` + пакет `excel`); Edge Function **не** используется. После импорта вызывается `invalidatePayrollPayoutDependents` (в т.ч. FIFO и месячный ФОТ).
- **Баланс в таблице ФОТ:** колонка «Баланс» и «Выплаты» — из `payoutsByEmployeeAndMonthFIFOProvider` (кумулятивный FIFO на конец месяца), **не** из `employeeAggregatedBalanceProvider` (баланс за всё время; используется в форме массовых выплат).

---

## 🧱 Архитектура и структура
Модуль реализован согласно принципам **Clean Architecture**.

### Слой Presentation (UI)

#### Экран и оболочка
- `lib/features/fot/presentation/screens/payroll_list_screen.dart` — корневой экран: шапка (chrome), `MobileAtmosphereMainSurface`, `IndexedStack` вкладок.
- `lib/features/fot/presentation/screens/tabs/` — обёртки вкладок: `payroll_tab_bonuses.dart`, `payroll_tab_penalties.dart`, `payroll_tab_payouts.dart`.

#### Панель фильтров (единая строка)
- `lib/features/fot/presentation/widgets/payroll_filters_toolbar.dart` — `PayrollFiltersToolbar`, `PayrollCompactMonthSwitcher`, `PayrollToolbarSearch`.
- `lib/features/fot/presentation/widgets/payroll_tab_segment.dart` — сегмент вкладок (ФОТ / Премии / Штрафы / Выплаты).
- `lib/features/fot/presentation/widgets/payroll_objects_bar_dropdown.dart` — мультивыбор объектов (`MenuAnchor`).
- `lib/features/fot/presentation/widgets/payroll_tab_toolbar_actions.dart` — правый блок: статус / «Добавить» / «Импорт».
- `lib/features/fot/presentation/widgets/payroll_toolbar_metrics.dart` — общая геометрия и `PayrollToolbarSegmentTrack` / `PayrollToolbarTextButton`.
- `lib/features/fot/presentation/widgets/payroll_mobile_search_field.dart` — поиск в шапке на телефоне.
- `lib/features/fot/presentation/widgets/payroll_employee_status_filter_segment.dart` — фильтр «Все / Работает / Уволен» на вкладке ФОТ.
- `lib/features/fot/presentation/providers/payroll_filter_providers.dart` — `payrollFilterProvider`, `payrollSearchQueryProvider`, `availableObjectsForPayrollProvider`.
- `lib/features/fot/presentation/utils/payroll_name_search_filters.dart` — фильтрация списков по ФИО.

#### Таблицы и действия
- `lib/features/fot/presentation/widgets/payroll_table_widget.dart` — обёртка вкладки ФОТ: FIFO, фильтр статуса, флаги `isPayrollsRefreshing` / `isSettlementRefreshing`.
- `lib/features/fot/presentation/widgets/payroll_table_view.dart` — основная таблица; `_groupPayrolls`; чекбоксы (`PayrollGridCheckbox`); контекстное меню по **правой кнопке мыши** (`onRowSecondaryTapDown`) → «Премия», «Штраф», «Выплата», «Детали» (PDF). Левый клик меню не вызывает.
- `lib/features/fot/presentation/widgets/payroll_refreshing_amount.dart` — `PayrollRefreshingAmount` (Cupertino-спиннер вместо суммы при пересчёте).
- `lib/features/fot/presentation/widgets/payroll_mobile_view.dart`, `payroll_card.dart` — mobile-карточки с тем же паттерном индикации.
- `lib/features/fot/presentation/widgets/payroll_export_action.dart` — экспорт в шапке: «Весь ФОТ» / «Только выбранные» → Edge Function `export-payroll` (`payroll` / `export`).
- `lib/features/fot/presentation/widgets/payroll_bonus_table_widget.dart`, `payroll_penalty_table_widget.dart`, `payroll_payout_table_widget.dart` — тела вкладок без дублирующих toolbar.
- `lib/features/fot/presentation/widgets/payroll_payout_excel_import_dialog.dart`, `payroll_payout_import_preview_dialog.dart` — импорт выплат из Excel.
- `lib/features/fot/presentation/widgets/payroll_payout_form_modal.dart`, `payroll_payout_amount_modal.dart` — ручное создание выплат.
- `lib/features/fot/presentation/providers/payroll_providers.dart` — FIFO, CRUD выплат, `invalidatePayrollFotTableDependents`, `invalidatePayrollPayoutDependents`.
- `lib/features/fot/presentation/providers/balance_providers.dart` — `employeeAggregatedBalanceProvider`, `singleEmployeeBalanceProvider`, `employeeBalanceAtDateProvider` (заготовка).

### Слой Domain
- `lib/features/fot/domain/entities/payroll_payout_import.dart` — `PayrollPayoutImportRow`, `PayrollPayoutImportParseResult`, `PayrollPayoutImportMatchStatus`.
- `lib/features/fot/domain/repositories/payroll_payout_repository.dart` — интерфейс CRUD выплат.

### Слой Data
- `lib/features/fot/data/models/payroll_payout_model.dart` — DTO выплаты (`employee_id`, `amount`, `payout_date`, `method`, `type`, `comment`).
- `lib/features/fot/data/repositories/payroll_payout_repository_impl.dart` — Supabase `payroll_payout`.

### Слой Application/Services
- `lib/features/fot/presentation/services/employee_financial_report_service.dart` — Единый сервис сбора данных за год (FIFO).
- `lib/features/fot/presentation/services/payroll_pdf_service.dart` — Генерация PDF с кумулятивным остатком.
- `lib/features/fot/presentation/services/payroll_payout_excel_import_service.dart` — Парсинг `.xlsx`, автопоиск колонок «ФИО» / «Сумма», сопоставление ФИО.
- `lib/features/fot/presentation/utils/payroll_payout_batch_save.dart` — Пакетное создание выплат; `invalidatePayrollPayoutDependents`.

### Инвалидация кэша после операций (Presentation)

| Операция | Функция | Затронутые провайдеры |
|----------|---------|------------------------|
| Премия / штраф (create/update/delete) | `invalidatePayrollFotTableDependents` | `filteredPayrollsProvider`, `payoutsByEmployeeAndMonthFIFOProvider`, `employeeAggregatedBalanceProvider` + список вкладки (`bonusesByFilterProvider` / `penaltiesByFilterProvider`) |
| Выплата (create/update/delete/import) | `invalidatePayrollPayoutDependents` | Всё из строки выше + `allPayoutsProvider`, `payrollPayoutsByFilterProvider`, `filteredPayrollPayoutsProvider` |

Без сброса `payoutsByEmployeeAndMonthFIFOProvider` колонки «Выплаты» и «Баланс» на вкладке ФОТ показывали устаревшие значения до перезагрузки экрана.

---

## 🗄 База данных и RLS

### Таблицы (Owner)
1. `employee_rates` — История ставок. **RLS: Enabled** (company_id).
   - **Constraint** `employee_rates_no_overlap` (EXCLUDE USING gist) — запрет пересечения `daterange(valid_from, COALESCE(valid_to, 'infinity'), '[]')` в рамках `(employee_id, company_id)`.
2. `business_trip_rates` (used) — Командировочные ставки. Owner модуля «Объекты», но критичны для расчёта.
   - **Constraint** `business_trip_rates_no_overlap` (EXCLUDE USING gist) — запрет пересечения периодов в рамках `(object_id, company_id, COALESCE(employee_id, sentinel-uuid))`. NULL-employee_id трактуется как «общая ставка для всех».
3. `payroll_payout` — Выплаты. **RLS: Enabled** (company_id). Индекс `idx_payroll_payout_company_date (company_id, payout_date)`.
4. `payroll_bonus` — Премии. **RLS: Enabled** (company_id). Индекс `idx_payroll_bonus_company_date (company_id, date)`.
5. `payroll_penalty` — Штрафы. **RLS: Enabled** (company_id). Индекс `idx_payroll_penalty_company_date (company_id, date)`.

### Расширения
- `btree_gist` — требуется для EXCLUDE-constraint по комбинации равенства (UUID) и диапазона дат.

### Активные RPC модуля
- `calculate_payroll_for_month(p_year int, p_month int, p_object_ids uuid[], p_company_id uuid)`
- `calculate_employee_balances(p_company_id uuid)`
- `calculate_employee_balances_before_date(p_date date, p_company_id uuid)`
- `calculate_employee_balances_at_date(p_date date, p_company_id uuid)`
- `calculate_single_employee_balance(p_employee_id uuid, p_company_id uuid)`

### Удалённые RPC (19.04.2026)
- `get_employee_bonuses(int, int)` — legacy, не использовался, без `company_id`.
- `calculate_payroll_for_month(int, int, uuid[])` — старая перегрузка без `company_id`.
- `calculate_base_salary_all_time()` — не использовался, без `company_id`.
- `calculate_business_trip_all_time()` — не использовался, без `company_id`.
- `get_payroll_report_data(int, int, uuid)` — не использовался; содержал альтернативную FIFO-логику, конфликтующую с клиентской.

---

## ⚙ Бизнес-логика (Audit)

### RPC `calculate_payroll_for_month` (начисления за месяц)
Строка попадает в результат, если за выбранный месяц (с учётом `p_company_id` и опционально `p_object_ids`) есть **часы** в базовом расчёте **или** **премия** **или** **штраф** **или** **выплата** (`payroll_payout` с датой в этом месяце; без привязки к объекту). Колонка `net_salary` по-прежнему только начисления; выплаты отображаются через FIFO. Подробнее: `docs/fot/calculations.md`.

**Важно:** RPC **не** возвращает сотрудников «в штате без операций за месяц». Такие строки добавляются на **клиенте** (`_groupPayrolls`) и на **сервере при экспорте** (`mergeZeroActivityRows` в `export-payroll`).

### Состав таблицы ФОТ на экране (`_groupPayrolls`)
1. Все строки из `filteredPayrollsProvider` (RPC / fallback).
2. Плюс сотрудники из отфильтрованного справочника (`employees`), если:
   - `employment_date` не позже последнего дня выбранного месяца;
   - **не уволен** (`status != fired`) **или** `|balance на конец месяца| > 0.01` (FIFO);
   - ещё не попали в п.1.
3. Для дополнительных строк: нулевые начисления, ставка из `currentHourlyRate`, выплаты и баланс — из `payoutsByEmployeeAndMonthFIFOProvider`.

### Экспорт ведомости в Excel (Edge Function `export-payroll`)
**Триггер UI:** `PayrollExportAction` в **шапке** экрана (`PermissionGuard`: `payroll` / `export`). Скрыт на вкладке «Выплаты». Параметры запроса: `year`, `month`, `companyId`, опционально `objectIds`, `searchQuery`, `employeeIds`.

**Алгоритм (сервер):**
1. RPC `calculate_payroll_for_month` за выбранный месяц (с теми же `objectIds` / `companyId`, что в UI).
2. Параллельно — FIFO за год: `calculate_employee_balances_before_date`, все `payroll_payout`, 12× `calculate_payroll_for_month` (без `objectIds` — для сквозного баланса).
3. `mergeZeroActivityRows`: дополнение «нулевыми» сотрудниками (условия как в `_groupPayrolls`; при переданном `employeeIds` — любой отмеченный ID).
4. Фильтр по `searchQuery` (подстрока ФИО, case-insensitive).
5. Сборка `.xlsx` (ExcelJS): колонки как в таблице; формулы «К выплате» и «Остаток»; строка ИТОГО; уволенные — розовая заливка.
6. Ответ: `base64` + `filename` (`ФОТ_<Месяц> <Год>.xlsx`); сохранение на устройстве — `WorkSearchExportServerService._saveExcelFile`.

**Режимы экспорта:**
| Режим | Условие в UI | Поведение |
|-------|----------------|-----------|
| Весь ФОТ | Нет отмеченных чекбоксов или пункт меню «Весь ФОТ» | RPC + все «нулевые» по правилу штат/баланс |
| Только выбранные | Есть отмеченные строки → «Только выбранные (N)» | Только `employeeIds` из чекбоксов (включая нулевые строки) |

### Алгоритм Cumulative FIFO Balance
1.  **Начальное сальдо:** Вызывается RPC `calculate_employee_balances_before_date` на 1 января выбранного года.
2.  **Параллельный сбор:** Загружаются начисления за все 12 месяцев года через параллельные вызовы `calculate_payroll_for_month`.
3.  **FIFO Распределение:** 
    - Каждая выплата (из всей истории) сначала гасит долг до начала года.
    - Остаток выплаты последовательно закрывает `netSalary` каждого месяца текущего года.
4.  **Кумуляция:** Баланс на конец месяца рассчитывается как бегущая строка. Это позволяет видеть, как декабрьская выплата «пробрасывается» в октябрь, уменьшая остаток долга именно того периода.

### Формирование годового PDF-отчета
Отчет больше не фильтрует выплаты по календарной дате. Вместо этого:
- Сумма «Выплачено» за месяц берется из распределения FIFO.
- Добавлена строка «ОСТАТОК К ВЫПЛАТЕ на конец месяца», которая отображает кумулятивный долг.
- Итоговый баланс года соответствует финальному значению из FIFO-цепочки.

### Импорт выплат из Excel (вкладка «Выплаты»)
Точка входа UI: кнопка **«Импорт из Excel»** в `PayrollTabToolbarActions` (панель фильтров).

1. **Параметры:** дата выплаты, способ (`card` / `cash` / `bank_transfer`), тип (`salary` / `advance`), комментарий — как при ручном вводе.
2. **Файл:** только `.xlsx`, байты в памяти (`file_picker`, `withData: true`). Предобработка: `sanitizeXlsxForExcelNumberFormats` (`lib/core/utils/xlsx_excel_compatibility.dart`).
3. **Колонки:** автопоиск заголовков по подстрокам `фио` и `сумм|перевод` в первых 15 строках; иначе — колонки B (ФИО) и C (сумма), данные с 2-й строки.
4. **Сумма:** `parseAmount` из `formatters.dart` (пробелы, запятая, символ ₽).
5. **Сопоставление ФИО** (`normalizePayrollImportFio`: lower case, `ё`→`е`, схлопывание пробелов):
   - точное совпадение с `Employee.fullName`;
   - иначе — фамилия + имя (2 токена в файле → любое отчество в справочнике; 3+ токена → полное отчество);
   - 0 кандидатов → `notFound`; 2+ → `ambiguous`.
   - Участвуют **все** сотрудники компании из `employeeProvider` (в т.ч. `EmployeeStatus.fired`).
6. **Предпросмотр:** таблица на всю ширину диалога; при `hasIssues` — баннер и подтверждение «Импортировать только найденных».
7. **Сохранение:** для каждой matched-строки — `PayrollPayoutModel` + `createPayoutUseCaseProvider` (UUID на клиенте).

**Права:** `PermissionGuard(module: 'payroll', permission: 'create')`.

---

## 🌲 Дерево файлов
```text
lib/features/fot/
├── data/
│   ├── models/             # payroll_payout_model, bonus, penalty
│   └── repositories/       # *_repository_impl.dart (Supabase)
├── domain/
│   ├── entities/           # payroll_calculation, payroll_transaction, payroll_payout_import
│   └── repositories/       # Интерфейсы CRUD
└── presentation/
    ├── providers/          # payroll_providers, balance_providers, payroll_filter_providers, bonus/penalty
    ├── screens/            # payroll_list_screen, tabs/
    ├── services/           # PDF, financial report, payroll_payout_excel_import_service
    ├── widgets/            # payroll_filters_toolbar, tables, modals, payroll_refreshing_amount
    └── utils/              # payroll_name_search_filters, payroll_payout_batch_save, payout_utils

test/features/fot/
└── payroll_payout_excel_import_service_test.dart
```

---

## 🔗 Интеграции
| Направление | Компонент | Назначение |
|-------------|-----------|------------|
| **Сотрудники** | `employeeProvider` / таблица `employees` | Сопоставление ФИО при импорте Excel |
| **Компания** | `activeCompanyIdProvider` | `company_id` в выплатах, RLS |
| **Экспорт Excel (ведомость)** | Edge Function `export-payroll` + `WorkSearchExportServerService` | Серверный Excel (`PayrollExportAction` в шапке); состав = таблица ФОТ |
| **Импорт Excel (выплаты)** | Клиент: `excel`, `file_picker` | Вкладка «Выплаты», `PayrollTabToolbarActions`; файл **не** сохраняется |
| **Табель (UI-паттерн)** | `TimesheetScreen`, `timesheet_filters_toolbar.dart` | Общая оболочка `MobileAtmosphere*`, высота панели 34 px, `EmployeesLayoutUtils` |
| **Core** | `formatters.parseAmount`, `xlsx_excel_compatibility` | Парсинг сумм и совместимость xlsx |

---

## 🗺 Roadmap
- 🟢 Hybrid-расчет (RPC + Fallback) — **Done**
- 🟢 Yearly PDF Report с FIFO балансом — **Done**
- 🟢 Cumulative FIFO Balance — **Done**
- 🟢 Parallel Loading Optimization — **Done**
- 🟢 Унификация логики отчетов (Table + Profile + PDF) — **Done**
- 🟢 Экспорт в Excel (ведомость ФОТ, Edge Function `export-payroll`) — **Done**
- 🟢 Паритет экспорта Excel с таблицей ФОТ (нулевые строки штат/баланс) — **Done (09.07.2026)**
- 🟢 UI-панель фильтров в стиле модуля «Табель» (единая строка, `PayrollFiltersToolbar`) — **Done (16.07.2026)**
- 🟢 Инвалидация FIFO/таблицы ФОТ после премий, штрафов и выплат — **Done (16.07.2026)**
- 🟢 Stale-while-revalidate UX таблицы ФОТ (`PayrollRefreshingAmount`) — **Done (16.07.2026)**
- 🟢 Импорт выплат из Excel (вкладка «Выплаты», клиентский парсинг) — **Done (26.05.2026)**
- 🟢 Унификация приоритета суточных во всех RPC — **Done (19.04.2026)**
- 🟢 Жёсткая защита от пересечения периодов ставок (UI + БД) — **Done (19.04.2026)**
- 🟢 Очистка и обезопасивание реестра RPC ФОТ — **Done (19.04.2026)**
- 🟡 Автоматическое уведомление сотрудника о выплате (Push) — **Planned**
- 🟡 LATERAL JOIN-оптимизация подбора ставок в `calculate_payroll_for_month` — **Backlog** (отложено сознательно).
