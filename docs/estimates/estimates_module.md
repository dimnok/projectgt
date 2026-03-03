# Модуль Сметы (Estimates)

**Дата актуализации:** 3 марта 2026 года (удаление накопительной ведомости, оптимизация ВОР)
**Статус:** Актуально (Strict Multi-tenancy, RBAC, VOR Automated Engine, Cloud Storage Integration, VOR Tab Over-limit Highlighting, Auto-refresh TTL 5m)

---

## ⚠️ Важное замечание
- **Владение:** Модуль полностью владеет таблицей `public.estimates` и `public.vors`.
- **Зависимости:** Критически зависит от модуля «Объекты» (фильтрация по `object_ids`) и «Склад» (расчет остатков материалов через `material_aliases`).
- **Безопасность:** Доступ к данным реализован через `SECURITY DEFINER` RPC-функции. Для ВОР реализована интеграция с Supabase Storage через Edge Functions с использованием `service_role` для записи и `authenticated` политик для чтения.
- **UI/UX:** Все модальные окна на Desktop переведены на единый стандарт `DesktopDialogContent.show()`. Экспорт общего списка смет в Excel удален в пользу более точных отчетов по ВОР.
- **Refresh:** Модуль подключен к глобальной системе обновления при фокусе (TTL 5 минут).

---

## 📂 Описание модуля
Модуль **Сметы** отвечает за управление стоимостными и количественными показателями строительных работ. Он объединяет плановые показатели (из импортированных смет) с фактическим выполнением.

**Ключевые функции:**
- **Импорт из Excel:** Поддержка форматов `.xls` и `.xlsx` с автоматическим парсимгом через Edge Functions.
- **Global On Focus Refresh:** Автоматическое фоновое обновление данных при возврате в приложение, если с последнего обновления прошло более 5 минут.
- **Strict Access Control:** Сотрудники видят только те сметы, объекты которых закреплены за их профилем.
- **Визуальное выделение превышений:** Работы, превышающие сметные лимиты, выделяются оранжевым фоном и акцентированным текстом.
- **Интеграция со Складом:** Автоматическое отображение количества полученных и оставшихся материалов.
- **Гибридный расчет выполнения:** Данные агрегируются из таблицы `work_items` в реальном времени.
- **Третий таб в деталях сметы (`ВОР`):** Отдельная таблица с динамическими колонками `ВОР-*`. Реализовано **визуальное выделение красным цветом** строк, у которых суммарное количество по всем ВОР (`ИТОГО`) превышает плановое сметное количество (`Кол-во`).
- **Сортировка ВОР по номеру:** Колонки `ВОР-*` в табе строятся по возрастанию номера ведомости.
- **Экспорт отчетов:** Поддерживается генерация Excel для ведомостей ВОР, отчетов по материалам и **накопительной ведомости ВОР**. Накопительный экспорт включает два листа (Объемы и Финансы), динамические колонки `ВОР-*`, итоговые строки по сметам, группировку и шрифтовое оформление (Times New Roman). Общий экспорт списка смет отключен.

---

## 🧱 Архитектура и структура
Модуль следует принципам **Clean Architecture**.

### Слой Presentation (UI)
- `lib/features/estimates/presentation/screens/estimates_list_screen.dart` — Реестр смет. Точка регистрации `RefreshTarget` для модуля. При возврате в фокус инвалидирует `estimateGroupsProvider`.
- `lib/features/estimates/presentation/screens/estimate_desktop_view.dart` — Основной экран.
- `lib/features/estimates/presentation/widgets/vor_list_dialog.dart` — Реестр ведомостей ВОР с карточной системой отображения, эффектами парения и логикой «одна открытая панель».
- `lib/features/estimates/presentation/widgets/vor_card_details.dart` — Детальная информация о ВОР. Включает секцию «Файлы» с возможностью мгновенного скачивания сгенерированных документов.
- `lib/features/estimates/presentation/widgets/vor_create_dialog.dart` — Пошаговый мастер создания ВОР. На этапе «Далее» инициирует фоновую генерацию и сохранение файла в Storage.
- `lib/features/estimates/presentation/services/vor_export_service.dart` — Сервис управления файлами конкретных ВОР.
- `lib/features/estimates/presentation/services/vor_cumulative_export_service.dart` — Сервис для генерации накопительного Excel отчета (Объемы + Финансы) по всем ВОР договора.
- `lib/features/estimates/presentation/widgets/vor_tab_table_view.dart` — Отдельная таблица для таба `ВОР` в деталях сметы. Динамически строит колонки `ВОР-*`, считает `ИТОГО`, синхронизирует горизонтальный скролл заголовка/тела и поддерживает поиск по позициям.
- `lib/features/estimates/presentation/providers/estimate_providers.dart` — Провайдеры Riverpod. Реализована логика очистки Storage при удалении ВОР в методе `deleteVor`.

### Слой Domain (Бизнес-логика)
- `lib/domain/entities/estimate.dart` — Основная сущность сметной позиции.

### Слой Data (Инфраструктура)
- `lib/data/datasources/estimate_data_source.dart` — Вызов RPC-функций Supabase.

---

## 🔗 Зависимости

### Таблицы модуля (owner)
- `public.estimates`
- `public.vors`
- `public.vor_items`
- `public.vor_status_history`

### Таблицы других модулей (usage)
- `public.contracts` (связь по `contract_id`)
- `public.objects` (связь через договор/объект для фильтрации и именования файлов)
- `public.work_items` (источник фактического выполнения)
- `public.company_members`, `public.profiles` (RBAC и object-scope доступ)
- `storage.objects`, `storage.buckets` (хранение документов ВОР)

---

## 🌲 Дерево файлов
```text
lib/features/estimates/
└── presentation/
    ├── mixins/
    │   └── estimate_actions_mixin.dart
    ├── providers/
    │   └── estimate_providers.dart
    ├── services/
    │   └── vor_export_service.dart
    ├── screens/
    │   ├── estimate_desktop_view.dart
    │   ├── estimate_details_screen.dart
    │   ├── estimate_form_screen.dart
    │   ├── estimate_mobile_view.dart
    │   ├── estimates_list_screen.dart
    │   └── import_estimate_form_modal.dart
    ├── utils/
    │   └── estimate_sorter.dart
    └── widgets/
        ├── acts_table_view.dart
        ├── estimate_completion_history_panel.dart
        ├── estimate_details_modal.dart
        ├── estimate_edit_dialog.dart
        ├── estimate_item_card.dart
        ├── estimate_item_details_dialog.dart
        ├── estimate_table_view.dart
        ├── vor_approve_dialog.dart
        ├── vor_card_details.dart
        ├── vor_create_dialog.dart
        ├── vor_list_dialog.dart
        ├── vor_tab_table_view.dart
        └── material_from_receipts_picker.dart
```

---

## 🗄 База данных (Audit)

### Таблица `public.estimates`
| Колонка | Тип | Описание |
|:---|:---|:---|
| id | UUID (PK) | Уникальный идентификатор позиции |
| company_id | UUID (FK) | Привязка к компании (Multi-tenancy) |
| number | TEXT | Порядковый номер (всегда "д-X" для новых позиций) |
| quantity | DOUBLE PRECISION | Плановый объем |
| price | DOUBLE PRECISION | Цена за единицу |
| total | DOUBLE PRECISION | Итоговая сумма (quantity * price) |

### Таблица `public.vors` (Заголовки ВОР)
| Колонка | Тип | Описание |
|:---|:---|:---|
| id | UUID (PK) | Уникальный идентификатор ведомости |
| company_id | UUID (FK) | Привязка к компании (Multi-tenancy) |
| contract_id | UUID (FK) | Ссылка на договор |
| number | TEXT | Порядковый номер (например, "ВОР-001") |
| status | vor_status | Статус (draft, pending, approved) |
| excel_url | TEXT | Путь к сгенерированному Excel файлу в Storage (`vor_documents`) |
| pdf_url | TEXT | Путь к подписанному скан-копии PDF |

### Хранилище (Supabase Storage)
- **Бакет:** `vor_documents`
- **Структура путей:** `[object_name_slug]/[vor_number_slug]_[timestamp].xlsx`
- **Транслитерация:** Имена папок и файлов автоматически переводятся в латиницу (slugify) для совместимости и читаемости.

### Таблица `public.vor_items` (Позиции ВОР)
| Колонка | Тип | Описание |
|:---|:---|:---|
| id | UUID (PK) | Уникальный идентификатор позиции |
| company_id | UUID (FK) | Привязка к компании (Multi-tenancy) |
| vor_id | UUID (FK) | Ссылка на родительский ВОР |
| estimate_item_id | UUID (FK) | Ссылка на позицию сметы (null для новых работ) |
| name | TEXT | Наименование (для extra-позиций без ссылки на estimates) |
| unit | TEXT | Единица измерения (для extra-позиций) |
| quantity | DOUBLE PRECISION | Фактически выполненный объем за период |
| is_extra | BOOLEAN | Флаг превышения сметы или новой работы |
| sort_order | INTEGER | Порядок отображения строки в ведомости |

### Таблица `public.vor_status_history` (История изменений ВОР)
| Колонка | Тип | Описание |
|:---|:---|:---|
| id | UUID (PK) | Уникальный идентификатор записи |
| company_id | UUID (FK) | Привязка к компании (Multi-tenancy) |
| vor_id | UUID (FK) | Ссылка на ВОР |
| status | vor_status | Статус, на который перешли |
| user_id | UUID (FK) | Кто совершил действие |
| comment | TEXT | Причина изменения (например, при возврате в черновик) |

### RLS по таблицам модуля
- `public.estimates` — ✅ Включен (`rowsecurity = true`)
- `public.vors` — ✅ Включен
- `public.vor_items` — ✅ Включен
- `public.vor_status_history` — ✅ Включен

Ключевые ограничения политик:
- `vors` удаляется только в статусе `draft`, UPDATE ограничен статусами `draft|pending`.
- `vor_items` изменяются только пока родительский `vors.status = 'draft'`.
- Все политики привязаны к `company_id IN get_my_company_ids()` и проверке `check_permission(..., 'estimates', ...)`.

### Индексы (ключевые)
- `estimates`: `idx_estimates_grouping`, `idx_estimates_sort`, `idx_estimates_filters`, `idx_estimates_contract_id`, `idx_estimates_company_id`.
- `vors`: `idx_vors_company`, `idx_vors_contract`.
- `vor_items`: `idx_vor_items_company`, `idx_vor_items_vor`.
- `vor_status_history`: `idx_vor_status_history_vor`.

### Триггеры
- `estimates`: `trg_sync_work_items_on_estimate_update` (`AFTER UPDATE`).
- `vors`: `tr_vors_updated_at` (`BEFORE UPDATE`).

### Ключевые RPC-функции (Логика ВОР)
1.  **`populate_vor_items(vor_id)`**: «Движок» ВОР. Автоматически наполняет ведомость фактически выполненными работами за период, сопоставляет их со сметой и помечает превышения (`is_extra`).
2.  **`get_next_vor_number(company_id, contract_id)`**: Генерирует следующий порядковый номер ВОР в рамках договора (ВОР-001, ВОР-002 и т.д.).
3.  **`get_vor_material_report`**: Возвращает свод по списанию материалов для экспорта из таба ВОР.

---

### Бизнес-логика формирования ВОР
1.  **Выбор периода и систем:** Пользователь указывает диапазон дат и одну или несколько инженерных систем.
2.  **Генерация данных:** RPC-функция `populate_vor_items` собирает все выполненные работы из журналов, сопоставляет их со сметой и выявляет превышения.
3.  **Облачная генерация (Multi-sheet):** Edge Function `generate_vor_v2` создает Excel-файл. Если выбрано несколько систем, для каждой создается отдельный лист с полной шапкой и подписями.
4.  **Хранение:** Файл сохраняется в Storage один раз при создании. Путь записывается в `vors.excel_url`.
5.  **Очистка:** При удалении записи ВОР соответствующий файл в Storage удаляется автоматически для экономии места.

---

## 🔌 Интеграции
- **Edge Functions (используются модулем):**
  - `generate_vor_v2` — генерация Excel ВОР.
  - `export-vor-materials` — генерация Excel по материалам ВОР.
  - `export-cumulative-vor` — накопительная генерация всех ВОР договора.
  - `excel_parse` / `xls_to_xlsx` — импорт смет из Excel.
- **Supabase Storage:**
  - Bucket `vor_documents` (`public = false`).
  - Политики `storage.objects` для `vor_documents`: чтение/загрузка/удаление для `authenticated`.
- **Связанные модули:**
  - `contracts/objects` — контекст договора и объекта.
  - `materials` — списание материалов по ВОР.
  - `roles` — RBAC-права на действия `read/create/update/delete`.

---

## 🗺️ Roadmap
- 🟢 Строгий контроль доступа (RLS + RPC) — **Done**
- 🟢 Интеграция остатков материалов — **Done**
- 🟢 Реестр ведомостей ВОР (UI + анимации + логика раскрытия) — **Done**
- 🟢 Структура БД для ВОР (vors, vor_items, status_history) — **Done**
- 🟢 Multi-tenancy и RLS для ВОР — **Done**
- 🟢 Интерактивная смена статусов ВОР с валидацией переходов — **Done**
- 🟢 Автоматическая нумерация ВОР и «движок» наполнения данными — **Done**
- 🟢 Интеграция облачного хранения и генерации Excel — **Done**
- 🟢 Автоматическая очистка Storage при удалении записей — **Done**
- 🟢 Транслитерация путей в Storage — **Done**
- 🟢 Разделение систем по листам в Excel — **Done**
- 🟢 Отдельный таб `ВОР` в деталях сметы с динамическими колонками `ВОР-*` — **Done**
- 🟢 Сортировка колонок `ВОР-*` по возрастанию номера — **Done**
- 🟢 UX-правки таба `ВОР`: увеличена колонка `Наименование`, уменьшены и центрированы `Кол-во/ВОР/ИТОГО` — **Done**
- 🟢 Накопительный экспорт всех ВОР договора в Excel (Объемы + Финансы, группировка, итоги) — **Done**
- 🟡 Просмотр состава работ ВОР в интерфейсе — **In Progress**
- 🟡 Массовое редактирование позиций — **Planned**
- 🔴 Генерация PDF отчетов по выполнению — **Planned**
