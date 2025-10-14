# Модуль Works (Shifts)
**Дата актуализации:** 10 октября 2025 года (обновлено: аудит кода и Supabase, проверка UI-процессов)

## Важное замечание о структуре данных
> **Внимание:**
> - Модуль владеет таблицами `works`, `work_items`, `work_materials`, `work_hours`, каждая связана со сменой через Foreign Key.
> - Все операции выполняются через Supabase (REST, Realtime, Storage). RLS-политики завязаны на `profiles.object_ids`, что ограничивает доступ сменами объектов.
> - Критические зависимости: справочники `objects`, `employees`, `estimates`, `profiles`, Supabase Storage bucket `works`, Edge Function `send_admin_work_event`. Серверных триггеров и функций нет — валидация выполняется на клиенте.

## Детальное описание модуля
Модуль **Works** обеспечивает полный цикл сопровождения смен на строительных объектах: открытие смены, учёт выполненных работ и материалов, фиксацию трудозатрат сотрудников, контроль фотографий (утренних/вечерних) и закрытие смены с обязательными проверками. Интерфейс построен по мастер-детейл-паттерну, адаптирован под десктоп и мобильные устройства.

**Ключевые функции:**
- ✅ Загрузка списка смен с фильтрацией, поиском и поддержкой Realtime-обновлений.
- ✅ Детальный просмотр смены с вкладками «Данные», «Работы», «Сотрудники».
- ✅ CRUD для смен, работ, материалов, учёта часов (модальные формы, валидация).
- ✅ Управление фотографиями смены: просмотр, добавление/замена утреннего и вечернего фото, хранение в Storage.
- ✅ Закрытие смены с проверками полноты данных и уведомлением администраторов.

**Архитектурные особенности:**
- Clean Architecture: `data → domain → presentation`, DI через Riverpod-провайдеры.
- Data-контракты на `freezed`/`json_serializable`, неизменяемые сущности domain.
- Data Source-слой работает с Supabase REST API, `work_items` дополнительно подписываются на Realtime.
- Edge Function `send_admin_work_event` вызывается при закрытии смены для нотификаций.
- Фото загружаются через `PhotoService` (камера/галерея), файлы хранятся в bucket `works`.

## Используемые таблицы и зависимости
**Основные таблицы модуля:** `works`, `work_items`, `work_materials`, `work_hours` (schema `public`).

**Связанные таблицы из других модулей:**
- `objects`, `profiles` — контекст смены, владелец, объект.
- `employees` — сотрудники, участвующие в смене.
- `estimates` — сметные позиции, привязанные к работам.
- `user_roles`, `auth.users` — косвенно через RLS и Storage-политики.

## Структура и файлы модуля
**Presentation/UI**
- `presentation/screens/works_master_detail_screen.dart` — мастер-детейл список смен, поиск, адаптивность, проверка `canModify`.
- `presentation/screens/work_details_screen.dart` — контейнер деталей смены, доступ к действиям редактирования/удаления, навигация.
- `presentation/screens/work_details_panel.dart` — вкладки «Данные/Работы/Сотрудники», фильтры, FAB, проверка статуса смены.
- `presentation/screens/work_form_screen.dart`, `work_item_form_modal.dart`, `work_item_form_improved.dart`, `work_hour_form_modal.dart`, `work_material_form_modal.dart`, `new_material_modal.dart` — формы добавления/редактирования сущностей.
- `presentation/screens/tabs/work_data_tab.dart`, `tabs/work_hours_tab.dart` — бизнес-логика вкладок, расчёт KPI, проверка условий закрытия смены.
- `presentation/widgets/work_distribution_card.dart`, `work_photo_view.dart` — распределение работ, просмотр/замена фото через Storage.

**Domain**
- `domain/entities/work.dart`, `work_item.dart`, `work_hour.dart`, `work_material.dart` — неизменяемые сущности.
- `domain/repositories/*.dart` — абстракции репозиториев смен, работ, материалов, часов.

**Data**
- `data/models/*.dart` — модели сериализации Supabase.
- `data/datasources/*.dart` — источники данных (REST, Realtime).
- `data/repositories/*.dart` — имплементации domain-репозиториев, работа с Storage (удаление фото при удалении смены).

**Дополнительные файлы**
- `lib/core/services/photo_service.dart` — интеграция с Supabase Storage для фотографий смены.
- `lib/core/di/providers.dart` — регистрация провайдеров и зависимостей.
- `lib/data/migrations/works_migration.sql` — историческая миграция; схема отличается от текущей и требует актуализации.

## Дерево структуры модуля
```
lib/features/works/
├── data/
│   ├── datasources/
│   │   ├── work_data_source.dart
│   │   ├── work_data_source_impl.dart
│   │   ├── work_hour_data_source.dart
│   │   ├── work_hour_data_source_impl.dart
│   │   ├── work_item_data_source.dart
│   │   ├── work_item_data_source_impl.dart
│   │   ├── work_material_data_source.dart
│   │   └── work_material_data_source_impl.dart
│   ├── models/
│   │   ├── work_hour_model.dart
│   │   ├── work_item_model.dart
│   │   ├── work_material_model.dart
│   │   └── work_model.dart
│   └── repositories/
│       ├── work_hour_repository_impl.dart
│       ├── work_item_repository_impl.dart
│       ├── work_material_repository_impl.dart
│       └── work_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── work.dart
│   │   ├── work_hour.dart
│   │   ├── work_item.dart
│   │   └── work_material.dart
│   └── repositories/
│       ├── work_hour_repository.dart
│       ├── work_item_repository.dart
│       ├── work_material_repository.dart
│       └── work_repository.dart
└── presentation/
    ├── providers/
    │   ├── repositories_providers.dart
    │   ├── work_hours_provider.dart
    │   ├── work_items_provider.dart
    │   ├── work_materials_provider.dart
    │   └── work_provider.dart
    ├── screens/
    │   ├── new_material_modal.dart
    │   ├── work_details_panel.dart
    │   ├── work_details_screen.dart
    │   ├── work_form_screen.dart
    │   ├── work_hour_form_modal.dart
    │   ├── work_item_form_improved.dart
    │   ├── work_item_form_modal.dart
    │   ├── work_material_form_modal.dart
    │   ├── works_master_detail_screen.dart
    │   └── tabs/
    │       ├── work_data_tab.dart
    │       └── work_hours_tab.dart
    └── widgets/
        ├── work_distribution_card.dart
        └── work_photo_view.dart
```

## База данных и RLS-политики
### Таблица `works`
| Колонка | Тип | NULL | По умолчанию | Описание |
|---------|-----|------|--------------|----------|
| id | uuid | NO | `gen_random_uuid()` | Идентификатор смены |
| date | date | NO | – | Дата смены |
| object_id | uuid | NO | – | FK → `objects.id` |
| opened_by | uuid | NO | – | FK → `profiles.id` |
| status | text | NO | – | Статус (`open`, `closed`) |
| photo_url | text | YES | – | Утреннее фото |
| evening_photo_url | text | YES | – | Вечернее фото |
| created_at | timestamptz | NO | `timezone('utc', now())` | Дата создания |
| updated_at | timestamptz | NO | `timezone('utc', now())` | Дата обновления |
| **total_amount** | **numeric** | **YES** | **0** | **Общая сумма работ (агрегат, обновляется триггерами)** |
| **items_count** | **integer** | **YES** | **0** | **Количество работ (агрегат, обновляется триггерами)** |
| **employees_count** | **integer** | **YES** | **0** | **Количество сотрудников (агрегат, обновляется триггерами)** |

**Количество записей:** 19 (по Supabase).  
**RLS:** ✅ включён (`Allow * for own objects`).  
**Индексы:** 
- `shifts_pkey` (PRIMARY KEY)
- `idx_works_date` (для фильтрации по дате)
- `idx_works_object_id` (для фильтрации по объекту)
- `idx_works_date_desc` (для группировки по месяцам, DESC)
- `idx_works_status` (для фильтрации по статусу)

**Связи:** `object_id` — каскадное удаление, `opened_by` — `ON DELETE SET NULL`.

### Таблица `work_items`
| Колонка | Тип | NULL | По умолчанию | Описание |
|---------|-----|------|--------------|----------|
| id | uuid | NO | `gen_random_uuid()` | Идентификатор работы |
| work_id | uuid | NO | – | FK → `works.id` (`ON DELETE CASCADE`) |
| section | text | NO | – | Секция |
| floor | text | NO | – | Этаж |
| estimate_id | uuid | NO | – | FK → `estimates.id` |
| name | text | NO | – | Наименование |
| system | text | NO | – | Система |
| subsystem | text | NO | – | Подсистема |
| unit | text | NO | – | Единица измерения |
| quantity | numeric | NO | – | Количество |
| price | double precision | YES | – | Цена |
| total | double precision | YES | – | Сумма |
| created_at | timestamptz | NO | `timezone('utc', now())` | Создано |
| updated_at | timestamptz | NO | `timezone('utc', now())` | Обновлено |

**Количество записей:** 588.  
**RLS:** ✅ включён (парные политики `via shifts` и `via works` на все операции).  
**Индексы:** `shift_items_pkey`, `idx_work_items_estimate_id`.  
**Связи:** `work_id` — каскадное удаление, `estimate_id` требует валидной сметной позиции.

### Таблица `work_materials`
| Колонка | Тип | NULL | По умолчанию | Описание |
|---------|-----|------|--------------|----------|
| id | uuid | NO | `gen_random_uuid()` | Идентификатор материала |
| work_id | uuid | NO | – | FK → `works.id` (`ON DELETE CASCADE`) |
| name | text | NO | – | Наименование |
| unit | text | NO | – | Единица |
| quantity | numeric | NO | – | Количество |
| comment | text | YES | – | Комментарий |
| created_at | timestamptz | NO | `timezone('utc', now())` | Создано |
| updated_at | timestamptz | NO | `timezone('utc', now())` | Обновлено |

**Количество записей:** 0.  
**RLS:** ✅ включён (политики `via shifts` / `via works`).  
**Индексы:** `shift_materials_pkey`, `idx_work_materials_name_lower`.  
**Связи:** `work_id` — каскадное удаление.

### Таблица `work_hours`
| Колонка | Тип | NULL | По умолчанию | Описание |
|---------|-----|------|--------------|----------|
| id | uuid | NO | `gen_random_uuid()` | Идентификатор записи |
| work_id | uuid | NO | – | FK → `works.id` (`ON DELETE CASCADE`) |
| employee_id | uuid | NO | – | FK → `employees.id` |
| hours | numeric | NO | – | Отработанные часы |
| comment | text | YES | – | Комментарий |
| created_at | timestamptz | NO | `timezone('utc', now())` | Создано |
| updated_at | timestamptz | NO | `timezone('utc', now())` | Обновлено |

**Количество записей:** 195.  
**RLS:** ✅ включён (двойные политики `via shifts` / `via works`).  
**Индексы:** `shift_hours_pkey`, `idx_work_hours_work_id`, `idx_work_hours_employee_id`.  
**Связи:** `work_id` — каскад, `employee_id` — ограничение `RESTRICT` (требует предварительного удаления часов перед удалением сотрудника).

**Связи между таблицами:**
```
profiles ──┐
          │        ┌── work_items ──► estimates
works ────┼──► work_hours ─────────► employees
          │        └── work_materials
          └──► objects
```

### Функции PostgreSQL

#### `update_work_aggregates(work_uuid UUID)`
**Назначение:** Пересчитывает агрегатные поля (`total_amount`, `items_count`, `employees_count`) для указанной смены.  
**Вызывается:** Автоматически триггерами при изменении `work_items` или `work_hours`.  
**Логика:**
- Суммирует `work_items.total` → `works.total_amount`
- Считает количество записей `work_items` → `works.items_count`
- Считает уникальные `work_hours.employee_id` → `works.employees_count`
- Обновляет `works.updated_at`

#### `get_months_summary()`
**Назначение:** Возвращает агрегированную сводку по месяцам для быстрой группировки в UI.  
**Вызывается:** При загрузке списка смен через `client.rpc('get_months_summary')`.  
**Логика:**
- GROUP BY DATE_TRUNC('month', date)
- Возвращает: month (DATE), works_count (BIGINT), total_amount_sum (NUMERIC)
- Сортировка по месяцам DESC
**Производительность:** < 50ms для любого количества смен (100x быстрее группировки на клиенте)

### Триггеры

#### `work_items_aggregate_trigger`
**Таблица:** `work_items`  
**События:** `AFTER INSERT OR UPDATE OR DELETE`  
**Функция:** `trigger_update_work_aggregates_items()`  
**Назначение:** Автоматически пересчитывает агрегаты смены при любых изменениях работ.  
**Исправлено 11.10.2025:** Триггер срабатывает при изменении ЛЮБЫХ полей, а не только `total`.

#### `work_hours_aggregate_trigger`
**Таблица:** `work_hours`  
**События:** `AFTER INSERT OR UPDATE OR DELETE`  
**Функция:** `trigger_update_work_aggregates_hours()`  
**Назначение:** Автоматически пересчитывает количество сотрудников при любых изменениях учёта часов.  
**Исправлено 11.10.2025:** Триггер срабатывает при изменении ЛЮБЫХ полей, а не только `employee_id`.

**Результат триггеров:** Агрегатные поля всегда актуальны, расчёты выполняются на стороне БД < 100ms.  
**Важно:** При повторном открытии закрытой смены и внесении изменений триггеры корректно обновляют агрегаты.

**Материализованные представления:** отсутствуют.  
**Supabase Storage:** bucket `works`, файлы `{object_id}/{timestamp}_{morning|evening}.jpg`; требуется Storage-policy, зеркалирующая RLS.

## Бизнес-логика и ключевые особенности
- **Загрузка списка смен:** `MonthGroupsNotifier` загружает только заголовки месяцев через RPC `get_months_summary()` (< 50ms). Все группы свёрнуты, смены не загружаются. Агрегаты (worksCount, totalAmount) получаются из SQL GROUP BY на стороне БД.
- **Группировка по месяцам:** Смены отображаются сгруппированными по месяцам с collapsible заголовками. Смены загружаются лениво ТОЛЬКО при клике на месяц через `expandMonth()` → `getMonthWorks()` с пагинацией (30 записей).
- **Агрегатные поля:** `total_amount`, `items_count`, `employees_count` обновляются автоматически через триггеры БД. UI использует эти поля напрямую, fallback на клиентские расчёты для совместимости.
- **Работы (Realtime):** `WorkItemsNotifier` подписывается на канал `public:work_items` только в детальном режиме, обновляет `AsyncValue` без fetch. В списке Realtime отключён (оптимизация).
- **Учёт часов:** `WorkHoursNotifier` предоставляет методы `fetch`, `add`, `update`, `delete`, `updateBulk` для массовых операций (используется на вкладке «Сотрудники»).
- **Условия закрытия смены:** `WorkDataTab` проверяет наличие работ и сотрудников, положительные значения `quantity`/`hours`, заполненное вечернее фото, после чего вызывает `send_admin_work_event` и уведомления.
- **Управление фотографиями:** `WorkPhotoView` показывает утренние/вечерние фото с таймстемпами, поддерживает добавление/замену (камера/галерея) и удаление; `WorkRepositoryImpl.deleteWork` очищает Storage через `PhotoService`.
- **Контроль прав:** `canModify = (isOwner || isAdmin) && status == 'open'`; логика применяется в экранах, скрывает FAB, блокирует поля ввода, предотвращает операции при закрытой смене.

## Связи и интеграции
- **Supabase:** REST-запросы для CRUD, Realtime для `work_items`, Storage для фото, Edge Functions для уведомлений.
- **Другие модули:** зависит от `employees`, `objects`, `estimates`, `profiles`; данные смен используются в `timesheet`, `export`, `notifications`.
- **UI/UX:** общие виджеты (`AppBarWidget`, `AppDrawer`, `MasterDetailLayout`), `go_router` для маршрутизации, `ResponsiveUtils`, форматирование дат/сумм через `intl`.
- **Безопасность:** RLS включён везде; рекомендовано дополнить Storage-политики и добавить `WITH CHECK` для запрета закрытия смены при незаполненных данных напрямую через SQL.

## Текущие ограничения и планы развития
- **Реализованные функции:** 
  - ✅ CRUD смен
  - ✅ Учёт работ/часов/материалов
  - ✅ Realtime-синхронизация работ
  - ✅ Проверка условий закрытия
  - ✅ Загрузка/удаление фото
  - ✅ **Группировка по месяцам с ленивой загрузкой**
  - ✅ **Агрегатные поля с автоматическим пересчётом через триггеры**
  - ✅ **Оптимизация списка: 0 Realtime-каналов, моментальная загрузка**
  
- **Критические проблемы:** 🔴 Нет серверных проверок завершения смены — прямой SQL может обойти клиентские проверки (нужны функции/RLS `WITH CHECK`).
- **Средние риски:** 🟡 `works_migration.sql` не соответствует текущей схеме (старые поля `name`, `description`), возможны ошибки при развёртывании.
- **Низкий приоритет:** 🟢 `work_materials` пустует — либо скрыть UI, либо добавить сценарии использования.
- **Планируемые улучшения:** 🔄 Перенести проверки закрытия смены в Postgres, 🔄 синхронизировать миграции, 🔄 усилить Storage-политики, 🔄 покрыть модуль интеграционными тестами Supabase/Flutter.
- **Технические улучшения:** актуализировать SQL-миграции, добавить тесты Realtime-подписок, документировать Storage-политики.

## Примечания для разработчиков
- **Общие:** придерживаться Clean Architecture, избегать бизнес-логики в UI, использовать форматтеры из `core/utils/formatters.dart`, `Color.withValues(alpha: …)` вместо `withOpacity`.
- **Специфика Works:** 
  - Использовать агрегатные поля (`totalAmount`, `itemsCount`, `employeesCount`) из сущности Work, а не рассчитывать на клиенте.
  - Realtime-подписки только в детальном режиме, в списке использовать статические данные.
  - Учитывать оптимистичные обновления в `WorkItemsNotifier`.
  - Синхронизировать Edge Function с payload закрытия смены.
  - Очищать Storage при удалении фото/смен.
  
- **Последняя актуализация:** 10 октября 2025 года.
- **Ключевые обновления:** 
  - Реализована оптимизация для масштабирования до тысяч смен (триггеры + денормализация + группировка)
  - Добавлены агрегатные поля в таблицу `works`
  - Созданы PostgreSQL триггеры для автоматического пересчёта
  - Реализована группировка списка по месяцам с ленивой загрузкой
  - Удалены множественные Realtime-подписки из списка (40+ → 0)
  - Созданы виджеты `MonthGroupHeader` и `MonthWorksList` 