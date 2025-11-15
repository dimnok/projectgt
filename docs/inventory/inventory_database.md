# База данных модуля "Склад" (учет ТМЦ)

**Дата создания:** 7 ноября 2025 года  
**Статус:** В разработке

---

## Общая информация

Модуль "Склад" использует следующие таблицы для учёта товарно-материальных ценностей (ТМЦ):
- `inventory_items` — основная таблица ТМЦ
- `inventory_receipts` — накладные прихода ТМЦ
- `inventory_receipt_items` — позиции накладных прихода
- `inventory_movements` — история перемещений ТМЦ
- `inventory_breakdowns` — заявки о поломках/утратах/ремонте
- `inventory_categories` — справочник категорий ТМЦ
- `inventory_inventory` — акты инвентаризации
- `inventory_inventory_items` — позиции актов инвентаризации

---

## 1. Таблица `inventory_items` (Основная таблица ТМЦ)

**Описание:** Хранит информацию о каждой единице ТМЦ в системе. Каждая запись представляет собой одну единицу ТМЦ.

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор ТМЦ (PK) |
| `name` | text | NO | — | Наименование ТМЦ |
| `category_id` | uuid | NO | — | Ссылка на категорию (FK → `inventory_categories.id`) |
| `serial_number` | text | YES | — | Серийный номер (обязателен, если категория требует) |
| `unit` | text | NO | — | Единица измерения (шт., м, кг и т.п.) |
| `photo_url` | text | YES | — | URL фотографии ТМЦ в Supabase Storage |
| `status` | text | NO | `'working'` | Статус ТМЦ (`working`, `repair`, `written_off`, `new`, `used`) |
| `condition` | text | NO | `'new'` | Состояние при приходе (`new`, `used`) |
| `location_type` | text | NO | `'warehouse'` | Тип местоположения (`warehouse`, `object`, `employee`) |
| `location_id` | uuid | YES | — | ID местоположения (склад = NULL, объект = `objects.id`, сотрудник = `employees.id`) |
| `responsible_id` | uuid | YES | — | Ответственное лицо (FK → `employees.id` или `profiles.id`) |
| `receipt_id` | uuid | YES | — | Ссылка на накладную прихода (FK → `inventory_receipts.id`) |
| `receipt_item_id` | uuid | YES | — | Ссылка на позицию накладной (FK → `inventory_receipt_items.id`) |
| `price` | numeric(10,2) | YES | — | Цена за единицу при приходе |
| `purchase_date` | date | YES | — | Дата приобретения (из накладной) |
| `warranty_expires_at` | date | YES | — | Дата окончания гарантии (если есть) |
| `service_life_months` | integer | YES | — | Срок службы в месяцах (индивидуальный для каждого ТМЦ, может отличаться от дефолтного значения в категории) |
| `issued_at` | date | YES | — | Дата выдачи (если выдано сотруднику или на объект) |
| `notes` | text | YES | — | Примечания |
| `created_at` | timestamptz | NO | `now()` | Дата создания записи |
| `updated_at` | timestamptz | NO | `now()` | Дата последнего обновления |
| `created_by` | uuid | YES | — | Кто создал запись (FK → `profiles.id`) |
| `updated_by` | uuid | YES | — | Кто обновил запись (FK → `profiles.id`) |

**Индексы:**
- `idx_inventory_items_serial_number` — индекс на `serial_number` (для поиска)
- `idx_inventory_items_category_id` — индекс на `category_id` (для фильтрации)
- `idx_inventory_items_location` — составной индекс на `location_type, location_id` (для поиска по местоположению)
- `idx_inventory_items_status` — индекс на `status` (для фильтрации)
- `idx_inventory_items_name` — GIN индекс на `name` (для полнотекстового поиска)

**Ограничения:**
- `inventory_items_serial_number_unique` — уникальность `serial_number` (если не NULL)
- `inventory_items_status_check` — проверка значения `status` (enum)
- `inventory_items_location_type_check` — проверка значения `location_type` (enum)

**RLS-политики:**
- Пользователи могут читать ТМЦ, к которым имеют доступ (по объектам из `profiles.object_ids`)
- Администраторы могут создавать, обновлять и удалять любые ТМЦ
- Пользователи могут обновлять статус ТМЦ, если они ответственные или администраторы

---

## 2. Таблица `inventory_receipts` (Накладные прихода ТМЦ)

**Описание:** Хранит информацию о накладных прихода ТМЦ на склад. Каждая накладная может содержать несколько позиций.

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор накладной (PK) |
| `receipt_number` | text | NO | — | Номер накладной (уникальный) |
| `receipt_date` | date | NO | — | Дата накладной |
| `supplier_id` | uuid | NO | — | Ссылка на поставщика (FK → `contractors.id`, тип `supplier`) |
| `file_url` | text | YES | — | URL скана накладной в Supabase Storage |
| `comment` | text | YES | — | Комментарий к накладной |
| `total_amount` | numeric(10,2) | YES | — | Общая сумма накладной (вычисляется из позиций) |
| `items_count` | integer | NO | `0` | Количество позиций в накладной |
| `created_at` | timestamptz | NO | `now()` | Дата создания записи |
| `updated_at` | timestamptz | NO | `now()` | Дата последнего обновления |
| `created_by` | uuid | YES | — | Кто создал накладную (FK → `profiles.id`) |

**Индексы:**
- `idx_inventory_receipts_receipt_number` — уникальный индекс на `receipt_number`
- `idx_inventory_receipts_supplier_id` — индекс на `supplier_id` (для фильтрации)
- `idx_inventory_receipts_receipt_date` — индекс на `receipt_date` (для сортировки)

**Ограничения:**
- `inventory_receipts_receipt_number_key` — уникальность `receipt_number`

**RLS-политики:**
- Пользователи могут читать накладные, к которым имеют доступ
- Администраторы могут создавать, обновлять и удалять накладные
- Пользователи могут создавать накладные (для своего объекта)

---

## 3. Таблица `inventory_receipt_items` (Позиции накладных прихода)

**Описание:** Хранит позиции накладных прихода ТМЦ. Каждая позиция может породить одну или несколько единиц ТМЦ (если количество > 1).

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор позиции (PK) |
| `receipt_id` | uuid | NO | — | Ссылка на накладную (FK → `inventory_receipts.id`) |
| `name` | text | NO | — | Наименование ТМЦ |
| `category_id` | uuid | NO | — | Ссылка на категорию (FK → `inventory_categories.id`) |
| `unit` | text | NO | — | Единица измерения |
| `quantity` | numeric(10,2) | NO | — | Количество единиц |
| `price` | numeric(10,2) | YES | — | Цена за единицу |
| `total` | numeric(10,2) | YES | — | Итоговая стоимость (`quantity × price`) |
| `serial_number` | text | YES | — | Серийный номер (если одна единица) |
| `photo_url` | text | YES | — | URL фотографии позиции в Supabase Storage |
| `notes` | text | YES | — | Примечание к позиции |
| `created_at` | timestamptz | NO | `now()` | Дата создания записи |

**Индексы:**
- `idx_inventory_receipt_items_receipt_id` — индекс на `receipt_id` (для связи с накладной)
- `idx_inventory_receipt_items_category_id` — индекс на `category_id` (для фильтрации)

**RLS-политики:**
- Пользователи могут читать позиции накладных, к которым имеют доступ
- Администраторы могут создавать, обновлять и удалять позиции
- Позиции создаются вместе с накладной

---

## 4. Таблица `inventory_movements` (История перемещений ТМЦ)

**Описание:** Хранит историю всех перемещений ТМЦ между складом, объектами и сотрудниками. Каждое перемещение фиксируется отдельной записью.

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор перемещения (PK) |
| `item_id` | uuid | NO | — | Ссылка на ТМЦ (FK → `inventory_items.id`) |
| `movement_type` | text | NO | — | Тип перемещения (`warehouse_to_object`, `warehouse_to_employee`, `object_to_warehouse`, `object_to_employee`, `employee_to_warehouse`, `employee_to_object`, `object_to_object`) |
| `from_location_type` | text | NO | — | Тип места отправления (`warehouse`, `object`, `employee`) |
| `from_location_id` | uuid | YES | — | ID места отправления (NULL для склада, иначе `objects.id` или `employees.id`) |
| `to_location_type` | text | NO | — | Тип места назначения (`warehouse`, `object`, `employee`) |
| `to_location_id` | uuid | YES | — | ID места назначения (NULL для склада, иначе `objects.id` или `employees.id`) |
| `from_responsible_id` | uuid | YES | — | Ответственный в месте отправления (FK → `employees.id` или `profiles.id`) |
| `to_responsible_id` | uuid | YES | — | Ответственный в месте назначения (FK → `employees.id` или `profiles.id`) |
| `reason` | text | YES | — | Причина перемещения |
| `notes` | text | YES | — | Примечания к перемещению |
| `moved_at` | date | NO | — | Дата перемещения |
| `created_at` | timestamptz | NO | `now()` | Дата создания записи |
| `created_by` | uuid | YES | — | Кто создал запись (FK → `profiles.id`) |

**Индексы:**
- `idx_inventory_movements_item_id` — индекс на `item_id` (для истории ТМЦ)
- `idx_inventory_movements_moved_at` — индекс на `moved_at` (для сортировки)
- `idx_inventory_movements_location` — составной индекс на `to_location_type, to_location_id` (для поиска по местоположению)

**Ограничения:**
- `inventory_movements_movement_type_check` — проверка значения `movement_type` (enum)

**RLS-политики:**
- Пользователи могут читать перемещения, к которым имеют доступ
- Администраторы могут создавать перемещения
- Пользователи могут создавать перемещения для своих объектов/сотрудников

---

## 5. Таблица `inventory_breakdowns` (Заявки о поломках/утратах/ремонте)

**Описание:** Хранит заявки о поломках, утратах и ремонте ТМЦ. Каждая заявка проходит через процесс рассмотрения комиссией.

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор заявки (PK) |
| `item_id` | uuid | NO | — | Ссылка на ТМЦ (FK → `inventory_items.id`) |
| `type` | text | NO | — | Тип заявки (`breakdown`, `loss`, `repair`) |
| `reported_by` | uuid | NO | — | Кто сообщил (FK → `profiles.id` или `employees.id`) |
| `description` | text | NO | — | Описание проблемы |
| `photo_url` | text | YES | — | URL фотографии поломки/утраты в Supabase Storage |
| `preliminary_reason` | text | YES | — | Предварительная причина (`wear`, `misuse`, `loss`, `defect`, `other`) |
| `status` | text | NO | `'pending'` | Статус заявки (`pending`, `written_off_no_charge`, `written_off_with_charge`, `sent_to_repair`, `returned_to_work`, `rejected`) |
| `commission_decision` | text | YES | — | Решение комиссии (текст) |
| `charge_amount` | numeric(10,2) | YES | — | Сумма удержания с сотрудника (если `status = 'written_off_with_charge'`) |
| `commission_members` | uuid[] | YES | — | Массив ID членов комиссии (FK → `employees.id`) |
| `decided_at` | date | YES | — | Дата решения комиссии |
| `decided_by` | uuid | YES | — | Кто принял решение (FK → `profiles.id`) |
| `notes` | text | YES | — | Примечания комиссии |
| `created_at` | timestamptz | NO | `now()` | Дата создания заявки |
| `updated_at` | timestamptz | NO | `now()` | Дата последнего обновления |

**Индексы:**
- `idx_inventory_breakdowns_item_id` — индекс на `item_id` (для связи с ТМЦ)
- `idx_inventory_breakdowns_status` — индекс на `status` (для фильтрации)
- `idx_inventory_breakdowns_reported_by` — индекс на `reported_by` (для поиска по сообщившему)
- `idx_inventory_breakdowns_type` — индекс на `type` (для фильтрации)

**Ограничения:**
- `inventory_breakdowns_type_check` — проверка значения `type` (enum)
- `inventory_breakdowns_status_check` — проверка значения `status` (enum)
- `inventory_breakdowns_preliminary_reason_check` — проверка значения `preliminary_reason` (enum)

**RLS-политики:**
- Пользователи могут читать заявки, к которым имеют доступ
- Пользователи могут создавать заявки для ТМЦ, к которым имеют доступ
- Администраторы и члены комиссии могут обновлять статус заявки

---

## 6. Таблица `inventory_categories` (Справочник категорий ТМЦ)

**Описание:** Хранит справочник категорий ТМЦ с настройками для каждой категории (обязательность серийного номера, срок службы и т.п.).

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор категории (PK) |
| `name` | text | NO | — | Наименование категории (уникальное) |
| `prefix` | text | NO | — | Префикс категории (например, "ИНВ", "СПЕЦ") |
| `serial_number_required` | boolean | NO | `false` | Обязателен ли серийный номер для категории |
| `service_life_required` | boolean | NO | `false` | Обязателен ли срок службы для категории |
| `service_life_months` | integer | YES | — | Дефолтный срок службы в месяцах (используется как значение по умолчанию при создании ТМЦ, но для каждого конкретного ТМЦ можно задать свой срок службы) |
| `description` | text | YES | — | Описание категории |
| `is_active` | boolean | NO | `true` | Активна ли категория (можно скрыть неиспользуемые) |
| `created_at` | timestamptz | NO | `now()` | Дата создания записи |
| `updated_at` | timestamptz | NO | `now()` | Дата последнего обновления |
| `created_by` | uuid | YES | — | Кто создал категорию (FK → `profiles.id`) |

**Индексы:**
- `idx_inventory_categories_name` — уникальный индекс на `name`
- `idx_inventory_categories_prefix` — уникальный индекс на `prefix`
- `idx_inventory_categories_is_active` — индекс на `is_active` (для фильтрации активных)

**Ограничения:**
- `inventory_categories_name_key` — уникальность `name`
- `inventory_categories_prefix_key` — уникальность `prefix`

**RLS-политики:**
- Пользователи могут читать категории
- Администраторы могут создавать, обновлять и удалять категории

---

## 7. Таблица `inventory_inventory` (Акты инвентаризации)

**Описание:** Хранит информацию об актах инвентаризации ТМЦ на складе или объекте.

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор акта (PK) |
| `inventory_date` | date | NO | — | Дата проведения инвентаризации |
| `location_type` | text | NO | — | Тип места инвентаризации (`warehouse`, `object`) |
| `location_id` | uuid | YES | — | ID места инвентаризации (NULL для склада, иначе `objects.id`) |
| `status` | text | NO | `'in_progress'` | Статус инвентаризации (`in_progress`, `completed`, `cancelled`) |
| `conducted_by` | uuid | NO | — | Кто проводил инвентаризацию (FK → `profiles.id`) |
| `commission_members` | uuid[] | YES | — | Массив ID членов комиссии (FK → `employees.id`) |
| `pdf_url` | text | YES | — | URL сформированного акта в PDF (Supabase Storage) |
| `notes` | text | YES | — | Примечания к инвентаризации |
| `created_at` | timestamptz | NO | `now()` | Дата создания акта |
| `updated_at` | timestamptz | NO | `now()` | Дата последнего обновления |
| `completed_at` | timestamptz | YES | — | Дата завершения инвентаризации |

**Индексы:**
- `idx_inventory_inventory_location` — составной индекс на `location_type, location_id`
- `idx_inventory_inventory_status` — индекс на `status` (для фильтрации)
- `idx_inventory_inventory_inventory_date` — индекс на `inventory_date` (для сортировки)

**Ограничения:**
- `inventory_inventory_status_check` — проверка значения `status` (enum)
- `inventory_inventory_location_type_check` — проверка значения `location_type` (enum)

**RLS-политики:**
- Пользователи могут читать акты инвентаризации, к которым имеют доступ
- Администраторы могут создавать, обновлять и завершать акты
- Пользователи могут создавать акты для своих объектов

---

## 8. Таблица `inventory_inventory_items` (Позиции актов инвентаризации)

**Описание:** Хранит позиции актов инвентаризации. Каждая позиция соответствует одной единице ТМЦ с отметкой о наличии/отсутствии.

**Количество записей:** 0 (новая таблица)  
**RLS:** ✅ Включён (требуется настройка)

| Колонка | Тип | Nullable | По умолчанию | Описание |
|---------|-----|----------|--------------|----------|
| `id` | uuid | NO | `gen_random_uuid()` | Уникальный идентификатор позиции (PK) |
| `inventory_id` | uuid | NO | — | Ссылка на акт инвентаризации (FK → `inventory_inventory.id`) |
| `item_id` | uuid | YES | — | Ссылка на ТМЦ из учёта (FK → `inventory_items.id`, NULL если не найдено в учёте) |
| `name` | text | NO | — | Наименование ТМЦ (из учёта или введённое вручную) |
| `status` | text | NO | — | Статус при инвентаризации (`found`, `not_found`, `found_additional`) |
| `notes` | text | YES | — | Примечания к позиции |
| `created_at` | timestamptz | NO | `now()` | Дата создания записи |

**Индексы:**
- `idx_inventory_inventory_items_inventory_id` — индекс на `inventory_id` (для связи с актом)
- `idx_inventory_inventory_items_item_id` — индекс на `item_id` (для связи с ТМЦ)
- `idx_inventory_inventory_items_status` — индекс на `status` (для фильтрации расхождений)

**Ограничения:**
- `inventory_inventory_items_status_check` — проверка значения `status` (enum)

**RLS-политики:**
- Пользователи могут читать позиции актов, к которым имеют доступ
- Администраторы могут создавать, обновлять и удалять позиции
- Позиции создаются вместе с актом инвентаризации

---

## Примечания

### Триггеры
- `update_inventory_items_updated_at` — автоматическое обновление `updated_at` в `inventory_items`
- `update_inventory_receipts_totals` — автоматический пересчёт `total_amount` и `items_count` в `inventory_receipts` при изменении позиций

### Представления (Views)
- `v_inventory_items_with_location` — представление ТМЦ с информацией о местоположении (JOIN с `objects`, `employees`)
- `v_inventory_movements_history` — представление истории перемещений с расширенной информацией (JOIN с `inventory_items`, `objects`, `employees`)

### Функции PostgreSQL
- `get_inventory_responsible(location_type text, location_id uuid)` — определение ответственного лица по местоположению

---

**Последнее обновление:** 7 ноября 2025 года

