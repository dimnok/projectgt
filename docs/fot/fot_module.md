# Модуль ФОТ (Фонд оплаты труда, Payroll)

**Дата актуализации:** 26 мая 2026 года
**Статус:** Актуально (Clean Architecture, Cumulative FIFO Balance, Parallel Batch Processing, Unified Reporting, Hardened Rate Periods, Excel Import Payouts)

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
- **Mobile-First UX (Extreme Minimalism):** Адаптивное переключение между табличным видом (Desktop/Tablet) и карточками (Mobile).
    - **Ultra-Clean Header:** Удалены дублирующие заголовки периодов над списками.
    - **AppBar De-cluttering:** Скрытие поиска и экспорта на мобильных устройствах.
    - **Loading States:** Добавлена индикация «Расчет выплат и балансов...» для сложных FIFO-вычислений.
- **Импорт выплат из Excel (26.05.2026):** Массовое создание выплат из банковской ведомости на вкладке «Выплаты». Файл не сохраняется на сервере и в Storage.

---

## ⚠️ Важное замечание
- **Owner таблиц:** `payroll_payout`, `payroll_bonus`, `payroll_penalty`, `employee_rates` — модуль ФОТ; `employees` — модуль «Сотрудники» (используется при импорте для сопоставления ФИО).
- **Мультикомпания:** все операции фильтруются по `activeCompanyId`; RLS на `company_id`.
- **Импорт Excel:** только клиент (`file_picker` + пакет `excel`); Edge Function **не** используется. После импорта инвалидируются `filteredPayrollPayoutsProvider`, `payrollPayoutsByFilterProvider`, `employeeAggregatedBalanceProvider`.

---

## 🧱 Архитектура и структура
Модуль реализован согласно принципам **Clean Architecture**.

### Слой Presentation (UI)
- `lib/features/fot/presentation/screens/payroll_list_screen.dart` — Основной экран с табами (ФОТ, Премии, Штрафы, Выплаты).
- `lib/features/fot/presentation/widgets/payroll_table_view.dart` — Основная таблица. Использует `EmployeeFinancialReportService` для детальных отчётов; контекстное меню → «Выплата».
- `lib/features/fot/presentation/widgets/payroll_payout_table_widget.dart` — Вкладка «Выплаты»: кнопки **«Импорт из Excel»** и **«Добавить»** (`PermissionGuard`: `payroll` / `create`).
- `lib/features/fot/presentation/widgets/payroll_payout_form_modal.dart` — Ручное создание/редактирование выплаты (шаг 1: параметры и сотрудники).
- `lib/features/fot/presentation/widgets/payroll_payout_amount_modal.dart` — Шаг 2: индивидуальные суммы при ручном массовом вводе.
- `lib/features/fot/presentation/widgets/payroll_payout_excel_import_dialog.dart` — Параметры выплаты + выбор файла `.xlsx`.
- `lib/features/fot/presentation/widgets/payroll_payout_import_preview_dialog.dart` — Предпросмотр строк импорта (Стр. / Статус / ФИО / Сумма).
- `lib/features/fot/presentation/providers/payroll_providers.dart` — FIFO, CRUD выплат (`createPayoutUseCaseProvider` и др.).
- `lib/features/fot/presentation/providers/balance_providers.dart` — `employeeAggregatedBalanceProvider` (RPC балансов).

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
- `lib/features/fot/presentation/utils/payroll_payout_batch_save.dart` — Пакетное создание выплат и инвалидация провайдеров.

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
    ├── providers/          # payroll_providers, balance_providers, filters
    ├── screens/            # payroll_list_screen, tabs/
    ├── services/           # PDF, financial report, payroll_payout_excel_import_service
    ├── widgets/            # tables, modals, excel import/preview dialogs
    └── utils/              # payroll_payout_batch_save, payout_utils, balance_utils

test/features/fot/
└── payroll_payout_excel_import_service_test.dart
```

---

## 🔗 Интеграции
| Направление | Компонент | Назначение |
|-------------|-----------|------------|
| **Сотрудники** | `employeeProvider` / таблица `employees` | Сопоставление ФИО при импорте Excel |
| **Компания** | `activeCompanyIdProvider` | `company_id` в выплатах, RLS |
| **Экспорт Excel (ведомость)** | Edge Function `export-payroll` | Серверный Excel FIFO-ведомости (`PayrollExportAction`) |
| **Импорт Excel (выплаты)** | Клиент: `excel`, `file_picker` | Только вкладка «Выплаты»; файл **не** сохраняется |
| **Core** | `formatters.parseAmount`, `xlsx_excel_compatibility` | Парсинг сумм и совместимость xlsx |

---

## 🗺 Roadmap
- 🟢 Hybrid-расчет (RPC + Fallback) — **Done**
- 🟢 Yearly PDF Report с FIFO балансом — **Done**
- 🟢 Cumulative FIFO Balance — **Done**
- 🟢 Parallel Loading Optimization — **Done**
- 🟢 Унификация логики отчетов (Table + Profile + PDF) — **Done**
- 🟢 Экспорт в Excel (ведомость ФОТ, Edge Function `export-payroll`) — **Done**
- 🟢 Импорт выплат из Excel (вкладка «Выплаты», клиентский парсинг) — **Done (26.05.2026)**
- 🟢 Унификация приоритета суточных во всех RPC — **Done (19.04.2026)**
- 🟢 Жёсткая защита от пересечения периодов ставок (UI + БД) — **Done (19.04.2026)**
- 🟢 Очистка и обезопасивание реестра RPC ФОТ — **Done (19.04.2026)**
- 🟡 Автоматическое уведомление сотрудника о выплате (Push) — **Planned**
- 🟡 LATERAL JOIN-оптимизация подбора ставок в `calculate_payroll_for_month` — **Backlog** (отложено сознательно).
