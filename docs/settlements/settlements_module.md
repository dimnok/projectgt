# Модуль Взаиморасчёты (Settlements)

**Дата актуализации:** 9 августа 2026  
**Изменения:**
- Оптимизирована синхронизация после CRUD: один вызов `syncSettlementProviders` вместо дублирующих перезагрузок.
- Автономер счёта — RPC `get_next_settlement_invoice_number` (без лимита 500 на клиенте).
- Добавлены `invoice_number_sequence.dart` и тесты нумерации.
- **Рефакторинг (аудит DRY):** устранены дубликаты форматтеров/диалогов между файлами модуля; dead code удалён; явные колонки в выборках оплат; исправлен `BuildContext` после `await`.
  - Общие хелперы вынесены в `core/utils`: `dateOnlyToJson`, `moneyInputFormatters()`, `showAdaptiveModal()`, `pickRuDate()`.
  - Фильтры реестра приведены к стилю модуля «Табель»: `MenuAnchor`, иконки, прокрутка, галочки; тип и оплата объединены в `SettlementsExtraFiltersDropdown`.
  - Удалён неиспользуемый `computeSettlementTotalToPay` (считается в БД GENERATED ALWAYS).

## ⚠️ Важное замечание

- **Owner-таблицы:** `settlement_operations`, `settlement_payments`.
- **Изоляция:** `company_id` + RLS (`get_my_company_ids()`, `check_permission(..., 'settlements', ...)`).
- **RBAC:** модуль `settlements` в `app_modules` (`sort_order = 92`).
- `paid_amount` и `payment_status` **не пишутся клиентом** — пересчитываются триггерами из `settlement_payments`.
- **Не путать** с `contract_acts` (акты КС-2) и с начислениями; с **ДДС** связаны только оплаты из выписки (`cash_flow_transaction_id`).

## 📝 Описание

Учёт счетов на оплату по договорам. Одна запись = один счёт. Оплаты — отдельные строки в `settlement_payments`.

**Функции:**
- Типы счёта: акт, аванс, прочее.
- CRUD счетов и ручных оплат; автоподсказка номера счёта по договору.
- НДС: ставка, режим «в сумме» / «сверху».
- Оплаты из банковской выписки (модуль ДДС).
- Реестр компании + вкладка «Финансы» в карточке договора.
- Фильтры и поиск в реестре (клиентская фильтрация загруженного списка).

## 🔗 Зависимости

| Роль | Сущности |
|------|----------|
| Owner | `settlement_operations`, `settlement_payments` |
| Usage | `contracts`, `contractors`, `objects`, `companies`, `cash_flow` |
| RBAC | `app_modules`, `role_permissions` |
| Не связан | `contract_acts`, Edge `ks2_operations` |

## 🖼️ Presentation

### Экраны и маршруты

| Элемент | Назначение |
|---------|------------|
| `SettlementsListScreen` | Реестр счетов компании |
| `/settlements` | Маршрут, право `settlements` / `read` |
| `ContractSettlementsSection` | Вкладка «Финансы» в договоре |

### Виджеты

| Виджет | Назначение |
|--------|------------|
| `SettlementsFiltersToolbar` | Поиск, каскадные фильтры (контрагент / объект / договор), объединённый фильтр тип+оплата, «Сбросить», «Новый» |
| `SettlementsOptionBarDropdown` | Выпадающий фильтр по сущности (стиль `TimesheetObjectsBarDropdown`) |
| `SettlementsExtraFiltersDropdown` | Объединённый фильтр типа операции и статуса оплаты (стиль `TimesheetListFilterDropdown`) |
| `SettlementsToolbarMetrics` | Геометрия панели фильтров (высота 34, радиус 18) |
| `SettlementsOperationsTable` | Таблица счетов; `compact` — для вкладки договора |
| `SettlementDetailsDialog` | Детали, сводка, таблица оплат, редактирование/удаление |
| `SettlementFormDialog` | Создание/редактирование реквизитов счёта |
| `SettlementPaymentFormDialog` | Ручная оплата по счёту |

### Общие хелперы (core/utils)

Диалоги модуля используют общие утилиты проекта (устранено дублирование между файлами):

| Хелпер | Файл | Назначение |
|--------|------|------------|
| `showAdaptiveModal<T>(context, builder)` | `core/utils/adaptive_dialog.dart` | `Dialog` на десктопе / `showModalBottomSheet` на мобильном. Название намеренно отличается от Flutter `showAdaptiveDialog` |
| `pickRuDate(context, initialDate)` | `core/utils/adaptive_dialog.dart` | Единый `DatePicker` (диапазон 2020–2100) |
| `moneyInputFormatters()` | `core/utils/formatters.dart` | Готовый список форматтеров для ввода сумм |
| `dateOnlyToJson(DateTime?)` | `core/utils/formatters.dart` | Сериализация дат в `yyyy-MM-dd` для JSON-моделей Supabase |
| `formatAmount(num)` | `core/utils/formatters.dart` | Форматирование сумм (замена локальных `_fmtAmount`) |

### Провайдеры

| Provider | Назначение |
|----------|------------|
| `settlementRepositoryProvider` | DI репозитория |
| `settlementListProvider` | Все счета компании |
| `contractSettlementsProvider(contractId)` | Счета по договору |
| `settlementPaymentsProvider(operationId)` | Оплаты по счёту (autoDispose) |

### Синхронизация состояния

После CRUD счёта или оплаты:

1. **Notifier** сразу обновляет локальный список (`_upsertOperation` / `_removeOperation` / локальные оплаты).
2. **`await syncSettlementProviders(ref, contractId: ...)`** — единственная полная перезагрузка: общий реестр + список по договору (параллельно, `quiet: true`).
3. **`findSettlementOperationInProviders`** — обновление деталей счёта из провайдеров без лишнего `getOperation`.

Вызывается из: `SettlementFormDialog`, `SettlementDetailsDialog`, `CashFlowFormDialog` (при привязке к счёту).

### Фильтры реестра

Клиентская фильтрация `SettlementsListFilters.apply()` по данным `settlementListProvider`.

| Фильтр | Поле |
|--------|------|
| Поиск | номер счёта, акт, договор, контрагент, объект |
| Контрагент / Объект / Договор | каскадная связь |
| Тип / Оплата | enum; объединены в одну кнопку «Фильтры» |

Опции выпадающих списков — `SettlementsFilterOptionsBuilder` из загруженных операций.  
UI фильтров — `MenuAnchor` (как в модуле «Табель»): иконки, заголовки секций, галочки, прокрутка длинных списков.

## ⚙️ Domain / Data

### Сущности

- `SettlementOperation` — счёт; `SettlementPayment` — оплата.
- `SettlementOperationType`: `act` \| `advance` \| `other`.
- `SettlementPaymentStatus`: `unpaid` \| `partial` \| `paid` \| `overpaid`.
- Статус в UI: только `resolvedPaymentStatus` → `computeSettlementPaymentStatus` (eps = 0.005).
- `SettlementOperationsTotals` — итоги по списку (`totalAmount`, `totalPaid`, `totalDebt`).

### Утилиты

| Файл | Назначение |
|------|------------|
| `invoice_number_sequence.dart` | Парсинг и расчёт следующего номера (зеркало SQL RPC) |
| `settlement_actions.dart` | `syncSettlementProviders`, `findSettlementOperationInProviders`, диалог удаления |
| `settlement_ui_labels.dart` | Подписи и цвета статусов |
| `settlements_list_filters.dart` | Состояние и логика фильтров |
| `settlements_filter_options.dart` | Опции фильтров из операций |

### Репозиторий (`SettlementRepositoryImpl`)

**Счета** — select с join `objects`, `contractors`, `contracts`:

| Метод | Описание |
|-------|----------|
| `getOperations({contractId})` | Список; фильтр по договору опционален |
| `getOperation(id)` | Одна операция |
| `createOperation` / `updateOperation` / `deleteOperation` | CRUD |
| `getNextInvoiceNumber(contractId)` | RPC `get_next_settlement_invoice_number` |

**Оплаты** — select с явным перечислением колонок `_paymentSelect` (без `select()` «всё»):

| Метод | Описание |
|-------|----------|
| `getPayments` / `createPayment` / `updatePayment` / `deletePayment` | CRUD оплат |

`toWriteJson` счёта исключает: `total_to_pay`, `payment_status`, `paid_amount`, `created_at`, `created_by`.  
`toUpdateJson` оплаты — только `payment_date`, `amount`, `note`.  
`cash_flow_transaction_id` не пишется клиентом.  
Сериализация дат (`period_from`, `period_to`, `act_date`, `invoice_date`, `payment_date`) — через общий `dateOnlyToJson` из `core/utils/formatters.dart`.

## 📂 Дерево файлов

```
lib/features/settlements/
├── domain/
│   ├── entities/
│   │   ├── settlement_operation.dart
│   │   └── settlement_payment.dart
│   ├── repositories/settlement_repository.dart
│   └── utils/invoice_number_sequence.dart
├── data/
│   ├── models/
│   │   ├── settlement_operation_model.dart
│   │   └── settlement_payment_model.dart
│   └── repositories/settlement_repository_impl.dart
└── presentation/
    ├── screens/settlements_list_screen.dart
    ├── state/settlement_state.dart
    ├── utils/
    │   ├── settlement_actions.dart
    │   ├── settlement_ui_labels.dart
    │   ├── settlements_filter_options.dart
    │   └── settlements_list_filters.dart
    └── widgets/
        ├── contract_settlements_section.dart
        ├── settlement_details_dialog.dart
        ├── settlement_form_dialog.dart
        ├── settlement_payment_form_dialog.dart
        ├── settlements_extra_filters_dropdown.dart
        ├── settlements_filters_toolbar.dart
        ├── settlements_option_bar_dropdown.dart
        ├── settlements_operations_table.dart
        └── settlements_toolbar_metrics.dart

test/features/settlements/
├── compute_settlement_payment_status_test.dart
└── invoice_number_sequence_test.dart
```

## 🗄️ База данных (Audit)

**RLS:** ✅ на `settlement_operations` и `settlement_payments`.

### `settlement_operations`

| Колонка | Тип | Примечание |
|---------|-----|------------|
| `id` | UUID | PK |
| `company_id` | UUID | FK → `companies` |
| `operation_type` | TEXT | `act` \| `advance` \| `other` |
| `object_id`, `contractor_id`, `contract_id` | UUID | FK |
| `invoice_number`, `invoice_date` | TEXT, DATE | Номер и дата счёта |
| `act_number` | TEXT | Обязателен для `act` |
| `amount`, `vat_amount` | NUMERIC | База и НДС |
| `is_vat_included`, `vat_rate` | BOOL, NUMERIC | Режим НДС |
| `advance_retention`, `warranty_retention` | NUMERIC | Удержания (в UI не редактируются) |
| `total_to_pay` | NUMERIC | GENERATED STORED |
| `paid_amount`, `payment_status` | NUMERIC, TEXT | Триггеры из оплат |
| `period_from/to`, `act_date`, `purpose` | — | В UI не редактируются |
| `note` | TEXT | Примечание |

**Индексы:** `(company_id)`, `(contract_id, invoice_date DESC)`, `(company_id, payment_status)`, `(company_id, operation_type)`.

### `settlement_payments`

| Колонка | Тип | Примечание |
|---------|-----|------------|
| `settlement_operation_id` | UUID | FK, ON DELETE CASCADE |
| `payment_date`, `amount` | DATE, NUMERIC | amount > 0 |
| `cash_flow_transaction_id` | UUID | FK → `cash_flow`, UNIQUE (partial) |
| `note` | TEXT | |

**Индексы:** `(settlement_operation_id, payment_date DESC)`, `(company_id)`, UNIQUE `(cash_flow_transaction_id)` WHERE NOT NULL.

### Триггеры

| Триггер | Назначение |
|---------|------------|
| `trg_settlement_payments_sync_paid` | `paid_amount` из суммы оплат |
| `trg_settlement_payment_status` | `payment_status` по суммам |
| `trg_guard_linked_settlement_payment` | Защита оплат из выписки от ручного UPDATE/DELETE |
| `trg_settlement_*_updated_at` | `updated_at` |

### Функции

| Функция | Назначение |
|---------|------------|
| `get_next_settlement_invoice_number(company_id, contract_id)` | Подсказка следующего номера: max завершающей цифровой группы + 1 |
| `process_bank_statement_entry` | Создание ДДС + оплаты (параметр `p_settlement_operation_id`) |

### RLS-права

| Таблица | SELECT | INSERT | UPDATE | DELETE |
|---------|--------|--------|--------|--------|
| `settlement_operations` | read | create | update | delete |
| `settlement_payments` | read | update | update | update |

### Edge Functions

Нет.

## 🧠 Бизнес-логика

### Формулы

```
total_to_pay = max(0, amount + vat_amount - advance_retention - warranty_retention)
```

Статус оплаты — `computeSettlementPaymentStatus(total_to_pay, paid_amount)`; в БД дублируется триггером `sync_settlement_payment_status`.

### Автономер счёта

Алгоритм (Dart `computeNextInvoiceNumber` = SQL RPC):

1. Scope: `(company_id, contract_id)`.
2. Из каждого `invoice_number` берётся последняя группа цифр (`(\d+)\s*$`).
3. Выбирается **максимальное** число; префикс — из строки-победителя.
4. Результат: `prefix + (max + 1)` (без дополнения нулями).

Примеры: `сч-13` → `сч-14`; при `сч-13` и `217-20` → `217-21`.

**Ограничение:** подсказка, не резервирование. Параллельное создание с одним номером возможно (UNIQUE на `invoice_number` нет).

### Сценарии

1. **Новый счёт** → форма → `syncSettlementProviders`.
2. **Детали** → тап по строке; при открытии — `getOperation` + загрузка оплат.
3. **Оплата** → вручную в деталях или из выписки ДДС.
4. **Удаление счёта** → только из деталей; каскадно удаляет оплаты.

### Оплаты из выписки (ДДС)

- Создание: `CashFlowFormDialog` → RPC `process_bank_statement_entry`.
- В UI: пометка «Из выписки», edit/delete заблокированы.
- Удаление транзакции ДДС → CASCADE оплаты → пересчёт `paid_amount`.

## 🔌 Интеграции

| Модуль | Связь |
|--------|-------|
| Договоры | FK, вкладка «Финансы», наследование НДС |
| ДДС | `cash_flow_transaction_id`, RPC при обработке выписки |
| Роли | `settlements` в матрице прав |
| Акты КС-2 | Нет связи |

## 🗺 Roadmap

### Реализовано

- CRUD счетов и оплат, RLS, RBAC
- Реестр, фильтры, вкладка «Финансы»
- Статусы оплаты (Dart + SQL)
- Интеграция с ДДС
- Оптимизированная синхронизация провайдеров
- RPC автономера счёта
- Тесты: статус оплаты, нумерация
- Рефакторинг DRY: общие хелперы в `core/utils`, унифицированный chip-фильтр, явные колонки в выборках оплат, удалён dead code (`computeSettlementTotalToPay`), исправлен `BuildContext` после `await`

### Планы

- 🟡 Серверные фильтры и пагинация реестра (эталон — Cash Flow)
- 🟡 UNIQUE на `(company_id, contract_id, invoice_number)` + обработка конфликта
- 🟡 UI для удержаний, периода, назначения
- 🟢 PDF/сканы к счёту

### Известные ограничения

- Реестр загружает все счета компании; фильтрация на клиенте; лимит PostgREST ~1000 строк.
- Дубликаты номеров счёта при одновременном создании не блокируются.
- `contract_acts.payment_status` не связан с Settlements.
- Итог «Остаток» в таблице — сумма положительных долгов (`totalDebt`).
