# Модуль Взаиморасчёты (Settlements)

**Дата актуализации:** 5 августа 2026 года  
**Изменения:**
- Модель пересмотрена: **операция = счёт на оплату**. Форма собирает только реквизиты счёта.
- Добавлен **НДС**: гибкий ввод ставки (`vat_rate`), круглая кнопка переключения активности НДС, режим «в сумме / сверху» (`is_vat_included`), автоматический расчёт `vat_amount` и `total_to_pay`.
- Автономер счёта по договору: `префикс последнего счёта + (max + 1)`.
- Форма переработана: Объект / Контрагент / Договор в одну строку, цветные стикеры типа, круглая кнопка `НДС` + текстовый ввод процента, компактный переключатель режима, живая сводка.
- Таблица и панель фильтров упрощены: колонки оплаты/статуса убраны, сводка — «Сумма счетов» (итого с НДС).
- Расслаблены CHECK-ограничения: для «По акту» нужен только `act_number`; для «Прочее» `purpose` необязателен.
- Параллельно блоку «Акты» договора (`contract_acts` / КС-2) — **не заменяет** формирование КС-2.

## ⚠️ Важное замечание

- **Владение таблицей:** `settlement_operations` (Owner — модуль Settlements).
- **Изоляция:** `company_id` + RLS через `get_my_company_ids()` и `check_permission(..., 'settlements', ...)`.
- **RBAC-модуль:** `settlements` в `app_modules` (название «Взаиморасчёты», `sort_order = 92`).
- При миграции права скопированы с модуля `contracts` для существующих ролей; далее настраиваются в UI «Роли».
- **Не путать** с вкладкой «Акты» в договоре (`contract_acts`) и с ДДС (`cash_flow`): это отдельный контур учёта выставленных счетов.
- Оплата счетов в этой версии **не отслеживается** (поля `paid_amount` / `payment_status` остались в БД с дефолтами, но убраны из UI). Зачёт оплат — roadmap.
- Файлы счетов (PDF/скан) и связка оплат с ДДС — **не в этой версии** (roadmap).

## 📝 Описание

Модуль **Settlements** предназначен для учёта выставленных счетов на оплату по договорам. Одна сущность — **операция = счёт** с типом; реквизиты счёта и (для типа «По акту») номер акта живут в одной карточке.

**Ключевые функции:**
- Типы счетов: **По акту**, **Аванс**, **Прочее**.
- Ручной CRUD счетов; автономер по договору с сохранением префикса.
- НДС: ставка (22% / 10% / 7% / 5% / 0% / Без НДС) и режим «в сумме» / «сверху»; автоматический расчёт базы, НДС и итога.
- Общий реестр компании с поиском и фильтром по типу + вкладка **«Финансы»** в карточке договора.
- Сводка: «Сумма счетов» (итого с НДС).
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
| `SettlementsListScreen` | Реестр компании: atmosphere-шапка (как Табель/ФОТ), `MobileAtmosphereMainSurface`, таблица счетов |
| Маршрут | `/settlements` (`AppRoutes.settlements`), право `settlements` / `read` |
| Меню | `AppDrawer` → «Взаиморасчёты», `AppRoute.settlements` |

### Виджеты
| Виджет | Назначение |
|--------|------------|
| `SettlementsFiltersToolbar` | Компактная панель: поиск, фильтр типа, сводка «Сумма счетов», обновить, «Новый» |
| `SettlementsOperationsTable` | Flex-таблица на всю ширину (без горизонтального скролла); колонка «Сумма» = итого с НДС; строка ИТОГО |
| `SettlementFormDialog` | Создание/редактирование счёта (ширина 920 на desktop) |
| `ContractSettlementsSection` | Вкладка `ContractDetailNavigationSection.finances` в карточке договора |

### Форма счёта (`SettlementFormDialog`)
Поля в логическом порядке:
1. **Объект** + **Контрагент** (сокращённое имя) + **Договор** — в одну строку; договор фильтруется по объекту и контрагенту.
2. **Тип** — цветные стикеры: «По акту» / «Аванс» / «Прочее».
3. **Номер акта** — только для типа «По акту».
4. **Номер счёта** + **Дата счёта** — в одну строку.
5. **Сумма** + **Блок НДС** (в одну строку):
   - **Сумма** (подпись меняется: «Сумма с НДС» / «Сумма без НДС» / «Сумма»).
   - **Круглая кнопка включения НДС** (`_VatEnableRoundButton`) + **Поле ввода процента НДС** (`GTTextField` с суффиксом `%`, например 22%, 20%, 10%).
6. **Переключатель режима НДС** (только при включённом НДС и ставке > 0): «НДС в сумме» / «НДС сверху».
7. **Сводка НДС** (только при включённом НДС и ставке > 0): «Без НДС» / «НДС» / «Итого с НДС».
8. **Примечание** (4 строки).

При выключенном НДС (нажатие на круглую кнопку `НДС`) или нулевой ставке блок НДС (переключатель «в сумме / сверху» + сводка) **скрывается**, а поле процента блокируется.

### Провайдеры состояния
| Provider | Назначение |
|----------|------------|
| `settlementRepositoryProvider` | DI репозитория (Supabase + `activeCompanyId`) |
| `settlementListProvider` | Список счетов компании |
| `contractSettlementsProvider(contractId)` | Список счетов по договору |

### Design System
- Шапка: `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, `MobileAtmosphereChromeCircleButton`
- Форма: `DesktopDialogContent` (width 920) / `MobileBottomSheetContent`, `GTTextField`, `GTDropdown`, `GTButtons`
- Элементы НДС: круглая кнопка переключателя активности `_VatEnableRoundButton`, кастомные стикеры типа (`_TypeSegment` / `_TypeSticker`), `_VatModeToggle` на `CupertinoSlidingSegmentedControl`
- Форматтеры: `formatCurrency`, `formatRuDate`, `parseAmount`, `amountFormatter` из `lib/core/utils/formatters.dart`
- Права: `PermissionGuard(module: 'settlements', ...)`

## ⚙️ Слой Domain / Data

### Сущности
- `SettlementOperation` (Freezed) — счёт на оплату
- `SettlementOperationType`: `act` | `advance` | `other`
- `SettlementPaymentStatus`: `unpaid` | `partial` | `paid` | `overpaid` (в UI не используется, зарезервировано)
- Хелперы: `computeSettlementTotalToPay`, `computeSettlementPaymentStatus`, getter `remainingAmount` (зарезервированы)

### Репозиторий
- Контракт: `SettlementRepository`
- Реализация: `SettlementRepositoryImpl` — таблица `settlement_operations`, select с join:
  - `objects:object_id(name)`
  - `contractors:contractor_id(short_name)`
  - `contracts:contract_id(number)`
- Методы: `getOperations({contractId?})`, `createOperation`, `updateOperation`, `deleteOperation`, `getNextInvoiceNumber(contractId)`

### Автономер счёта
`getNextInvoiceNumber(contractId)`:
- Выбирает все `invoice_number` по договору.
- Извлекает завершающую группу цифр (regex): `сч-13` → 13, `217-3` → 3, `2` → 2.
- Берёт максимум и его префикс.
- Возвращает `префикс + (max + 1)`; если счетов нет — `1`.
- При создании/смене договора номер подставляется автоматически (с перезаписью); при редактировании не меняется.

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
├── 20260720220000_create_settlement_operations.sql
├── 20260803180000_simplify_settlement_operations_constraints.sql
├── 20260804120000_add_settlement_vat_rate.sql
└── 20260804130000_add_settlement_is_vat_included.sql

docs/settlements/
└── settlements_module.md
```

## 🗄️ База данных (Audit)

**Источник аудита:** live DB через MCP Supabase (`api.progt.ru`), 04.08.2026.  
**Миграции:** 4 файла (см. дерево выше).

### Таблица `settlement_operations`

| Колонка | Тип | Nullable | Описание |
|---------|-----|----------|----------|
| `id` | UUID | NO | PK, `gen_random_uuid()` |
| `company_id` | UUID | NO | FK → `companies` ON DELETE CASCADE |
| `operation_type` | TEXT | NO | `act` \| `advance` \| `other` |
| `object_id` | UUID | NO | FK → `objects` |
| `contractor_id` | UUID | NO | FK → `contractors` |
| `contract_id` | UUID | NO | FK → `contracts` ON DELETE CASCADE |
| `period_from` / `period_to` | DATE | YES | Период работ (необязательно) |
| `act_number` | TEXT | YES | Номер акта (обязателен для `act`) |
| `act_date` | DATE | YES | Дата акта (необязательно) |
| `invoice_number` | TEXT | NO | Номер счёта |
| `invoice_date` | DATE | NO | Дата счёта |
| `amount` | NUMERIC | NO | База (без НДС) ≥ 0 |
| `is_vat_included` | BOOLEAN | NO | `true` = НДС в сумме; `false` = НДС сверху (default `true`) |
| `vat_rate` | NUMERIC | YES | Ставка НДС (22/10/7/5/0). `NULL` = без НДС |
| `vat_amount` | NUMERIC | NO | Сумма НДС ≥ 0 |
| `advance_retention` | NUMERIC | NO | Авансовые удержания ≥ 0 (в UI не используется, default 0) |
| `warranty_retention` | NUMERIC | NO | Гарантийные удержания ≥ 0 (в UI не используется, default 0) |
| `total_to_pay` | NUMERIC | — | **GENERATED STORED:** `GREATEST(0, amount + vat_amount − advance_retention − warranty_retention)` |
| `paid_amount` | NUMERIC | NO | Оплачено ≥ 0 (в UI не используется, default 0) |
| `payment_status` | TEXT | NO | `unpaid` \| `partial` \| `paid` \| `overpaid` (в UI не используется) |
| `purpose` | TEXT | YES | Назначение (необязательно) |
| `note` | TEXT | YES | Примечание |
| `created_at` / `updated_at` | TIMESTAMPTZ | NO | `updated_at` — trigger `set_updated_at` |
| `created_by` | UUID | YES | FK → `auth.users` |

**CHECK (ключевые):**
- `operation_type` ∈ (`act`, `advance`, `other`).
- `payment_status` ∈ (`unpaid`, `partial`, `paid`, `overpaid`).
- Для `act`: `act_number` не пустой.
- Для `advance` / `other`: `act_number` IS NULL, `act_date` IS NULL, удержания = 0.
- `period_to` ≥ `period_from` (если оба заданы).

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

**Нет.** Модуль не использует Edge Functions (логика CRUD — клиент → PostgREST).

## 🧠 Бизнес-логика

### Типы счетов

| Тип | Когда | Особенности полей |
|-----|-------|-------------------|
| **По акту** | Закрыли работы/поставку и выставили счёт | Номер акта обязателен |
| **Аванс** | Предоплата до акта | Без акта и удержаний |
| **Прочее** | Доплата, корректировка и т.п. | Без акта и удержаний |

### НДС

Управление НДС осуществляется через круглую кнопку активности `НДС` и поле ввода процента (`GTTextField` с суффиксом `%`).
По умолчанию предлагаются стандартные значения (22% или ставка из выбранного договора), но пользователь может ввести любой процент вручную.

Режимы:
- **НДС в сумме** (`is_vat_included = true`, по умолчанию) — введённая сумма включает НДС.
  - `база = сумма / (1 + ставка/100)`, `НДС = сумма − база`, `итого = сумма`.
- **НДС сверху** (`is_vat_included = false`) — введённая сумма без НДС, налог начисляется сверху.
  - `база = сумма`, `НДС = сумма × ставка/100`, `итого = сумма + НДС`.
- При выключенном НДС или ставке `0%`: `НДС = 0`, `база = сумма`, `итого = сумма`; блок НДС в UI скрыт.

В БД всегда хранится `amount` = база (без НДС); `total_to_pay` (generated) = `amount + vat_amount` = итого с НДС. `vat_rate` = числовое значение ставки (или `NULL` при отключенном НДС).

### Формулы

```text
итого (total_to_pay) = amount + vat_amount          (generated, не ниже 0)
```

### Сценарии

1. **Новый счёт:** выбрать объект/контрагент/договор → номер счёта подставится автоматически → выбрать тип → заполнить реквизиты → ввести сумму и ставку НДС → сохранить.
2. **Редактирование:** открыть строку реестра → изменить поля → сохранить (номер счёта не пересчитывается).
3. **Контроль по договору:** вкладка «Финансы» договора — список счетов и сводка «Сумма счетов».

## 🔌 Интеграции

| Интеграция | Как |
|------------|-----|
| Договоры | FK `contract_id`; вкладка «Финансы» → `ContractSettlementsSection`; ставка и режим НДС наследуются из договора |
| Объекты / Контрагенты | FK + dropdown в форме |
| Роли | модуль `settlements` в матрице прав |
| ДДС (`cash_flow`) | **нет связи** |
| Акты КС-2 (`contract_acts`) | **нет связи**; старый блок не изменялся |
| Storage / файлы счетов | **нет** |

## 🗺 Roadmap

### Реализовано
- ✅ Таблица + RLS + `app_modules` / seed прав с `contracts`
- ✅ CRUD счетов (ручной ввод)
- ✅ Реестр `/settlements` + фильтр по типу + flex-таблица
- ✅ Форма счёта: логичный порядок полей, цветные стикеры типа, круглая кнопка включения НДС и текстовый ввод процента
- ✅ НДС: гибкая ставка + режим «в сумме / сверху» + автосчёт базы/НДС/итога
- ✅ Автономер счёта по договору с сохранением префикса
- ✅ Вкладка «Финансы» в договоре

### Планы
- 🟡 Файлы PDF/скан к счёту
- 🟡 Зачёт оплат (история частичных оплат отдельными записями)
- 🟡 Привязка оплат к строкам ДДС
- 🟡 Связка со старыми `contract_acts` (по решению продукта)
- 🟢 Табличная часть счёта (позиции: №, наименование, кол-во, ед.изм., цена, сумма)
- 🟢 Печать счёта в PDF (шапка с реквизитами, банк, QR, подписи)

### Известные ограничения
- Оплата счетов не отслеживается (поля `paid_amount` / `payment_status` зарезервированы в БД, в UI убраны).
- Старый ручной «статус оплаты» в блоке «Акты» договора **не синхронизируется** с Settlements (параллельные контуры).
- Автономер учитывает только числовые окончания; при смешанных форматах префикс берётся у счёта с максимальным номером.
