# Модуль Выгрузка (Export)

**Дата актуализации:** 21 августа 2026 года  
**Статус:** Актуально (Clean Architecture, Server-side Pagination, единый период для поиска и ВОР)

> **Изменения 21.08.2026 (скачивание ВОР):**
> - `VorDownloadAction` больше не открывает отдельный `showDateRangePicker` на весь экран.
> - Период для Excel/PDF ВОР берётся только из `workSearchDateRangeProvider` (календарь в AppBar: `WorkSearchDateRangeAction`).
> - Если период не выбран — предупреждение `SnackBarUtils.showWarning`: «Сначала выберите период в календаре»; генерация не запускается.
> - Кнопки ВОР по-прежнему активны только при выбранном объекте (`exportSelectedObjectIdProvider`).
> - Право доступа: `PermissionGuard` `module: export`, `permission: export`.

---

## 📌 Важное замечание

Модуль **не владеет** таблицами. Это инструмент поиска выполненных работ и экспорта отчётов. Данные читаются из `works` / `work_items` и связанных справочников.

**Особенности:**
- Поле поиска (`ExportSearchAction`) и каскадные чипы фильтров (`ExportSearchFilterChips`) показываются только на Desktop (`ResponsiveUtils.isDesktop`, ширина ≥ 900 px).
- Календарь периода, кнопки ВОР и экспорт Excel доступны в AppBar на всех ширинах экрана.
- Серверная пагинация UI: 250 строк на страницу (`WorkSearchState.pageSize`).
- Серверная агрегация итогов в одном RPC (`total_count`, `total_quantity`, `total_sum`).
- Кэш объектов со сменами: `objectsWithWorksProvider` (`ref.keepAlive`) + префетч при входе на `ExportScreen`.

---

## 🛑 Технические ограничения (Limits)

1. **Лимит выборки экспорта поиска:** до 100 000 строк в Edge Function `export-work-search-all` (защита памяти сервера).
2. **Лимит PostgREST:** 1000 строк обходится внутри `export-work-search-all` циклом `p_from` / `p_to`.
3. **Payload Limit:** передача массива `results` с клиента в `export-work-search-pto` может дать HTTP 413 при объёме > 10 МБ.
4. **Тайм-аут Edge Function:** 60 секунд.

---

## 📖 Описание

Модуль нужен для расширенного поиска выполненных работ и выгрузки отчётов (таблица поиска, ВОР Excel/PDF).

**Ключевые функции:**
- Поиск по наименованию работ (ILike на стороне RPC).
- Фильтрация по объекту (обязательно) и периоду дат (календарь в шапке).
- Каскадный Multi-select: системы → участки → этажи.
- Итоги по всей выборке, не только по текущей странице.
- Контекстное меню строки: переход к смене / редактирование позиции (по ролям).
- Скачивание ВОР (Excel и PDF) за тот же период, что выбран для поиска.
- Экспорт результатов поиска в Excel (формат ПТО).

---

## 🔗 Зависимости

- **Владение таблицами (Owner):** нет.
- **Использование таблиц (Usage):**
  - `works` — смены (дата, объект, статус). RLS: ✅ включён.
  - `work_items` — позиции работ. RLS: ✅ включён.
  - `estimates` — цена, номер позиции. RLS: ✅ включён.
  - `objects` — название объекта. RLS: ✅ включён.
  - `contracts` — подписанты и номер договора в отчётах ВОР. RLS: ✅ включён.

---

## 🎨 Слой Presentation

### Экраны
- `ExportScreen` — экран модуля, заголовок «Поиск по работам».
- `ExportTabSearch` — таблица результатов; объект обязателен.

### AppBar
- `ExportSearchAction` — поиск (только Desktop).
- `WorkSearchDateRangeAction` — компактный календарь периода; единственный UI выбора дат для поиска, экспорта ПТО и ВОР.
- `VorDownloadAction` — PDF и Excel ВОР.
- `WorkSearchExportAction` — Excel по текущей выборке поиска.

### Провайдеры (Riverpod)
- `workSearchProvider` — состояние поиска и пагинация (`WorkSearchState`).
- `workSearchFilterValuesProvider` — доступные значения чипов (RPC каскада).
- `exportSearchFilterProvider` — выбранные системы / участки / этажи.
- `exportSelectedObjectIdProvider` — выбранный объект.
- `workSearchDateRangeProvider` — период дат (`DateTimeRange?`, по умолчанию `null`).
- `exportSearchQueryProvider` / `exportSearchQueryDebouncedProvider` — текст поиска, debounce 500 ms (`kExportSearchDebounceMs`).
- `objectsWithWorksProvider` — `Set<String>` object_id со сменами компании.
- `vorRepositoryProvider` — генерация ВОР через Edge Functions.

### Виджеты
- `ExportResultsTableView` — таблица со синхронизированным скроллом, динамической шириной колонок (`_measureText`), строкой итогов.
- `ExportSearchFilterChips` — каскадные чипы (Desktop).
- Уведомления: `SnackBarUtils` (не стандартный Material SnackBar).

---

## ⚙️ Слой Domain/Data

### Сущности
- `WorkSearchResult` — строка результата (Freezed, `abstract class`).
- `WorkSearchPaginatedResult` — страница + `totalCount` / `totalQuantity` / `totalSum`.
- `WorkSearchFilterValues` — списки systems / sections / floors.

### Репозитории
- `WorkSearchRepository` / `WorkSearchRepositoryImpl` / `WorkSearchDataSourceImpl` — RPC поиска и фильтров. Даты в API: `GtFormatters.formatDateForApi`.
- `VorRepository` / `VorRepositoryImpl` — `generate_vor` (xlsx) и `generate_vor_pdf` (pdf). Даты в теле: `DateTime.toIso8601String()`.
- `WorkSearchExportServerService` — `export-work-search-all` + `export-work-search-pto`.

---

## 📂 Дерево файлов

```text
lib/features/export/
├── data/
│   ├── datasources/
│   │   ├── work_search_data_source.dart
│   │   └── work_search_data_source_impl.dart
│   └── repositories/
│       ├── vor_repository_impl.dart
│       └── work_search_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── work_search_result.dart
│   └── repositories/
│       ├── vor_repository.dart
│       └── work_search_repository.dart
└── presentation/
    ├── providers/
    │   ├── export_objects_with_works_provider.dart
    │   ├── export_search_providers.dart
    │   ├── repositories_providers.dart
    │   ├── work_search_date_provider.dart
    │   └── work_search_provider.dart
    ├── screens/
    │   ├── export_screen.dart
    │   └── tabs/
    │       └── export_tab_search.dart
    ├── services/
    │   └── work_search_export_server_service.dart
    └── widgets/
        ├── export_results_table_view.dart
        ├── export_search_action.dart
        ├── export_search_filter_chips.dart
        ├── vor_download_action.dart
        ├── work_search_date_filter.dart
        └── work_search_export_action.dart
```

Файла `export_work_item_edit_modal.dart` в модуле нет (редактирование — через `work_item_form_improved` модуля Works).

---

## 🗄️ База данных (Audit)

Модуль таблиц не создаёт. Проверено через `information_schema` / `pg_class` / `pg_indexes` / `pg_proc` (MCP Supabase, 21.08.2026).

### RLS используемых таблиц
| Таблица | RLS |
|---|---|
| `works` | ✅ включён |
| `work_items` | ✅ включён |
| `estimates` | ✅ включён |
| `objects` | ✅ включён |
| `contracts` | ✅ включён |

### SQL Functions (RPC) модуля
| Функция | Security | Клиент |
|---|---|---|
| `get_distinct_work_object_ids(p_company_id uuid)` | DEFINER | `objectsWithWorksProvider` |
| `get_work_items_available_filters(...)` | DEFINER | `WorkSearchDataSourceImpl.getFilterValues` |
| `search_work_items_with_aggregates(...)` | DEFINER | `WorkSearchDataSourceImpl.searchMaterials` |
| `search_work_items_paginated(...)` | DEFINER | legacy / Edge `export-work-search-all` |
| `get_work_items_aggregates(...)` | DEFINER | legacy |

RPC ВОР (`compute_vor_item_rows`, `populate_vor_items`, `recalculate_vor` и др.) принадлежат модулю смет, не экрану Выгрузка.

### Индексы (факт БД)
- `idx_works_date_desc` — `works(date DESC)`. ✅ есть.
- `idx_work_items_name_trgm` — GIN `work_items(name gin_trgm_ops)`. ✅ есть.
- `idx_work_items_name_gin` — в БД **нет** (устаревшее имя в прошлой версии документа).

---

## 🧠 Бизнес-логика

### Форматирование
Запрещены локальные `DateFormat` / `NumberFormat` в UI. Используются `formatRuDate`, `formatCurrency`, `formatQuantity`, для RPC — `GtFormatters.formatDateForApi`.

### Поиск
1. Пользователь выбирает **объект** (обязательно).
2. RPC отдаёт доступные фильтры для объекта (и периода, если задан).
3. Выбор системы сужает участки (серверный каскад).
4. Текст поиска обновляет таблицу и чипы с debounce 500 ms.
5. Сортировка: `works.date` DESC, затем `id` (в RPC).

### Скачивание ВОР (Excel / PDF)

```text
Нажатие PDF или Excel
  → объект не выбран → кнопки неактивны
  → период null → предупреждение, выход
  → период задан → generate_vor / generate_vor_pdf
       (objectId, dateFrom, dateTo, фильтры шапки, searchQuery)
```

Период **не** выбирается во втором окне. Источник дат — тот же календарь, что для поиска.

### Учёт истории в файле ВОР (Historical Usage)
Для позиции сметы суммируется объём **строго до** `dateFrom`. Остаток лимита: `Лимит − Выполнено_ранее`.

### Распределение объёмов (Overrun Splitting)
- **Норма:** объём в пределах остатка сметы.
- **Превышение:** сверх лимита или без привязки к смете.

### Оформление файла
- Секция превышений: заголовок «ПРЕВЫШЕНИЕ ОБЪЕМОВ И ДОПОЛНИТЕЛЬНЫЕ РАБОТЫ...».
- Excel: серый фон разделителя `#EEEEEE`.
- Подписанты — из `contracts` по договору.

---

## 🔌 Интеграции

**Edge Functions, вызываемые из модуля Export (код `lib/features/export/`):**
- `generate_vor` — Excel ВОР.
- `generate_vor_pdf` — PDF ВОР.
- `export-work-search-all` — полная выборка поиска.
- `export-work-search-pto` — Excel формата ПТО.

`list_edge_functions` в MCP проекта нет; список сверён с `supabase/functions/` и вызовами `functions.invoke` в коде.

**Не вызываются из модуля Export** (модуль смет / материалы):
- `generate_vor_v2`
- `export-vor-materials`
- `export-cumulative-vor`

**Пакеты:** `file_saver`, `file_selector`, `share_plus`, `path_provider`, `supabase_flutter`, `flutter_riverpod`.

---

## 🗺️ Roadmap

- [x] Серверная пагинация (250 строк/стр).
- [x] Каскадный Multi-select фильтров.
- [x] Серверная агрегация итогов.
- [x] Кастомная таблица с закрепленным заголовком.
- [x] Унификация форматирования (`GtFormatters`).
- [x] Серверная сортировка по дате (RPC).
- [x] ВОР Excel и PDF: история и превышения.
- [x] Единый период шапки для поиска и скачивания ВОР (21.08.2026).
- [ ] Оптимизация экспорта поиска для файлов > 50 тыс. строк.
- [ ] Адаптивная таблица поиска на Mobile.
