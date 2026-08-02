# Модуль ТМЦ (TMC)

**Дата актуализации:** 29 июля 2026  

**Изменения:**
- UI видимости остатков: колонки «На складе / Выдано / Где лежит» в реестре; экран `/tmc/stock`.
- Поле «Количество» в операции **Поступление** всегда доступно (в т.ч. для индивидуального учёта).
- `tmc_items.quantity` синхронизируется триггерами с `tmc_balances` / `tmc_units` (`tmc_recalc_item_quantity`).
- RPC `tmc_list_items` отдаёт `qty_in_stock`, `qty_issued`, `qty_on_object`, `location_summary`.
- RPC `tmc_list_stock` — остатки по складам.
- Клиент больше не пишет `quantity` при create/update позиции (`toWriteJson`).
- Кнопка «Поступление» вынесена первой в карточке позиции.
- Инвентаризация UI по-прежнему заглушка; Mobile / QR / фото Storage / авто-уведомления — не реализованы.

---

## ⚠️ Важное замечание

- **Владение таблицами:** все `tmc_*` принадлежат модулю ТМЦ.
- **Не путать с** модулем **Материалы** (`materials`): строительные накладные / FIFO. ТМЦ — учёт имущества компании (инструмент, СИЗ, оргтехника и т.п.).
- **Каталог ≠ склад.** `tmc_items` — справочник позиций. Физический остаток появляется только после операции **поступления** на конкретный склад.
- **Изоляция данных:** `company_id` + RLS (`get_my_company_ids()` + `check_permission(..., 'tmc', ...)`).
- **Остатки:** прямой `INSERT`/`UPDATE`/`DELETE` на `tmc_balances` у роли `authenticated` **отозван**. Изменение остатков — только через RPC `tmc_post_operation`.
- **Количество в карточке** (`tmc_items.quantity`):
  - не редактируется вручную в UI;
  - не отправляется клиентом при insert/update позиции;
  - пересчитывается триггерами `trg_tmc_balances_recalc_qty` / `trg_tmc_units_recalc_qty` → `tmc_recalc_item_quantity`;
  - в реестре дополнительно показываются live-поля из `tmc_list_items` (склад / выдано / объект / где лежит).
- **Desktop-only:** модуль в `AppModuleAvailability.desktopOnlyModuleIds` (`tmc`).
- **Права ролей:** в `app_modules` есть код `tmc`; массовый seed `role_permissions` **не делался** (live count = 0). Owner обходит проверки; остальным права — в UI «Роли».
- **Storage:** bucket `tmc` создан; загрузка фото из приложения — следующий этап.

---

## 📖 Описание

Модуль учёта товарно-материальных ценностей / имущества компании:

- каталог позиций (индивидуальный и количественный учёт);
- склады;
- индивидуальные единицы с инвентарными номерами;
- остатки по местам хранения (балансы + единицы);
- экран остатков по складам;
- журнал операций движения;
- выдача сотрудникам (assignments);
- ремонт и списание;
- отчёты Excel;
- in-app уведомления (чтение своих);
- в профиле — блок «Выданное имущество».

### Ключевые функции (v1)

| Функция | Статус |
|---------|--------|
| Реестр позиций + KPI + колонки остатков/места | ✅ |
| Экран остатков по складам (`/tmc/stock`) | ✅ |
| Карточка позиции / единицы | ✅ |
| Справочники (склады, категории) | ✅ |
| Операции через RPC (кол-во в поступлении всегда) | ✅ |
| Журнал операций | ✅ |
| Отчёты Excel (`export`) | ✅ |
| Уведомления (свои) | ✅ чтение |
| Профиль: выданное имущество | ✅ |
| Синхронизация `tmc_items.quantity` | ✅ триггеры |
| Инвентаризация UI | 🟡 заглушка (таблицы есть) |
| Mobile / QR | ❌ |
| Фото в Storage | ❌ UI |
| Авто-уведомления по срокам | ❌ |

---

## 🔗 Зависимости

### Таблицы модуля (owner)

`tmc_warehouses`, `tmc_categories`, `tmc_conditions`, `tmc_items`, `tmc_units`, `tmc_balances`, `tmc_operations`, `tmc_operation_items`, `tmc_condition_history`, `tmc_assignments`, `tmc_attachments`, `tmc_repairs`, `tmc_write_offs`, `tmc_inventories`, `tmc_inventory_items`, `tmc_notifications`, `tmc_inventory_number_seq`

### Таблицы / сущности других модулей (usage)

| Сущность | Использование |
|----------|----------------|
| `companies` | `company_id` |
| `employees` | выдача, ответственный, self-assignments |
| `objects` | местонахождение «объект» |
| `contractors` | поставщик (`type = supplier`) |
| `profiles` | связь user → `employee_id` для self SELECT |
| `app_modules` / `role_permissions` | RBAC модуль `tmc` |
| Storage bucket `tmc` | вложения (зарезервирован) |

---

## 🖥 Слой Presentation

### Экраны и маршруты

| Экран | Маршрут | Примечание |
|-------|---------|------------|
| `TmcListScreen` | `/tmc` | Реестр, KPI, фильтры; колонки остатков |
| `TmcItemDetailsScreen` | `/tmc/items/:id` | Карточка; «Поступление» — первое действие |
| `TmcStockScreen` | `/tmc/stock` | Остатки по складам (фильтр склада + поиск) |
| `TmcOperationsScreen` | `/tmc/operations` | Журнал операций |
| `TmcReportsScreen` | `/tmc/reports` | Excel; требует `export` |
| `TmcNotificationsScreen` | `/tmc/notifications` | Свои уведомления |
| `TmcInventoryScreen` | `/tmc/inventory` | Заглушка «в разработке» |

Все маршруты `/tmc*` — desktop-guarded (`AppRoutes.tmcStock = '/tmc/stock'`).

### Виджеты

| Виджет | Назначение |
|--------|------------|
| `TmcKpiCards` | KPI дашборда |
| `TmcFiltersToolbar` | Поиск / категория / тип учёта + действия (в т.ч. «Остатки по складам») |
| `TmcItemsTable` | Таблица: наименование, категория, учёт, **на складе**, **выдано**, **где лежит**, цена/стоимость, статус |
| `TmcItemFormDialog` | Создание / правка позиции (**без** поля количества) |
| `TmcOperationDialog` | Операция → RPC; количество видно для quantitative и для `receipt` |
| `TmcCatalogsDialog` | Склады / категории (`manage_catalogs`) |

### Сервисы / утилиты

- `TmcExcelExportService` — выгрузки Excel (`excel` + `FileSaver`).
- `tmc_ui_labels.dart` — подписи статусов/типов (`stockBalances`, `emptyStock` и др.).

### Провайдеры (Riverpod)

Файл: `presentation/state/tmc_providers.dart`

- `tmcRepositoryProvider`
- `tmcDashboardProvider`
- `tmcItemsListProvider` / фильтры `TmcItemsListFilters`
- `tmcItemProvider`, `tmcUnitsProvider` / `tmcItemUnitsProvider`, `tmcItemOperationsProvider`
- `tmcCategoriesProvider`, `tmcConditionsProvider`, `tmcWarehousesProvider`
- `tmcStockProvider` (`TmcStockQuery`: warehouseId + search)
- `tmcOperationsProvider`
- `tmcAssignmentsProvider(employeeId)`
- `tmcInventoriesProvider`, уведомления и др.

### Права в UI (роли)

Модуль `tmc` в матрице прав. Скрыт только `import` (`permissions_matrix`: `'tmc': ['import']`).

| Код | Смысл |
|-----|--------|
| `read` / `create` / `update` / `delete` | CRUD каталога и базовые действия |
| `export` | Excel-отчёты |
| `issue` | Выдача / возврат / передача между сотрудниками |
| `move` | Перемещения, резерв |
| `repair` | Ремонт |
| `write_off` | Списание / недостача |
| `inventory` | Инвентаризация / `inventory_adjust` |
| `view_cost` | Стоимость в KPI / отчётах |
| `manage_catalogs` | Склады, категории, системные справочники |

Профиль: `PropertyScreen` читает активные `tmc_assignments` по `employee_id` текущего профиля (self RLS, без обязательного `tmc.read`).

---

## ⚙️ Слой Domain / Data

### Enums (`tmc_enums.dart`)

- `TmcAccountingType`: `individual` \| `quantitative`
- `TmcItemStatus`: `active` \| `archived`
- `TmcUnitStatus`: `in_stock`, `on_object`, `issued`, `temporarily_transferred`, `in_repair`, `in_service`, `reserved`, `lost`, `written_off`
- `TmcLocationType`: `warehouse`, `object`, `employee`, `office`, `repair_org`, `other`
- `TmcOperationType`: `receipt`, `issue`, `return_from_employee`, `transfer_to_object`, `return_from_object`, `move_between_objects`, `move_between_warehouses`, `transfer_between_employees`, `reserve`, `unreserve`, `send_to_repair`, `return_from_repair`, `change_condition`, `inventory_adjust`, `write_off`, `shortage`, `correction`
- `TmcWriteOffReason`: `wear`, `breakdown`, `loss`, `shortage`, `obsolescence`, `end_of_life`, `other`

### Сущности

Freezed: `TmcItem` (+ поля `qtyInStock`, `qtyIssued`, `qtyOnObject`, `locationSummary`), `TmcUnit`, `TmcWarehouse`, `TmcCategory`, `TmcCondition`, `TmcOperation` (+ items), `TmcAssignment`, `TmcRepair`, `TmcWriteOff`, `TmcInventory` (+ items), `TmcNotification`, `TmcDashboardStats`.

Plain class: `TmcStockBalance` — строка остатка для экрана складов.

### Репозиторий

- Контракт: `TmcRepository`
- Реализация: `TmcRepositoryImpl`

Ключевые методы:
- каталог: `listItems` → RPC `tmc_list_items` (с разбивкой остатков); `getItem` обогащает остатками через list; create/update **без** поля `quantity` в payload;
- `listStock` → RPC `tmc_list_stock`;
- справочники: categories / conditions / warehouses;
- единицы: `listUnits`, `getUnit`, `nextInventoryNumber`;
- операции: `listOperations`, `getOperation`, **`postOperation` → RPC `tmc_post_operation`**;
- assignments, repairs, write-offs, inventories;
- notifications; dashboard → `tmc_dashboard_stats`.

### Модели

Freezed + `json_serializable` (`FieldRename.snake`), helpers в `tmc_json_utils.dart`.  
`TmcItemModel.toWriteJson` удаляет `quantity` и `total_cost`.

---

## 📂 Дерево файлов

```
lib/features/tmc/
├── data/
│   ├── models/          # Freezed + .g.dart модели
│   └── repositories/
│       └── tmc_repository_impl.dart
├── domain/
│   ├── entities/        # Freezed + tmc_enums.dart + tmc_stock_balance.dart
│   └── repositories/
│       └── tmc_repository.dart
└── presentation/
    ├── screens/
    │   ├── tmc_list_screen.dart
    │   ├── tmc_item_details_screen.dart
    │   ├── tmc_stock_screen.dart
    │   ├── tmc_operations_screen.dart
    │   ├── tmc_reports_screen.dart
    │   ├── tmc_notifications_screen.dart
    │   └── tmc_inventory_screen.dart
    ├── widgets/
    │   ├── tmc_kpi_cards.dart
    │   ├── tmc_filters_toolbar.dart
    │   ├── tmc_items_table.dart
    │   ├── tmc_item_form_dialog.dart
    │   ├── tmc_operation_dialog.dart
    │   └── tmc_catalogs_dialog.dart
    ├── services/
    │   └── tmc_excel_export_service.dart
    ├── state/
    │   └── tmc_providers.dart
    └── utils/
        └── tmc_ui_labels.dart

supabase/migrations/
├── 20260729120000_create_tmc_module.sql
├── 20260729120100_tmc_operations_rpc.sql
├── 20260729120200_tmc_storage_bucket.sql
├── 20260729120300_tmc_assignments_self_select.sql
├── 20260729120400_tmc_notifications_own_only.sql
└── 20260729130000_tmc_stock_visibility.sql

docs/tmc/
└── tmc_module.md

test/features/tmc/
└── tmc_enums_and_export_test.dart
```

Wiring вне фичи: `app_router.dart`, `app_drawer.dart`, `app_module_availability.dart`, матрица ролей, `profile/.../property_screen.dart`.

---

## 🗄️ База данных (Audit)

**Источник аудита:** live DB через MCP Supabase (`api.progt.ru`), 29.07.2026.  
**Миграции в репозитории:** `20260729120*_tmc_*.sql`, `20260729130000_tmc_stock_visibility.sql`  
(на сервере применены также MCP-имена `tmc_stock_visibility`, `tmc_stock_list_and_triggers`).

### `app_modules`

| code | name | icon_key | sort_order | is_active |
|------|------|----------|------------|-----------|
| `tmc` | ТМЦ | `cube_box` | 55 | true |

### Таблицы (live)

17 таблиц `tmc_*`. **RLS:** ✅ включён на всех.

| Таблица | RLS |
|--------|-----|
| `tmc_assignments` … `tmc_write_offs` (все 17) | ✅ `true` |

#### `tmc_items` (каталог)

| Колонка | Описание |
|---------|----------|
| `accounting_type` | `individual` \| `quantitative` |
| `unit_price`, `quantity`, `total_cost` | `quantity` — денормализованный итог; источник правды по местам — balances/units |
| прочие | name, sku, category, supplier, archive, audit |

#### `tmc_units` / `tmc_balances`

- Индивидуальный учёт → `tmc_units` (инв. №, статус, локация).
- Количественный → `tmc_balances` (qty по warehouse/object/employee/…).
- Клиент: SELECT; изменение — только RPC.

#### Прочие

Без изменений относительно v1: warehouses, categories, conditions, operations (+ items), condition_history, assignments, attachments, repairs, write_offs, inventories (+ items), notifications, inventory_number_seq.

### RLS

Типовой паттерн: `company_id ∈ get_my_company_ids()` + `check_permission(..., 'tmc', ...)`.

Исключения:
- `tmc_assignments` — self SELECT по employee профиля;
- `tmc_notifications` — только `user_id = auth.uid()`;
- `tmc_balances` — DML для `authenticated` отозван.

### Индексы

Ключевые:  
`idx_tmc_warehouses_company`, `idx_tmc_categories_company`, `idx_tmc_conditions_company`,  
`idx_tmc_items_company|category|name`,  
`idx_tmc_units_company_item|status|employee`, `tmc_units_inventory_company_uq`,  
`idx_tmc_balances_unique_loc`, `idx_tmc_balances_item`,  
`idx_tmc_operations_company|type`, `idx_tmc_operation_items_operation|item`,  
`idx_tmc_assignments_active`, `idx_tmc_notifications_user`, …

### Функции (RPC / helpers) — live

| Функция | Назначение |
|---------|------------|
| `tmc_post_operation(jsonb)` | Проведение операции |
| `tmc_dashboard_stats(uuid)` | KPI |
| `tmc_list_items(...)` | Реестр + `qty_in_stock` / `qty_issued` / `qty_on_object` / `location_summary` |
| `tmc_list_stock(company, warehouse?, search?)` | Остатки на складах (balances + units `in_stock`) |
| `tmc_recalc_item_quantity(item_id)` | Пересчёт `tmc_items.quantity` |
| `tmc_trg_recalc_item_qty()` | Trigger function |
| `tmc_next_inventory_number` | Инв. № |
| `tmc_adjust_balance` | Helper остатков |
| `tmc_status_for_location` / `tmc_status_for_operation` | Маппинг статуса |

Права по типам операций в `tmc_post_operation` — без изменений (receipt→`create`, issue→`issue`, move→`move`, …).

### Триггеры (важные)

| Триггер | Таблица | Смысл |
|---------|--------|-------|
| `trg_tmc_balances_recalc_qty` | `tmc_balances` | AFTER I/U/D → recalc item qty |
| `trg_tmc_units_recalc_qty` | `tmc_units` | AFTER I/U/D → recalc item qty |
| `trg_tmc_*_updated_at` | ряд таблиц | `set_updated_at()` |

### Edge Functions

**Нет** функций, специфичных для ТМЦ. Логика — Postgres RPC + клиент PostgREST.  
(Инструмент `list_edge_functions` в текущем MCP недоступен; по коду модуля вызовов Edge нет.)

### Storage

Bucket `tmc` ✅ существует. Клиентская загрузка фото — не подключена.

---

## 🧠 Бизнес-логика

### Типы учёта

1. **Индивидуальный** — единицы в `tmc_units` с инвентарным номером. При поступлении можно указать количество > 1 → создаётся несколько единиц.
2. **Количественный** — остатки в `tmc_balances` по локациям.

### Каталог vs остаток

```text
Создание позиции каталога  → quantity = 0, на складе ничего нет
Поступление (receipt)      → выбор склада + количество → balances/units
tmc_items.quantity         → сумма/count по balances или units (триггер)
Реестр / stock screen      → live разбивка и места хранения
```

### Формула quantity (recalc)

```text
quantitative: quantity = SUM(tmc_balances.quantity) WHERE item_id = …
individual:   quantity = COUNT(tmc_units) WHERE not archived AND status <> written_off
```

### Статус единицы

- поступление на склад → `in_stock`;
- выдача → `issued` + `tmc_assignments`;
- ремонт → `in_repair` + `tmc_repairs`;
- списание → `written_off` + `tmc_write_offs`.

### Основной сценарий

1. Создать склад (справочники).
2. Создать позицию каталога (без количества).
3. **Поступление** на склад с количеством.
4. Контроль: реестр (колонки остатков) или **Остатки по складам**.
5. Выдача / перемещение / возврат / ремонт / списание.
6. Отчёты Excel, профиль сотрудника.

### Инвентаризация

Схема и RPC-тип `inventory_adjust` есть. UI — заглушка.

### Уведомления

Чтение своих записей есть. Автогенерация по срокам — нет.

---

## 🔌 Интеграции

| Интеграция | Как |
|------------|-----|
| Роли / RBAC | `app_modules.code = tmc`, `check_permission` |
| Сотрудники | FK, выдача, `PropertyScreen` |
| Объекты | местонахождение |
| Контрагенты | поставщик позиции |
| Профиль | выданное имущество ← `tmc_assignments` |
| Материалы (`materials`) | **нет связи** |
| ДДС / ФОТ / Сметы | **нет** |
| Excel | пакет `excel`, право `export` |
| Storage | bucket `tmc`, upload — позже |
| Edge Functions | нет для ТМЦ |

---

## 🗺 Roadmap

### Реализовано

- ✅ Схема БД + RLS + seed категорий/состояний + `app_modules`
- ✅ RPC операций, дашборда, списка, инв. номеров, **остатков по складам**, recalc quantity
- ✅ Desktop: реестр с остатками, карточка, stock screen, операции, отчёты, уведомления, справочники
- ✅ Self SELECT assignments; уведомления только свои
- ✅ Профиль «Выданное имущество»
- ✅ Desktop-only guard; тесты enums/export

### Планы / долги

- 🟡 Полноценная инвентаризация UI
- 🟡 Mobile / QR
- 🟡 Загрузка фото/вложений в Storage
- 🟡 Авто-уведомления по срокам
- 🟡 Обогащение Excel-отчётов реальными `tmc_balances` (не только units)
- 🟢 Seed прав ТМЦ для типовых ролей
- 🟢 Импорт каталога (`import` скрыт)

### Известные ограничения

- Не-Owner без прав в «Ролях» модуль недоступен.
- Инвентаризация в меню — UI «в разработке».
- `total_cost` в KPI скрыт без `view_cost`.
- `getItem` обогащает остатки через `listItems` по имени (при дубликатах имён — риск неоднозначности; редкий кейс).

---

## ✅ Чек-лист аудита (29.07.2026, повтор)

| Проверка | Результат |
|----------|-----------|
| Файлы `lib/features/tmc/` | ✅ ~80 dart-файлов (+ `tmc_stock_screen`, `tmc_stock_balance`) |
| Таблицы live `tmc_%` | ✅ 17, RLS ✅ |
| RPC `tmc_*` | ✅ 10 (вкл. `tmc_list_stock`, `tmc_recalc_item_quantity`, `tmc_trg_recalc_item_qty`) |
| Триггеры recalc qty | ✅ на `tmc_balances`, `tmc_units` |
| Edge Functions ТМЦ | ❌ не используются |
| Bucket `tmc` | ✅ |
| `role_permissions` seed `tmc` | ❌ 0 записей |
| Миграции в репозитории | ✅ 6 файлов |
| Документация соответствует коду | ✅ этот файл |
