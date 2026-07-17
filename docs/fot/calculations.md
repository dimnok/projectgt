# Детализация расчетов модуля ФОТ

**Дата:** 16 июля 2026 года

**Изменения 16.07.2026:**
- Документирована **инвалидация клиентского кэша** после мутаций: премии/штрафы → `invalidatePayrollFotTableDependents`; выплаты → `invalidatePayrollPayoutDependents`. Без сброса `payoutsByEmployeeAndMonthFIFOProvider` UI показывал устаревшие «Выплаты» и «Баланс» при неизменных начислениях RPC.
- **UI:** пересчёт FIFO/RPC на вкладке ФОТ использует stale-while-revalidate (таблица не скрывается; `PayrollRefreshingAmount` в денежных колонках). См. `docs/fot/ui_structure.md`.

**Изменения 09.07.2026:**
- Документирован **паритет состава строк**: таблица ФОТ (UI), Edge Function `export-payroll` и RPC `calculate_payroll_for_month` — разные уровни агрегации (см. раздел «Состав строк: RPC, UI и Excel»).

**Изменения 19.04.2026:**
- Унифицирован приоритет командировочных ставок во всех RPC (`calculate_payroll_for_month`, `calculate_employee_balances`, `calculate_employee_balances_before_date`, `calculate_employee_balances_at_date`, `calculate_single_employee_balance`).
- Удалены неиспользуемые функции (`get_employee_bonuses`, `calculate_base_salary_all_time`, `calculate_business_trip_all_time`, `get_payroll_report_data`, старая перегрузка `calculate_payroll_for_month` без `company_id`).
- В `calculate_employee_balances_at_date` добавлены `company_id`-фильтры в подзапросы по `employee_rates` и `business_trip_rates`.

**Ранее:** RPC `calculate_payroll_for_month` и клиентский fallback включают в результат сотрудников с премией и/или штрафом за месяц **без** отработанных часов (при тех же фильтрах `p_object_ids` / `company_id`).

## 🚀 Hybrid расчет ФОТ

Модуль использует гибридную схему для обеспечения максимальной скорости при сохранении надежности.

### 1. Серверный расчет (PostgreSQL RPC)
Основной метод получения данных — вызов функции `calculate_payroll_for_month`.
- **Преимущество:** Агрегация тысяч записей `work_hours` и `employee_rates` за миллисекунды.
- **Логика:**
    - Объединяет `work_hours` (из закрытых смен) и `employee_attendance`.
    - Подбирает актуальную часовую ставку из `employee_rates` для каждой даты (с фильтром по `company_id`).
    - Рассчитывает суточные через `business_trip_rates` по **унифицированному приоритету** (см. ниже раздел «Приоритет суточных»).
    - Суммирует премии и штрафы за указанный период.
    - **Включение строки:** сотрудник попадает в выборку, если за месяц есть часы (в `base_calc`) **или** премия **или** штраф (после фильтров по объектам и компании) **или** хотя бы одна **выплата** с `payout_date` в этом календарном месяце (по `company_id`; у выплат нет `object_id`, поэтому фильтр `p_object_ids` на них не действует). Сумма выплаты в колонку `net_salary` не входит — она по-прежнему в FIFO/колонке «Выплаты».

### Состав строк: RPC, UI и Excel

| Источник | Что включает сверх RPC |
|----------|-------------------------|
| **RPC** `calculate_payroll_for_month` | Только сотрудники с часами / премией / штрафом / выплатой в месяце |
| **Таблица ФОТ (UI)** | + сотрудники из справочника: устроены до конца месяца и (**не уволены** или **баланс ≠ 0** на конец месяца по FIFO). Реализация: `_groupPayrolls` |
| **Excel** `export-payroll` | То же дополнение, что в UI (`mergeZeroActivityRows`). При `employeeIds` в запросе — все отмеченные ID, включая «нулевые» |

Условие «в штате» в UI и экспорте: `status != fired` (отпуск, больничный и т.д. считаются «в штате»). Порог баланса: `|balance| > 0.01`.

### 2. Клиентский расчет (Dart Fallback)
Если RPC-вызов завершился ошибкой, провайдер `filteredPayrollsProvider` автоматически переключается на метод `_calculatePayrollClientSide`.
- Выполняет ту же логику на стороне клиента, используя загруженные данные.
- Гарантирует работоспособность модуля даже при проблемах с функциями БД.
- Объединяет множество сотрудников из часов, премий, штрафов и **выплат** за месяц (см. `bonusesByFilterProvider` / `penaltiesByFilterProvider` / `payrollPayoutsByFilterProvider`).

## 💰 Алгоритм FIFO для выплат
Выплаты в системе не привязаны жестко к конкретному месяцу начисления в базе данных (в таблице `payroll_payout` есть `payout_date`, но нет `period_month`).

Для корректного отображения колонки "Выплаты" в таблице ФОТ используется **сквозной FIFO (First In, First Out)**:
1.  **Исторический долг**: Сначала вычисляется сумма всех начислений до 1 января выбранного года (через RPC `calculate_employee_balances_before_date`).
2.  **Гашение прошлого**: Все выплаты сотрудника (в хронологическом порядке) сначала направляются на закрытие этого исторического долга.
3.  **Текущий год**: Только после того, как исторический долг полностью погашен, остаток выплат распределяется по месяцам (1-12) выбранного года.
4.  **Отображение**: В таблице конкретного месяца отображается сумма, которая была распределена на этот месяц после закрытия всех предыдущих задолженностей.
5.  **Остаток без начислений за год:** если после гашения исторического долга часть выплаты не «ложится» ни на один месяц с положительным `net_salary` (все начисления за год нулевые или отсутствуют), остаток относится на **календарный месяц даты выплаты** в выбранном году — иначе колонка «Выплаты» для таких сотрудников оставалась бы пустой.

## 📊 Расчет баланса
Баланс сотрудника рассчитывается через RPC `calculate_employee_balances(p_company_id)`.
- **Формула:** `Total Accrued - Total Paid`.
- Учитывает всю историю работы сотрудника в системе в рамках выбранной компании.
- В UI: `employeeAggregatedBalanceProvider` (массовые выплаты), `singleEmployeeBalanceProvider` (профиль сотрудника).

## 🧭 Приоритет суточных (унифицированный)

Логика выбора `business_trip_rates` для отработанной смены `(employee_id, object_id, work_date, work_hours)` едина во всех RPC ФОТ:

1. Берутся все ставки по объекту, активные на `work_date` (`valid_from <= work_date AND (valid_to IS NULL OR valid_to >= work_date)`), отфильтрованные по `company_id`.
2. Из них рассматриваются только те, где **выполнен `minimum_hours`** (`work_hours >= COALESCE(minimum_hours, 0)`).
3. Среди подходящих выбирается **одна** ставка с наибольшим приоритетом по правилу:
   - сначала **именная** (`employee_id = current employee`),
   - затем **общая** (`employee_id IS NULL`),
   - при равенстве типа — самая поздняя по `valid_from`.

В SQL это реализовано через скалярный подзапрос вида:
```sql
SELECT btr.rate
FROM business_trip_rates btr
WHERE btr.object_id   = ah.obj_id
  AND (p_company_id IS NULL OR btr.company_id = p_company_id)
  AND (btr.employee_id = ah.emp_id OR btr.employee_id IS NULL)
  AND ah.work_date >= btr.valid_from
  AND (btr.valid_to IS NULL OR ah.work_date <= btr.valid_to)
  AND ah.work_hours >= COALESCE(btr.minimum_hours, 0)
ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC
LIMIT 1
```

**Важное следствие:** если у сотрудника есть именная ставка с `minimum_hours = 8`, но в этот день он отработал 6 часов, для него применится **общая ставка по объекту** (если её `minimum_hours` выполнен), а не «нулевые суточные». Раньше в части RPC именная ставка побеждала общую безусловно — это и было причиной разночтений между балансами и месячным расчётом.

## 🔄 Согласованность UI после изменений данных

Колонки «Выплаты» и «Баланс» на вкладке ФОТ берутся из **клиентского** FIFO (`payoutsByEmployeeAndMonthFIFOProvider`), а не напрямую из RPC `calculate_payroll_for_month`. FIFO зависит от:

1. `calculate_employee_balances_before_date` (долг до года),
2. всех записей `payroll_payout` (`allPayoutsProvider`),
3. twelve× `calculate_payroll_for_month` за выбранный год (`net_salary` по месяцам).

После любой **премии**, **штрафа** или **выплаты** соответствующие провайдеры должны быть сброшены (см. `invalidatePayrollFotTableDependents` / `invalidatePayrollPayoutDependents` в `payroll_providers.dart`). Формулы FIFO при этом **не меняются** — обновляется только кэш Riverpod.

`employeeAggregatedBalanceProvider` (RPC `calculate_employee_balances`, баланс за всё время) **не подставляется** в колонку «Баланс» таблицы ФОТ; используется, например, при массовом вводе выплат.

## 🛡 Защита периодов ставок

### `employee_rates`
- БД: EXCLUDE-constraint `employee_rates_no_overlap` запрещает любое пересечение `daterange(valid_from, COALESCE(valid_to, 'infinity'), '[]')` в рамках `(employee_id, company_id)`.
- UI (`AddEmployeeRateDialog`): перед сохранением вызывается `EmployeeRateRepository.findOverlappingRates(...)`, и если найдены пересечения — показывается диалог с перечнем и описанием действия для каждой записи (закрыта датой / удалена / заменена). Сохранение происходит только при подтверждении.
- Логика разрешения пересечений (`EmployeeRateRepositoryImpl.setNewRate`):
  - `existingFrom == newValidFrom` → старая запись удаляется, на её место встаёт новая;
  - `existingFrom < newValidFrom` → старая закрывается датой `newValidFrom - 1 день`;
  - `existingFrom > newValidFrom` → будущая запись удаляется (новая её перекрывает).
- Старый частичный индекс `idx_employee_rates_active_unique` удалён (избыточен; не учитывал `company_id`).

### `business_trip_rates`
- БД: EXCLUDE-constraint `business_trip_rates_no_overlap` запрещает пересечения в рамках `(object_id, company_id, COALESCE(employee_id, sentinel-uuid))`. `COALESCE` нужен потому, что `NULL` `employee_id` означает «общая ставка»: без него EXCLUDE считал бы NULL≠NULL и не блокировал две пересекающиеся общие ставки на один объект.
- UI: `BusinessTripRateRepositoryImpl` уже выполнял `hasOverlappingPeriods()` и выбрасывал ошибку до записи. Constraint в БД — последняя линия защиты от прямых INSERT/UPDATE через миграции, импорты, ручной SQL.

