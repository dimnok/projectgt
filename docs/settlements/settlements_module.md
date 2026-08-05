# Модуль Взаиморасчёты (Settlements)

**Дата актуализации:** 5 августа 2026 года  
**Изменения:**
- Добавлен учёт оплат (этап 1): статусы, поле «Оплачено», фильтр, сводки «К оплате / Оплачено / Долг».
- Единая логика статуса: `computeSettlementPaymentStatus` + SQL-триггер `sync_settlement_payment_status`.
- Аудит модуля: сохранение скрытых полей при редактировании, синхронизация провайдеров, оптимистичный CRUD.
- Централизация: `SettlementOperationsTotals`, `settlement_actions.dart`, `resolvedPaymentStatus`.

## ⚠️ Важное замечание

- **Владение таблицей:** `settlement_operations` (Owner — модуль Settlements).
- **Изоляция:** `company_id` + RLS через `get_my_company_ids()` и `check_permission(..., 'settlements', ...)`.
- **RBAC-модуль:** `settlements` в `app_modules` (название «Взаиморасчёты», `sort_order = 92`).
- **Не путать** с вкладкой «Акты» в договоре (`contract_acts`) и с ДДС (`cash_flow`): это отдельный контур учёта выставленных счетов.
- Статус оплаты в `contract_acts` **не синхронизируется** с Settlements (параллельные контуры).
- История частичных оплат и связка с ДДС — **roadmap (этап 2)**.

## 📝 Описание

Модуль **Settlements** предназначен для учёта выставленных счетов на оплату по договорам. Одна сущность — **операция = счёт** с типом; реквизиты счёта и (для типа «По акту») номер акта живут в одной карточке.

**Ключевые функции:**
- Типы счетов: **По акту**, **Аванс**, **Прочее**.
- Ручной CRUD счетов; автономер по договору с сохранением префикса.
- НДС: произвольная ставка, режим «в сумме» / «сверху»; автоматический расчёт базы, НДС и итога.
- **Учёт оплат (этап 1):** поле «Оплачено», автоматический статус, фильтр, сводки.
- Общий реестр компании с поиском и фильтрами + вкладка **«Финансы»** в карточке договора.
- Работает для всех видов договоров (`customer` / `subcontract` / `supply`).

## 🔗 Зависимости

| Роль | Таблицы / модули |
|------|------------------|
| **Owner** | `settlement_operations` |
| **Usage** | `contracts`, `contractors`, `objects`, `companies`, `auth.users` (created_by) |
| **RBAC** | `app_modules.code = 'settlements'`, `role_permissions` |
| **Не зависит** | `contract_acts`, `contract_act_lines`, Edge `ks2_operations`, `cash_flow` |

## 🖼️ Слой Presentation

### Экраны
| Виджет | Назначение |
|--------|------------|
| `SettlementsListScreen` | Реестр компании: atmosphere-шапка, таблица счетов, фильтры |
| Маршрут | `/settlements` (`AppRoutes.settlements`), право `settlements` / `read` |
| Меню | `AppDrawer` → «Взаиморасчёты`, `AppRoute.settlements` |

### Виджеты
| Виджет | Назначение |
|--------|------------|
| `SettlementsFiltersToolbar` | Поиск, фильтр типа, фильтр оплаты, сводки, обновить, «Новый» |
| `SettlementsOperationsTable` | Flex-таблица: дата, тип, счёт, акт, договор, контрагент, объект, **к оплате**, **статус**, **оплачено**, **остаток** |
| `SettlementFormDialog` | Создание/редактирование счёта (ширина 920 на desktop) |
| `ContractSettlementsSection` | Вкладка `ContractDetailNavigationSection.finances` в карточке договора |

### Форма счёта (`SettlementFormDialog`)
Поля в логическом порядке:
1. **Объект** + **Контрагент** + **Договор** — в одну строку.
2. **Тип** — цветные стикеры: «По акту» / «Аванс» / «Прочее».
3. **Номер акта** — только для типа «По акту».
4. **Номер счёта** + **Дата счёта**.
5. **Сумма** + **Блок НДС** (круглая кнопка `НДС`, поле процента, переключатель «в сумме / сверху»).
6. **Сводка НДС** (при включённом НДС).
7. **Блок оплаты:** поле «Оплачено», кнопка «Оплачен полностью», сводка (к оплате / остаток / статус).
8. **Примечание**.

При редактировании сохраняются скрытые поля из БД: `period_from/to`, `act_date`, `purpose`, удержания, `created_by`.

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

После CRUD вызывается `syncSettlementProviders(ref, contractId: ...)` — оба списка остаются синхронными.

### Design System
- Шапка: `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, `MobileAtmosphereChromeCircleButton`
- Форма: `DesktopDialogContent` (width 920) / `MobileBottomSheetContent`, `GTTextField`, `GTDropdown`, `GTButtons`
- Форматтеры: `formatCurrency`, `formatRuDate`, `parseAmount`, `amountFormatter` из `lib/core/utils/formatters.dart`
- Права: `PermissionGuard(module: 'settlements', ...)`

## ⚙️ Слой Domain / Data

### Сущности
- `SettlementOperation` (Freezed) — счёт на оплату
- `SettlementOperationType`: `act` | `advance` | `other`
- `SettlementPaymentStatus`: `unpaid` | `partial` | `paid` | `overpaid`
- Хелперы:
  - `computeSettlementTotalToPay` — сумма к оплате
  - `computeSettlementPaymentStatus` — статус из сумм (eps = 0.005)
  - `resolvedPaymentStatus` — **единственный способ** получить статус в UI
  - `remainingAmount`, `positiveDebt`, `hasOutstandingDebt`, `hasOverpayment`
- `SettlementOperationsTotals` — extension на `List<SettlementOperation>` (totalAmount, totalPaid, totalDebt)

### Репозиторий
- Контракт: `SettlementRepository`
- Реализация: `SettlementRepositoryImpl` — таблица `settlement_operations`, select с join:
  - `objects:object_id(name)`
  - `contractors:contractor_id(short_name)`
  - `contracts:contract_id(number)`
- Методы: `getOperations({contractId?})`, `createOperation`, `updateOperation`, `deleteOperation`, `getNextInvoiceNumber(contractId)`
- `getNextInvoiceNumber`: последние 500 счетов по договору (order by `invoice_date` DESC), парсинг суффикса в Dart

### Автономер счёта
`getNextInvoiceNumber(contractId)`:
- Извлекает завершающую группу цифр (regex): `сч-13` → 13, `217-3` → 3.
- Берёт максимум и его префикс → `префикс + (max + 1)`.
- Ограничение: учитываются только последние 500 счетов по дате.

### Модель
- `SettlementOperationModel` (Freezed + json_serializable, `FieldRename.snake`)
- `toWriteJson` исключает: `total_to_pay`, `payment_status`, `created_at`, `created_by`
- `toDomain()` пересчитывает `paymentStatus` через `computeSettlementPaymentStatus`

### CRUD (оптимистичное обновление)
`SettlementListNotifier`:
1. Выполняет операцию в репозитории.
2. Сразу обновляет локальный список (upsert/remove).
3. Фоновый `load(quiet: true)` — при ошибке reload сохраняется оптимистичное состояние.

## 📂 Дерево файлов

```
lib/features/settlements/
├── domain/
│   ├── entities/settlement_operation.dart
│   └── repositories/settlement_repository.dart
├── data/
│   ├── models/settlement_operation_model.dart
│   └── repositories/settlement_repository_impl.dart
└── presentation/
    ├── screens/settlements_list_screen.dart
    ├── state/settlement_state.dart
    ├── utils/
    │   ├── settlement_ui_labels.dart
    │   └── settlement_actions.dart
    └── widgets/
        ├── settlement_form_dialog.dart
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
└── 20260805130000_backfill_settlement_payment_status.sql

docs/settlements/
└── settlements_module.md
```

## 🗄️ База данных (Audit)

**Источник аудита:** live DB через MCP Supabase (`api.progt.ru`), 05.08.2026.  
**Миграции:** 6 файлов (см. дерево выше).

### Таблица `settlement_operations`

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID | NO | PK, `gen_random_uuid()` |
| `company_id` | UUID | NO | FK → `companies` ON DELETE CASCADE |
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
| `is_vat_included` | BOOLEAN | NO | `true` = НДС в сумме (default `true`) |
| `vat_rate` | NUMERIC | YES | Ставка НДС. `NULL` = без НДС |
| `vat_amount` | NUMERIC | NO | Сумма НДС ≥ 0 |
| `advance_retention` | NUMERIC | NO | Авансовые удержания ≥ 0 (в UI не редактируется) |
| `warranty_retention` | NUMERIC | NO | Гарантийные удержания ≥ 0 (в UI не редактируется) |
| `total_to_pay` | NUMERIC | — | **GENERATED STORED:** `GREATEST(0, amount + vat_amount − advance_retention − warranty_retention)` |
| `paid_amount` | NUMERIC | NO | Оплачено ≥ 0 (default 0) |
| `payment_status` | TEXT | NO | `unpaid` \| `partial` \| `paid` \| `overpaid` — **триггер** |
| `purpose` | TEXT | YES | Назначение (в UI не редактируется) |
| `note` | TEXT | YES | Примечание |
| `created_at` / `updated_at` | TIMESTAMPTZ | NO | `updated_at` — trigger `set_updated_at` |
| `created_by` | UUID | YES | FK → `auth.users` (не перезаписывается при update) |

**CHECK (ключевые):**
- `operation_type` ∈ (`act`, `advance`, `other`).
- `payment_status` ∈ (`unpaid`, `partial`, `paid`, `overpaid`).
- Для `act`: `act_number` не пустой.
- Для `advance` / `other`: `act_number` IS NULL, `act_date` IS NULL, удержания = 0.

### Триггеры

| Триггер | Назначение |
|---------|------------|
| `trg_settlement_operations_updated_at` | `updated_at = now()` |
| `trg_settlement_payment_status` | Пересчёт `payment_status` из `paid_amount` и `total_to_pay` (eps = 0.005) |

### RLS

**RLS:** ✅ **Включён** (`relrowsecurity = true`)

| Policy | Команда | Условие (смысл) |
|--------|---------|-----------------|
| `Strict SELECT for settlement_operations` | SELECT | `company_id ∈ get_my_company_ids()` AND `check_permission(..., 'settlements', 'read')` |
| `Strict INSERT for settlement_operations` | INSERT | company + `create` |
| `Strict UPDATE for settlement_operations` | UPDATE | company + `update` |
| `Strict DELETE for settlement_operations` | DELETE | company + `delete` |

### Индексы

- `idx_settlement_operations_company` — `(company_id)`
- `idx_settlement_operations_contract` — `(contract_id, invoice_date DESC)`
- `idx_settlement_operations_status` — `(company_id, payment_status)`
- `idx_settlement_operations_type` — `(company_id, operation_type)`

### Edge Functions

**Нет.** Модуль не использует Edge Functions.

## 🧠 Бизнес-логика

### Типы счетов

| Тип | Когда | Особенности полей |
|-----|-------|-------------------|
| **По акту** | Закрыли работы/поставку и выставили счёт | Номер акта обязателен |
| **Аванс** | Предоплата до акта | Без акта и удержаний |
| **Прочее** | Доплата, корректировка и т.п. | Без акта и удержаний |

### НДС

- **НДС в сумме** (`is_vat_included = true`): `база = сумма / (1 + ставка/100)`, `итого = сумма`.
- **НДС сверху** (`is_vat_included = false`): `база = сумма`, `итого = сумма + НДС`.
- В БД: `amount` = база; `total_to_pay` (generated) = `amount + vat_amount − удержания`.

### Статусы оплаты (этап 1)

Статус **не выбирается вручную** — рассчитывается из сумм:

| Статус | Условие |
|--------|---------|
| `unpaid` | `paid_amount ≤ 0` |
| `partial` | `0 < paid_amount < total_to_pay` |
| `paid` | `paid_amount ≈ total_to_pay` (или `total_to_pay = 0`) |
| `overpaid` | `paid_amount > total_to_pay` |

```text
total_to_pay = GREATEST(0, amount + vat_amount − advance_retention − warranty_retention)
остаток      = total_to_pay − paid_amount
долг         = max(0, остаток)   // при eps = 0.005
```

**Источники правды:**
- Запись: SQL-триггер `sync_settlement_payment_status`
- Чтение/UI: `resolvedPaymentStatus` → `computeSettlementPaymentStatus`

### Сценарии

1. **Новый счёт:** объект/контрагент/договор → автономер → тип → сумма/НДС → (оплата) → сохранить.
2. **Редактирование:** открыть строку → изменить → сохранить (скрытые поля БД сохраняются).
3. **Контроль по договору:** вкладка «Финансы» — список + сводки.
4. **Фильтрация:** по типу, статусу оплаты, текстовый поиск; сводки считаются по отфильтрованному списку.

## 🔌 Интеграции

| Интеграция | Как |
|------------|-----|
| Договоры | FK `contract_id`; вкладка «Финансы»; наследование НДС из договора |
| Объекты / Контрагенты | FK + dropdown в форме |
| Роли | модуль `settlements` в матрице прав |
| ДДС (`cash_flow`) | **нет связи** (roadmap) |
| Акты КС-2 (`contract_acts`) | **нет связи** |
| Storage / файлы счетов | **нет** (roadmap) |

## 🗺 Roadmap

### Реализовано
- ✅ Таблица + RLS + RBAC
- ✅ CRUD счетов, автономер, НДС
- ✅ Реестр `/settlements` + вкладка «Финансы»
- ✅ **Учёт оплат (этап 1):** статусы, поле «Оплачено», фильтр, сводки
- ✅ Единая логика статуса (Dart + SQL-триггер)
- ✅ Тесты `computeSettlementPaymentStatus`
- ✅ Аудит: сохранение скрытых полей, синхронизация провайдеров, оптимистичный CRUD

### Планы
- 🟡 История частичных оплат (`settlement_payments`) — этап 2
- 🟡 Привязка оплат к строкам ДДС
- 🟡 Файлы PDF/скан к счёту
- 🟡 UI для удержаний, периода, назначения
- 🟢 Табличная часть счёта, печать PDF

### Известные ограничения
- Автономер: только последние 500 счетов по договору.
- Фильтрация — на клиенте (при росте данных — серверные фильтры).
- `contract_acts.payment_status` не связан с Settlements.
