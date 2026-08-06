# Модуль Взаиморасчёты (Settlements)

**Дата актуализации:** 6 августа 2026 года  
**Изменения:**
- Упрощена панель реестра: убраны дублирующие сводки «К оплате / Оплачено / Долг» и кнопка «Обновить» (итоги — в подвале таблицы; список обновляется при открытии и после CRUD).
- **Интеграция с ДДС:** оплата из банковской выписки создаёт `settlement_payment` с привязкой `cash_flow_transaction_id`.
- Колонка `cash_flow_transaction_id` в `settlement_payments` + уникальный индекс (1 транзакция ДДС = 1 оплата).
- Триггер `trg_guard_linked_settlement_payment` — защита оплат из выписки от ручного изменения/удаления.
- В `SettlementDetailsDialog` оплаты из выписки помечаются «Из выписки», edit/delete заблокированы в UI.
- RPC `process_bank_statement_entry` расширен параметром `p_settlement_operation_id`.
- Окно деталей счёта (`SettlementDetailsDialog`) с историей оплат.
- Таблица `settlement_payments` + триггер синхронизации `paid_amount` и `payment_status`.
- Форма счёта — только реквизиты; оплаты — в деталях.
- Удаление счёта из таблицы убрано (только через детали).
- Исправлена синхронизация статусов при изменении оплат.

## ⚠️ Важное замечание

- **Владение таблицами:** `settlement_operations`, `settlement_payments` (Owner — модуль Settlements).
- **Изоляция:** `company_id` + RLS через `get_my_company_ids()` и `check_permission(..., 'settlements', ...)`.
- **RBAC-модуль:** `settlements` в `app_modules` (название «Взаиморасчёты», `sort_order = 92`).
- **Не путать** с вкладкой «Акты» в договоре (`contract_acts`) и с ДДС (`cash_flow`): это разные контуры (начисления vs факт денег), но **оплаты из выписки связаны** через `settlement_payments.cash_flow_transaction_id`.
- Статус оплаты в `contract_acts` **не синхронизируется** с Settlements (параллельные контуры).
- `paid_amount` и `payment_status` **не пишутся клиентом** — пересчитываются триггерами из `settlement_payments`.

## 📝 Описание

Модуль **Settlements** предназначен для учёта выставленных счетов на оплату по договорам. Одна сущность — **операция = счёт** с типом; реквизиты счёта и (для типа «По акту») номер акта живут в одной карточке. **Оплаты** — отдельные записи в `settlement_payments`.

**Ключевые функции:**
- Типы счетов: **По акту**, **Аванс**, **Прочее**.
- Ручной CRUD счетов; автономер по договору с сохранением префикса.
- НДС: произвольная ставка, режим «в сумме» / «сверху»; автоматический расчёт базы, НДС и итога.
- **История оплат:** частичные и полные платежи по счёту — вручную в окне деталей или **автоматически из банковской выписки** (модуль ДДС).
- Автоматический статус оплаты, фильтры; итоги «К оплате / Оплачено / Остаток» — в подвале таблицы реестра.
- Общий реестр компании с поиском и фильтрами + вкладка **«Финансы»** в карточке договора.
- Работает для всех видов договоров (`customer` / `subcontract` / `supply`).

## 🔗 Зависимости

| Роль | Таблицы / модули |
|------|------------------|
| **Owner** | `settlement_operations`, `settlement_payments` |
| **Usage** | `contracts`, `contractors`, `objects`, `companies`, `auth.users` (created_by), `cash_flow` (через `settlement_payments.cash_flow_transaction_id`) |
| **RBAC** | `app_modules.code = 'settlements'`, `role_permissions` |
| **Не зависит** | `contract_acts`, `contract_act_lines`, Edge `ks2_operations` |

## 🖼️ Слой Presentation

### Экраны
| Виджет | Назначение |
|--------|------------|
| `SettlementsListScreen` | Реестр компании: atmosphere-шапка, таблица счетов, фильтры |
| Маршрут | `/settlements` (`AppRoutes.settlements`), право `settlements` / `read` |
| Меню | `AppDrawer` → «Взаиморасчёты», `AppRoute.settlements` |

### Виджеты
| Виджет | Назначение |
|--------|------------|
| `SettlementsFiltersToolbar` | Поиск, фильтр типа, фильтр оплаты, «Новый» |
| `SettlementsOperationsTable` | Flex-таблица: дата, тип, счёт, акт, договор, контрагент, объект, **к оплате**, **статус**, **оплачено**, **остаток**; подвал с итогами по отфильтрованным строкам |
| `SettlementDetailsDialog` | Детали счёта (ширина 960 на desktop): реквизиты, сводка, таблица оплат, редактирование/удаление |
| `SettlementFormDialog` | Создание/редактирование реквизитов счёта (ширина 920 на desktop) |
| `SettlementPaymentFormDialog` | Добавление/редактирование одной оплаты |
| `ContractSettlementsSection` | Вкладка `ContractDetailNavigationSection.finances` в карточке договора |

### Окно деталей (`SettlementDetailsDialog`)
1. **Сводка:** к оплате / оплачено / остаток / статус.
2. **Реквизиты:** дата, тип, акт, договор, контрагент, объект, суммы, НДС, примечание.
3. **Таблица оплат:** дата, сумма, примечание; добавить / редактировать / удалить (право `update`).
   - Оплаты с `cash_flow_transaction_id` (из выписки): пометка **«Из выписки»**, кнопки edit/delete скрыты; изменение только через удаление транзакции в ДДС.
4. **Действия:** «Редактировать» (форма счёта), «Удалить» (право `delete`, каскадно удаляет оплаты).

**Навигация:** тап по строке в реестре или вкладке «Финансы» → детали (не форма редактирования).

### Форма счёта (`SettlementFormDialog`)
Поля в логическом порядке:
1. **Объект** + **Контрагент** + **Договор** — в одну строку.
2. **Тип** — цветные стикеры: «По акту» / «Аванс» / «Прочее».
3. **Номер акта** — только для типа «По акту».
4. **Номер счёта** + **Дата счёта**.
5. **Сумма** + **Блок НДС** (круглая кнопка `НДС`, поле процента, переключатель «в сумме / сверху»).
6. **Сводка НДС** (при включённом НДС).
7. **Примечание**.

**Оплаты в форме не редактируются** — только в `SettlementDetailsDialog`.

При смене типа с «По акту» на «Аванс»/«Прочее» очищаются поля акта (`act_number`, `act_date`, `period_from/to`).

При редактировании сохраняются скрытые поля из БД: `purpose`, удержания, `created_by`.

### Утилиты UI
| Файл | Назначение |
|------|------------|
| `settlement_ui_labels.dart` | Подписи типов и статусов оплаты, цвета бейджей |
| `settlement_actions.dart` | `syncSettlementProviders`, `showSettlementDeleteConfirmDialog` |

### Провайдеры состояния
| Provider | Назначение |
|----------|------------|
| `settlementRepositoryProvider` | DI репозитория (Supabase + `activeCompanyId`) |
| `settlementListProvider` | Список счетов компании |
| `contractSettlementsProvider(contractId)` | Список счетов по договору |
| `settlementPaymentsProvider(operationId)` | Список оплат по счёту (autoDispose) |

После CRUD счёта или оплаты вызывается `syncSettlementProviders(ref, contractId: ...)` — оба списка остаются синхронными. Ручное обновление реестра не требуется: данные подгружаются при первом открытии экрана и после операций create/update/delete.

### Design System
- Шапка: `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, `MobileAtmosphereChromeCircleButton`
- Диалоги: `DesktopDialogContent` / `MobileBottomSheetContent`, `GTTextField`, `GTDropdown`, `GTButtons`, `GTConfirmationDialog`
- Форматтеры: `formatCurrency`, `formatRuDate`, `parseAmount`, `amountFormatter` из `lib/core/utils/formatters.dart`
- Права: `permissionServiceProvider` / `PermissionGuard(module: 'settlements', ...)`

## ⚙️ Слой Domain / Data

### Сущности
- `SettlementOperation` (Freezed) — счёт на оплату
- `SettlementPayment` (Freezed) — одна оплата по счёту; поле `cashFlowTransactionId` (nullable); геттер `isFromBankStatement`
- `SettlementOperationType`: `act` | `advance` | `other`
- `SettlementPaymentStatus`: `unpaid` | `partial` | `paid` | `overpaid`
- Хелперы:
  - `computeSettlementPaymentStatus` — статус из сумм (eps = 0.005)
  - `resolvedPaymentStatus` — **единственный способ** получить статус в UI
  - `remainingAmount`, `positiveDebt`, `hasOutstandingDebt`, `hasOverpayment`
- `SettlementOperationsTotals` — extension на `List<SettlementOperation>` (totalAmount, totalPaid, totalDebt)

### Репозиторий
- Контракт: `SettlementRepository`
- Реализация: `SettlementRepositoryImpl`
- **Счета** (`settlement_operations`), select с join:
  - `objects:object_id(name)`
  - `contractors:contractor_id(short_name)`
  - `contracts:contract_id(number)`
- Методы счетов: `getOperations`, `getOperation`, `createOperation`, `updateOperation`, `deleteOperation`, `getNextInvoiceNumber`
- Методы оплат: `getPayments`, `createPayment`, `updatePayment`, `deletePayment`

### Модели
- `SettlementOperationModel` — `toWriteJson` исключает: `total_to_pay`, `payment_status`, `paid_amount`, `created_at`, `created_by`
- `SettlementPaymentModel` — `toWriteJson` исключает `created_at`, `created_by`, `cash_flow_transaction_id`; `toUpdateJson` — только `payment_date`, `amount`, `note`

### CRUD (оптимистичное обновление)
`SettlementListNotifier` / `SettlementPaymentsNotifier`:
1. Выполняет операцию в репозитории.
2. Сразу обновляет локальный список.
3. Фоновый `load(quiet: true)` при необходимости.

## 📂 Дерево файлов

```
lib/features/settlements/
├── domain/
│   ├── entities/
│   │   ├── settlement_operation.dart
│   │   └── settlement_payment.dart
│   └── repositories/settlement_repository.dart
├── data/
│   ├── models/
│   │   ├── settlement_operation_model.dart
│   │   └── settlement_payment_model.dart
│   └── repositories/settlement_repository_impl.dart
└── presentation/
    ├── screens/settlements_list_screen.dart
    ├── state/settlement_state.dart
    ├── utils/
    │   ├── settlement_ui_labels.dart
    │   └── settlement_actions.dart
    └── widgets/
        ├── settlement_details_dialog.dart
        ├── settlement_form_dialog.dart
        ├── settlement_payment_form_dialog.dart
        ├── settlements_filters_toolbar.dart
        ├── settlements_operations_table.dart
        └── contract_settlements_section.dart

test/features/settlements/
└── compute_settlement_payment_status_test.dart

supabase/migrations/
├── 20260720220000_create_settlement_operations.sql
├── 20260803180000_simplify_settlement_operations_constraints.sql
├── 20260804120000_add_settlement_vat_rate.sql
├── 20260804130000_add_settlement_is_vat_included.sql
├── 20260805120000_settlement_payment_status_trigger.sql
├── 20260805130000_backfill_settlement_payment_status.sql
├── 20260805140000_create_settlement_payments.sql
├── 20260805150000_fix_settlement_payment_status_sync.sql
├── 20260805160000_link_settlement_payments_to_cash_flow.sql
└── 20260805170000_fix_settlement_bank_payment_security.sql

docs/settlements/
└── settlements_module.md
```

## 🗄️ База данных (Audit)

**Источник аудита:** live DB через MCP Supabase (`api.progt.ru`), 05.08.2026.  
**Миграции:** 10 файлов (см. дерево выше).

### Таблица `settlement_operations`

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID | NO | PK |
| `company_id` | UUID | NO | FK → `companies` |
| `operation_type` | TEXT | NO | `act` \| `advance` \| `other` |
| `object_id` | UUID | NO | FK → `objects` |
| `contractor_id` | UUID | NO | FK → `contractors` |
| `contract_id` | UUID | NO | FK → `contracts` ON DELETE CASCADE |
| `period_from` / `period_to` | DATE | YES | Период работ (в UI не редактируется) |
| `act_number` | TEXT | YES | Номер акта (обязателен для `act`) |
| `act_date` | DATE | YES | Дата акта (в UI не редактируется) |
| `invoice_number` | TEXT | NO | Номер счёта |
| `invoice_date` | DATE | NO | Дата счёта |
| `amount` | NUMERIC | NO | База (без НДС) ≥ 0 |
| `is_vat_included` | BOOLEAN | NO | `true` = НДС в сумме |
| `vat_rate` | NUMERIC | YES | Ставка НДС. `NULL` = без НДС |
| `vat_amount` | NUMERIC | NO | Сумма НДС ≥ 0 |
| `advance_retention` | NUMERIC | NO | Авансовые удержания ≥ 0 |
| `warranty_retention` | NUMERIC | NO | Гарантийные удержания ≥ 0 |
| `total_to_pay` | NUMERIC | — | **GENERATED STORED** |
| `paid_amount` | NUMERIC | NO | Сумма оплат (триггер из `settlement_payments`) |
| `payment_status` | TEXT | NO | `unpaid` \| `partial` \| `paid` \| `overpaid` |
| `purpose` | TEXT | YES | Назначение (в UI не редактируется) |
| `note` | TEXT | YES | Примечание |
| `created_at` / `updated_at` | TIMESTAMPTZ | NO | |
| `created_by` | UUID | YES | FK → `auth.users` |

### Таблица `settlement_payments`

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID | NO | PK |
| `company_id` | UUID | NO | FK → `companies` |
| `settlement_operation_id` | UUID | NO | FK → `settlement_operations` ON DELETE CASCADE |
| `payment_date` | DATE | NO | Дата оплаты |
| `amount` | NUMERIC | NO | Сумма > 0 |
| `note` | TEXT | YES | Примечание |
| `cash_flow_transaction_id` | UUID | YES | FK → `cash_flow(id)` ON DELETE CASCADE; уникален (partial index) |
| `created_at` / `updated_at` | TIMESTAMPTZ | NO | |
| `created_by` | UUID | YES | FK → `auth.users` |

**Индексы:**
- `idx_settlement_payments_operation` — `(settlement_operation_id, payment_date DESC)`
- `idx_settlement_payments_company` — `(company_id)`
- `idx_settlement_payments_cash_flow_unique` — UNIQUE `(cash_flow_transaction_id)` WHERE NOT NULL

### Триггеры

| Триггер | Назначение |
|---------|------------|
| `trg_settlement_operations_updated_at` | `updated_at = now()` |
| `trg_settlement_payment_status` | Пересчёт `payment_status` при изменении сумм счёта |
| `trg_settlement_payments_sync_paid` | Пересчёт `paid_amount` + `payment_status` из суммы `settlement_payments` |
| `trg_settlement_payments_updated_at` | `updated_at` на оплатах |
| `trg_guard_linked_settlement_payment` | Запрет UPDATE/DELETE оплат с `cash_flow_transaction_id` (кроме CASCADE при удалении ДДС) |

### RLS

**RLS:** ✅ **Включён** на обеих таблицах

| Таблица | SELECT | INSERT | UPDATE | DELETE |
|---------|--------|--------|--------|--------|
| `settlement_operations` | `read` | `create` | `update` | `delete` |
| `settlement_payments` | `read` | `update` | `update` | `update` |

Права на оплаты требуют `settlements` / `update` (не `create`).

### Edge Functions

**Нет.**

## 🧠 Бизнес-логика

### Сценарии

1. **Новый счёт:** «Новый» → форма реквизитов → сохранить (статус «Не оплачен»).
2. **Просмотр счёта:** тап по строке → детали + список оплат.
3. **Добавить оплату:** детали → «Добавить оплату» → сумма, дата, примечание.
4. **Редактировать счёт:** детали → «Редактировать» → форма реквизитов.
5. **Удалить счёт:** детали → «Удалить» (каскадно удаляет оплаты).
6. **Оплата из выписки (ДДС):** ДДС → Выписка → «Обработать» → выбрать договор → опционально счёт взаиморасчётов → сохранить. Атомарно: `cash_flow` + `settlement_payment` + пометка выписки. Статус счёта пересчитывается триггером.

### Оплаты из банковской выписки

| Шаг | Где | Действие |
|-----|-----|----------|
| 1 | ДДС → Выписка | Контекстное меню → «Обработать» |
| 2 | `CashFlowFormDialog` | Заполнить реквизиты ДДС, выбрать **договор** |
| 3 | Тот же диалог | Опционально: **Счёт взаиморасчётов** (только неоплаченные по договору; право `settlements` / `update`) |
| 4 | Сохранение | RPC `process_bank_statement_entry` с `p_settlement_operation_id` |

**Поведение при удалении транзакции ДДС:**
1. `ON DELETE CASCADE` удаляет связанную `settlement_payment`.
2. Триггер `sync_settlement_paid_amount_from_payments` пересчитывает `paid_amount` / `payment_status` счёта.
3. Триггер `on_cash_flow_transaction_deleted` возвращает строку выписки в статус «не обработана».

**Ограничения:**
- Одна транзакция ДДС → не более одной оплаты (unique index).
- Повторная обработка той же строки выписки блокируется в RPC (`is_imported = false`).
- Сумма из выписки целиком записывается в оплату (возможна переплата → статус `overpaid`).

### Статусы оплаты

Статус рассчитывается автоматически из `paid_amount` (сумма `settlement_payments`) и `total_to_pay`:

| Статус | Условие |
|--------|---------|
| `unpaid` | `paid_amount ≤ 0` |
| `partial` | `0 < paid_amount < total_to_pay` |
| `paid` | `paid_amount ≈ total_to_pay` |
| `overpaid` | `paid_amount > total_to_pay` |

**Источники правды:**
- Запись: `sync_settlement_paid_amount_from_payments` + `sync_settlement_payment_status`
- Чтение/UI: `resolvedPaymentStatus` → `computeSettlementPaymentStatus`

## 🔌 Интеграции

| Интеграция | Как |
|------------|-----|
| Договоры | FK `contract_id`; вкладка «Финансы»; наследование НДС из договора |
| Объекты / Контрагенты | FK + dropdown в форме |
| Роли | модуль `settlements` в матрице прав |
| ДДС (`cash_flow`) | `settlement_payments.cash_flow_transaction_id` → `cash_flow.id`; создание через RPC `process_bank_statement_entry(p_settlement_operation_id)` из `CashFlowFormDialog` |
| Акты КС-2 (`contract_acts`) | **нет связи** |

## 🗺 Roadmap

### Реализовано
- ✅ Таблица счетов + RLS + RBAC
- ✅ CRUD счетов, автономер, НДС
- ✅ Реестр `/settlements` + вкладка «Финансы»
- ✅ История оплат (`settlement_payments`)
- ✅ Окно деталей счёта с таблицей оплат
- ✅ Статусы оплаты (Dart + SQL-триггеры)
- ✅ Тесты `computeSettlementPaymentStatus`
- ✅ Привязка оплат к транзакциям ДДС (обработка банковской выписки)

### Планы
- 🟡 Автоподбор счёта по назначению платежа / сумме
- 🟡 Файлы PDF/скан к счёту
- 🟡 UI для удержаний, периода, назначения
- 🟢 Табличная часть счёта, печать PDF

### Известные ограничения
- Автономер: только последние 500 счетов по договору.
- Фильтрация — на клиенте.
- `contract_acts.payment_status` не связан с Settlements.
- Оплаты из выписки нельзя редактировать вручную — только через ДДС.
- Итог «Остаток» в таблице — сумма положительных долгов (`totalDebt`), не чистый нетто-остаток.
