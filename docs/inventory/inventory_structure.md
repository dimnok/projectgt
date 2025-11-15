# Структура и связи модуля "Склад" (учет ТМЦ)

**Дата создания:** 7 ноября 2025 года  
**Статус:** В разработке

---

## Общая схема модуля

Модуль "Склад" состоит из 8 основных таблиц, которые связаны между собой через Foreign Keys и интегрируются с существующими таблицами системы (`employees`, `objects`, `contractors`, `profiles`).

---

## Диаграмма связей таблиц

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Модуль "Склад" (Inventory)                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│ inventory_categories│ (Справочник категорий)
│─────────────────────│
│ id (PK)             │
│ name                │
│ prefix              │
│ serial_number_req   │
│ service_life_req    │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐
│ inventory_items     │ (Основная таблица ТМЦ)
│─────────────────────│
│ id (PK)             │◄──────────────────┐
│ category_id (FK)    │                    │
│ serial_number       │                    │
│ status              │                    │
│ location_type       │                    │
│ location_id         │                    │
│ responsible_id      │                    │
│ receipt_id (FK)     │                    │
│ receipt_item_id(FK) │                    │
└──────────┬──────────┘                    │
           │                                │
           │ 1:N                            │
           │                                │
           │  ┌─────────────────────────────┘
           │  │
           │  │ 1:N
           ↓  ↓
┌─────────────────────┐         ┌─────────────────────┐
│ inventory_movements │         │ inventory_breakdowns│
│─────────────────────│         │─────────────────────│
│ id (PK)             │         │ id (PK)             │
│ item_id (FK)        │         │ item_id (FK)        │
│ movement_type       │         │ type                │
│ from_location_type  │         │ status              │
│ to_location_type    │         │ reported_by         │
│ moved_at            │         │ charge_amount       │
└─────────────────────┘         └─────────────────────┘

┌─────────────────────┐
│ inventory_receipts  │ (Накладные прихода)
│─────────────────────│
│ id (PK)             │
│ receipt_number      │
│ receipt_date        │
│ supplier_id (FK)    │
│ file_url            │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐
│inventory_receipt_   │ (Позиции накладных)
│items                │
│─────────────────────│
│ id (PK)             │
│ receipt_id (FK)     │
│ name                │
│ category_id (FK)    │
│ quantity            │
│ price               │
└─────────────────────┘

┌─────────────────────┐
│ inventory_inventory │ (Акты инвентаризации)
│─────────────────────│
│ id (PK)             │
│ inventory_date      │
│ location_type       │
│ location_id         │
│ status              │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐
│inventory_inventory_ │ (Позиции актов)
│items                │
│─────────────────────│
│ id (PK)             │
│ inventory_id (FK)   │
│ item_id (FK)        │
│ status              │
└─────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│              Существующие таблицы системы                           │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│ contractors         │ (Поставщики)
│─────────────────────│
│ id (PK)             │
│ type = 'supplier'   │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐
│ inventory_receipts  │
│ supplier_id (FK)    │
└─────────────────────┘

┌─────────────────────┐
│ employees           │ (Сотрудники)
│─────────────────────│
│ id (PK)             │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐         ┌─────────────────────┐
│ inventory_items     │         │ inventory_movements │
│ location_id (FK)    │         │ to_location_id (FK)  │
│ responsible_id (FK) │         │ from_location_id(FK)│
└─────────────────────┘         └─────────────────────┘

┌─────────────────────┐
│ objects             │ (Объекты)
│─────────────────────│
│ id (PK)             │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐         ┌─────────────────────┐
│ inventory_items     │         │ inventory_movements │
│ location_id (FK)    │         │ to_location_id (FK)  │
│                     │         │ from_location_id(FK)│
└─────────────────────┘         └─────────────────────┘

┌─────────────────────┐
│ profiles            │ (Пользователи)
│─────────────────────│
│ id (PK)             │
└──────────┬──────────┘
           │
           │ 1:N
           ↓
┌─────────────────────┐         ┌─────────────────────┐
│ inventory_items     │         │ inventory_receipts │
│ created_by (FK)     │         │ created_by (FK)      │
│ updated_by (FK)     │         └─────────────────────┘
└─────────────────────┘
```

---

## Детальное описание связей

### 1. Связь `inventory_items` → `inventory_categories`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_items.category_id` → `inventory_categories.id`

**Описание:** Каждая единица ТМЦ принадлежит одной категории. Категория определяет:
- Префикс категории
- Обязательность серийного номера
- Срок службы (если требуется)

**Каскадное удаление:** RESTRICT (нельзя удалить категорию, если есть ТМЦ этой категории)

---

### 2. Связь `inventory_items` → `inventory_receipts`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_items.receipt_id` → `inventory_receipts.id`

**Описание:** Каждая единица ТМЦ связана с накладной прихода, через которую она поступила на склад.

**Каскадное удаление:** SET NULL (при удалении накладной поле обнуляется, но ТМЦ остаётся)

---

### 3. Связь `inventory_items` → `inventory_receipt_items`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_items.receipt_item_id` → `inventory_receipt_items.id`

**Описание:** Каждая единица ТМЦ связана с позицией накладной прихода. Если в позиции количество > 1, создаётся несколько единиц ТМЦ с одинаковым `receipt_item_id`.

**Каскадное удаление:** SET NULL (при удалении позиции поле обнуляется, но ТМЦ остаётся)

---

### 4. Связь `inventory_items` → `employees` (местоположение)

**Тип:** Many-to-One (N:1), условная  
**FK:** `inventory_items.location_id` → `employees.id` (если `location_type = 'employee'`)

**Описание:** Если ТМЦ выдано сотруднику, `location_type = 'employee'` и `location_id` указывает на сотрудника.

**Каскадное удаление:** SET NULL (при удалении сотрудника ТМЦ возвращается на склад)

---

### 5. Связь `inventory_items` → `objects` (местоположение)

**Тип:** Many-to-One (N:1), условная  
**FK:** `inventory_items.location_id` → `objects.id` (если `location_type = 'object'`)

**Описание:** Если ТМЦ передано на объект, `location_type = 'object'` и `location_id` указывает на объект.

**Каскадное удаление:** SET NULL (при удалении объекта ТМЦ возвращается на склад)

---

### 6. Связь `inventory_items` → `employees` (ответственный)

**Тип:** Many-to-One (N:1), опциональная  
**FK:** `inventory_items.responsible_id` → `employees.id`

**Описание:** Ответственное лицо за ТМЦ. Определяется автоматически по местоположению:
- На складе — складской работник
- На объекте — ответственный за объект (из `object_approvers`)
- У сотрудника — сам сотрудник

**Каскадное удаление:** SET NULL (при удалении сотрудника ответственный обнуляется)

---

### 7. Связь `inventory_receipts` → `contractors`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_receipts.supplier_id` → `contractors.id` (где `contractors.type = 'supplier'`)

**Описание:** Каждая накладная прихода связана с поставщиком из справочника контрагентов.

**Каскадное удаление:** RESTRICT (нельзя удалить поставщика, если есть накладные)

---

### 8. Связь `inventory_receipt_items` → `inventory_receipts`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_receipt_items.receipt_id` → `inventory_receipts.id`

**Описание:** Каждая позиция накладной принадлежит одной накладной.

**Каскадное удаление:** CASCADE (при удалении накладной удаляются все позиции)

---

### 9. Связь `inventory_receipt_items` → `inventory_categories`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_receipt_items.category_id` → `inventory_categories.id`

**Описание:** Каждая позиция накладной относится к одной категории ТМЦ.

**Каскадное удаление:** RESTRICT (нельзя удалить категорию, если есть позиции)

---

### 10. Связь `inventory_movements` → `inventory_items`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_movements.item_id` → `inventory_items.id`

**Описание:** Каждое перемещение связано с одной единицей ТМЦ. История перемещений хранится в отдельной таблице.

**Каскадное удаление:** CASCADE (при удалении ТМЦ удаляется вся история перемещений)

---

### 11. Связь `inventory_movements` → `employees` (откуда/куда)

**Тип:** Many-to-One (N:1), условная  
**FK:** `inventory_movements.from_location_id` → `employees.id` (если `from_location_type = 'employee'`)  
**FK:** `inventory_movements.to_location_id` → `employees.id` (если `to_location_type = 'employee'`)

**Описание:** Если перемещение связано с сотрудником, `location_id` указывает на сотрудника.

**Каскадное удаление:** SET NULL (при удалении сотрудника поле обнуляется)

---

### 12. Связь `inventory_movements` → `objects` (откуда/куда)

**Тип:** Many-to-One (N:1), условная  
**FK:** `inventory_movements.from_location_id` → `objects.id` (если `from_location_type = 'object'`)  
**FK:** `inventory_movements.to_location_id` → `objects.id` (если `to_location_type = 'object'`)

**Описание:** Если перемещение связано с объектом, `location_id` указывает на объект.

**Каскадное удаление:** SET NULL (при удалении объекта поле обнуляется)

---

### 13. Связь `inventory_breakdowns` → `inventory_items`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_breakdowns.item_id` → `inventory_items.id`

**Описание:** Каждая заявка о поломке/утрате связана с одной единицей ТМЦ.

**Каскадное удаление:** CASCADE (при удалении ТМЦ удаляются все заявки)

---

### 14. Связь `inventory_breakdowns` → `profiles` / `employees`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_breakdowns.reported_by` → `profiles.id` или `employees.id`

**Описание:** Кто сообщил о поломке/утрате.

**Каскадное удаление:** SET NULL (при удалении пользователя/сотрудника поле обнуляется)

---

### 15. Связь `inventory_inventory` → `objects` (местоположение)

**Тип:** Many-to-One (N:1), условная  
**FK:** `inventory_inventory.location_id` → `objects.id` (если `location_type = 'object'`)

**Описание:** Если инвентаризация проводится на объекте, `location_id` указывает на объект.

**Каскадное удаление:** SET NULL (при удалении объекта поле обнуляется)

---

### 16. Связь `inventory_inventory_items` → `inventory_inventory`

**Тип:** Many-to-One (N:1)  
**FK:** `inventory_inventory_items.inventory_id` → `inventory_inventory.id`

**Описание:** Каждая позиция акта инвентаризации принадлежит одному акту.

**Каскадное удаление:** CASCADE (при удалении акта удаляются все позиции)

---

### 17. Связь `inventory_inventory_items` → `inventory_items`

**Тип:** Many-to-One (N:1), опциональная  
**FK:** `inventory_inventory_items.item_id` → `inventory_items.id`

**Описание:** Если позиция найдена в учёте, `item_id` указывает на ТМЦ. Если позиция не найдена в учёте (`status = 'found_additional'`), `item_id = NULL`.

**Каскадное удаление:** SET NULL (при удалении ТМЦ поле обнуляется)

---

## Связи с существующими таблицами

### `profiles` (Пользователи)
- `inventory_items.created_by` → `profiles.id`
- `inventory_items.updated_by` → `profiles.id`
- `inventory_receipts.created_by` → `profiles.id`
- `inventory_movements.created_by` → `profiles.id`
- `inventory_breakdowns.reported_by` → `profiles.id` (опционально)
- `inventory_breakdowns.decided_by` → `profiles.id`
- `inventory_inventory.conducted_by` → `profiles.id`

### `employees` (Сотрудники)
- `inventory_items.location_id` → `employees.id` (если `location_type = 'employee'`)
- `inventory_items.responsible_id` → `employees.id`
- `inventory_movements.from_location_id` → `employees.id` (если `from_location_type = 'employee'`)
- `inventory_movements.to_location_id` → `employees.id` (если `to_location_type = 'employee'`)
- `inventory_movements.from_responsible_id` → `employees.id`
- `inventory_movements.to_responsible_id` → `employees.id`
- `inventory_breakdowns.reported_by` → `employees.id` (опционально)
- `inventory_breakdowns.commission_members` → `employees.id[]` (массив)
- `inventory_inventory.commission_members` → `employees.id[]` (массив)

### `objects` (Объекты)
- `inventory_items.location_id` → `objects.id` (если `location_type = 'object'`)
- `inventory_movements.from_location_id` → `objects.id` (если `from_location_type = 'object'`)
- `inventory_movements.to_location_id` → `objects.id` (если `to_location_type = 'object'`)
- `inventory_inventory.location_id` → `objects.id` (если `location_type = 'object'`)

### `contractors` (Контрагенты)
- `inventory_receipts.supplier_id` → `contractors.id` (где `contractors.type = 'supplier'`)

---

## Логика определения ответственного лица

Ответственное лицо (`inventory_items.responsible_id`) определяется автоматически по местоположению:

1. **На складе** (`location_type = 'warehouse'`, `location_id = NULL`):
   - Ответственный — складской работник (из профиля пользователя или настройки системы)

2. **На объекте** (`location_type = 'object'`, `location_id = objects.id`):
   - Ответственный — ответственный за объект из таблицы `object_approvers` (роль `project_manager`)

3. **У сотрудника** (`location_type = 'employee'`, `location_id = employees.id`):
   - Ответственный — сам сотрудник (`employees.id`)

---

---

## Логика перемещений

При перемещении ТМЦ создаётся запись в `inventory_movements` и обновляется `inventory_items`:

1. **Создание записи перемещения:**
   - Заполнение полей `from_location_type`, `from_location_id`
   - Заполнение полей `to_location_type`, `to_location_id`
   - Определение ответственных лиц
   - Установка даты перемещения

2. **Обновление ТМЦ:**
   - Обновление `location_type` и `location_id`
   - Обновление `responsible_id`
   - Обновление `issued_at` (если выдано сотруднику или на объект)

---

## Логика инвентаризации

При проведении инвентаризации:

1. **Создание акта** (`inventory_inventory`):
   - Выбор места инвентаризации (склад или объект)
   - Установка статуса `in_progress`

2. **Добавление позиций** (`inventory_inventory_items`):
   - Для каждой единицы ТМЦ по выбранному месту создаётся позиция
   - Отмечается статус: `found`, `not_found`, `found_additional`

3. **Завершение инвентаризации:**
   - Статус акта меняется на `completed`
   - Формируется PDF-акт
   - Сохраняется ссылка на PDF в `pdf_url`

---

**Последнее обновление:** 7 ноября 2025 года

