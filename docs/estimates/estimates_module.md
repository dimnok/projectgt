# Модуль Сметы (Estimates)

**Дата актуализации:** 22 августа 2026 года  
**Изменения:** На карточке сметы в desktop Sidebar (`_EstimateListTile`) отображается процент выполнения по объёму. Значение приходит из RPC `get_estimate_groups` (`completion_percent`) в поле `EstimateFile.completionPercent`. Формула совпадает с бейджем в шапке открытой сметы: `SUM(факт work_items.quantity) / SUM(план estimates.quantity) × 100`. Миграция `get_estimate_groups_completion_percent` (сервер: `20260822182303`).
**Статус:** Актуально (Clean Architecture, Riverpod, Strict Multi-tenancy, RBAC, Subsystem Filter Bar, Sidebar Completion Percent, VOR Excel/PDF Storage Flow, VOR Tab Dynamic Columns, Cumulative Excel with Excess Column, Estimate Revisions/Addendums, VOR Draft Delete by Creator, VOR Signed PDF Web Upload)

---

## ⚠️ Важное замечание
- **Владение таблицами:** модуль владеет `public.estimates`, `public.vors`, `public.vor_items`, `public.vor_systems`, `public.vor_status_history`.
- **Multi-tenancy:** все owner-таблицы модуля используют `company_id`; доступ строится вокруг `get_my_company_ids()` и `check_permission(..., 'estimates', ...)`.
- **RLS-ограничение ВОР:** стандартный `UPDATE` для `public.vors` разрешен только пока запись находится в статусах `draft` или `pending`. Для загрузки PDF после подписания используется отдельная `SECURITY DEFINER` функция `public.set_vor_pdf_document(...)`.
- **Удаление черновика ВОР:** отдельного RBAC-права «удалить ВОР» нет — используется модуль `estimates`, действие `delete`, плюс исключение для создателя (`vors.created_by = auth.uid()`). Владелец компании проходит через `check_permission` (`is_owner = true`). Подписанные и «на подписании» ведомости удалить нельзя.
- **Storage:** для документов ВОР используется закрытый bucket `vor_documents`. Excel-файлы генерируются через Edge Functions, подписанные PDF загружаются с клиента и открываются через signed URL.
- **Flutter Web (signed PDF):** на Web **не использовать** `dart:io` `File` для загрузки PDF — `dart:io` в браузере недоступен, ошибка `Unsupported operation: _Namespace`. Клиент читает `PlatformFile.bytes` (`FilePicker` с `withData: kIsWeb`) и передает `Uint8List` в `uploadVorPdf`; datasource вызывает `storage.uploadBinary` с `contentType: application/pdf`. На mobile/desktop байты получаются через `File(path).readAsBytes()`.
- **UI-особенность:** в реестре ВОР у подписанных записей кнопка PDF меняет цвет по состоянию файла: красный, если PDF еще не загружен, зеленый, если файл уже есть.
- **Sidebar (desktop):** карточка файла сметы (`_EstimateListTile`) показывает бейдж процента рядом с названием. Процент **не** считается на клиенте по всем позициям списка: его отдаёт `get_estimate_groups`, чтобы не загружать `work_items` для каждой сметы.
- **Видимость строк:** `estimates.visible_in_estimates_module = false` скрывает позицию из UI модуля «Сметы» и из `get_estimate_groups`; строка остаётся на карточке договора и в выполнении/материалах.

---

## 📂 Описание
Модуль **Сметы** отвечает за хранение плановых объемов и стоимости работ, импорт смет из Excel, агрегацию фактического выполнения и формирование ведомостей объемов работ (ВОР) по периодам договора.

**Ключевые функции:**
- **Импорт смет из Excel:** разбор `.xlsx` на клиенте (`excel` + `ExcelEstimateService`). Шаблон импорта — Edge Function `generate-estimate-import-template`.
- **Процент выполнения в Sidebar:** агрегат по объёму на карточке каждой сметы без открытия позиций.
- **Strict Access Control:** видимость и мутации ограничены RBAC-политиками и object-scope доступом.
- **Гибрид данных:** план берется из `public.estimates`, факт работ агрегируется из `public.work_items`.
- **VOR Engine:** создание ВОР через `get_next_vor_number(...)` + `populate_vor_items(...)`.
- **Excel export:** генерация Excel ВОР через `generate_vor_v2`, повторное скачивание из Storage без обязательной регенерации.
- **Signed PDF flow:** у подписанной ВОР можно загрузить signed PDF в Storage (`uploadBinary`), затем открыть его по signed URL. На Web — только через байты, без `File`.
- **Накопительная ведомость:** отдельный cumulative export по всем ВОР договора через `export-cumulative-vor`. Включает расчет превышения (excess quantity) относительно плановых объемов сметы.
- **Версионирование (LC / ДС):** отслеживание изменений сметы через ревизии (`estimate_revisions`). Поддержка дополнительных соглашений с сохранением истории изменений каждой позиции по `position_id`.
- **Авто-миграция:** автоматическое создание базовой ревизии ("Основная") для старых смет при первом обращении к функционалу ДС.
- **Таб `ВОР` в деталях сметы:** динамические колонки `ВОР-*`, расчет `ИТОГО`, сортировка по номеру ВОР, визуализация превышений.
- **Фильтр по подсистеме (desktop):** над таблицей позиций — горизонтальная полоса текстовых переключателей «Все» + уникальные значения колонки `subsystem`; клиентская фильтрация без запросов к БД.
- **История выполнения позиции (desktop):** боковая панель «Исполнение» — дата, участок/этаж, количество, вкладки «История» / «Сводка»; под участком/этажом — кто открыл смену (из модуля «Смены»).

---

## 🔗 Зависимости

### Таблицы модуля (owner)
- `public.estimates`
- `public.estimate_revisions` — история версий смет (Original, ДС-1, ДС-2)
- `public.estimate_revision_items` — позиции конкретной ревизии
- `public.vors`
- `public.vor_items`
- `public.vor_systems`
- `public.vor_status_history`

### Таблицы других модулей (usage)
- `public.contracts` — контекст договора для ВОР и фильтрации смет
- `public.objects` — именование и группировка смет через договор/объект
- `public.work_items` — источник фактического выполнения (колонки `section`, `floor`, `quantity`, `work_id`)
- `public.works` — дата смены (`date`) и автор открытия смены (`opened_by` → `profiles.id`)
- `public.profiles` — имена пользователей для истории ВОР и истории выполнения (`short_name`, `full_name`)
- `public.company_members` — RBAC и tenant membership
- `storage.buckets`, `storage.objects` — хранение Excel/PDF документов ВОР и файлов смет (`vor_documents`, `estimates`)
- View `public.estimates_with_contracts` — `estimates` + `contract_number`

### Внешние зависимости
- `supabase_flutter`
- `file_picker`
- `file_saver`
- `share_plus`
- `url_launcher`
- `excel`

---

## 🧱 Архитектура
Модуль реализован в стиле **Clean Architecture**, но часть VOR-сервисов организационно находится в `presentation/services`, а доменные сущности и репозиторные контракты расположены в общих слоях `lib/domain` и `lib/data`.

### Слой Presentation
- `lib/features/estimates/presentation/screens/estimates_list_screen.dart` — реестр смет, вход в модуль, refresh-target.
- `lib/features/estimates/presentation/screens/estimate_desktop_view.dart` — основной desktop-экран смет и табов; состояние фильтра подсистемы, комбинирование с поиском и фильтрами выполнения. `_EstimateListTile` показывает `formatPercentage(file.completionPercent, decimalDigits: 1)` рядом с названием сметы.
- `lib/features/estimates/presentation/widgets/estimate_subsystem_filter_bar.dart` — текстовые переключатели подсистем над таблицей; утилиты `estimateSubsystemFilterLabel`, `collectEstimateSubsystemLabels`.
- `lib/features/estimates/presentation/widgets/estimate_table_view.dart` — таблица позиций (колонки «Система», «Подсистема»), режимы «Смета» / «Выполнение».
- `lib/features/estimates/presentation/widgets/estimate_completion_history_panel.dart` — боковая панель «Исполнение»: история и сводка выполнения по позиции; ФИО открывшего смену (`openedByName`) под строкой участок/этаж.
- `lib/features/estimates/presentation/widgets/estimate_filter_buttons.dart` — фильтры статуса выполнения (перевыполнение / 100% / 0%) на вкладке «Выполнение».
- `lib/features/estimates/presentation/widgets/estimate_search_field.dart` — поиск по наименованию и номеру позиции.
- `lib/features/estimates/presentation/screens/import_estimate_form_modal.dart` — импорт Excel в модуль.
- `lib/features/estimates/presentation/widgets/vor_list_dialog.dart` — реестр ВОР, статусы, действия, кнопки Excel/PDF; удаление черновика с проверкой `canDeleteVor` (право `estimates.delete` **или** совпадение `created_by` с текущим пользователем).
- `lib/features/estimates/presentation/widgets/vor_recalculate_confirm_dialog.dart` — подтверждение пересчёта черновика ВОР при появлении новых работ за период.
- `lib/features/estimates/presentation/widgets/vor_card_details.dart` — история статусов и файлов, отображение signed PDF metadata.
- `lib/features/estimates/presentation/widgets/vor_create_dialog.dart` — создание ВОР по периоду и системам.
- `lib/features/estimates/presentation/widgets/vor_approve_dialog.dart` — подтверждение подписания и предварительный выбор PDF (`FilePicker` с `withData: kIsWeb`).
- `lib/features/estimates/presentation/widgets/vor_tab_table_view.dart` — таб `ВОР` с динамическими колонками.
- `lib/features/estimates/presentation/providers/estimate_providers.dart` — Riverpod-провайдеры, TTL cache, invalidation, `VorActions` (`uploadPdf` принимает `Uint8List bytes`), `estimateCompletionHistoryProvider`. `EstimateFile.completionPercent` заполняется из `estimateGroupsProvider` (`g['completion_percent']`).
- `lib/features/estimates/presentation/utils/vor_pdf_actions.dart` — upload/open signed PDF: Web — `PlatformFile.bytes` + `VorActions.uploadPdf(bytes)`; mobile/desktop — `File.readAsBytes()`; открытие через signed URL и `url_launcher`.

### Слой Application / Services
- `lib/features/estimates/presentation/services/vor_export_service.dart` — скачивание/фоновая генерация Excel ВОР, отчет по материалам.
- `lib/features/estimates/presentation/services/vor_cumulative_export_service.dart` — cumulative export по договору.

### Слой Domain
- `lib/domain/entities/estimate.dart` — доменная сущность сметной позиции.
- `lib/domain/entities/estimate_completion_history.dart` — запись истории выполнения: `date`, `quantity`, `section`, `floor`, `openedByName`.
- `lib/domain/entities/vor.dart` — доменная сущность ВОР и истории статусов.
- `lib/domain/repositories/estimate_repository.dart` — контракт репозитория смет и ВОР (`uploadVorPdf`: `Uint8List bytes`, `fileName`).

### Слой Data
- `lib/data/datasources/estimate_data_source.dart` — Supabase datasource, CRUD смет, VOR RPC/storage flow, `uploadVorPdf` → `vor_documents.uploadBinary` (`contentType: application/pdf`), `getEstimateCompletionHistory` (join `work_items` / `works` / `profiles`).
- `lib/data/models/estimate_model.dart` — DTO смет.
- `lib/data/models/vor_model.dart` — DTO ВОР, mapping `pdf_url/excel_url/status_history`.
- `lib/data/repositories/estimate_repository_impl.dart` — bridge data/domain; маппинг `openedByName` из nested `works.profiles` (`_resolveOpenedByName`: приоритет `short_name`, затем `full_name`).

---

## 🌲 Дерево файлов
```text
lib/features/estimates/
├── presentation/
│   ├── mixins/
│   │   └── estimate_actions_mixin.dart
│   ├── providers/
│   │   └── estimate_providers.dart
│   ├── screens/
│   │   ├── estimate_desktop_view.dart
│   │   ├── estimate_details_screen.dart
│   │   ├── estimate_form_screen.dart
│   │   ├── estimate_mobile_view.dart
│   │   ├── estimates_list_screen.dart
│   │   ├── import_estimate_form_modal.dart
│   │   ├── import_estimate_addendum_modal.dart
│   │   └── import_estimate_bulk_update_modal.dart
│   ├── services/
│   │   ├── estimate_addendum_excel_service.dart
│   │   ├── estimate_bulk_update_excel_service.dart
│   │   ├── vor_cumulative_export_service.dart
│   │   └── vor_export_service.dart
│   ├── utils/
│   │   ├── estimate_sorter.dart
│   │   └── vor_pdf_actions.dart
│   └── widgets/
│       ├── acts_table_view.dart
│       ├── estimate_completion_history_panel.dart
│       ├── estimate_details_modal.dart
│       ├── estimate_edit_dialog.dart
│       ├── estimate_filter_buttons.dart
│       ├── estimate_subsystem_filter_bar.dart
│       ├── estimate_item_card.dart
│       ├── estimate_item_details_dialog.dart
│       ├── estimate_mobile_header.dart
│       ├── estimate_search_field.dart
│       ├── estimate_table_view.dart
│       ├── export_cumulative_vor_button.dart
│       ├── material_from_receipts_picker.dart
│       ├── vor_approve_dialog.dart
│       ├── vor_card_details.dart
│       ├── vor_create_dialog.dart
│       ├── vor_list_dialog.dart
│       ├── vor_recalculate_confirm_dialog.dart
│       └── vor_tab_table_view.dart
```

---

## 🗄 База данных (Audit)

### Таблицы

#### `public.estimates`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| contract_id | uuid | FK на договор |
| object_id | uuid | FK на объект |
| system | text | система |
| subsystem | text | подсистема |
| name | text | наименование |
| article | text | артикул |
| manufacturer | text | производитель |
| unit | text | единица измерения |
| quantity | double precision | плановый объём |
| price | double precision | цена |
| total | double precision | сумма |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| estimate_title | text | заголовок файла сметы (группа в Sidebar) |
| number | text | номер позиции |
| company_id | uuid | tenant isolation |
| position_id | uuid | стабильный ID позиции через ревизии |
| visible_in_estimates_module | boolean | `false` — скрыта в модуле «Сметы» и `get_estimate_groups` (default `true`) |

#### `public.estimate_revisions`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| company_id | uuid | tenant isolation |
| contract_id | uuid | FK на договор |
| estimate_title | text | заголовок файла сметы |
| revision_no | integer | 0 — Original, 1+ — ДС |
| revision_label | text | «Основная», «ДС-1» и т.д. |
| status | text | `draft`, `approved`, `archived` |
| revision_type | text | `original`, `addendum` |
| based_on_revision_id | uuid | Ссылка на предыдущую версию |
| source_file_path | text | путь исходного Excel |
| effective_from | date | дата вступления |
| approved_at | timestamptz | дата утверждения |
| created_by | uuid | автор |
| user_description | text | описание ДС |
| applied_to_estimates_at | timestamptz | когда применено к `estimates` |
| applied_by | uuid | кто применил |
| created_at, updated_at | timestamptz | аудит |

#### `public.estimate_revision_items`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| company_id | uuid | tenant isolation |
| revision_id | uuid | FK на ревизию |
| position_id | uuid | Тот же ID, что в `estimates` |
| source_estimate_id | uuid | исходная позиция `estimates` |
| row_no | integer | номер строки |
| system, subsystem, number, name, article, manufacturer, unit | text | снимок позиции |
| quantity, price, total | double precision | данные на момент ревизии |
| change_type | text | `added`, `removed`, `qty_changed`, `price_changed`, `unchanged` |
| created_at | timestamptz | дата создания |

#### `public.vors`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK ВОР |
| company_id | uuid | tenant isolation |
| contract_id | uuid | FK на договор |
| number | text | номер вида `ВОР-001` |
| start_date | date | начало периода |
| end_date | date | конец периода |
| status | vor_status | `draft`, `pending`, `approved` |
| excel_url | text | путь Excel в Storage |
| excel_combined_url | text | путь общего Excel-листа в Storage |
| pdf_url | text | путь signed PDF в Storage |
| include_combined_sheet | boolean | формировать общий лист без разделения превышений |
| baseline_revision_id | uuid | опциональная привязка к ревизии сметы |
| created_at | timestamptz | дата создания |
| updated_at | timestamptz | дата обновления |
| created_by | uuid | создатель (используется в правиле удаления черновика) |

#### `public.vor_items`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| company_id | uuid | tenant isolation |
| vor_id | uuid | FK на ВОР |
| estimate_item_id | uuid | FK на сметную позицию |
| name | text | имя для extra/manual строк |
| unit | text | единица измерения |
| quantity | double precision | объем за период |
| is_extra | boolean | превышение/новая позиция |
| sort_order | integer | порядок строк |
| created_at | timestamptz | дата создания |

#### `public.vor_systems`
| Колонка | Тип |
|:---|:---|
| vor_id | uuid |
| company_id | uuid |
| system_name | text |

#### `public.vor_status_history`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| company_id | uuid | tenant isolation |
| vor_id | uuid | FK на ВОР |
| status | vor_status | зафиксированный статус |
| user_id | uuid | автор действия |
| comment | text | комментарий события |
| created_at | timestamptz | дата события |

### RLS
- `public.estimates` — ✅ Включен
- `public.estimate_revisions` — ✅ Включен
- `public.estimate_revision_items` — ✅ Включен
- `public.vors` — ✅ Включен
- `public.vor_items` — ✅ Включен
- `public.vor_systems` — ✅ Включен
- `public.vor_status_history` — ✅ Включен

### Ключевые политики
- `estimates`: `SELECT/UPDATE/DELETE` учитывают не только `company_id`, но и object-scope пользователя через `profiles.object_ids`, если пользователь не owner компании.
- `vors`: обычный `UPDATE` разрешен только для записей в `draft` или `pending`.
- `vors`: `DELETE` (`Strict DELETE for vors`) — только `status = 'draft'` **и** (`check_permission(..., 'estimates', 'delete')` **или** `created_by = auth.uid()`).
- `vor_items`: `INSERT/UPDATE` разрешены только если связанный `vors.status = 'draft'`.
- `vor_items`: `DELETE` — каскад при удалении черновика; условие совпадает с правом удаления родительской ВОР (право `estimates.delete` или создатель).
- `vor_systems`, `vor_status_history`: `DELETE` — те же условия, что и для `vor_items` (каскадное удаление черновика ВОР).
- `vor_systems`, `vor_status_history`: `SELECT/INSERT` ограничены company-scope.

### Индексы и триггеры
- `estimates`: `idx_estimates_company_id`, `idx_estimates_contract_id`, `idx_estimates_object_id`, `idx_estimates_grouping` (`estimate_title, object_id, contract_id`), `idx_estimates_filters`, `idx_estimates_sort`, `idx_estimates_name_gin_trgm`, `uq_estimates_company_contract_position`
- `estimates`: trigger `trg_sync_work_items_on_estimate_update` (AFTER UPDATE) синхронизирует связанные `work_items`
- `estimate_revisions`: `idx_estimate_revisions_company_contract`, `idx_estimate_revisions_contract_title_status`, `uq_estimate_revisions_contract_title_revision`; trigger `tr_estimate_revisions_updated_at`
- `estimate_revision_items`: `idx_estimate_revision_items_revision`, `idx_estimate_revision_items_position`
- `vors`: `idx_vors_company`, `idx_vors_contract`, `idx_vors_baseline_revision_id`
- `vor_items`: `idx_vor_items_company`, `idx_vor_items_vor`
- `vor_status_history`: `idx_vor_status_history_vor`
- `vors`: trigger `tr_vors_updated_at` обновляет `updated_at`

### Представления
- `public.estimates_with_contracts` — строки `estimates` плюс `contract_number` и `visible_in_estimates_module`
- `public.v_materials_grouped_by_estimate` — агрегаты материалов по позиции (используется в `get_estimate_completion_by_ids`)

### Storage audit
- Bucket: `vor_documents` — Public: `false`. Policies на `storage.objects`: `SELECT` / `INSERT` / `DELETE` для `authenticated` (фильтр `bucket_id = 'vor_documents'`).
- Bucket: `estimates` — Public: `false`. Policies завязаны на `check_permission(..., 'estimates', ...)` (`SELECT`/`INSERT`/`UPDATE`/`DELETE`).

### Аудит статистики таблиц (`pg_stat_user_tables`, 22.08.2026)
- `estimates`: `n_live_tup = 3116`, `idx_scan = 253502`, `seq_scan = 10689`
- `estimate_revisions`: `n_live_tup = 0`, `idx_scan = 0`, `seq_scan = 4`
- `estimate_revision_items`: `n_live_tup = 0`, `idx_scan = 0`, `seq_scan = 2`
- `vors`: `n_live_tup = 1`, `idx_scan = 14`, `seq_scan = 1772`
- `vor_items`: `n_live_tup = 1754`, `idx_scan = 253`, `seq_scan = 755`
- `vor_status_history`: `n_live_tup = 5`, `idx_scan = 0`, `seq_scan = 214`
- `vor_systems`: `n_live_tup = 3`, `idx_scan = 0`, `seq_scan = 256`

### RPC / SQL функции модуля
1. `get_estimate_groups(p_company_id)` — группы смет для Sidebar/списка: `estimate_title`, `object_id`, `contract_id`, `contract_number`, `items_count`, `total_amount`, **`completion_percent`**. Фильтр: `visible_in_estimates_module = true`, RBAC `estimates.read`, object-scope (owner или `profiles.object_ids`). Факт берётся из агрегата `work_items` по `estimate_id` в рамках `company_id`.
2. `get_estimate_completion_by_ids(p_company_id, p_estimate_ids)` — выполнение по позициям открытой сметы (шапка, таблица «Выполнение»).
3. `populate_vor_items(p_vor_id)` — наполняет `vor_items` фактом работ за период.
4. `get_next_vor_number(p_company_id, p_contract_id)` — возвращает следующий номер ВОР в рамках договора.
5. `recalculate_vor(p_vor_id)` — пересчёт состава черновика ВОР за период.
6. `get_draft_vor_needs_recalc(p_contract_id)` — флаги «нужен пересчёт» для черновиков договора.
7. `get_vor_recalc_changes(p_vor_id)` — превью изменений перед пересчётом.
8. `set_vor_pdf_document(p_vor_id, p_company_id, p_pdf_url)` — `SECURITY DEFINER` функция для обновления `pdf_url` у уже подписанной ВОР.
9. `apply_estimate_bulk_update(...)` — массовое обновление позиций сметы.
10. `find_similar_estimates(...)` — поиск похожих позиций при импорте.

---

## ⚙️ Бизнес-логика

### Импорт смет
1. Пользователь выбирает `.xlsx` в `ImportEstimateFormModal`.
2. Шаблон импорта при необходимости скачивается через Edge Function `generate-estimate-import-template`.
3. Парсинг выполняется на клиенте (`ExcelEstimateService` + пакет `excel`).
4. Сметные позиции сохраняются в `public.estimates` с tenant binding по `company_id`.

> Аудит 22.08.2026: в текущем feature-flow модуля «Сметы» **нет** вызовов Edge Functions `excel_parse` и `xls_to_xlsx`. `excel_parse` используется модулем материалов (`receipts_remote_parser.dart`), не импортом смет.

### Процент выполнения на карточке сметы (desktop Sidebar)
1. `estimateGroupsProvider` вызывает RPC `get_estimate_groups(p_company_id)`.
2. Сервер считает процент **по объёму** (не среднее арифметическое процентов позиций):

```sql
CASE
  WHEN SUM(e.quantity) = 0 THEN 0
  ELSE SUM(completed_quantity) / SUM(e.quantity) * 100
END
```

`completed_quantity` — `SUM(work_items.quantity)` по `estimate_id` в рамках `company_id`.
3. Клиент кладёт значение в `EstimateFile.completionPercent`.
4. `_EstimateListTile` показывает бейдж через `formatPercentage(..., decimalDigits: 1)` справа от названия, перед кнопкой удаления.
5. Та же формула используется в шапке открытой сметы (`totalExecutedQty / totalPlannedQty * 100` из `get_estimate_completion_by_ids`). Цифры совпадают при одинаковом наборе видимых позиций.
6. Мобильный реестр (`estimates_list_screen`) поле `completionPercent` пока **не отображает**.

### История выполнения позиции (вкладка «Выполнение», desktop)
1. Пользователь выбирает строку в таблице выполнения — слева открывается панель `EstimateCompletionHistoryPanel`.
2. Провайдер `estimateCompletionHistoryProvider(estimateId)` вызывает `EstimateRepository.getEstimateCompletionHistory`.
3. Datasource читает `work_items` с join:
   ```sql
   work_items → works!inner(date, profiles!opened_by(short_name, full_name))
   ```
   фильтр: `estimate_id`, `company_id`; сортировка по `works.date` DESC.
4. Каждая запись истории содержит: дату смены, количество, участок (`section`), этаж (`floor`), опционально `openedByName`.
5. **Отображение:** дата и количество в одной строке; участок/этаж — `bodySmall`; ФИО открывшего смену — `labelSmall`, 10px, приглушённый цвет, под участком/этажом. Если имя пустое — строка не показывается.
6. Вкладка **«Сводка»** агрегирует количество по иерархии участок → этаж (без ФИО).
7. **Ограничение:** показывается автор **открытия смены** (`works.opened_by`), а не пользователь, вручную внёсший конкретную строку `work_items` (отдельного `created_by` у строки работы нет).

### Фильтр по подсистеме (desktop, вкладки «Смета» и «Выполнение»)
1. Уникальные подсистемы собираются из загруженных позиций сметы (`collectEstimateSubsystemLabels`): значение колонки `subsystem`, пустое — подпись **«Без подсистемы»**.
2. Полоса переключателей (`EstimateSubsystemFilterBar`) показывается **только если подсистем больше одной**; на вкладке **«ВОР»** не отображается.
3. По умолчанию активен пункт **«Все»** (`selectedSubsystem == null`).
4. Выбор подсистемы фильтрует строки таблицы на клиенте; повторное нажатие на активный переключатель сбрасывает фильтр на «Все».
5. Фильтр комбинируется с текстовым поиском (`EstimateSearchField`) и, на вкладке «Выполнение», с фильтрами статуса (`EstimateFilterButtons`).
6. При смене сметы в боковом списке выбор подсистемы сбрасывается.
7. Если выбранная подсистема исчезла из данных (обновление позиций), фильтр автоматически трактуется как «Все» без записи в state.

### Создание ВОР
1. Пользователь выбирает договор, период и список систем.
2. `createVor(...)` создает заголовок ВОР в `public.vors`.
3. `populateVorItems(...)` сразу наполняет `public.vor_items` фактом из `work_items`.
4. После создания UI инвалидирует `vorsProvider` и `contractVorCompletionProvider`.

### Статусы ВОР
1. Переходы в UI ограничены цепочкой `draft -> pending -> approved`, с возможностью возврата `pending -> draft`.
2. После `approved` обычное редактирование и удаление блокируются политиками и UI.
3. История смен статуса пишется в `public.vor_status_history`.

### Удаление черновика ВОР

| Кто | Может удалить черновик? |
|:---|:---|
| Владелец компании | Да (через `check_permission`, `is_owner = true`) |
| Пользователь с правом **Сметы → Удаление** (`estimates.delete`) | Да |
| **Создатель ведомости** (`vors.created_by`) | Да, даже без `estimates.delete` |
| Остальные пользователи | Нет |

**Последовательность (UI + `VorActions.deleteVor`):**
1. Кнопка корзины в `vor_list_dialog.dart` видна только при `canDeleteVor` (черновик + одно из условий выше).
2. Пользователь подтверждает удаление в диалоге.
3. Клиент читает `excel_url`, `excel_combined_url`, `pdf_url`.
4. `estimate_data_source.deleteVor` удаляет запись из `vors` (RLS: только `draft` + право/создатель).
5. Каскадно удаляются `vor_items`, `vor_systems`, `vor_status_history` (RLS-политики `DELETE` с тем же условием).
6. Файлы удаляются из bucket `vor_documents`.
7. Инвалидируются `vorsProvider`, `draftVorNeedsRecalcProvider`, `contractVorCompletionProvider`.

**Ограничения:**
- Статусы `pending` и `approved` удалить нельзя (ни в UI, ни в RLS).
- Для позиций сметы дополнительно проверяется object-scope; для ВОР — нет, только company + право/создатель.
- Если к ВОР привязан акт КС-2 (`ks2_acts.vor_id`, `ON DELETE RESTRICT`), удаление может быть заблокировано на уровне FK.

### Версионирование (LC / ДС)
1. **Инициализация (Baseline):** При первом скачивании шаблона ДС или импорте ДС для старой сметы создается ревизия №0 ("Основная") на базе текущих данных `estimates`.
2. **position_id:** Все строки сметы получают стабильный `position_id`. При добавлении новой строки в Excel (без ID) система генерирует новый UUID.
3. **Draft ДС:** Импорт Excel создает черновик (`draft`) ревизии. Система сравнивает строки с предыдущей `approved` ревизией и проставляет `change_type`.
4. **Сравнение:** Позиции сопоставляются по `position_id`. Если ID нет в базе — `added`. Если ID есть, но нет в файле — `removed`. Если изменились цифры — `qty_changed`/`price_changed`.

### Excel flow
1. Excel ВОР генерируется через Edge Function `generate_vor_v2`.
2. Шаблон LC / ДС генерируется через Edge Function `generate_estimate_addendum_template` с форматированием Times New Roman 12.
3. Если `vors.excel_url` уже заполнен, клиент сначала пытается скачать готовый файл из `vor_documents`.
4. Если скачать не удалось, выполняется повторная серверная генерация.

### Signed PDF flow
1. При подписании пользователь может сразу выбрать signed PDF в `vor_approve_dialog.dart` (`FilePicker.pickFiles`, `withData: kIsWeb` на Web).
2. Если файл не выбран в момент подписания, позже его можно загрузить из карточки подписанной ВОР (кнопка PDF в `vor_list_dialog.dart`).
3. **Чтение файла на клиенте:**
   - **Web:** `PlatformFile.bytes` из `FilePicker` (путь `file.path` в браузере не используется).
   - **Mobile / Desktop:** `File(file.path).readAsBytes()` если `bytes` не пришли из picker.
4. `VorActions.uploadPdf` → `EstimateRepository.uploadVorPdf(vorId, bytes, fileName)`.
5. Datasource загружает PDF в bucket `vor_documents` через `storage.uploadBinary` (`contentType: application/pdf`), не через `storage.upload(File)`.
6. Для signed PDF используется безопасный путь вида `contract_id/vor_id/timestamp_safe_name.pdf`.
7. Обновление `vors.pdf_url` происходит через `set_vor_pdf_document(...)`, потому что обычный `UPDATE` для `approved` запрещен RLS-политикой.
8. После загрузки в `vor_status_history` пишется дополнительная запись с комментарием `Загружен подписанный ВОР PDF`.
9. Открытие PDF выполняется через `getVorPdfViewUrl` (signed URL) и `url_launcher` (`VorPdfActions.openPdf`).

> **Не использовать** `dart:io` `File` на Web при загрузке signed PDF: ошибка `Unsupported operation: _Namespace`. Эталон кроссплатформенной загрузки — аватар сотрудника (`EmployeeAvatarController`, модуль Employees).

### Очистка файлов
1. Удаление ВОР разрешено только для `draft` и только пользователям из таблицы прав выше.
2. Перед удалением клиент считывает `excel_url`, `excel_combined_url` и `pdf_url`.
3. После удаления записи из БД все связанные файлы удаляются из bucket `vor_documents`.

### Таб `ВОР`
1. Колонки `ВОР-*` строятся динамически по списку ВОР договора.
2. Выполнение агрегируется по `vor_items`.
3. Суммарный показатель `ИТОГО` сравнивается с планом сметы.
4. При превышении планового объема строка визуально подсвечивается.

---

## 🔌 Интеграции

### Edge Functions
Аудит 22.08.2026: `list_edge_functions` в MCP Supabase этого проекта **нет**. Список сверён с `supabase/functions/*/index.ts` и вызовами `functions.invoke` в клиенте.

**Используются текущим feature-flow смет/ВОР:**
- `generate_vor_v2` — генерация Excel ВОР (`vor_export_service.dart`).
- `export-vor-materials` — Excel-отчёт по материалам ВОР.
- `export-cumulative-vor` — накопительный Excel по всем ВОР договора.
- `generate-estimate-import-template` — шаблон импорта сметы.
- `export-estimate-bulk-update-template` — шаблон массового обновления позиций.
- `generate_estimate_addendum_template` — шаблон LC/ДС (вызов из `estimate_data_source.dart`; каталога в `supabase/functions/` в репозитории нет).
- `export-contract-estimate-addenda` — Excel сметы с колонками ДС (карточка договора).
- `export-contract-estimate-execution` — Excel сметы с колонками выполнения (карточка договора).

**Есть в репозитории, но не в UI реестра смет/ВОР:**
- `generate_vor_pdf` — вызывается из `lib/features/export/data/repositories/vor_repository_impl.dart`.
- `generate_vor` — предыдущая версия генерации Excel ВОР.

**Не относятся к импорту смет:**
- `excel_parse` — парсинг Excel приходов (модуль материалов).
- `xls_to_xlsx` — в `supabase/functions/` репозитория нет.

### Storage
- bucket `vor_documents` — Excel и signed PDF ВОР; загрузка PDF: `uploadBinary` (`Uint8List`, `application/pdf`); чтение PDF — signed URL
- bucket `estimates` — файлы шаблонов/импорта смет; RLS через `check_permission` модуля `estimates`

### Связанные модули
- `contracts` — договорный контекст ВОР
- `objects` — объектная группировка и метаданные
- `materials` — материалы и связанный material report
- `works` — фактические объемы через `work_items`
- `roles` / `company_members` — RBAC

---

## 🗺️ Roadmap
- 🟢 Импорт смет из Excel на клиенте (`ExcelEstimateService`) + шаблон `generate-estimate-import-template` — **Done**
- 🟢 Strict Multi-tenancy и RBAC для owner-таблиц — **Done**
- 🟢 Реестр ВОР с карточками и историей статусов — **Done**
- 🟢 Автоматическая нумерация ВОР — **Done**
- 🟢 Автоматическое наполнение `vor_items` фактом работ — **Done**
- 🟢 Excel export для ВОР — **Done**
- 🟢 Cumulative export по всем ВОР договора — **Done**
- 🟢 Автоматическая очистка Excel/PDF из Storage при удалении draft ВОР — **Done**
- 🟢 Удаление черновика ВОР создателем без права `estimates.delete` (RLS + UI) — **Done**
- 🟢 Пересчёт черновика ВОР при новых работах за период (`recalculate_vor`, `vor_recalculate_confirm_dialog`) — **Done**
- 🟢 Signed PDF upload/view для подписанной ВОР — **Done**
- 🟢 Загрузка signed PDF ВОР на Flutter Web (`Unsupported operation: _Namespace`) — **Done** (12.08.2026, bytes + `uploadBinary`)
- 🟢 Цветовая индикация наличия PDF в карточке ВОР — **Done**
- 🟢 Отображение автора и даты загрузки PDF в секции файлов — **Done**
- 🟢 Система версионирования смет (LC / ДС) — **Done**
- 🟢 Авто-миграция старых смет в базовую ревизию — **Done**
- 🟢 Серверная генерация шаблонов ДС (Times New Roman 12) — **Done**
- 🟢 Фильтр по подсистеме (текстовые переключатели над таблицей, desktop) — **Done**
- 🟢 ФИО открывшего смену в истории выполнения позиции (desktop, `estimate_completion_history_panel`) — **Done**
- 🟢 Процент выполнения на карточке сметы в desktop Sidebar (`get_estimate_groups.completion_percent`) — **Done** (22.08.2026)
- 🟡 Процент выполнения на карточке сметы в мобильном реестре — **Planned**
- 🟡 ФИО открывшего смену в мобильной истории выполнения (`estimate_details_modal`) — **Planned**
- 🟡 Фильтр по подсистеме на mobile — **Planned**
- 🟡 Интерфейс просмотра и утверждения ревизий — **Planned**
- 🟡 Backfill старых PDF-загрузок в `vor_status_history` — **Planned**
- 🟡 Массовое редактирование позиций ВОР — **Planned**
- 🔴 Полноценная серверная генерация финального PDF ВОР из текущего UI-потока — **Planned**
