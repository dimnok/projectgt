# Модуль ТМЦ (TMC)

**Дата актуализации:** 15 августа 2026  

**Изменения в этой версии (15.08.2026, аудит + чистка мёртвого кода):**
- Проведён аудит модуля (структура, бизнес-логика, UI, БД через MCP Supabase).
- Удалены неиспользуемые методы `TmcRepository` (архивация, `getUnit`, правка категорий/складов, инвентаризация, `listRepairs`, `nextInventoryNumber` и др.) — в коде не вызывались.
- Удалены Dart-сущности и модели `TmcRepair` / `TmcInventory` (таблицы `tmc_repairs`, `tmc_inventories` в БД **сохранены**; клиентский API — при реализации UI).
- `getOperation` убран из публичного контракта; в `TmcRepositoryImpl` — приватный `_getOperation` для `postOperation`.
- `TmcItemsTable`: пустой реестр обрабатывает `TmcListScreen`, не таблица.
- Отчёт «В ремонте» — `listUnits(status: 'in_repair')`, не `tmc_repairs`.
- Миграции в репозитории: **11** файлов `*tmc*` (вкл. `140000`, `141000`); на live применены.
- RPC `tmc_*` на live: **15** функций (вкл. `tmc_close_unit_assignments`, `tmc_consume_employee_assignments`).

**Предыдущая версия (15.08.2026, целостность выдач):**
- Возврат количественного учёта списывает выдачи FIFO по количеству (не закрывает одну запись целиком).
- Списание и ремонт закрывают активную выдачу единицы; количественное — если списание с сотрудника.
- Выдать индивидуальную единицу можно только со склада; единица должна принадлежать выбранной позиции.
- Списание без места «откуда» сервер не проводит.
- В UI подключены уже существовавшие операции «На объект» и «Из ремонта».
- Правка единицы больше не отправляет статус и место (только инв. №, S/N, штрихкод, гарантия, комментарий).

**Предыдущая версия (15.08.2026, журнал операций UI):**
- `TmcOperationsPanel`: компактная таблица (дата / тип / позиции / кол-во), высота строки 40 px.
- Фильтр типа — сегментная полоска «Тип» (инверсия выбранного сегмента), визуально отдельно от пилюль `TmcSectionNavBar`.
- Короткие подписи типов: `TmcUiLabels.operationTypeShort`.
- Повторный аудит БД через MCP Supabase (`api.progt.ru`): 17 таблиц `tmc_*`, RLS ✅, 13 функций `tmc_*`, bucket `tmc` (`public = false`), `role_permissions` по `tmc` = 0. Схема без изменений.

**Предыдущая версия (15.08.2026, встроенные разделы + аудит документации):**
- Все разделы модуля открываются внутри основной области `TmcListScreen` (`TmcModuleSection` + `TmcSectionNavBar`), без отдельных экранов.
- Карточка позиции — встроенный просмотр (`TmcItemDetailsPanel`); «назад» возвращает в текущий раздел.
- Удалены экраны-оболочки: `TmcOperationsScreen`, `TmcStockScreen`, `TmcReportsScreen`, `TmcInventoryScreen`, `TmcNotificationsScreen`, диалог `TmcCatalogsDialog`.
- Маршруты `/tmc/operations`, `/tmc/stock`, `/tmc/reports`, `/tmc/inventory`, `/tmc/notifications` сняты. Остались `/tmc` и `/tmc/items/:itemId`.
- Аудит БД: 17 таблиц `tmc_*`, RLS ✅, 13 функций `tmc_*`, bucket `tmc`, `role_permissions` по `tmc` = 0.

**Предыдущая версия (15.08.2026, встроенная карточка):**
- Карточка позиции открывается внутри основной области модуля (`TmcItemDetailsPanel`), а не отдельным экраном. Кнопка «назад» возвращает в реестр.

**Предыдущая версия (15.08.2026, реестр и серийные номера):**
- Реестр: адаптивная таблица без слипания колонок; колонки «Учёт» и «Статус» убраны из списка (архив — бейдж у названия).
- Действия в строке: кнопка «Выдать» / «Возврат» + меню `···` / правый клик (`GTContextMenu`).
- Индивидуальные единицы: поле `tmc_units.serial_number`; ввод S/N при поступлении (`TmcSerialNumbersEditor`) и правка в `TmcUnitFormDialog`.
- RPC: `tmc_create_item_with_receipt` пробрасывает `serial_numbers`; `tmc_post_operation` пишет S/N на каждую создаваемую единицу (`tmc_receipt_serial_number`).
- Карточка сотрудника: вкладка ТМЦ по-прежнему показывает активные выдачи (`EmployeeTmcSection`).

**Предыдущая версия (15.08.2026, стоимость в выдаче):**
- [`TmcAssignment.unitPrice`](../../lib/features/tmc/domain/entities/tmc_assignment.dart) — join-поле, не колонка `tmc_assignments`
- `listAssignments`: select `tmc_items:item_id(name, unit_price)`; разбор `tmcParseNullableDouble`
- Карточка сотрудника читает те же выдачи: [`EmployeeTmcSection`](../../lib/features/employees/presentation/widgets/employee_tmc_section.dart)

**Предыдущая версия (29.07.2026):**
- UI видимости остатков: колонки «На складе / Выдано / Где лежит» в реестре; раздел остатков по складам.
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
- раздел остатков по складам (внутри модуля);
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
| Раздел остатков по складам | ✅ |
| Встроенные разделы (без отдельных экранов) | ✅ |
| Карточка позиции внутри модуля | ✅ |
| Серийные номера единиц (S/N) | ✅ |
| Справочники (склады, категории) | ✅ |
| Операции через RPC (кол-во в поступлении всегда) | ✅ |
| Журнал операций | ✅ |
| Отчёты Excel (`export`) | ✅ |
| Уведомления (свои) | ✅ чтение |
| Профиль / карточка сотрудника: выданное имущество | ✅ |
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

Один экран-оболочка: `TmcListScreen`. Шапка модуля (меню, заголовок «ТМЦ», тема) постоянна. KPI (`TmcKpiCards`) и панель разделов (`TmcSectionNavBar`) остаются на месте. Ниже меняется содержимое:

| `TmcModuleSection` | Панель | Примечание |
|--------------------|--------|------------|
| `registry` | `TmcFiltersToolbar` + `TmcItemsTable` | Поиск, категория, тип учёта, «Новая позиция» |
| `operations` | `TmcOperationsPanel` | Сегментный фильтр типа + компактная таблица (дата / тип / позиции / кол-во) |
| `stock` | `TmcStockPanel` | Склад + поиск; тап открывает карточку |
| `reports` | `TmcReportsPanel` | Excel; действие требует `export` |
| `inventory` | `TmcInventoryPanel` | Заглушка «в разработке» |
| `notifications` | `TmcNotificationsPanel` | Свои уведомления (`tmcNotificationsProvider`) |
| `catalogs` | `TmcCatalogsPanel` | Склады / категории; пункт виден при `manage_catalogs` |

Карточка позиции (`TmcItemDetailsPanel`) открывается **поверх текущего раздела** (`Offstage` + `TickerMode`): фильтры раздела не сбрасываются. «Назад» закрывает карточку. Переключение пилюли закрывает карточку и меняет раздел.

### Маршруты (`app_router.dart`)

| Маршрут | Виджет | Примечание |
|---------|--------|------------|
| `/tmc` | `TmcListScreen` | Основной вход; право `tmc.read`; desktop-guard |
| `/tmc/items/:itemId` | `TmcListScreen(openedItemId:)` | Deep link на карточку внутри той же оболочки |

Дочерние маршруты разделов (`/tmc/operations` и т.п.) **удалены**.

### Виджеты

| Виджет | Назначение |
|--------|------------|
| `TmcKpiCards` | KPI: на складе / выдано / на объекте / стоимость (`view_cost`); доп. сигналы ремонт/утеря/списание |
| `TmcSectionNavBar` | Пилюли разделов (`TmcModuleSection`) |
| `TmcFiltersToolbar` | Поиск / категория / тип учёта / обновить / «Новая позиция» (только реестр) |
| `TmcItemsTable` | Колонки: №, наименование, категория, на складе, выдано, где лежит, цена/стоимость (`view_cost`), действия. «Выдать»/«Возврат» + `GTContextMenu`. Пустой список — в `TmcListScreen` |
| `TmcOperationsPanel` | Журнал: сегментный фильтр типа (полоска «Тип», выбранный — инверсия); таблица дата / тип / позиции / кол-во (строка 40 px). Не путать с пилюлями `TmcSectionNavBar` |
| `TmcItemDetailsPanel` | Карточка: вкладки Основное / Единицы / Закупка / История; быстрые операции. Файл: `screens/tmc_item_details_screen.dart` (виджет, не отдельный Route-экран) |
| `TmcItemFormDialog` | Создание / правка позиции; при создании — поступление и S/N |
| `TmcOperationDialog` | Операция → RPC `tmc_post_operation`; индивидуальный учёт — выбор единицы; поступление — S/N |
| `TmcSerialNumbersEditor` | Поля серийных номеров при поступлении нескольких экземпляров |
| `TmcUnitFormDialog` | Правка единицы: инв. №, S/N, штрихкод, гарантия |
| `TmcCatalogsPanel` | Склады / категории (`manage_catalogs`) |

Design System: `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, `MobileAtmosphereChromeCircleButton`, `GTPrimaryButton`, `GTDropdown`, `GTTextField`, `GTContextMenu`, `AppSnackBar`, `AppDrawer`. Форматтеры: `formatCurrency`, `formatQuantity`, `formatRuDate`, `formatRuDateTime`.

### Сервисы / утилиты

- `TmcExcelExportService` — выгрузки Excel (`excel` + `FileSaver`).
- `tmc_ui_labels.dart` — подписи статусов/типов; `operationTypeShort` для фильтра журнала; хелперы `parseQuantity` / `parsePrice`, `receiptUnitCount`, `nonEmptySerials`, `warehouseLabel`, `unitLabel`.

### Провайдеры (Riverpod)

Файл: `presentation/state/tmc_providers.dart`

- `tmcRepositoryProvider`
- `tmcDashboardProvider`
- `tmcItemsListProvider` / фильтры `TmcItemsListFilters`
- `tmcItemProvider`, `tmcItemUnitsProvider`, `tmcItemOperationsProvider`
- `tmcCategoriesProvider`, `tmcConditionsProvider`, `tmcWarehousesProvider`
- `tmcStockProvider` (`TmcStockQuery`: warehouseId + search)
- `tmcOperationsProvider`
- `tmcAssignmentsProvider(employeeId)`
- `tmcNotificationsProvider`

Провайдера `tmcUnitsProvider` **нет** (ошибка прошлых редакций документации).

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

Freezed: `TmcItem` (+ поля `qtyInStock`, `qtyIssued`, `qtyOnObject`, `locationSummary`), `TmcUnit`, `TmcWarehouse`, `TmcCategory`, `TmcCondition`, `TmcOperation` (+ items), `TmcAssignment` (+ join `unitPrice` из `tmc_items.unit_price`), `TmcWriteOff`, `TmcNotification`, `TmcDashboardStats`.

Plain class: `TmcStockBalance` — строка остатка для раздела складов.

**Без Dart-модели (только БД):** `tmc_repairs`, `tmc_inventories`, `tmc_inventory_items`, `tmc_balances`, `tmc_attachments`, `tmc_condition_history`. Ремонт в UI — через операции и `tmc_units.status = in_repair`; инвентаризация — заглушка `TmcInventoryPanel`.

Слой **use cases** в модуле **отсутствует** (как в остальных фичах проекта): оркестрация в Notifier'ах, диалогах и RPC.

### Репозиторий

- Контракт: `TmcRepository` (19 публичных методов)
- Реализация: `TmcRepositoryImpl` (~660 строк после чистки)
- DI: `tmcRepositoryProvider` в `presentation/state/` импортирует `TmcRepositoryImpl` напрямую

| Группа | Методы |
|--------|--------|
| Дашборд | `getDashboardStats` → RPC `tmc_dashboard_stats` |
| Каталог | `listItems` → RPC `tmc_list_items`; `getItem` (обогащение остатками через list по **имени**); `createItem`, `createItemWithReceipt` → RPC `tmc_create_item_with_receipt`; `updateItem` (**без** `quantity` в payload) |
| Остатки | `listStock` → RPC `tmc_list_stock` |
| Единицы | `listUnits`, `updateUnit` (статус/место **не** в payload — только RPC) |
| Справочники | `listCategories`, `createCategory`; `listConditions`; `listWarehouses`, `createWarehouse` |
| Операции | `listOperations`, `postOperation` → RPC `tmc_post_operation` (внутри — `_getOperation`) |
| Выдачи / списания | `listAssignments`, `listWriteOffs` |
| Уведомления | `listNotifications`, `markNotificationRead` |

**Удалено из контракта (мёртвый код, 15.08.2026):** `archiveItem`, `archiveCategory`, `getUnit`, `updateCategory`, `updateWarehouse`, `getOperation` (публичный), `listRepairs`, `listInventories`, `createInventory`, `updateInventoryItem`, `completeInventory`, `nextInventoryNumber`.

### Модели

Freezed + `json_serializable` (`FieldRename.snake`), helpers в `tmc_json_utils.dart`.  
Модели: item, unit, warehouse, category, condition, operation (+ items), assignment, write_off, notification, dashboard_stats.  
`TmcItemModel.toWriteJson` удаляет `quantity` и `total_cost`.  
`listItems` / `listStock` маппят domain напрямую, минуя `TmcItemModel` / отдельную balance-модель.

---

## 📂 Дерево файлов

```
lib/features/tmc/
├── data/
│   ├── models/          # item, unit, warehouse, category, condition, operation,
│   │                    # assignment, write_off, notification, dashboard_stats,
│   │                    # tmc_json_utils.dart
│   └── repositories/
│       └── tmc_repository_impl.dart
├── domain/
│   ├── entities/        # Freezed + tmc_enums.dart + tmc_stock_balance.dart
│   │                    # (без tmc_repair / tmc_inventory — только БД)
│   └── repositories/
│       └── tmc_repository.dart
└── presentation/
    ├── screens/
    │   ├── tmc_list_screen.dart
    │   └── tmc_item_details_screen.dart
    ├── widgets/
    │   ├── tmc_kpi_cards.dart
    │   ├── tmc_section_nav.dart
    │   ├── tmc_filters_toolbar.dart
    │   ├── tmc_items_table.dart
    │   ├── tmc_item_form_dialog.dart
    │   ├── tmc_operation_dialog.dart
    │   ├── tmc_serial_numbers_editor.dart
    │   ├── tmc_unit_form_dialog.dart
    │   ├── tmc_operations_panel.dart
    │   ├── tmc_stock_panel.dart
    │   ├── tmc_reports_panel.dart
    │   ├── tmc_inventory_panel.dart
    │   ├── tmc_notifications_panel.dart
    │   └── tmc_catalogs_panel.dart
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
├── 20260729130000_tmc_stock_visibility.sql
├── 20260730120000_tmc_main_warehouse.sql
├── 20260815120000_tmc_create_item_serial_number.sql
├── 20260815130000_tmc_receipt_serial_numbers.sql
├── 20260815140000_tmc_operation_assignment_integrity.sql
└── 20260815141000_tmc_post_operation_assignment_integrity.sql

docs/tmc/
└── tmc_module.md

test/features/tmc/
└── tmc_enums_and_export_test.dart
```

Wiring вне фичи: `app_router.dart`, `app_drawer.dart`, `app_module_availability.dart`, матрица ролей, `profile/.../property_screen.dart`.

---

## 🗄️ База данных (Audit)

**Источник аудита:** live DB через MCP Supabase (`api.progt.ru`), 15.08.2026.  
**Миграции в репозитории:** 11 файлов `*tmc*` — от `20260729120000_create_tmc_module.sql` до `20260815141000_tmc_post_operation_assignment_integrity.sql` (все applied на live).

### `app_modules`

| code | name | icon_key | sort_order | is_active |
|------|------|----------|------------|-----------|
| `tmc` | ТМЦ | `cube_box` | 55 | true |

### Таблицы (live)

17 таблиц `tmc_*`. **RLS:** ✅ включён на всех (`relrowsecurity = true`, `relforcerowsecurity = false`).

| Таблица | RLS | live rows (`pg_stat_user_tables`, 15.08.2026) |
|---------|-----|-----------------------------------------------|
| `tmc_assignments` | ✅ | 4 |
| `tmc_attachments` | ✅ | 0 |
| `tmc_balances` | ✅ | 6 |
| `tmc_categories` | ✅ | 12 |
| `tmc_condition_history` | ✅ | 0 |
| `tmc_conditions` | ✅ | 18 |
| `tmc_inventories` | ✅ | 0 |
| `tmc_inventory_items` | ✅ | 0 |
| `tmc_inventory_number_seq` | ✅ | 1 |
| `tmc_items` | ✅ | 13 |
| `tmc_notifications` | ✅ | 0 |
| `tmc_operation_items` | ✅ | 26 |
| `tmc_operations` | ✅ | 26 |
| `tmc_repairs` | ✅ | 0 |
| `tmc_units` | ✅ | 46 |
| `tmc_warehouses` | ✅ | 4 |
| `tmc_write_offs` | ✅ | 0 |

#### `tmc_items` (каталог)

| Колонка | Описание |
|---------|----------|
| `accounting_type` | `individual` \| `quantitative` |
| `unit_price`, `quantity`, `total_cost` | `quantity` — денормализованный итог; источник правды по местам — balances/units |
| прочие | name, sku, category, supplier, archive, audit |

#### `tmc_units` / `tmc_balances`

- Индивидуальный учёт → `tmc_units` (инв. №, **`serial_number`**, штрихкод, статус, локация).
- Количественный → `tmc_balances` (qty по warehouse/object/employee/…).
- Клиент: SELECT; изменение остатков — только RPC. Правка S/N единицы — `UPDATE tmc_units` через `updateUnit`.

#### Прочие

Без изменений относительно v1: warehouses, categories, conditions, operations (+ items), condition_history, assignments, attachments, repairs, write_offs, inventories (+ items), notifications, inventory_number_seq.

### RLS

Типовой паттерн: `company_id ∈ get_my_company_ids()` + `check_permission(..., 'tmc', ...)`.

Исключения:
- `tmc_assignments` — self SELECT по employee профиля;
- `tmc_notifications` — только `user_id = auth.uid()` (без `tmc.read` для админов на live);
- `tmc_balances` — DML для `authenticated` отозван.

**RLS drift (live vs миграция `20260729120000`):** на live INSERT/UPDATE для `tmc_categories` и `tmc_warehouses` — через `tmc.create` / `tmc.update`, а не только `manage_catalogs`. Операции в приложении идут через SECURITY DEFINER RPC.

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
| `tmc_post_operation(jsonb)` | Проведение операции; при receipt individual пишет S/N из `serial_numbers[i]` |
| `tmc_create_item_with_receipt(jsonb)` | Создание позиции + опциональное поступление |
| `tmc_receipt_serial_number(jsonb, int)` | Helper: S/N i-й создаваемой единицы |
| `tmc_dashboard_stats(uuid)` | KPI |
| `tmc_list_items(...)` | Реестр + `qty_in_stock` / `qty_issued` / `qty_on_object` / `location_summary` |
| `tmc_list_stock(company, warehouse?, search?)` | Остатки на складах (balances + units `in_stock`) |
| `tmc_recalc_item_quantity(item_id)` | Пересчёт `tmc_items.quantity` |
| `tmc_trg_recalc_item_qty()` | Trigger function |
| `tmc_next_inventory_number` | Инв. № |
| `tmc_adjust_balance` | Helper остатков |
| `tmc_status_for_location` / `tmc_status_for_operation` | Маппинг статуса |
| `tmc_protect_system_warehouse` | Защита системного склада |
| `tmc_close_unit_assignments` | Закрытие активных выдач единицы |
| `tmc_consume_employee_assignments` | FIFO-списание количества с выдач сотрудника |

Права по типам операций в `tmc_post_operation` — без изменений (receipt→`create`, issue→`issue`, move→`move`, …).

### Триггеры (live)

| Триггер | Таблица | Функция |
|---------|---------|---------|
| `trg_tmc_balances_recalc_qty` | `tmc_balances` | `tmc_trg_recalc_item_qty` |
| `trg_tmc_units_recalc_qty` | `tmc_units` | `tmc_trg_recalc_item_qty` |
| `trg_tmc_warehouses_protect_system` | `tmc_warehouses` | `tmc_protect_system_warehouse` |
| `trg_tmc_*_updated_at` | assignments, categories, conditions, inventories, inventory_items, items, operations, repairs, units, warehouses, write_offs | `set_updated_at()` |

### Edge Functions

В `supabase/functions/` **нет** каталогов `tmc*`. В коде модуля нет `functions.invoke`. Логика — Postgres RPC + клиент PostgREST.  
Инструмент `list_edge_functions` в текущем MCP **отсутствует**; проверка — файлы репозитория + grep по `lib/features/tmc`.

### Storage

Bucket `tmc` ✅ существует. Клиентская загрузка фото — не подключена.

---

## 🧠 Бизнес-логика

### Типы учёта

1. **Индивидуальный** — единицы в `tmc_units` с инвентарным номером и опциональным заводским **серийным номером** (`serial_number`). При поступлении можно указать количество > 1 → создаётся несколько единиц; для каждой можно вписать свой S/N. Операции (выдача, перемещение, списание) идут по выбранной единице.
2. **Количественный** — остатки в `tmc_balances` по локациям.

### Каталог vs остаток

```text
Создание позиции каталога  → quantity = 0, на складе ничего нет
Поступление (receipt)      → выбор склада + количество → balances/units
tmc_items.quantity         → сумма/count по balances или units (триггер)
Реестр / раздел остатков  → live разбивка и места хранения
```

### Формула quantity (recalc)

```text
quantitative: quantity = SUM(tmc_balances.quantity) WHERE item_id = …
individual:   quantity = COUNT(tmc_units) WHERE not archived AND status <> written_off
```

### Статус единицы

- поступление на склад → `in_stock`;
- выдача → `issued` + `tmc_assignments` (только из `in_stock`);
- возврат количественный → FIFO по `issued_at`: количество выдачи уменьшается или запись закрывается;
- ремонт → `in_repair` + `tmc_repairs`, активная выдача единицы закрывается;
- списание → `written_off` + `tmc_write_offs`, активная выдача единицы закрывается.

### Основной сценарий

1. Создать склад (справочники).
2. Создать позицию каталога (без количества).
3. **Поступление** на склад с количеством.
4. Контроль: реестр (колонки остатков) или **Остатки по складам**.
5. Выдача / перемещение / возврат / ремонт / списание.
6. Отчёты Excel, профиль сотрудника.

### Инвентаризация

Схема БД и RPC-тип `inventory_adjust` есть. UI — заглушка `TmcInventoryPanel`. Клиентский API репозитория для `tmc_inventories` **удалён** (будет добавлен при реализации раздела).

### Уведомления

Чтение своих записей есть. Автогенерация по срокам — нет.

---

## 🔌 Интеграции

| Интеграция | Как |
|------------|-----|
| Роли / RBAC | `app_modules.code = tmc`, `check_permission` |
| Сотрудники | FK, выдача, `PropertyScreen`, вкладка «ТМЦ» в карточке (`EmployeeTmcSection`) |
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
- ✅ Desktop: один экран `TmcListScreen`, встроенные разделы и карточка позиции
- ✅ Журнал операций: компактная таблица + сегментный фильтр типа
- ✅ Серийные номера единиц (ввод при поступлении и правка в карточке)
- ✅ Контекстное меню и быстрые действия в реестре
- ✅ Self SELECT assignments; уведомления только свои
- ✅ Профиль «Выданное имущество»
- ✅ Карточка сотрудника: вкладка «ТМЦ» (просмотр активных выдач + стоимость)
- ✅ Desktop-only guard; тесты enums/export
- ✅ Аудит модуля + удаление мёртвого кода репозитория (15.08.2026)

### Планы / долги

- 🟡 Полноценная инвентаризация UI (+ восстановить entity/model и методы репозитория)
- 🟡 Списание количественного ТМЦ с сотрудника в UI (RPC поддерживает, диалог — нет)
- 🟡 Централизовать правила «когда можно выдать/вернуть» (сейчас в диалоге, карточке и таблице)
- 🟡 Вынести построение payload операции из `TmcOperationDialog` в domain
- 🟡 Исправить `getItem` — обогащение по id, не по имени
- 🟡 Mobile / QR
- 🟡 Загрузка фото/вложений в Storage
- 🟡 Авто-уведомления по срокам
- 🟡 Обогащение Excel-отчётов реальными `tmc_balances` (не только units)
- 🟡 Отчёт «В ремонте» через `tmc_repairs` (сейчас `listUnits(in_repair)`)
- 🟢 Seed прав ТМЦ для типовых ролей
- 🟢 Импорт каталога (`import` скрыт)
- 🟢 UI архивации позиций / правка категорий и складов (методы репозитория удалены)

### Известные ограничения

- Не-Owner без прав в «Ролях» модуль недоступен.
- Инвентаризация в меню — UI «в разработке» (`TmcInventoryPanel`).
- `total_cost` в KPI скрыт без `view_cost`.
- `getItem` обогащает остатки через `listItems` по имени (при дубликатах имён или limit — риск нулевых остатков).
- `listAssignments` возвращает все выдачи; фильтр `is_active` — в UI (`PropertyScreen`, `EmployeeTmcSection`).
- Типы операций в enum/RPC без UI: `return_from_object`, `move_between_objects`, `transfer_between_employees`, `reserve`, `unreserve`, `shortage`, `inventory_adjust`, `correction`.

---

## ✅ Чек-лист аудита (15.08.2026, после чистки кода)

| Проверка | Результат |
|----------|-----------|
| Файлы `lib/features/tmc/` | ✅ ~73 исходников (+ generated); `screens`: `tmc_list_screen`, `tmc_item_details_screen` (`TmcItemDetailsPanel`) |
| Журнал операций UI | ✅ `TmcOperationsPanel`: сегментный фильтр + компактная таблица |
| Удалённые экраны-оболочки | ✅ `Tmc*Screen` разделов и `TmcCatalogsDialog` отсутствуют |
| Маршруты | ✅ `/tmc`, `/tmc/items/:itemId`; дочерние разделы сняты |
| Провайдеры | ✅ 13 `final` в `tmc_providers.dart`; `tmcUnitsProvider` нет |
| `TmcRepository` методы | ✅ 19 публичных; мёртвые методы удалены |
| Dart entity repair/inventory | ❌ удалены; таблицы БД сохранены |
| Таблицы live `tmc_%` | ✅ 17, RLS ✅ на всех |
| RPC `tmc_*` | ✅ 15 (вкл. `tmc_close_unit_assignments`, `tmc_consume_employee_assignments`) |
| Триггеры recalc qty | ✅ на `tmc_balances`, `tmc_units` |
| Edge Functions ТМЦ | ❌ нет в `supabase/functions/` |
| Bucket `tmc` | ✅ `public = false` |
| `role_permissions` seed `tmc` | ❌ 0 записей (`module_code = 'tmc'`) |
| Grants `authenticated` на `tmc_balances` | ✅ нет INSERT/UPDATE/DELETE |
| Миграции в репозитории | ✅ **11** файлов `*tmc*` |
| Миграции applied (live) | ✅ вкл. `140000`, `141000`, serial numbers |
| Тесты | ✅ `test/features/tmc/tmc_enums_and_export_test.dart` |
| Документация соответствует коду | ✅ этот файл (15.08.2026) |
