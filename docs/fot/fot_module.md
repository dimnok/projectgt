# Модуль ФОТ (Фонд оплаты труда, Payroll)

**Дата актуализации:** 23 августа 2026 года (полный аудит кода, БД self-hosted, Edge Function)

**Изменения в этой версии (аудит 23.08.2026):**
- Документация приведена к фактическому состоянию кода, PostgreSQL и `export-payroll`.
- Зафиксированы сигнатуры RPC (`timestamptz`, имена аргументов), RLS, индексы, constraints.
- Описан фильтр объектов 23.08.2026: премии/штрафы без `object_id` не входят в срез; при выбранном объекте выплаты не добавляют строку в ведомость.
- Зафиксированы расхождения аудита (см. Roadmap): RLS без `check_permission` на премии/штрафы/выплаты; `is_official` в БД без поля в Dart; `calculate_employee_balances_at_date` не режет выплаты по дате; клиентский fallback не фильтрует часы по объекту.

**Предыдущие версии (кратко):** UI-панель как у «Табель» (16.07.2026); FIFO + stale-while-revalidate (16.07.2026); Excel-импорт выплат (26.05.2026); EXCLUDE на ставки и очистка RPC (19.04.2026). Детали UI — [`ui_structure.md`](./ui_structure.md), формул — [`calculations.md`](./calculations.md).

---

## Важное замечание

Модуль **не хранит** готовую ведомость. Таблицы `payroll_calculation` и `payroll_deduction` **в БД отсутствуют**. Строка ФОТ считается динамически.

**Owner таблиц модуля:**
- `payroll_bonus`, `payroll_penalty`, `payroll_payout`

**Usage (другие модули владеют CRUD, ФОТ читает для расчёта):**
- `employee_rates` — UI ставок в «Сотрудники»; запись в БД требует прав модуля `payroll`
- `business_trip_rates` — суточные; owner «Сотрудники» / «Объекты»; SELECT также при `payroll.read`
- `employees`, `work_hours`, `works`, `employee_attendance`, `objects`, `company_members`

Ключевые принципы:
- начисления за месяц — RPC `calculate_payroll_for_month` (часы только из **закрытых** смен + `employee_attendance`)
- колонки «Выплаты» и «Баланс» на вкладке ФОТ — **клиентский FIFO** (`payoutsByEmployeeAndMonthFIFOProvider`), не колонка RPC
- FIFO всегда **по всей компании** (12 месяцев без `objectIds`); при фильтре объекта начисления срезаются, выплаты/баланс остаются сквозными
- мультикомпания: клиент передаёт `activeCompanyId`; RLS на `company_id` / `get_my_company_ids()`
- без активной компании провайдеры возвращают пустые списки
- импорт выплат — только клиент (`file_picker` + `excel`), файл на сервер не пишется
- экспорт ведомости — Edge Function `export-payroll` (ExcelJS, `service_role`)

---

## Описание модуля

Модуль считает заработную плату за месяц: часы × ставка, суточные, премии, штрафы, выплаты и кумулятивный остаток.

Ключевые функции:
- вкладки: ФОТ / Премии / Штрафы / Выплаты
- фильтры: месяц, объекты (мультивыбор), поиск ФИО, статус (Все / Работает / Уволен) на вкладке ФОТ
- hybrid-расчёт: PostgreSQL RPC, при ошибке — Dart fallback
- Cumulative FIFO: выплата гасит долги от ранних к поздним
- Excel-ведомость (сервер) и Excel-импорт выплат (клиент)
- годовой PDF сотрудника (`PayrollPdfService` + `EmployeeFinancialReportService`) — тот же FIFO, что в таблице
- карточка сотрудника по клику на ФИО (`employees.read`)
- контекстное меню строки ФОТ только ПКМ: Премия / Штраф / Выплата / Детали (PDF)

Архитектурные особенности:
- Clean Architecture: `presentation` / `domain` / `data`
- Riverpod; Freezed-модели выплат/премий/штрафов и `PayrollCalculation`
- списки премий/штрафов/выплат читаются из провайдеров напрямую в Supabase, не через repository `getAll*`
- repository в модуле — только CRUD create/update/delete

---

## Зависимости

### Таблицы модуля (owner)
- `payroll_bonus`
- `payroll_penalty`
- `payroll_payout`

### Таблицы других модулей (usage)
- `employee_rates` — почасовая ставка на дату смены
- `business_trip_rates` — суточные по объекту
- `employees` — ФИО, статус, дата трудоустройства, ставка в UI
- `work_hours` + `works` — часы закрытых смен
- `employee_attendance` — ручные часы
- `objects` — фильтр и название объекта у премии/штрафа
- `company_members` / `profiles` — RLS и `activeCompanyId`

### Связанные модули
- `employees` — справочник, карточка, ставки
- `timesheet` — те же источники часов; UI-паттерн панели
- `objects` — суточные и фильтр
- `company` — `activeCompanyIdProvider`
- `roles` — модуль `payroll`: `read`, `create`, `update`, `delete`, `export`. Право `import` в матрице ролей **отключено**; импорт Excel выплат идёт через `create`
- `profile` — финансовый отчёт сотрудника использует RPC и FIFO ФОТ
- `export` — `WorkSearchExportServerService.exportPayroll`

---

## Presentation

Корневой экран: `PayrollListScreen`. Подробная вёрстка: [`ui_structure.md`](./ui_structure.md).

| Файл | Назначение |
|------|------------|
| `screens/payroll_list_screen.dart` | Шапка, `IndexedStack` вкладок, `skipLoadingOnReload` для RPC |
| `screens/tabs/payroll_tab_*.dart` | Обёртки вкладок Премии / Штрафы / Выплаты |
| `widgets/payroll_filters_toolbar.dart` | Единая строка фильтров |
| `widgets/payroll_table_widget.dart` / `payroll_table_view.dart` | Таблица ФОТ, `_groupPayrolls` |
| `widgets/payroll_mobile_view.dart` / `payroll_card.dart` | Карточки на телефоне |
| `widgets/payroll_refreshing_amount.dart` | Спиннер в суммах при пересчёте |
| `widgets/payroll_export_action.dart` | Excel: весь ФОТ / выбранные |
| `widgets/payroll_*_table_*.dart` | Таблицы премий, штрафов, выплат |
| `widgets/payroll_transaction_form_modal.dart` | Форма премии/штрафа |
| `widgets/payroll_payout_form_modal.dart` / `payroll_payout_amount_modal.dart` | Ручные и массовые выплаты |
| `widgets/payroll_payout_excel_import_dialog.dart` | Импорт выплат |
| `providers/payroll_providers.dart` | RPC месяца, FIFO, выплаты, инвалидация |
| `providers/bonus_providers.dart` / `penalty_providers.dart` | Списки и CRUD |
| `providers/balance_providers.dart` | Баланс за всё время / одного / на дату |
| `providers/payroll_filter_providers.dart` | Год, месяц, объекты, поиск |
| `services/employee_financial_report_service.dart` | Годовые данные FIFO для PDF |
| `services/payroll_pdf_service.dart` | PDF |
| `services/payroll_payout_excel_import_service.dart` | Парсинг `.xlsx` и матчинг ФИО |

### Права UI

| Действие | Право |
|----------|--------|
| Вход в модуль / маршрут | `payroll.read` |
| Добавить премию / штраф / выплату, импорт Excel | `payroll.create` |
| Экспорт ведомости | `payroll.export` |
| Карточка сотрудника по ФИО | `employees.read` |

---

## Domain / Data

### Domain

| Файл | Назначение |
|------|------------|
| `entities/payroll_calculation.dart` | Freezed: часы, ставка, база, премии, штрафы, суточные, `netSalary` |
| `entities/payroll_transaction.dart` | Интерфейс премии/штрафа + enum типа |
| `entities/payroll_payout_import.dart` | Строка Excel: `matched` / `notFound` / `ambiguous` |
| `repositories/payroll_*_repository.dart` | Интерфейсы CRUD (без list) |

`PayrollCalculation` — расчёт в памяти, не таблица БД.

### Data

| Файл | Таблица |
|------|---------|
| `models/payroll_bonus_model.dart` | `payroll_bonus` |
| `models/payroll_penalty_model.dart` | `payroll_penalty` |
| `models/payroll_payout_model.dart` | `payroll_payout` (поля: `id`, `employee_id`, `company_id`, `amount`, `payout_date`, `method`, `type`, `comment`, `created_at`) |
| `repositories/*_impl.dart` | Supabase insert/update/delete с `company_id` |

Колонка БД `payroll_payout.is_official` (boolean, default `true`) **в Dart-модели нет** — клиент её не читает и не пишет.

Списки читаются в провайдерах (`from('payroll_*').select()`), не в repository.

---

## Дерево файлов

```text
lib/features/fot/
├── data/
│   ├── models/                 # bonus, penalty, payout (+ freezed/g)
│   └── repositories/           # CRUD impl
├── domain/
│   ├── entities/               # payroll_calculation, payroll_transaction, payroll_payout_import
│   └── repositories/           # интерфейсы CRUD
└── presentation/
    ├── providers/              # payroll, bonus, penalty, balance, filter, grid selection
    ├── screens/                # payroll_list_screen + tabs/
    ├── services/               # PDF, financial report, excel import
    ├── widgets/                # toolbar, tables, modals, export
    └── utils/                  # search filters, batch save, payout/balance helpers

test/features/fot/
└── payroll_payout_excel_import_service_test.dart

supabase/functions/export-payroll/
└── index.ts                    # Excel-ведомость
```

---

## База данных (Audit)

Источник: `information_schema`, `pg_policies`, `pg_indexes`, `pg_constraint`, `pg_proc`, `pg_stat_user_tables` на self-hosted **23.08.2026**. Миграции фильтра объектов применены: `payroll_object_filter_exclude_unassigned`, `payroll_object_filter_exclude_payout_only`.

Приблизительный объём (`n_live_tup`): `payroll_payout` ~969, `employee_rates` ~248, `payroll_bonus` ~38, `payroll_penalty` ~25, `business_trip_rates` ~19.

### Таблица `payroll_bonus`

| Колонка | Тип | Nullable | Default |
|---------|-----|----------|---------|
| `id` | uuid PK | NO | `gen_random_uuid()` |
| `type` | text | NO | — |
| `amount` | numeric | NO | — |
| `reason` | text | YES | — |
| `created_at` | timestamptz | NO | `now()` |
| `employee_id` | uuid FK → `employees` | NO | нулевой uuid (legacy) |
| `object_id` | uuid FK → `objects` | YES | — |
| `date` | date | YES | — |
| `company_id` | uuid FK → `companies` ON DELETE CASCADE | NO | — |

**RLS:** ✅ включён, `FORCE` нет.  
Политика `Users can manage bonuses of their companies` (`ALL`): `company_id IN (get_my_company_ids())`. **`check_permission('payroll', …)` нет** — любой участник компании с доступом к API может менять премии.

Индексы: PK, `idx_payroll_bonus_company_date (company_id, date)`, `idx_payroll_bonus_employee_id`, `idx_payroll_bonus_object_id`.

Триггеров нет. CHECK на сумму нет.

### Таблица `payroll_penalty`

Колонки как у премий (`type`, `amount`, `reason`, `employee_id`, `object_id`, `date`, `company_id`, `created_at`).

**RLS:** ✅. Политика `Users can manage penalties of their companies` (`ALL`) — только `company_id`. Без `check_permission`.

Индексы: PK, `idx_payroll_penalty_company_date`, `idx_payroll_penalty_employee_date (employee_id, date)`, `idx_payroll_penalty_object_id`.

### Таблица `payroll_payout`

| Колонка | Тип | Nullable | Default |
|---------|-----|----------|---------|
| `id` | uuid PK | NO | `gen_random_uuid()` |
| `amount` | numeric | NO | — |
| `payout_date` | date | NO | — |
| `method` | text | NO | — |
| `created_at` | timestamptz | NO | `now()` |
| `employee_id` | uuid FK → `employees` | NO | нулевой uuid (legacy) |
| `type` | text | NO | `'salary'` |
| `is_official` | boolean | NO | `true` |
| `comment` | text | YES | — |
| `company_id` | uuid FK → `companies` ON DELETE CASCADE | NO | — |

**RLS:** ✅. Политика `Users can manage payouts of their companies` (`ALL`) — только `company_id`. Без `check_permission`.

Индексы: PK, `idx_payroll_payout_company_date (company_id, payout_date)`, `idx_payroll_payout_employee_id`.

`object_id` у выплат **нет**.

### Таблица `employee_rates` (usage)

| Колонка | Тип |
|---------|-----|
| `id` | uuid PK |
| `employee_id` | uuid FK → `employees` ON DELETE CASCADE |
| `hourly_rate` | numeric(10,2), CHECK `> 0` |
| `valid_from` / `valid_to` | date, CHECK период |
| `company_id` | uuid FK ON DELETE CASCADE |
| `created_at`, `created_by` | timestamptz / uuid → `profiles` |

**RLS:** ✅.

| Политика | Команда | Условие |
|----------|---------|---------|
| `Users can view employee rates of their companies` | SELECT | `company_id IN (get_my_company_ids())` — **без** `payroll.read` |
| `employee_rates_select` | SELECT | `payroll.read` **или** ставка своего `profiles.employee_id` |
| `employee_rates_insert` | INSERT | `payroll.create` — **без** проверки `company_id` |
| `employee_rates_update` | UPDATE | `payroll.update` — **без** `company_id` |
| `employee_rates_delete` | DELETE | `payroll.delete` — **без** `company_id` |

EXCLUDE `employee_rates_no_overlap`: gist `(employee_id, company_id, daterange(valid_from, COALESCE(valid_to,'infinity'), '[]'))`.

Индекс подбора ставки: `idx_employee_rates_employee_company_from (employee_id, company_id, valid_from DESC)`.

### Таблица `business_trip_rates` (usage)

Суточные по объекту. CHECK `rate >= 0`, `valid_to >= valid_from`. EXCLUDE `business_trip_rates_no_overlap` с sentinel-uuid для `employee_id IS NULL` (общая ставка).

**RLS:** SELECT при `employees.read` **или** `payroll.read`; INSERT/UPDATE/DELETE — `employees.update` + `company_id`.

Триггер `business_trip_rates_updated_at` (BEFORE UPDATE).

### Расширения
- `btree_gist` — для EXCLUDE по UUID + `daterange`.

### RPC модуля (факт в БД)

Все, кроме `calculate_single_employee_balance`, — `LANGUAGE plpgsql`, **SECURITY INVOKER**. EXECUTE есть у `anon`, `authenticated`, `service_role` (изоляция — RLS таблиц внутри INVOKER).

| Функция | Аргументы (факт) | Результат | Security |
|---------|------------------|-----------|----------|
| `calculate_payroll_for_month` | `p_year int`, `p_month int`, `p_object_ids uuid[]` default NULL, `p_company_id uuid` default NULL | TABLE: employee_id, full_name, total_hours, base_salary, business_trip_total, bonuses_total, penalties_total, net_salary, current_hourly_rate | INVOKER |
| `calculate_employee_balances` | `p_company_id uuid` | TABLE(employee_id, balance) | INVOKER |
| `calculate_employee_balances_before_date` | **`p_before_date timestamptz`**, `p_company_id uuid` | TABLE(employee_id, accruals_sum, payouts_sum, balance) | INVOKER |
| `calculate_employee_balances_at_date` | **`p_date timestamptz`**, `p_company_id uuid` | TABLE(employee_id, balance) | INVOKER |
| `calculate_single_employee_balance` | `p_employee_id uuid`, `p_company_id uuid` | numeric | **DEFINER**, STABLE, **без** `SET search_path` |
| `get_employee_rate` | `p_employee_id uuid`, `p_date date`, `p_company_id uuid` | numeric | INVOKER, STABLE |

`get_employee_rate` вызывается из модуля «Сотрудники» (`employee_rate_data_source.dart`), не из `lib/features/fot`.

`p_company_id` / `p_object_ids` у месячной RPC допускают NULL (кросс-компания / все объекты). Клиент и `export-payroll` всегда передают `companyId`.

### Удалённые RPC (19.04.2026, подтверждено отсутствием в `pg_proc`)
- `get_employee_bonuses`
- `calculate_payroll_for_month(int, int, uuid[])` без `company_id`
- `calculate_base_salary_all_time`
- `calculate_business_trip_all_time`
- `get_payroll_report_data`

### Миграции ФОТ (репозиторий → сервер)

| Миграция | Суть |
|----------|------|
| `20260410120000` / applied `payroll_include_bonus_penalty_without_hours` | Строка без часов, если есть премия/штраф |
| `20260411120000` / `payroll_include_payout_in_month*` | Строка, если есть выплата за месяц |
| `20260419120000` | Индексы `(company_id, date)` |
| `20260419120200`–`20800` | Дроп старых RPC, приоритет суточных, `company_id` в балансах |
| `employee_rates_no_overlap` / `business_trip_rates_no_overlap` | EXCLUDE |
| `drop_employee_rates_active_unique` | Удалён частичный unique |
| `20260823180000` applied `payroll_object_filter_exclude_unassigned` | При `p_object_ids` премии/штрафы только с совпавшим `object_id` |
| `20260823181000` applied `payroll_object_filter_exclude_payout_only` | При `p_object_ids` выплата **не** создаёт строку ведомости |

---

## Бизнес-логика

Подробные формулы: [`calculations.md`](./calculations.md).

### Hybrid-расчёт месяца

1. `filteredPayrollsProvider` → RPC `calculate_payroll_for_month` с годом, месяцем, `objectIds` или null, `companyId`.
2. Ошибка RPC → `_calculatePayrollClientSide` (логируется в `dart:developer`).
3. Fallback берёт часы из `payrollWorkHoursProvider` (**без** фильтра объектов), премии/штрафы — уже с фильтром объектов, выплаты — только если объекты не выбраны.

### Состав строк вкладки ФОТ

| Источник | Что в списке |
|----------|----------------|
| RPC | Часы и/или премия и/или штраф за месяц. Выплата добавляет строку **только** если объекты не выбраны. `net_salary` = база + суточные + премии − штрафы (выплата в сумму не входит) |
| UI `_groupPayrolls` | При «Все объекты»: + сотрудники, устроенные до конца месяца и (не уволены **или** \|FIFO-баланс\| > 0.01). При фильтре объекта доп. строк нет |
| Excel `mergeZeroActivityRows` | То же, что UI; при `employeeIds` — все отмеченные |

### FIFO (вкладка ФОТ и Excel)

1. Исторический долг: `calculate_employee_balances_before_date` на 1 января года (`p_before_date`).
2. Все `payroll_payout` компании, по дате возрастания.
3. 12× `calculate_payroll_for_month` **без** `objectIds` — `net_salary` месяца.
4. Выплата сначала гасит долг до года, затем месяцы 1–12 с положительным начислением.
5. Остаток выплаты в выбранном году, если гасить нечего, относится на **календарный месяц даты выплаты**.
6. Баланс(М) = Баланс(М−1) + Начислено(М) − Выплата_FIFO(М).

При фильтре объекта колонки «Выплаты» / «Баланс» / «Остаток» смешивают срез начислений объекта и **сквозной** FIFO компании.

### Инвалидация кэша

| Операция | Функция |
|----------|---------|
| Премия / штраф | `invalidatePayrollFotTableDependents` + список вкладки |
| Выплата / импорт | `invalidatePayrollPayoutDependents` (включает строку выше + списки выплат) |

### Баланс «за всё время»

- `employeeAggregatedBalanceProvider` → `calculate_employee_balances` — форма массовых выплат, **не** колонка «Баланс» таблицы.
- `singleEmployeeBalanceProvider` → `calculate_single_employee_balance` — профиль.
- `employeeBalanceAtDateProvider` → `calculate_employee_balances_at_date` — **нигде не watch**, заготовка. В RPC выплаты **не** ограничены `p_date` (начисления ограничены).

### Экспорт Excel

`PayrollExportAction` → `WorkSearchExportServerService.exportPayroll` → `export-payroll`.

Тело: `year`, `month`, `companyId`, опционально `objectIds`, `searchQuery`, `employeeIds`. JWT пользователя в `Authorization`; внутри функции — `SERVICE_ROLE_KEY`.

Колонки файла: Сотрудник, Статус, Часы, Ставка, Базовая сумма, Премии, Штрафы, Суточные, К выплате, Выплаты, Остаток, Баланс. Уволенные — розовая заливка. ИТОГО. Формулы «К выплате» и «Остаток».

### Импорт выплат

Вкладка «Выплаты», `payroll.create`. Только `.xlsx` в памяти. Матчинг ФИО: lower, `ё`→`е`, все сотрудники компании включая уволенных. Пакет через `savePayrollPayoutBatch`.

---

## Интеграции

### Внутренние
- `employees`, `timesheet` (часы и UI-shell), `objects`, `company`, `roles`, `profile` (PDF/FIFO), `export`

### Пакеты
- `supabase_flutter`, `flutter_riverpod`, `freezed`, `json_serializable`, `excel`, `file_picker`, `collection`

### Edge Functions

MCP `list_edge_functions` в этом окружении недоступен. В репозитории и в вызовах клиента:

| Функция | Файл | Назначение |
|---------|------|------------|
| `export-payroll` | `supabase/functions/export-payroll/index.ts` | Ведомость `.xlsx` (ExcelJS) |

В `supabase/config.toml` отдельного блока `[functions.export-payroll]` нет (в отличие от части других функций). Вызов идёт с пользовательским JWT.

Других Edge Functions модуля ФОТ в `supabase/functions/` нет.

---

## Roadmap

### Реализовано
- Hybrid RPC + fallback
- FIFO + паритет PDF / таблицы / Excel
- Параллельная загрузка 12 месяцев
- Экспорт Excel, импорт выплат
- Фильтр объектов: без «висячих» премий/штрафов и без строк «только выплата»
- UI-панель как у «Табель», stale-while-revalidate
- EXCLUDE на периоды ставок
- Очистка старых RPC

### Расхождения аудита 23.08.2026 (не закрыты кодом)

| Приоритет | Факт | Следствие |
|-----------|------|-----------|
| 🔴 | RLS `payroll_bonus` / `payroll_penalty` / `payroll_payout` — только `company_id` | Права `payroll.create/update/delete` в UI не дублируются в БД |
| 🔴 | `calculate_single_employee_balance` — SECURITY DEFINER без `search_path` | Типовой риск DEFINER; EXECUTE у `anon` |
| 🟡 | `calculate_employee_balances_at_date`: выплаты без фильтра по `p_date` | Провайдер не используется; включать в UI нельзя без правки SQL |
| 🟡 | `employee_rates` INSERT/UPDATE/DELETE без `company_id` в политике | Запись опирается только на `payroll.*` |
| 🟡 | Fallback `_calculatePayrollClientSide` не фильтрует часы по объекту | При сбое RPC срез объекта завысит часы |
| 🟡 | При фильтре объекта «Остаток» = начисления объекта − FIFO всей компании | Цифры колонок не про один срез |
| 🟢 | `payroll_payout.is_official` есть в БД, нет в Dart | Мёртвая колонка для приложения |
| 🟢 | `docs/database_structure.md` описывал несуществующие `payroll_calculation` / `payroll_deduction` | Исправлено в этом аудите |
| 🟢 | Статический анализ `lib/features/fot` | Ошибок нет |

### Planned / Backlog
- 🟡 Push-уведомление сотруднику о выплате
- 🟡 LATERAL JOIN для подбора ставок в `calculate_payroll_for_month`
- 🟡 Выровнять RLS премий/штрафов/выплат с `check_permission('payroll', …)`
- 🟡 Починить фильтр даты в `calculate_employee_balances_at_date` или удалить мёртвый провайдер
