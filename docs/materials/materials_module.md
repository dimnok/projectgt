# Модуль Материалы (Materials)
**Дата актуализации:** 8 октября 2025 года (создано: полный аудит БД и кода)

---

## Важное замечание о структуре данных

> **Внимание:**
> - Модуль владеет **4 таблицами**: `materials`, `receipts`, `material_aliases`, `kit_components`
> - **Архитектура**: гибридная — хранение накладных + привязка к сметам через алиасы
> - **Критические зависимости**: 
>   - `estimates` (сметы) — для привязки материалов к каноническим позициям
>   - `contractors` (контрагенты) — для идентификации поставщиков
>   - `work_items` (позиции работ) — для отслеживания использования материалов
> - **Метод списания**: FIFO (First In, First Out) **строго в рамках договора**
> - **Особенность**: Представление `v_materials_with_usage` динамически вычисляет использование материалов

---

## Детальное описание модуля

Модуль **Материалы** — система учёта материалов на основе накладных с автоматическим списанием по методу FIFO (First In, First Out). 

### Зачем нужен модуль

Модуль решает задачу **сквозного учёта материалов от поставки до использования**:
- Импорт накладных из Excel/CSV
- Привязка материалов из накладных к сметным позициям (через алиасы)
- Отслеживание расхода материалов в режиме реального времени
- Расчёт остатков по методу FIFO с учётом договоров
- Контроль дублирования накладных (по SHA256-хешу файла)

### Ключевые функции

1. **Импорт накладных** — загрузка Excel/CSV, парсинг, сохранение в БД
2. **Маппинг материалов** — привязка названий из накладных к сметным позициям через алиасы
3. **Умный поиск** — нахождение похожих материалов с использованием trigram similarity (опечатки, разные варианты написания)
4. **FIFO-списание** — автоматический расчёт использования и остатков по принципу "первый пришёл — первый ушёл"
5. **Фильтрация** — по договорам, датам, привязке к смете
6. **Экспорт** — выгрузка данных в Excel

### Архитектурные особенности

- **FIFO строго по договору**: материалы списываются только из партий того же договора, к которому относится сметная позиция
- **Динамический расчёт**: использование и остатки вычисляются на лету через представление `v_materials_with_usage`
- **Нормализация данных**: автоматическая очистка пробелов, замена вариантов "×" на единый символ
- **Защита от дублей**: уникальный индекс по комбинации `receipt_id + name + unit + quantity + price`
- **Умный поиск**: использование pg_trgm для нахождения похожих материалов даже при опечатках

---

## Используемые таблицы и зависимости

### Основные таблицы модуля

1. **`materials`** — основная таблица материалов из накладных (1671 запись, из них 154 привязаны к смете)
2. **`receipts`** — реестр накладных (509 записей)
3. **`material_aliases`** — алиасы для маппинга материалов к сметам (24 записи)
4. **`kit_components`** — состав комплектов (BOM) для сметных позиций (0 записей)

### Связанные таблицы из других модулей

- **`estimates`** — сметы (используется для привязки материалов через алиасы)
- **`contracts`** — договоры (используется для фильтрации и FIFO в рамках договора)
- **`contractors`** — контрагенты/поставщики (опциональная связь для алиасов)
- **`work_items`** — позиции работ (используется для отслеживания расхода материалов)
- **`auth.users`** — пользователи (для отслеживания автора импорта)

---

## Структура и файлы модуля

### Presentation/UI (экраны, виджеты, провайдеры)

**Экраны:**
- `material_screen.dart` — главный экран с таблицей материалов
- `materials_mapping_screen.dart` — экран привязки материалов к сметным позициям

**Виджеты:**
- `materials_link_button.dart` — кнопка для перехода к модулю материалов
- `materials_import_action.dart` — действие импорта накладных
- `materials_export_action.dart` — действие экспорта в Excel
- `materials_mapping_action.dart` — действие маппинга материалов
- `materials_search.dart` — виджет поиска материалов
- `materials_date_filter.dart` — фильтр по датам
- `contracts_filter_chips.dart` — фильтр по договорам (чипсы)

**Провайдеры (Riverpod):**
- `materials_providers.dart` — провайдеры для загрузки и фильтрации материалов
- `materials_pager.dart` — пагинация таблицы материалов
- `materials_mapping_providers.dart` — провайдеры для экрана маппинга

### Domain (сущности, use cases)

**Отсутствуют** — модуль использует модели данных напрямую без промежуточных use cases.

### Data (модели, репозитории, data sources)

**Модели:**
- `material_item.dart` — модель материала (Freezed + json_serializable)

**Репозитории:**
- `materials_repository.dart` — работа с таблицами `materials`, `receipts`, `material_aliases`
- `materials_import_repository.dart` — импорт накладных (парсинг, сохранение)

**Парсеры:**
- `receipts_remote_parser.dart` — парсинг Excel/CSV накладных

---

## Дерево структуры модуля

```
lib/features/materials/
├── presentation/
│   ├── screens/
│   │   ├── material_screen.dart
│   │   └── materials_mapping_screen.dart
│   ├── widgets/
│   │   ├── materials_link_button.dart
│   │   ├── materials_import_action.dart
│   │   ├── materials_export_action.dart
│   │   ├── materials_mapping_action.dart
│   │   ├── materials_search.dart
│   │   ├── materials_date_filter.dart
│   │   └── contracts_filter_chips.dart
│   └── providers/
│       ├── materials_providers.dart
│       ├── materials_pager.dart
│       └── materials_mapping_providers.dart
└── data/
    ├── models/
    │   └── material_item.dart
    ├── repositories/
    │   ├── materials_repository.dart
    │   └── materials_import_repository.dart
    └── parsers/
        └── receipts_remote_parser.dart
```

---

## База данных и RLS-политики

### 1. Таблица `materials` (Материалы)

**Количество записей:** 1671 (154 привязаны к смете, 1517 не привязаны)  
**RLS:** ✅ Включён

| Колонка | Тип | Описание | Обязательность | Значение по умолчанию |
|---------|-----|----------|----------------|----------------------|
| `id` | uuid | Уникальный идентификатор материала | Обязательно | `gen_random_uuid()` |
| `name` | text | Название материала (нормализовано триггером) | Обязательно | — |
| `unit` | text | Единица измерения (нормализовано триггером) | Опционально | — |
| `quantity` | numeric | Количество в накладной | Опционально | — |
| `price` | numeric | Цена за единицу | Опционально | — |
| `total` | numeric | Итоговая стоимость (вычисляемая колонка: `quantity * price`) | **Generated** | `quantity * price` |
| `receipt_number` | text | Номер накладной (нормализовано триггером) | Опционально | — |
| `receipt_date` | date | Дата накладной | Опционально | — |
| `used` | numeric | Использовано (вычисляется через `v_materials_with_usage`) | Опционально | — |
| `file_url` | text | URL файла накладной в Storage | Опционально | — |
| `created_at` | timestamptz | Дата создания записи | Обязательно | `now()` |
| `created_by` | uuid | FK к `auth.users.id` (автор импорта) | Опционально | — |
| `remaining` | numeric | Остаток (вычисляемая колонка: `quantity - used`) | **Generated** | `quantity - used` |
| `receipt_id` | uuid | FK к `receipts.id` | Опционально | — |
| `contract_number` | text | Номер договора (нормализовано триггером) | Опционально | — |

**Индексы:**
- `materials_pkey` — PRIMARY KEY (id)
- `idx_materials_name_lower` — btree (lower(name)) — для поиска без учёта регистра
- `idx_materials_name_trgm` — GIN trigram (name) — для умного поиска по схожести
- `idx_materials_receipt_id` — btree (receipt_id) — для быстрой связи с накладными
- `idx_materials_receipt_number_date` — btree (receipt_number, receipt_date)
- `uq_materials_receipt_row` — UNIQUE (receipt_id, lower(name), unit, quantity, price) — защита от дублей

**Foreign Keys:**
- `materials_receipt_id_fkey`: `receipt_id` → `receipts.id` (NO ACTION / NO ACTION)
- `materials_created_by_fkey`: `created_by` → `auth.users.id`

**Триггеры:**
1. `trg_materials_norm_biur` — BEFORE INSERT/UPDATE — вызывает `trg_materials_normalize()` для нормализации `name`, `unit`, `receipt_number`, `contract_number`
2. `materials_normalize_receipt_number` — BEFORE INSERT/UPDATE — вызывает `trg_materials_normalize_receipt_number()` для нормализации номера накладной

---

### 2. Таблица `receipts` (Накладные)

**Количество записей:** 509  
**RLS:** ✅ Включён

| Колонка | Тип | Описание | Обязательность | Значение по умолчанию |
|---------|-----|----------|----------------|----------------------|
| `id` | uuid | Уникальный идентификатор накладной | Обязательно | `gen_random_uuid()` |
| `receipt_number` | text | Номер накладной | Обязательно | — |
| `receipt_date` | date | Дата накладной | Обязательно | — |
| `file_sha256` | text | SHA256-хеш файла для защиты от дублей | Опционально | — |
| `created_at` | timestamptz | Дата создания записи | Обязательно | `now()` |

**Индексы:**
- `receipts_pkey` — PRIMARY KEY (id)
- `receipts_receipt_number_receipt_date_key` — UNIQUE (receipt_number, receipt_date)

**Foreign Keys:** Нет исходящих FK. Есть входящие:
- `materials.receipt_id` → `receipts.id`

---

### 3. Таблица `material_aliases` (Алиасы материалов)

**Количество записей:** 24  
**RLS:** ✅ Включён

| Колонка | Тип | Описание | Обязательность | Значение по умолчанию |
|---------|-----|----------|----------------|----------------------|
| `id` | uuid | Уникальный идентификатор алиаса | Обязательно | `gen_random_uuid()` |
| `created_at` | timestamptz | Дата создания | Обязательно | `now()` |
| `updated_at` | timestamptz | Дата обновления | Обязательно | `now()` |
| `estimate_id` | uuid | FK к `estimates.id` (сметная позиция) | Обязательно | — |
| `supplier_id` | uuid | FK к `contractors.id` (поставщик) | Опционально | — |
| `alias_raw` | text | Оригинальное название из накладной | Обязательно | — |
| `normalized_alias` | text | Нормализованное название (нижний регистр) | **Generated** | `lower(alias_raw)` |
| `uom_raw` | text | Единица измерения как в накладной | Опционально | — |
| `multiplier_to_estimate` | numeric | Коэффициент перевода в единицу из сметы | Обязательно | `1` |
| `is_active` | boolean | Флаг активности алиаса | Обязательно | `true` |
| `metadata` | jsonb | Дополнительные данные | Обязательно | `{}` |

**Комментарий:** Сопоставление названий материалов из накладных к сметным позициям (каноническим материалам).

**Индексы:**
- `material_aliases_pkey` — PRIMARY KEY (id)
- `idx_material_aliases_estimate` — btree (estimate_id)
- `idx_material_aliases_normalized` — btree (normalized_alias)
- `idx_material_aliases_supplier` — btree (supplier_id)
- `ux_material_alias_unique` — UNIQUE (estimate_id, normalized_alias, supplier_id)

**Foreign Keys:**
- `material_aliases_estimate_id_fkey`: `estimate_id` → `estimates.id` (CASCADE)
- `material_aliases_supplier_id_fkey`: `supplier_id` → `contractors.id` (SET NULL)

---

### 4. Таблица `kit_components` (Состав комплектов)

**Количество записей:** 0  
**RLS:** ✅ Включён

| Колонка | Тип | Описание | Обязательность | Значение по умолчанию |
|---------|-----|----------|----------------|----------------------|
| `id` | uuid | Уникальный идентификатор компонента | Обязательно | `gen_random_uuid()` |
| `created_at` | timestamptz | Дата создания | Обязательно | `now()` |
| `updated_at` | timestamptz | Дата обновления | Обязательно | `now()` |
| `parent_estimate_id` | uuid | FK к `estimates.id` (родительский комплект) | Обязательно | — |
| `component_estimate_id` | uuid | FK к `estimates.id` (компонент комплекта) | Обязательно | — |
| `qty_per_kit` | numeric | Количество компонента на один комплект | Обязательно | — |
| `uom_component` | text | Единица измерения компонента | Опционально | — |
| `notes` | text | Примечания | Опционально | — |

**Комментарий:** Состав комплектов (BOM) для сметных позиций.

**Индексы:**
- `kit_components_pkey` — PRIMARY KEY (id)
- `idx_kit_components_parent` — btree (parent_estimate_id)
- `idx_kit_components_component` — btree (component_estimate_id)
- `ux_kit_components_pair` — UNIQUE (parent_estimate_id, component_estimate_id)

**Foreign Keys:**
- `kit_components_parent_estimate_id_fkey`: `parent_estimate_id` → `estimates.id` (CASCADE)
- `kit_components_component_estimate_id_fkey`: `component_estimate_id` → `estimates.id` (CASCADE)

---

### 5. Представление `v_materials_with_usage` (Материалы с расчётом использования)

**Описание:** Представление материалов с расчётом использования по методу FIFO. **ВАЖНО:** FIFO применяется СТРОГО в рамках договора — материалы списываются только из партий того же договора, к которому относится сметная позиция.

**Структура:**
- `id` — ID материала
- `name` — Название
- `unit` — Единица измерения
- `quantity` — Количество
- `price` — Цена
- `total` — Сумма
- `receipt_number` — Номер накладной
- `receipt_date` — Дата накладной
- `file_url` — URL файла
- `contract_number` — Номер договора
- `used` — Использовано (FIFO)
- `remaining` — Остаток (FIFO, с особой логикой для последней партии)
- `estimate_id` — ID сметной позиции (привязка через алиасы)

**Логика FIFO:**
1. Нормализация названий материалов и алиасов (очистка пробелов, замена "Мм" → "mm")
2. Привязка материала к `estimate_id` через `material_aliases` с проверкой совпадения `contract_number`
3. Расчёт использования по estimate: сумма `work_items.quantity` для каждого `estimate_id`
4. Распределение использования по партиям в порядке `receipt_date` (FIFO) **в рамках одного estimate_id + contract_number**
5. Вычисление `remaining` с особой логикой для последней партии в очереди FIFO

---

### Связи между таблицами (ASCII-диаграмма)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Модуль Материалы                            │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│    receipts     │ (509 записей)
│─────────────────│
│ id (PK)         │
│ receipt_number  │
│ receipt_date    │
│ file_sha256     │
│ created_at      │
└────────┬────────┘
         │
         │ 1:N
         ↓
┌─────────────────┐
│   materials     │ (1671 запись, 154 привязаны)
│─────────────────│
│ id (PK)         │◄───────────────────┐
│ name            │                    │
│ unit            │                    │
│ quantity        │                    │
│ price           │                    │
│ total (CALC)    │                    │
│ receipt_id (FK) │                    │
│ receipt_number  │                    │
│ receipt_date    │                    │
│ contract_number │                    │
│ used (CALC)     │                    │  Динамическая привязка
│ remaining(CALC) │                    │  через алиасы
│ file_url        │                    │  (v_materials_with_usage)
│ created_by (FK) │                    │
│ created_at      │                    │
└─────────────────┘                    │
                                        │
                                        │
┌─────────────────────┐                │
│  material_aliases   │ (24 записи)    │
│─────────────────────│                │
│ id (PK)             │                │
│ estimate_id (FK)    │────────┐       │
│ supplier_id (FK)    │        │       │
│ alias_raw           │        │       │
│ normalized_alias    │        │       │
│ multiplier_to_...   │        │       │
│ is_active           │        │       │
└─────────────────────┘        │       │
                               │       │
                               ↓       │
                         ┌──────────┐  │
                         │estimates │  │  Связь через
                         │──────────│  │  normalized name
                         │ id (PK)  │  │  matching
                         │ name     │──┘
                         │ ...      │
                         └────┬─────┘
                              │
                              │ 1:N (contract_id)
                              ↓
                         ┌──────────┐
                         │contracts │
                         │──────────│
                         │ id (PK)  │
                         │ number   │
                         │ ...      │
                         └──────────┘

┌─────────────────────┐
│  kit_components     │ (0 записей)
│─────────────────────│
│ id (PK)             │
│ parent_estimate_id  │────────┐
│ component_est_id    │────┐   │
│ qty_per_kit         │    │   │
└─────────────────────┘    │   │
                           │   │
                           ↓   ↓
                      ┌──────────┐
                      │estimates │
                      │──────────│
                      │ id (PK)  │
                      └──────────┘

Использование материалов отслеживается через:

┌──────────┐
│work_items│ (позиции работ)
│──────────│
│ id       │
│ estimate_id (FK) ├──→ Суммируется для расчёта `used` в FIFO
│ quantity │
└──────────┘
```

---

## Edge Functions

### 1. `excel_parse` (v4)

**Назначение:** Парсинг Excel/CSV файлов накладных с извлечением данных.

**Входные параметры:**
- `file` — Base64-encoded файл
- `mapping` — Конфигурация парсинга (колонки, ячейки глобальных параметров)

**Возвращает:**
- `sheet` — Имя листа
- `receiptNumber` — Номер накладной
- `receiptDate` — Дата накладной (ISO)
- `contractNumber` — Номер договора (извлечён корректно с 8 октября 2025)
- `items[]` — Массив материалов

**Особенности:**
- Поддерживает Excel (.xlsx, .xls) и CSV
- Автоматическое определение формата дат (Excel date code, dd.MM.yyyy)
- Правильная обработка номера договора: "№244 СУБ-07 от 17.05.2024" → "244 СУБ-07"

---

### 2. `receipts_import` (v4)

**Назначение:** Импорт массива накладных в БД с проверкой дублей.

**Входные параметры:**
- `files[]` — Массив объектов с данными накладных

**Возвращает:**
- `insertedRows` — Количество вставленных материалов
- `importedReceipts` — Количество новых накладных
- `skippedReceipts` — Количество пропущенных (дубли)
- `perFile[]` — Детали по каждой накладной

**Особенности:**
- Проверка дублей по `(номер + договор + дата)` с 8 октября 2025
- Автоматическое создание/обновление записей в `receipts`
- Пакетная вставка материалов в `materials`
- Обновление `contract_number` для старых записей

---

### 3. `receipts-attach-fileurl` (v1)

**Назначение:** Привязка URL файла из Storage к материалам накладной.

**Входные параметры:**
- `receiptNumber` — Номер накладной
- `receiptDate` — Дата накладной
- `contractNumber` — Номер договора (опционально)
- `storagePath` — Путь к файлу в Storage

**Возвращает:**
- `ok: true` — Успех

**Особенности:**
- Использует Service Role Key для обхода RLS
- Обновляет `file_url` для всех материалов совпадающей накладной

---

### 4. `xls_to_xlsx` (v5)

**Назначение:** Конвертация старого формата .xls в современный .xlsx.

**Входные параметры:**
- `xls` — Base64-encoded .xls файл (или binary через multipart)

**Возвращает:**
- `xlsx` — Base64-encoded .xlsx файл

**Особенности:**
- Убирает cell styles для предотвращения ошибок numFmtId
- Поддерживает JSON и multipart/form-data

---

## Функции PostgreSQL

### 1. `normalize_whitespace(s text)` → text

**Описание:** Нормализует пробелы в строке: удаляет лишние, заменяет tab/newline на пробелы, удаляет неразрывные пробелы.

**Использование:** Вызывается триггерами для нормализации полей `name`, `unit`, `receipt_number`, `contract_number` в таблице `materials`.

---

### 2. `normalize_receipt_number(input text)` → text

**Описание:** Нормализует номер накладной: оставляет только цифры.

**Использование:** Вызывается триггером перед вставкой/обновлением для поля `receipt_number` в `materials`.

---

### 3. `normalize_material_name(input_text text)` → text

**Описание:** Нормализует название материала: приводит к нижнему регистру и заменяет все варианты "умножения" (х/x/×/⨯/·/*) на единый символ 'x'.

**Использование:** Используется в функции `search_materials_by_similarity()` для нормализации запросов и названий при поиске.

---

### 4. `extract_contract_number(input_text text)` → text

**Описание:** Извлекает номер договора из строки вида "№244 СУБ-07 от 17.05.2024".

**Примеры:**
- "№244 СУБ-07 от 17.05.2024" → "244 СУБ-07"
- "№173-суб-07 от 25.05.2024" → "173-суб-07"
- "244 СУБ-07" → "244 СУБ-07"
- "№244" → "244"

**Использование:** Вызывается триггером `trg_materials_normalize()` для поля `contract_number` в `materials`.

---

### 5. `search_materials_by_similarity(search_query text, contract_num text)` → TABLE

**Описание:** Умный поиск материалов с ранжированием по схожести названия. Использует trigram similarity для нахождения похожих материалов даже при опечатках. Автоматически нормализует разные варианты написания (х/x/×). Сортирует результаты по релевантности: сначала самые похожие.

**Возвращает:**
- `id` — UUID материала
- `name` — Название
- `unit` — Единица измерения
- `receipt_number` — Номер накладной
- `similarity_score` — Оценка схожести (0-1, где 1 = полное совпадение)

**Логика:**
1. Нормализация поискового запроса через `normalize_material_name()`
2. Поиск по `v_materials_with_usage` с условиями:
   - `contract_number = contract_num`
   - `estimate_id IS NULL` (непривязанные материалы)
   - Trigram similarity > 0.1 ИЛИ LIKE-совпадение
3. Расчёт `similarity_score` с бонусами:
   - Trigram similarity (базовая оценка)
   - +0.9 — если название начинается с запроса
   - +0.8 — если запрос находится в начале слова
4. Сортировка по `similarity_score DESC`, затем по `name ASC`
5. LIMIT 500

**SQL (сокращённо):**
```sql
CREATE OR REPLACE FUNCTION search_materials_by_similarity(
  search_query text,
  contract_num text
)
RETURNS TABLE (
  id uuid,
  name text,
  unit text,
  receipt_number text,
  similarity_score real
)
LANGUAGE sql
STABLE
AS $$
  WITH normalized_query AS (
    SELECT normalize_material_name(search_query) AS nq
  )
  SELECT 
    v.id,
    v.name,
    v.unit,
    v.receipt_number,
    GREATEST(
      similarity(normalize_material_name(v.name), nq),
      CASE WHEN normalize_material_name(v.name) LIKE nq || '%' THEN 0.9 ELSE 0 END,
      CASE WHEN normalize_material_name(v.name) LIKE '% ' || nq || '%' THEN 0.8 ELSE 0 END
    ) AS similarity_score
  FROM v_materials_with_usage v
  WHERE v.contract_number = contract_num
    AND v.estimate_id IS NULL
    AND (
      similarity(normalize_material_name(v.name), nq) > 0.1
      OR normalize_material_name(v.name) LIKE '%' || nq || '%'
    )
  ORDER BY similarity_score DESC, v.name ASC
  LIMIT 500;
$$;
```

---

### 6. `get_unlinked_materials_by_contract(contract_num text)` → TABLE

**Описание:** Возвращает все непривязанные материалы (estimate_id = NULL) для указанного договора без лимита записей.

**Возвращает:**
- `id` — UUID материала
- `name` — Название
- `unit` — Единица измерения
- `receipt_number` — Номер накладной
- `receipt_date` — Дата накладной

**Использование:** Экран маппинга материалов (`materials_mapping_screen.dart`) для отображения списка непривязанных материалов.

---

### 7. `v_materials_usage_period(in_date_start date, in_date_end date, in_contract_number text)` → TABLE

**Описание:** Функция расчёта использования материалов за период по методу FIFO. **ВАЖНО:** FIFO применяется СТРОГО в рамках договора — материалы списываются только из партий того же договора, к которому относится сметная позиция.

**Возвращает:**
- `material_id` — ID материала
- `name` — Название
- `unit` — Единица измерения
- `receipt_number` — Номер накладной
- `receipt_date` — Дата накладной
- `quantity` — Количество в партии
- `price` — Цена
- `total` — Сумма
- `used_period` — Использовано **за указанный период** (FIFO)
- `remaining_end` — Остаток на конец периода (FIFO)
- `used_total` — Использовано с начала строительства (FIFO)
- `estimate_id` — ID сметной позиции
- `estimate_number` — Номер сметы
- `estimate_name` — Название сметной позиции
- `file_url` — URL файла накладной

**Логика:**
1. Фильтрация материалов по `in_contract_number` (опционально)
2. Привязка к `estimate_id` через алиасы с проверкой совпадения `contract_number`
3. Расчёт использования на конец периода (`wi_sum_end`) и на начало периода (`wi_sum_start`) через агрегацию `work_items.quantity`
4. FIFO-распределение: расчёт `prev_cum` (накопительная сумма предыдущих партий) **в рамках estimate_id + contract_number**
5. Вычисление:
   - `used_period` = (использовано к концу) - (использовано к началу)
   - `remaining_end` = `quantity` - (использовано к концу)
   - `used_total` = использовано с начала по FIFO

**Особенность:** PARTITION BY изменён с `estimate_id` на `estimate_id, contract_number` для строгого FIFO по договорам.

---

## Триггеры

### 1. `trg_materials_norm_biur` → `trg_materials_normalize()`

**Событие:** BEFORE INSERT OR UPDATE на `materials`  
**Уровень:** ROW

**Функция триггера:**
```sql
CREATE OR REPLACE FUNCTION public.trg_materials_normalize()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.name            := public.normalize_whitespace(NEW.name);
  NEW.unit            := public.normalize_whitespace(NEW.unit);
  NEW.receipt_number  := public.normalize_whitespace(NEW.receipt_number);
  
  -- ИСПРАВЛЕНО (8 октября 2025): Используем extract_contract_number
  NEW.contract_number := public.extract_contract_number(
    public.normalize_whitespace(NEW.contract_number)
  );
  
  RETURN NEW;
END;
$function$
```

**Описание:** Нормализует пробелы в ключевых полях перед сохранением. Извлекает правильный номер договора из строк вида "№244 СУБ-07 от 17.05.2024".

---

### 2. `materials_normalize_receipt_number` → `trg_materials_normalize_receipt_number()`

**Событие:** BEFORE INSERT OR UPDATE на `materials`  
**Уровень:** ROW

**Функция триггера:**
```sql
CREATE OR REPLACE FUNCTION public.trg_materials_normalize_receipt_number()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
begin
  if new.receipt_number is not null then
    new.receipt_number := public.normalize_receipt_number(new.receipt_number);
  end if;
  return new;
end;
$function$
```

**Описание:** Нормализует номер накладной (оставляет только цифры) перед сохранением.

---

## RLS-политики

### Таблица `materials`

**RLS:** ✅ Включён

| Политика | Тип | Роли | Условие |
|----------|-----|------|---------|
| `materials_read` | SELECT | authenticated | `true` (все могут читать) |
| `materials_insert_authenticated` | INSERT | authenticated | `true` (все могут вставлять) |
| `materials_update_own` | UPDATE | authenticated | `auth.uid() = created_by` (изменять только свои записи) |
| `materials_delete_own` | DELETE | authenticated | `auth.uid() = created_by` (удалять только свои записи) |

---

### Таблица `receipts`

**RLS:** ✅ Включён

| Политика | Тип | Роли | Условие |
|----------|-----|------|---------|
| `receipts_select` | SELECT | authenticated | `true` (все могут читать) |
| `receipts_insert` | INSERT | authenticated | `true` (все могут вставлять) |

**Замечание:** Нет политик UPDATE/DELETE — накладные неизменяемы после создания.

---

### Таблица `material_aliases`

**RLS:** ✅ Включён

| Политика | Тип | Роли | Условие |
|----------|-----|------|---------|
| `material_aliases_read` | SELECT | authenticated | `true` (все могут читать) |
| `material_aliases_insert` | INSERT | authenticated | `true` (все могут создавать) |
| `material_aliases_update` | UPDATE | authenticated | `true` (все могут изменять) |
| `material_aliases_delete` | DELETE | authenticated | `true` (все могут удалять) |

**Замечание:** Полный доступ для всех аутентифицированных пользователей.

---

### Таблица `kit_components`

**RLS:** ✅ Включён

| Политика | Тип | Роли | Условие |
|----------|-----|------|---------|
| `kit_components_read` | SELECT | authenticated | `true` (все могут читать) |
| `kit_components_insert` | INSERT | authenticated | `true` (все могут создавать) |
| `kit_components_update` | UPDATE | authenticated | `true` (все могут изменять) |
| `kit_components_delete` | DELETE | authenticated | `true` (все могут удалять) |

**Замечание:** Полный доступ для всех аутентифицированных пользователей.

---

## Бизнес-логика и ключевые особенности

### 1. Процесс импорта накладных

**Шаги:**
1. Пользователь выбирает файл Excel/CSV через `FilePicker`
2. `receipts_remote_parser.dart` парсит файл:
   - Определяет формат (столбцы: название, ед. изм., количество, цена)
   - Извлекает номер накладной и дату
   - Создаёт список `MaterialItem`
3. Вычисление SHA256-хеша файла для защиты от дублей
4. `materials_import_repository.dart` сохраняет данные:
   - Создаёт запись в `receipts` (или находит существующую по `receipt_number + receipt_date`)
   - Вставляет материалы в `materials` с привязкой к `receipt_id`
   - Триггеры автоматически нормализуют данные
5. Загрузка файла в Supabase Storage (опционально)
6. Вызов функции `attach_material_file_url()` для привязки URL к материалам

**Защита от дублей:**
- Уникальный индекс `receipts_receipt_number_receipt_date_key` на таблице `receipts`
- Уникальный индекс `uq_materials_receipt_row` на комбинацию `receipt_id + name + unit + quantity + price`

---

### 2. Маппинг материалов к сметным позициям

**Проблема:** Названия материалов в накладных часто отличаются от сметных позиций:
- "Профиль направляющий ПН 50х40" vs "Профиль ПН-2 (50/40)"
- "кабель ВВГ 3х1,5" vs "КАБЕЛЬ ВВГ 3×1.5"

**Решение через алиасы:**
1. Пользователь открывает экран `materials_mapping_screen.dart`
2. Выбирает договор (фильтр)
3. Видит список непривязанных материалов из функции `get_unlinked_materials_by_contract()`
4. Для каждого материала:
   - Вводит поисковый запрос
   - Функция `search_materials_by_similarity()` находит похожие сметные позиции с оценкой схожести
   - Пользователь выбирает соответствие
5. **НОВОЕ (9 октября 2025):** Диалог ввода коэффициента конверсии:
   - Если единицы измерения разные (шт vs м, упак vs шт), пользователь указывает коэффициент
   - Примеры: 1 шт = 2 м → коэффициент 2.0; 1 упак = 100 шт → коэффициент 100.0
   - Валидация: коэффициент > 0 и <= 10000
6. Создаётся запись в `material_aliases`:
   - `estimate_id` — выбранная сметная позиция
   - `alias_raw` — название из накладной
   - `normalized_alias` — автоматически (generated)
   - `multiplier_to_estimate` — коэффициент конверсии единиц
   - `supplier_id` — опционально
7. При следующей загрузке накладной с таким же названием привязка происходит автоматически

**Умный поиск:**
- Использует pg_trgm extension для fuzzy matching
- Нормализует варианты написания (х/x/×)
- Ранжирует результаты по релевантности (similarity_score)
- Учитывает опечатки и частичные совпадения

**Конверсия единиц измерения (9 октября 2025):**
- FIFO-списание теперь учитывает `multiplier_to_estimate`
- Формула: `Списание = Использовано_из_работ × multiplier`
- Пример: Использовано 10 шт × 2.0 = Списано 20 м из накладной

---

### 3. FIFO-списание материалов

**Принцип:** Материалы расходуются в порядке поступления (First In, First Out).

**Критическое изменение (6 октября 2025):** FIFO теперь работает **строго в рамках договора**. Ранее материалы могли списываться из партий других договоров, что приводило к ошибкам учёта.

**Пример:**
```
Договор A:
  Партия 1: 100 м кабеля (01.01.2025)
  Партия 2: 50 м кабеля (15.01.2025)
  Использовано: 120 м

FIFO-распределение:
  Партия 1: использовано 100 м, остаток 0 м
  Партия 2: использовано 20 м, остаток 30 м

Договор B:
  Партия 3: 200 м кабеля (10.01.2025)
  
  НЕ БУДЕТ использоваться для договора A, 
  даже если дата раньше партии 2!
```

**Реализация в БД:**
- Представление `v_materials_with_usage`:
  - CTE `material_estimate`: привязка к `estimate_id` только из того же договора
  - CTE `me_fifo`: `PARTITION BY estimate_id, contract_number` (ранее было только `estimate_id`)
  - Вычисление `prev_cum_qty` — накопительная сумма предыдущих партий в очереди FIFO
  - Вычисление `used` и `remaining` с учётом FIFO

---

### 4. Управление состоянием (Riverpod)

**Провайдеры:**

1. **`materials_providers.dart`**:
   - `materialsStreamProvider` — стрим материалов из `v_materials_with_usage`
   - Фильтрация по договору, датам, привязке к смете
   - Поиск по названию
   - Сортировка

2. **`materials_pager.dart`**:
   - `MaterialsPager` — StateNotifier для пагинации
   - Управление страницами, лимитами, загрузкой

3. **`materials_mapping_providers.dart`**:
   - Провайдеры для экрана маппинга
   - Список непривязанных материалов
   - Поиск сметных позиций через `search_materials_by_similarity()`
   - Создание алиасов

**Особенности:**
- Использование `.family` для параметризованных провайдеров
- Автоматическое обновление через Supabase Realtime (опционально)
- Кэширование через Riverpod

---

### 5. Адаптивность UI

**Экраны:**
- `material_screen.dart`:
  - Desktop: таблица с фильтрами, поиском, экспортом/импортом
  - Tablet/Mobile: упрощённый список с drawer для фильтров

**Виджеты:**
- Используют `LayoutBuilder` для определения размера экрана
- Адаптивные кнопки (иконка + текст на desktop, только иконка на mobile)
- Responsive таблицы (PlutoGrid с настройкой ширины колонок)

---

## Связи и интеграции

### Интеграция с другими модулями

1. **Модуль Сметы (Estimates)**:
   - Привязка материалов к сметным позициям через `material_aliases`
   - Отслеживание расхода материалов через `work_items`

2. **Модуль Договоры (Contracts)**:
   - Фильтрация материалов по договорам
   - Ограничение FIFO-списания рамками договора

3. **Модуль Контрагенты (Contractors)**:
   - Идентификация поставщиков через `material_aliases.supplier_id`

4. **Модуль Работы (Works)**:
   - Связь через `work_items` для отслеживания использования материалов

---

### Технические зависимости (из pubspec.yaml)

**Основные:**
- `supabase_flutter` — клиент Supabase
- `riverpod` / `flutter_riverpod` — управление состоянием
- `freezed` / `freezed_annotation` — генерация неизменяемых классов
- `json_annotation` / `json_serializable` — сериализация JSON

**UI:**
- `pluto_grid` — таблицы
- `file_picker` — выбор файлов
- `excel` — парсинг Excel
- `csv` — парсинг CSV

**Утилиты:**
- `crypto` — вычисление SHA256-хешей
- `intl` — форматирование дат и чисел

---

### RLS и безопасность

**Текущее состояние:**

| Таблица | RLS | Статус |
|---------|-----|--------|
| `materials` | ✅ | ✅ Корректно (8 октября 2025: исправлены политики) |
| `receipts` | ✅ | ✅ Корректно |
| `material_aliases` | ✅ | ✅ Корректно |
| `kit_components` | ✅ | ✅ Корректно |

**Политики `materials` (обновлено 8 октября 2025):**
- SELECT — все аутентифицированные пользователи могут читать
- INSERT — все аутентифицированные пользователи могут создавать
- UPDATE — пользователи могут изменять только свои материалы (`created_by = auth.uid()`)
- DELETE — пользователи могут удалять только свои материалы (`created_by = auth.uid()`)

**Рекомендации для будущих улучшений:**

1. **Все таблицы**:
   - Рассмотреть внедрение ролевой модели (admin, manager, user)
   - Ограничить удаление материалов только для администраторов
   - Добавить аудит изменений (история операций)

---

## Текущие ограничения и планы развития

### Реализованные функции ✅

- ✅ Импорт накладных из Excel/CSV
- ✅ Парсинг различных форматов накладных
- ✅ Защита от дублирования накладных (SHA256)
- ✅ Маппинг материалов к сметным позициям через алиасы
- ✅ Умный поиск с trigram similarity
- ✅ FIFO-списание в рамках договора
- ✅ Фильтрация по договорам, датам, привязке
- ✅ Экспорт в Excel
- ✅ Адаптивный UI (desktop/tablet/mobile)
- ✅ Нормализация данных (пробелы, регистр, символы)

---

### Критические проблемы

**🟡 Средний приоритет:**
1. **Отсутствие валидации данных при импорте** — возможна вставка некорректных данных (отрицательные количества, NULL в критических полях)

**🟢 Низкий приоритет:**
1. **Таблица `kit_components` не используется** — 0 записей, функционал не реализован
2. **Отсутствие истории изменений** — нет аудита изменений в `materials` и `material_aliases`
3. **Нет механизма отката маппинга** — после привязки алиаса нельзя вернуть материал в статус "непривязанный"

---

### Планируемые улучшения 🔄

**Функциональные:**
- 🔄 Автоматический маппинг на основе ML (обучение на существующих алиасах)
- 🔄 Массовый маппинг материалов (выбрать несколько, привязать к одной позиции)
- 🔄 История изменений материалов (audit log)
- 🔄 Механизм отката маппинга (удаление/деактивация алиасов)
- 🔄 Работа с комплектами (BOM) — заполнение `kit_components`
- 🔄 Уведомления о низких остатках материалов
- 🔄 Прогнозирование расхода материалов

**UX:**
- 🔄 Drag & drop для импорта накладных
- 🔄 Предпросмотр накладной перед импортом
- 🔄 Подсказки при маппинге (показывать историю привязок пользователя)
- 🔄 Визуализация FIFO-списания (график использования партий)

**Безопасность:**
- 🔄 Ролевая модель доступа (admin, manager, user)
- 🔄 Ограничение удаления материалов
- 🔄 Аудит всех операций (кто, когда, что изменил)

---

### Технические улучшения

**Тесты:**
- 🔄 Юнит-тесты для парсеров накладных
- 🔄 Интеграционные тесты для FIFO-логики
- 🔄 E2E-тесты для процесса маппинга

**Производительность:**
- 🔄 Кэширование результатов `v_materials_with_usage` (материализованное представление)
- 🔄 Индексирование полей для быстрой фильтрации
- 🔄 Пагинация для больших наборов данных (уже частично реализовано)

**Код:**
- 🔄 Рефакторинг провайдеров (упростить, уменьшить дублирование)
- 🔄 Выделение use cases в слой Domain
- 🔄 Документирование всех функций и классов

---

## Примечания для разработчиков

### Общие примечания

- **FIFO-логика изменена 6 октября 2025**: при работе с материалами учитывайте, что списание происходит **строго в рамках договора**
- **Представление `v_materials_with_usage` динамическое**: не сохраняет данные, вычисляет на лету. Для больших объёмов данных рассмотрите материализованное представление
- **Триггеры автоматически нормализуют данные**: не нужно вызывать `normalize_whitespace()` вручную перед вставкой
- **Умный поиск требует pg_trgm extension**: убедитесь, что расширение включено в БД

### Специфичные для модуля

1. **При импорте накладных**:
   - Всегда вычисляйте SHA256-хеш для защиты от дублей
   - Проверяйте формат файла (поддержка Excel и CSV)
   - Обрабатывайте ошибки парсинга (некорректные данные, пустые ячейки)

2. **При работе с алиасами**:
   - Используйте функцию `search_materials_by_similarity()` для поиска похожих сметных позиций
   - Учитывайте `multiplier_to_estimate` для конвертации единиц измерения
   - Проверяйте совпадение `contract_number` при привязке

3. **При расчёте остатков**:
   - Используйте `v_materials_with_usage` для актуальных данных
   - Не полагайтесь на колонку `used` в таблице `materials` — она вычисляется динамически
   - Для отчётов за период используйте функцию `v_materials_usage_period()`

4. **При разработке UI**:
   - PlutoGrid требует явного указания ширины колонок для адаптивности
   - Используйте единые форматтеры из `lib/core/utils/formatters.dart`
   - Кэшируйте зависимости от контекста перед `await` (см. правила Flutter)

---

**Последняя актуализация:** 9 октября 2025 года

**Ключевые обновления:**

**9 октября 2025:**
- **Детальный аудит всех Edge Functions:** 4 функции (excel_parse, receipts_import, receipts-attach-fileurl, xls_to_xlsx)
- **Удаление устаревших функций БД:**
  - Удалена старая перегрузка `v_materials_usage_period(text, date, date)` с некорректным FIFO
  - Удалена дублирующая функция `attach_material_file_url` (заменена Edge Function)
- **Добавлены комментарии к функциям БД** для улучшения документации
- **Обновлена структура документации:** добавлен раздел Edge Functions

**8 октября 2025:**
- Полный аудит базы данных модуля "Материалы"
- Документирование всех 4 таблиц с детальным описанием структуры
- Анализ 7 функций PostgreSQL (включая FIFO-логику и умный поиск)
- Описание 2 триггеров для нормализации данных
- **Исправление RLS-политик:** устранено дублирование и конфликт INSERT/UPDATE
- **Исправление парсинга contract_number:** "№244 СУБ-07 от 17.05.2024" → "244 СУБ-07"
- **Обновление проверки дублей накладных:** по (номер + договор + дата)
- Документирование представления `v_materials_with_usage`
- Анализ связей между таблицами (Foreign Keys)
- Описание индексов (включая GIN trigram для поиска)
- Документирование миграций (FIFO по договорам, умный поиск)
- Анализ кода приложения (16 файлов Dart)
- Выявление актуальной статистики: 1671 материал, 509 накладных, 24 алиаса


