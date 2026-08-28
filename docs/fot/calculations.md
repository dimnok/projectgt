# Детализация расчетов модуля ФОТ

**Дата:** 28 августа 2026 года

**Изменения 28.08.2026:**
- Клиент FIFO и `export-payroll` загружают выплаты порциями по 1000, иначе PostgREST отбрасывает старые строки.
- Часы для ФОТ и PDF: `TimesheetDataSource` / `EmployeeAttendanceDataSource` (порции по 1000). Отдельный SELECT часов в ФОТ убран.

**Изменения 23.08.2026:**
- Фильтр объектов: при заданном `p_object_ids` премии и штрафы без `object_id` в срез не входят; выплата не создаёт строку ведомости. Правило то же на вкладках «Премии» / «Штрафы» (`inFilter('object_id', …)`).
- Сигнатуры RPC сверены с `pg_proc`: `p_before_date` / `p_date` имеют тип **timestamptz**, не `date`.
- Зафиксировано: `calculate_employee_balances_at_date` суммирует **все** выплаты компании, без отсечения по `p_date`.

**Изменения 16.07.2026:** инвалидация FIFO-кэша; stale-while-revalidate UI — см. `docs/fot/ui_structure.md`.

**Изменения 09.07.2026:** паритет состава строк RPC / UI / Excel.

**Изменения 19.04.2026:** единый приоритет суточных; удалены неиспользуемые RPC.

---

## Hybrid расчёт ФОТ

Основной путь — RPC `calculate_payroll_for_month`. При ошибке — `filteredPayrollsProvider` → `_calculatePayrollClientSide`.

### 1. Серверный расчёт

`calculate_payroll_for_month(p_year int, p_month int, p_object_ids uuid[] DEFAULT NULL, p_company_id uuid DEFAULT NULL)`

Логика (факт SQL на 23.08.2026):
- Часы: `work_hours` ∩ `works.status = 'closed'` UNION ALL `employee_attendance` за год/месяц.
- Фильтр объекта: `object_id = ANY(p_object_ids)` (NULL в `p_object_ids` = все объекты).
- Ставка дня: `employee_rates` на `work_date`, `ORDER BY valid_from DESC LIMIT 1`.
- Суточные: см. раздел «Приоритет суточных».
- Премии/штрафы: сумма `amount` за месяц; при `p_object_ids` — только `object_id = ANY(...)`.
- `net_salary` = база + суточные + премии − штрафы. Выплаты в сумму **не** входят.
- Строка в результате, если есть часы **или** премия **или** штраф **или** (`p_object_ids IS NULL` **и** есть выплата за месяц).

`current_hourly_rate` — ставка, активная на `CURRENT_DATE`, не на день смены.

### Состав строк: RPC, UI и Excel

| Источник | Сверх RPC |
|----------|-----------|
| **RPC** | Только активность месяца (правило выплаты — см. выше) |
| **Таблица ФОТ** | При «Все объекты»: + штат без начислений (`_groupPayrolls`). При объекте — только RPC |
| **Excel** `export-payroll` | Как UI. При `employeeIds` — все отмеченные ID. Нулевые строки штата при `objectIds` не добавляются, кроме режима «только выбранные» |

«В штате»: `status != fired`. Порог баланса: `|balance| > 0.01`. Устроен не позже последнего дня месяца.

### 2. Клиентский fallback

`_calculatePayrollClientSide` в `payroll_providers.dart`:
- Часы из `payrollWorkHoursProvider` → табель (`getTimesheetEntries` + `getAttendanceRecords`) за месяц. **Фильтр объектов на часы не накладывается.**
- Премии/штрафы из `bonusesByFilterProvider` / `penaltiesByFilterProvider` (фильтр объектов есть).
- Выплаты добавляют сотрудника в список только без фильтра объектов.
- Ставка дня: `getEmployeeRateForDateUseCase`. Суточные: `getActiveRateForEmployeeAndDate`.

Пока RPC жив, fallback не влияет на экран.

---

## FIFO выплат

В `payroll_payout` есть `payout_date`, нет периода начисления.

Клиент (`payoutsByEmployeeAndMonthFIFOProvider`) и Excel (`buildFifoForYear` в `export-payroll`) считают одинаково:

1. Исторический долг: RPC `calculate_employee_balances_before_date(p_before_date timestamptz, p_company_id uuid)` на `YYYY-01-01`. Берётся колонка `accruals_sum`.
2. Все выплаты компании, сортировка по дате. Загрузка порциями по 1000 строк (`payout_date`, `id`).
3. 12 вызовов `calculate_payroll_for_month` **без** `p_object_ids` — `net_salary` месяца.
4. Каждая выплата: сначала гасит долг до года, затем месяцы 1–12 с `net_salary > 0`.
5. Если остаток выплаты некуда отнести и `payout_date.year == выбранный год` — сумма идёт в календарный месяц даты выплаты.
6. Баланс(М) = бегущая сумма: старт = непогашенный исторический долг после всех выплат; каждый месяц `+ net_salary − fifo_payout`.

Колонки «Выплаты» и «Баланс» таблицы ФОТ берутся из этого FIFO, не из RPC месяца.

---

## Баланс за всё время

`calculate_employee_balances(p_company_id uuid)`:

`база + суточные + премии − штрафы − выплаты` по всей истории компании.

UI: `employeeAggregatedBalanceProvider` (массовые выплаты), `singleEmployeeBalanceProvider` → `calculate_single_employee_balance` (профиль).

`calculate_employee_balances_at_date(p_date timestamptz, p_company_id uuid)`: начисления, премии, штрафы с `date <= p_date`; **выплаты без отсечения по дате**. Провайдер `employeeBalanceAtDateProvider` в UI не используется.

---

## Приоритет суточных

Едино во всех пяти расчётных RPC:

1. Ставки объекта, активные на `work_date`, с фильтром `company_id`.
2. Только если `work_hours >= COALESCE(minimum_hours, 0)`.
3. Среди них: именная (`employee_id` сотрудника) важнее общей (`employee_id IS NULL`); при равенстве типа — позднейший `valid_from`.

```sql
SELECT btr.rate
FROM business_trip_rates btr
WHERE btr.object_id = ah.obj_id
  AND (p_company_id IS NULL OR btr.company_id = p_company_id)
  AND (btr.employee_id = ah.emp_id OR btr.employee_id IS NULL)
  AND ah.work_date >= btr.valid_from
  AND (btr.valid_to IS NULL OR ah.work_date <= btr.valid_to)
  AND ah.work_hours >= COALESCE(btr.minimum_hours, 0)
ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC
LIMIT 1
```

Если именная ставка требует 8 часов, а отработано 6 — берётся общая ставка объекта (если её `minimum_hours` выполнен).

---

## Согласованность UI после мутаций

После премии / штрафа / выплаты сбрасывать кэш через `invalidatePayrollFotTableDependents` / `invalidatePayrollPayoutDependents` (`payroll_providers.dart`). Формулы FIFO не меняются.

---

## Защита периодов ставок

### `employee_rates`
- БД: EXCLUDE `employee_rates_no_overlap`.
- UI: `EmployeeRateRepository.findOverlappingRates` → диалог; `setNewRate` закрывает/удаляет пересечения.

### `business_trip_rates`
- БД: EXCLUDE `business_trip_rates_no_overlap` с `COALESCE(employee_id, sentinel-uuid)`.
- UI: `hasOverlappingPeriods()` до INSERT.

Канонический обзор модуля: `docs/fot/fot_module.md`.
