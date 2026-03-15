# Модуль Сметы (Estimates)

**Дата актуализации:** 8 марта 2026 года  
**Изменения:** Внедрение системы версионирования смет (LC / ДС). Добавлены таблицы `estimate_revisions`, `estimate_revision_items`, поддержка `position_id` для отслеживания изменений, Edge Function для генерации шаблонов ДС, механизм авто-миграции старых смет.
**Статус:** Актуально (Clean Architecture, Riverpod, Strict Multi-tenancy, RBAC, VOR Excel/PDF Storage Flow, VOR Tab Dynamic Columns, Cumulative Excel with Excess Column, Estimate Revisions/Addendums)

---

## ⚠️ Важное замечание
- **Владение таблицами:** модуль владеет `public.estimates`, `public.vors`, `public.vor_items`, `public.vor_systems`, `public.vor_status_history`.
- **Multi-tenancy:** все owner-таблицы модуля используют `company_id`; доступ строится вокруг `get_my_company_ids()` и `check_permission(..., 'estimates', ...)`.
- **RLS-ограничение ВОР:** стандартный `UPDATE` для `public.vors` разрешен только пока запись находится в статусах `draft` или `pending`. Для загрузки PDF после подписания используется отдельная `SECURITY DEFINER` функция `public.set_vor_pdf_document(...)`.
- **Storage:** для документов ВОР используется закрытый bucket `vor_documents`. Excel-файлы генерируются через Edge Functions, подписанные PDF загружаются с клиента и открываются через signed URL.
- **UI-особенность:** в реестре ВОР у подписанных записей кнопка PDF меняет цвет по состоянию файла: красный, если PDF еще не загружен, зеленый, если файл уже есть.

---

## 📂 Описание
Модуль **Сметы** отвечает за хранение плановых объемов и стоимости работ, импорт смет из Excel, агрегацию фактического выполнения и формирование ведомостей объемов работ (ВОР) по периодам договора.

**Ключевые функции:**
- **Импорт смет из Excel:** загрузка `.xlsx/.xls` с разбором через Edge Functions `excel_parse` и `xls_to_xlsx`.
- **Strict Access Control:** видимость и мутации ограничены RBAC-политиками и object-scope доступом.
- **Гибрид данных:** план берется из `public.estimates`, факт работ агрегируется из `public.work_items`.
- **VOR Engine:** создание ВОР через `get_next_vor_number(...)` + `populate_vor_items(...)`.
- **Excel export:** генерация Excel ВОР через `generate_vor_v2`, повторное скачивание из Storage без обязательной регенерации.
- **Signed PDF flow:** у подписанной ВОР можно загрузить signed PDF в Storage, затем открыть его по signed URL.
- **Накопительная ведомость:** отдельный cumulative export по всем ВОР договора через `export-cumulative-vor`. Включает расчет превышения (excess quantity) относительно плановых объемов сметы.
- **Версионирование (LC / ДС):** отслеживание изменений сметы через ревизии (`estimate_revisions`). Поддержка дополнительных соглашений с сохранением истории изменений каждой позиции по `position_id`.
- **Авто-миграция:** автоматическое создание базовой ревизии ("Основная") для старых смет при первом обращении к функционалу ДС.
- **Таб `ВОР` в деталях сметы:** динамические колонки `ВОР-*`, расчет `ИТОГО`, сортировка по номеру ВОР, визуализация превышений.

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
- `public.work_items` — источник фактического выполнения
- `public.profiles` — имена пользователей для истории ВОР
- `public.company_members` — RBAC и tenant membership
- `storage.buckets`, `storage.objects` — хранение Excel/PDF документов ВОР

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
- `lib/features/estimates/presentation/screens/estimate_desktop_view.dart` — основной desktop-экран смет и табов.
- `lib/features/estimates/presentation/screens/import_estimate_form_modal.dart` — импорт Excel в модуль.
- `lib/features/estimates/presentation/widgets/vor_list_dialog.dart` — реестр ВОР, статусы, действия, удаление, кнопки Excel/PDF.
- `lib/features/estimates/presentation/widgets/vor_card_details.dart` — история статусов и файлов, отображение signed PDF metadata.
- `lib/features/estimates/presentation/widgets/vor_create_dialog.dart` — создание ВОР по периоду и системам.
- `lib/features/estimates/presentation/widgets/vor_approve_dialog.dart` — подтверждение подписания и предварительный выбор PDF.
- `lib/features/estimates/presentation/widgets/vor_tab_table_view.dart` — таб `ВОР` с динамическими колонками.
- `lib/features/estimates/presentation/providers/estimate_providers.dart` — Riverpod-провайдеры, TTL cache, invalidation, `VorActions`.
- `lib/features/estimates/presentation/utils/vor_pdf_actions.dart` — upload/open сценарии для signed PDF.

### Слой Application / Services
- `lib/features/estimates/presentation/services/vor_export_service.dart` — скачивание/фоновая генерация Excel ВОР, отчет по материалам.
- `lib/features/estimates/presentation/services/vor_cumulative_export_service.dart` — cumulative export по договору.

### Слой Domain
- `lib/domain/entities/estimate.dart` — доменная сущность сметной позиции.
- `lib/domain/entities/vor.dart` — доменная сущность ВОР и истории статусов.
- `lib/domain/repositories/estimate_repository.dart` — контракт репозитория смет и ВОР.

### Слой Data
- `lib/data/datasources/estimate_data_source.dart` — Supabase datasource, CRUD смет, VOR RPC/storage flow.
- `lib/data/models/estimate_model.dart` — DTO смет.
- `lib/data/models/vor_model.dart` — DTO ВОР, mapping `pdf_url/excel_url/status_history`.
- `lib/data/repositories/estimate_repository_impl.dart` — bridge data/domain.

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
│   │   └── import_estimate_form_modal.dart
│   ├── services/
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
│       ├── estimate_item_card.dart
│       ├── estimate_item_details_dialog.dart
│       ├── estimate_mobile_header.dart
│       ├── estimate_search_field.dart
│       ├── estimate_table_view.dart
│       ├── material_from_receipts_picker.dart
│       ├── vor_approve_dialog.dart
│       ├── vor_card_details.dart
│       ├── vor_create_dialog.dart
│       ├── vor_list_dialog.dart
│       └── vor_tab_table_view.dart
```

---

## 🗄 База данных (Audit)

### Таблицы

#### `public.estimates`
| Колонка | Тип |
|:---|:---|
| id | uuid |
| contract_id | uuid |
| object_id | uuid |
| system | text |
| subsystem | text |
| name | text |
| article | text |
| manufacturer | text |
| unit | text |
| quantity | double precision |
| price | double precision |
| total | double precision |
| created_at | timestamptz |
| updated_at | timestamptz |
| estimate_title | text |
| number | text |
| company_id | uuid |
| position_id | uuid | Уникальный стабильный ID позиции (через все ревизии) |

#### `public.estimate_revisions`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| revision_no | integer | 0 - Original, 1+ - ДС |
| revision_label | text | "Основная", "ДС-1" и т.д. |
| status | text | `draft`, `approved` |
| revision_type | text | `original`, `addendum` |
| based_on_revision_id | uuid | Ссылка на предыдущую версию |

#### `public.estimate_revision_items`
| Колонка | Тип | Назначение |
|:---|:---|:---|
| id | uuid | PK |
| revision_id | uuid | FK на ревизию |
| position_id | uuid | Тот же ID, что в `estimates` |
| change_type | text | `added`, `removed`, `qty_changed`, `price_changed`, `unchanged` |
| quantity, price, total | double | Данные на момент ревизии |

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
| pdf_url | text | путь signed PDF в Storage |
| created_at | timestamptz | дата создания |
| updated_at | timestamptz | дата обновления |
| created_by | uuid | создатель |

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
- `public.vors` — ✅ Включен
- `public.vor_items` — ✅ Включен
- `public.vor_systems` — ✅ Включен
- `public.vor_status_history` — ✅ Включен

### Ключевые политики
- `estimates`: `SELECT/UPDATE/DELETE` учитывают не только `company_id`, но и object-scope пользователя через `profiles.object_ids`, если пользователь не owner компании.
- `vors`: `DELETE` разрешен только для `status = 'draft'`.
- `vors`: обычный `UPDATE` разрешен только для записей в `draft` или `pending`.
- `vor_items`: `INSERT/UPDATE/DELETE` разрешены только если связанный `vors.status = 'draft'`.
- `vor_systems` и `vor_status_history`: доступ ограничен company-scope.

### Индексы и триггеры
- `vors`: `idx_vors_company`, `idx_vors_contract`
- `vor_items`: `idx_vor_items_company`, `idx_vor_items_vor`
- `vor_status_history`: `idx_vor_status_history_vor`
- `vors`: trigger `tr_vors_updated_at` обновляет `updated_at`

### Storage audit
- Bucket: `vor_documents`
- Public: `false`
- `storage.objects` policy для bucket `vor_documents`:
  - `SELECT` для `authenticated`
  - `INSERT` для `authenticated`
  - `DELETE` для `authenticated`

### Аудит статистики таблиц (`pg_stat_user_tables`)
- `estimates`: `n_live_tup = 1515`, `idx_scan = 6108764`, `seq_scan = 46672`
- `vors`: `n_live_tup = 6`, `idx_scan = 908`, `seq_scan = 5799`
- `vor_items`: `n_live_tup = 475`, `idx_scan = 928`, `seq_scan = 2154`
- `vor_status_history`: `n_live_tup = 19`, `idx_scan = 133`, `seq_scan = 988`
- `vor_systems`: `n_live_tup = 18`, `idx_scan = 285`, `seq_scan = 879`

### RPC / SQL функции модуля
1. `populate_vor_items(p_vor_id)` — наполняет `vor_items` фактом работ за период.
2. `get_next_vor_number(p_company_id, p_contract_id)` — возвращает следующий номер ВОР в рамках договора.
3. `set_vor_pdf_document(p_vor_id, p_company_id, p_pdf_url)` — `SECURITY DEFINER` функция для обновления `pdf_url` у уже подписанной ВОР.

---

## ⚙️ Бизнес-логика

### Импорт смет
1. Пользователь выбирает `.xlsx/.xls`.
2. При необходимости старый Excel конвертируется через `xls_to_xlsx`.
3. Парсинг выполняется через `excel_parse`.
4. Сметные позиции сохраняются в `public.estimates` с tenant binding по `company_id`.

### Создание ВОР
1. Пользователь выбирает договор, период и список систем.
2. `createVor(...)` создает заголовок ВОР в `public.vors`.
3. `populateVorItems(...)` сразу наполняет `public.vor_items` фактом из `work_items`.
4. После создания UI инвалидирует `vorsProvider` и `contractVorCompletionProvider`.

### Статусы ВОР
1. Переходы в UI ограничены цепочкой `draft -> pending -> approved`, с возможностью возврата `pending -> draft`.
2. После `approved` обычное редактирование и удаление блокируются политиками и UI.
3. История смен статуса пишется в `public.vor_status_history`.

### Версионирование (LC / ДС)
1. **Инициализация (Baseline):** При первом скачивании шаблона ДС или импорте ДС для старой сметы создается ревизия №0 ("Основная") на базе текущих данных `estimates`.
2. **position_id:** Все строки сметы получают стабильный `position_id`. При добавлении новой строки в Excel (без ID) система генерирует новый UUID.
3. **Draft ДС:** Импорт Excel создает черновик (`draft`) ревизии. Система сравнивает строки с предыдущей `approved` ревизией и проставляет `change_type`.
4. **Сравнение:** Позиции сопоставляются по `position_id`. Если ID нет в базе — `added`. Если ID есть, но нет в файле — `removed`. Если изменились цифры — `qty_changed`/`price_changed`.

### Excel flow
1. Excel ВОР генерируется через Edge Function `generate_vor_v2`.
2. Шаблон LC / ДС генерируется через Edge Function `generate_estimate_addendum_template` с форматированием Times New Roman 12.
3. Если `vors.excel_url` уже заполнен, клиент сначала пытается скачать готовый файл из `vor_documents`.
3. Если скачать не удалось, выполняется повторная серверная генерация.

### Signed PDF flow
1. При подписании пользователь может сразу выбрать signed PDF в `vor_approve_dialog.dart`.
2. Если файл не выбран в момент подписания, позже его можно загрузить из карточки подписанной ВОР.
3. PDF загружается в bucket `vor_documents`.
4. Для signed PDF используется безопасный путь вида `contract_id/vor_id/timestamp_safe_name.pdf`.
5. Обновление `vors.pdf_url` происходит через `set_vor_pdf_document(...)`, потому что обычный `UPDATE` для `approved` запрещен RLS-политикой.
6. После загрузки в `vor_status_history` пишется дополнительная запись с комментарием `Загружен подписанный ВОР PDF`.
7. Открытие PDF выполняется через signed URL и `url_launcher`.

### Очистка файлов
1. Удаление ВОР разрешено только для `draft`.
2. Перед удалением клиент считывает `excel_url` и `pdf_url`.
3. После удаления записи из БД оба файла удаляются из bucket `vor_documents`.

### Таб `ВОР`
1. Колонки `ВОР-*` строятся динамически по списку ВОР договора.
2. Выполнение агрегируется по `vor_items`.
3. Суммарный показатель `ИТОГО` сравнивается с планом сметы.
4. При превышении планового объема строка визуально подсвечивается.

---

## 🔌 Интеграции

### Edge Functions
- `generate_vor_v2` — актуальная генерация Excel ВОР.
- `generate_estimate_addendum_template` — генерация шаблона для ДС (Times New Roman 12, числовой формат).
- `export-vor-materials` — Excel отчет по материалам ВОР.
- `export-cumulative-vor` — cumulative Excel по всем ВОР договора.
- `excel_parse` — парсинг Excel смет.
- `xls_to_xlsx` — конвертация старого формата Excel.

### Edge Functions, найденные в проекте, но не используемые напрямую текущим feature-flow
- `generate_vor_pdf` — присутствует в проекте и используется другими слоями/репозиториями, но не задействован в текущем UI реестра смет/VOR.

### Storage
- bucket `vor_documents`
- Excel и PDF хранятся в одном bucket
- чтение PDF выполняется через signed URL

### Связанные модули
- `contracts` — договорный контекст ВОР
- `objects` — объектная группировка и метаданные
- `materials` — материалы и связанный material report
- `works` — фактические объемы через `work_items`
- `roles` / `company_members` — RBAC

---

## 🗺️ Roadmap
- 🟢 Импорт смет из Excel через Supabase Edge Functions — **Done**
- 🟢 Strict Multi-tenancy и RBAC для owner-таблиц — **Done**
- 🟢 Реестр ВОР с карточками и историей статусов — **Done**
- 🟢 Автоматическая нумерация ВОР — **Done**
- 🟢 Автоматическое наполнение `vor_items` фактом работ — **Done**
- 🟢 Excel export для ВОР — **Done**
- 🟢 Cumulative export по всем ВОР договора — **Done**
- 🟢 Автоматическая очистка Excel/PDF из Storage при удалении draft ВОР — **Done**
- 🟢 Signed PDF upload/view для подписанной ВОР — **Done**
- 🟢 Цветовая индикация наличия PDF в карточке ВОР — **Done**
- 🟢 Отображение автора и даты загрузки PDF в секции файлов — **Done**
- 🟢 Система версионирования смет (LC / ДС) — **Done**
- 🟢 Авто-миграция старых смет в базовую ревизию — **Done**
- 🟢 Серверная генерация шаблонов ДС (Times New Roman 12) — **Done**
- 🟡 Интерфейс просмотра и утверждения ревизий — **Planned**
- 🟡 Backfill старых PDF-загрузок в `vor_status_history` — **Planned**
- 🟡 Массовое редактирование позиций ВОР — **Planned**
- 🔴 Полноценная серверная генерация финального PDF ВОР из текущего UI-потока — **Planned**
