# Модуль Взаиморасчёты (Settlements)

**Дата актуализации:** 20 июля 2026 года  
**Изменения:**
- Первая версия модуля: операции учёта счетов и оплат (типы Акт / Аванс / Прочее).
- UI-реестр в стиле Табеля/ФОТ (atmosphere-шапка, компактная панель фильтров, flex-таблица).
- Форма создания/редактирования с сегментом типа, блоками полей и живой сводкой сумм.
- Вкладка «Финансы» в карточке договора заполнена секцией операций.
- Параллельно блоку «Акты» договора (`contract_acts` / КС-2) — **не заменяет** формирование КС-2.

## ⚠️ Важное замечание

- **Владение таблицей:** `settlement_operations` (Owner — модуль Settlements).
- **Изоляция:** `company_id` + RLS через `get_my_company_ids()` и `check_permission(..., 'settlements', ...)`.
- **RBAC-модуль:** `settlements` в `app_modules` (название «Взаиморасчёты», `sort_order = 92`).
- При миграции права скопированы с модуля `contracts` для существующих ролей; далее настраиваются в UI «Роли».
- **Не путать** с вкладкой «Акты» в договоре (`contract_acts`) и с ДДС (`cash_flow`): это отдельный контур учёта выставления и оплаты.
- Файлы счетов (PDF/скан) и связка оплат с ДДС — **не в v1** (roadmap).

## 📝 Описание

Модуль **Settlements** предназначен для учёта финансовых операций по договорам: выставление счетов, фиксация оплат, контроль долга. Одна сущность — **операция** с типом; счёт и (при необходимости) данные акта живут в одной карточке.

**Ключевые функции:**
- Типы операций: **Акт**, **Аванс**, **Прочее**.
- Ручной CRUD операций; статус оплаты считается из сумм «Оплачено» и «К оплате».
- Общий реестр компании с поиском и фильтрами + вкладка **«Финансы»** в карточке договора.
- Сводка: выставлено / оплачено / долг.
- Работает для всех видов договоров (`customer` / `subcontract` / `supply`).

## 🔗 Зависимости

| Роль | Таблицы / модули |
|------|------------------|
| **Owner** | `settlement_operations` |
| **Usage** | `contracts`, `contractors`, `objects`, `companies`, `auth.users` (created_by) |
| **RBAC** | `app_modules.code = 'settlements'`, `role_permissions` |
| **Не зависит** | `contract_acts`, `contract_act_lines`, Edge `ks2_operations`, `cash_flow` (в v1) |

## 🖼️ Слой Presentation

### Экраны
| Виджет | Назначение |
|--------|------------|
| `SettlementsListScreen` | Реестр компании: atmosphere-шапка (как Табель/ФОТ), `MobileAtmosphereMainSurface`, таблица операций |
| Маршрут | `/settlements` (`AppRoutes.settlements`), право `settlements` / `read` |
| Меню | `AppDrawer` → «Взаиморасчёты», `AppRoute.settlements` |

### Виджеты
| Виджет | Назначение |
|--------|------------|
| `SettlementsFiltersToolbar` | Компактная панель: поиск, тип, статус, сводка, обновить, «Новая» |
| `SettlementsOperationsTable` | Flex-таблица на всю ширину (без горизонтального скролла); строка ИТОГО |
| `SettlementFormDialog` | Создание/редактирование: сегмент типа, блоки Контекст / Акт / Счёт / Суммы, сводка |
| `ContractSettlementsSection` | Вкладка `ContractDetailNavigationSection.finances` в карточке договора |

### Провайдеры состояния
| Provider | Назначение |
|----------|------------|
| `settlementRepositoryProvider` | DI репозитория (Supabase + `activeCompanyId`) |
| `settlementListProvider` | Список операций компании |
| `contractSettlementsProvider(contractId)` | Список операций по договору |

### Design System
- Шапка: `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, `MobileAtmosphereChromeCircleButton`
- Форма: `DesktopDialogContent` / `MobileBottomSheetContent`, `GTTextField`, `GTDropdown`, `GTButtons`
- Форматтеры: `formatCurrency`, `formatRuDate`, `parseAmount`, `amountFormatter` из `lib/core/utils/formatters.dart`
- Права: `PermissionGuard(module: 'settlements', ...)`

## ⚙️ Слой Domain / Data

### Сущности
- `SettlementOperation` (Freezed) — операция взаиморасчётов
- `SettlementOperationType`: `act` \| `advance` \| `other`
- `SettlementPaymentStatus`: `unpaid` \| `partial` \| `paid` \| `overpaid`
- Хелперы: `computeSettlementTotalToPay`, `computeSettlementPaymentStatus`, getter `remainingAmount`

### Репозиторий
- Контракт: `SettlementRepository`
- Реализация: `SettlementRepositoryImpl` — таблица `settlement_operations`, select с join:
  - `objects:object_id(name)`
  - `contractors:contractor_id(short_name)`
  - `contracts:contract_id(number)`
- Методы: `getOperations({contractId?})`, `createOperation`, `updateOperation`, `deleteOperation`

### Модель
- `SettlementOperationModel` (Freezed + json_serializable, `FieldRename.snake`)
- `toWriteJson` исключает generated `total_to_pay` и служебные timestamps при insert/update

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
    ├── utils/settlement_ui_labels.dart
    └── widgets/
        ├── settlement_form_dialog.dart
        ├── settlements_filters_toolbar.dart
        ├── settlements_operations_table.dart
        └── contract_settlements_section.dart

supabase/migrations/
└── 20260720220000_create_settlement_operations.sql

docs/settlements/
└── settlements_module.md
```

## 🗄️ База данных (Audit)

**Источник аудита:** live DB через MCP Supabase (`api.progt.ru`), 20.07.2026.  
**Миграция:** `supabase/migrations/20260720220000_create_settlement_operations.sql`

### Таблица `settlement_operations`

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID | NO | PK, `gen_random_uuid()` |
| `company_id` | UUID | NO | FK → `companies` ON DELETE CASCADE |
| `operation_type` | TEXT | NO | `act` \| `advance` \| `other` |
| `object_id` | UUID | NO | FK → `objects` |
| `contractor_id` | UUID | NO | FK → `contractors` |
| `contract_id` | UUID | NO | FK → `contracts` ON DELETE CASCADE |
| `period_from` / `period_to` | DATE | YES | Период работ (обязательны для `act`) |
| `act_number` / `act_date` | TEXT / DATE | YES | Реквизиты акта (обязательны для `act`) |
| `invoice_number` / `invoice_date` | TEXT / DATE | NO | Реквизиты счёта |
| `amount` | NUMERIC | NO | База ≥ 0 |
| `vat_amount` | NUMERIC | NO | НДС ≥ 0 |
| `advance_retention` | NUMERIC | NO | Авансовые удержания ≥ 0 |
| `warranty_retention` | NUMERIC | NO | Гарантийные удержания ≥ 0 |
| `total_to_pay` | NUMERIC | — | **GENERATED STORED:** `GREATEST(0, amount + vat_amount − advance_retention − warranty_retention)` |
| `paid_amount` | NUMERIC | NO | Оплачено ≥ 0 |
| `payment_status` | TEXT | NO | `unpaid` \| `partial` \| `paid` \| `overpaid` |
| `purpose` | TEXT | YES | Обязателен для `other` |
| `note` | TEXT | YES | Комментарий |
| `created_at` / `updated_at` | TIMESTAMPTZ | NO | `updated_at` — trigger `set_updated_at` |
| `created_by` | UUID | YES | FK → `auth.users` |

**CHECK (ключевые):**
- Для `act`: номер/дата акта и период обязательны.
- Для `advance` / `other`: поля акта NULL, удержания = 0.
- Для `other`: `purpose` не пустой.

### RLS

**RLS:** ✅ **Включён** (`relrowsecurity = true`)

| Policy | Команда | Условие (смысл) |
|--------|---------|-----------------|
| `Strict SELECT for settlement_operations` | SELECT | `company_id ∈ get_my_company_ids()` AND `check_permission(..., 'settlements', 'read')` |
| `Strict INSERT for settlement_operations` | INSERT | company + `create` |
| `Strict UPDATE for settlement_operations` | UPDATE | company + `update` |
| `Strict DELETE for settlement_operations` | DELETE | company + `delete` |

### Индексы

По миграции:
- `idx_settlement_operations_company` — `(company_id)`
- `idx_settlement_operations_contract` — `(contract_id, invoice_date DESC)`
- `idx_settlement_operations_status` — `(company_id, payment_status)`
- `idx_settlement_operations_type` — `(company_id, operation_type)`

### Edge Functions

**Нет.** Модуль не использует Edge Functions (проверка: вызовов из кода модуля нет; логика CRUD — клиент → PostgREST).

## 🧠 Бизнес-логика

### Типы операций

| Тип | Когда | Особенности полей |
|-----|-------|-------------------|
| **Акт** | Закрыли работы/поставку и выставили счёт | Период, номер/дата акта, удержания |
| **Аванс** | Предоплата до акта | Без акта и удержаний; назначение опционально |
| **Прочее** | Доплата, корректировка и т.п. | Назначение обязательно |

### Формулы

```text
К оплате = max(0, Сумма + НДС − Авансовые удержания − Гарантийные удержания)
Остаток  = К оплате − Оплачено
```

Статус оплаты (клиент, при сохранении):

| Условие | Статус |
|---------|--------|
| Оплачено ≈ 0 | `unpaid` |
| 0 < Оплачено < К оплате | `partial` |
| Оплачено ≈ К оплате | `paid` |
| Оплачено > К оплате | `overpaid` |

Зачёт аванса в v1: вручную в операции типа «Акт» через поле **Авансовые удержания** (отдельной сущности «зачёт» нет).

### Сценарии

1. **Аванс:** тип Аванс → объект/контрагент/договор → счёт → сумма/НДС → оплачено → сохранить.
2. **Акт:** тип Акт → контекст → период и акт → счёт → суммы и удержания → оплачено → сохранить.
3. **Контроль долга:** реестр / Финансы договора — фильтр по статусу, сводка «Долг».

## 🔌 Интеграции

| Интеграция | Как |
|------------|-----|
| Договоры | FK `contract_id`; вкладка «Финансы» → `ContractSettlementsSection` |
| Объекты / Контрагенты | FK + dropdown в форме |
| Роли | модуль `settlements` в матрице прав |
| ДДС (`cash_flow`) | **нет связи в v1** |
| Акты КС-2 (`contract_acts`) | **нет связи в v1**; старый блок не изменялся |
| Storage / файлы счетов | **нет в v1** |

## 🗺 Roadmap

### Реализовано
- ✅ Таблица + RLS + `app_modules` / seed прав с `contracts`
- ✅ CRUD операций (ручной ввод)
- ✅ Реестр `/settlements` + фильтры + flex-таблица
- ✅ Форма с типами и автосводкой
- ✅ Вкладка «Финансы» в договоре

### Планы
- 🟡 Файлы PDF/скан к операции
- 🟡 Опциональная привязка оплат к строкам ДДС
- 🟡 Подтягивание / связка со старыми `contract_acts` (по решению продукта)
- 🟢 История частичных оплат отдельными записями (сейчас одно поле `paid_amount`)

### Известные ограничения
- Статус оплаты хранится в строке операции; при ручном изменении сумм клиент пересчитывает статус при сохранении.
- Старый ручной «статус оплаты» в блоке «Акты» договора **не синхронизируется** с Settlements (параллельные контуры).
