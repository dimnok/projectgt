# Модуль Works (Shifts & Work Plans)
**Дата актуализации:** 18 августа 2026 года — Фильтр сводки месяца по объекту (правая панель, список смен слева не меняется):
- **UI (`MonthDetailsPanel`):** нажатие на строку в блоке «По объектам» выбирает объект. График, KPI (сумма, число смен, специалисты, часы, средняя смена, выработка / чел.) и блок «По системам» пересчитываются только по этому объекту. Повторное нажатие или кнопка «Все объекты» снимает фильтр. Список объектов остаётся полным (выбранная строка подсвечивается). Список смен слева **не** фильтруется.
- **Состояние:** выбор объекта хранится в `State` панели (`_selectedObjectId`). Сбрасывается при уходе со сводки (виджет уничтожается) и при смене месяца (`didUpdateWidget` / новый `ValueKey` по году-месяцу). `null` — все объекты.
- **График:** `LightWork` / `LightWorkModel` получили `objectId`; `getMonthWorksForChart` читает `object_id`; фильтр на клиенте по выбранному ID.
- **KPI суммы/смен:** из `ObjectSummary` выбранного объекта (`get_month_objects_summary` без фильтра — список объектов всегда полный).
- **Системы / часы / специалисты:** RPC `get_month_systems_summary`, `get_month_hours_summary`, `get_month_employees_summary` принимают опциональный `p_object_id uuid DEFAULT NULL`. Клиент передаёт ID через `MonthSummaryQuery`.
- **БД:** миграция `20260818210000_month_summary_object_filter.sql`, применена на сервере (`schema_migrations`: `20260818183230` / `month_summary_object_filter`). Схема таблиц не менялась.
- **Аудит 18.08.2026:** RLS ✅ на `works`, `work_items`, `work_hours`, `work_plans`, `work_plan_blocks`, `work_plan_items`, `telegram_outbox`. Live-строки (approx.): `works` 1011, `work_items` 27351, `work_hours` 9081, `telegram_outbox` 868 (из них `failed` 859, `pending` 9); таблицы планов пустые. MCP `list_edge_functions` в проекте нет — список Edge Functions сверен по `supabase/functions/`.

Предыдущая запись: 2 августа 2026 года — Добавление сотрудника в открытую смену без указания часов:
- **Симптом:** при добавлении сотрудника в открытую смену форма требовала обязательного ввода часов, блокируя сохранение ошибкой «Пожалуйста, введите количество часов». Это противоречило бизнес-сценарию «добавил утром → проставил часы в конце дня» и расходилось с поведением формы открытия смены, где сотрудники создаются с `hours = 0`.
- **Причина:** валидатор поля «Часы» в `WorkHourFormModal` требовал непустое значение. На уровне БД ограничений нет (`work_hours.hours` — `numeric NOT NULL` без CHECK), то есть `0` уже разрешён.
- **Решение (`work_hour_form_modal.dart`):** поле «Часы» стало необязательным. Пустое значение валидатор пропускает, в `_save()` оно парсится как `0` (с учётом запятой как десятичного разделителя). Если значение введено — проверяется, что это корректное неотрицательное число. Обновлён поясняющий подзаголовок и `helperText` поля.
- **Не затронуто:** проверка закрытия смены (`WorkValidationBlock`) — там `hours ≤ 0` по-прежнему блокирует закрытие; массовое заполнение пресетами 8/10/12 ч.
- Миграций/изменений схемы БД нет.

Предыдущая запись: 2 августа 2026 года — Оптимизация загрузки номеров позиций во вкладке «Работы» (устранение «висящих» спиннеров):
- **Симптом:** синие номера позиций в списке работ смены грузились медленно — верхние позиции показывали номер, нижние зависали на `CupertinoActivityIndicator`.
- **Причина:** номер подтягивался из `estimateNotifierProvider` — отдельная тяжёлая загрузка **всех** смет + линейный поиск `firstWhereOrNull` по каждой строке списка (O(n×m) на каждый rebuild) + проверка загрузки через `ref.read` (не реактивно) → внешний `Consumer` не перестраивался после прихода смет, и карточки со спиннером не обновлялись.
- **Решение (JOIN на стороне БД):** номер теперь приезжает **одним запросом** вместе со списком работ через `select('*, estimates!estimate_id(number)')` в `fetchWorkItems` / `fetchWorkItemById`. Поле `number` добавлено в `WorkItem` и `WorkItemModel`; в модели помечено `@JsonKey(includeFromJson: false, includeToJson: false)` — **не хранится** в `work_items` и не уходит в БД при insert/update (существует только в памяти после загрузки). Источник номера — `estimates.number` (text).
- **UI `WorkDetailsPanel`:** удалены спиннеры номеров, геттер `_areEstimatesLoading`, per-item `ref.watch(estimateNotifierProvider)` (лишняя подписка на каждую строку), загрузка всех смет при инициализации (нужна была только ради номеров). Номер берётся напрямую из `item.number ?? '-'`.
- **Поведение:** номер всегда «живой» — берётся из сметы при каждом чтении. Удаление сметы заблокировано FK `ON DELETE RESTRICT` (`shift_items_estimate_id_fkey`), поэтому сценарий «номер `-`» практически невозможен. Историческая заморозка номеров в `work_items` **не** делается (бизнес-решение открыто).
- Миграций/изменений схемы БД нет.

Предыдущая запись: 2 августа 2026 года — Защита агрегатов смены от гонки при параллельных изменениях:
- **БД**: `update_work_aggregates` берёт row-level блокировку строки `works` (`SELECT ... FOR UPDATE`) перед пересчётом `total_amount` / `own_total_amount` / `items_count` / `employees_count`. Параллельные вставки/удаления в `work_items` / `work_hours` сериализуются по смене — последний пересчёт всегда видит все закоммиченные строки. Миграция `20260802130000_work_aggregates_race_safe.sql` (+ разовый пересчёт всех смен).
- **App, вкладка «Данные»**: число сотрудников считается из живого списка `work_hours` (уже загружается), кэш `work.employees_count` — только fallback. Мгновенно отражает добавление/удаление сотрудника без перезагрузки смены и лишних запросов.
- **App, открытие смены**: вместо N параллельных `Future.wait` вставок — один пакетный `updateBulk` (одна транзакция → триггер срабатывает корректно, меньше запросов).
- Симптом: вкладка «Сотрудники» показывала 6, вкладка «Данные» — 5 (устаревший кэш `employees_count`).

Предыдущая запись: 2 августа 2026 года — Большая чистка мёртвого кода (аудит по всему `lib/` + `dart analyze` + тесты):
- Удалён файл-заглушка `screens/work_item_form_modal.dart` (deprecated typedef, 0 импортов).
- `WorkItemRepository`: удалены `getAllWorkItems()` и одиночный `addWorkItem()` (+ datasource/repository-impl + `WorkItemsNotifier.add`/`getAllWorkItems`); живой путь — пакетный `addWorkItems`.
- `WorkHourRepository`: удалён `fetchWorkHoursByEmployeeAndPeriod()` (+ datasource interface/impl).
- Провайдеры: удалены `workItemsNotifierProvider`, `WorkItemsNotifier.seed`, `MonthGroupsNotifier.openedByListFilter`.
- Удалены 10 неиспользуемых констант `WorksStrings` и поле `WorkFormScreen.parentContext`.
- `WorkBlockState`: удалены `withData`, `copy`, `copyFrom` (0 вызовов).
- DI (`lib/core/di/providers.dart`): удалены осиротевшие `workHourDataSourceProvider` / `workHourRepositoryProvider` (модуль использует свои из `repositories_providers.dart`).
- Планы (legacy `lib/domain`/`lib/data`): удалён `GetWorkPlanUseCase` (+ провайдер); из `WorkPlanRepository`/`WorkPlanDataSource` убраны `getWorkPlan`, `getUserWorkPlans`, `getWorkPlanDetails`, `getWorkPlansByObject`, `getWorkPlansBySystem`, `getWorkPlansStatistics`, `workPlanExists`.
- `WorkPlanNotifier`: удалены `loadWorkPlanDetails`, `createWorkPlan`, `updateWorkPlan`, `clearSelectedWorkPlan`, `clearError` и поля create/update/get usecases (форма вызывает `createWorkPlanUseCaseProvider`/`updateWorkPlanUseCaseProvider` напрямую; в notifier остались `loadWorkPlans` + `deleteWorkPlan`).

Предыдущая запись: 28 июля 2026 года — Удалён мёртвый контур «материалы смены»: код (entity/model/repository/provider/форма) и таблица `work_materials` (миграция `20260728061000_drop_work_materials`, применена на сервере). Вкладки деталей смены: **Данные / Работы / Сотрудники**. Проверка на macOS: открытие смены и переключение вкладок без ошибок.

Предыдущая запись: 11 мая 2026 года — Оптимизация доставки Telegram: клиент вызывает воркер асинхронно (без ожидания); Edge Function `process_telegram_outbox` переведена на параллельную обработку задач (`Promise.all`); подтвержден FIFO порядок в RPC `claim_telegram_outbox`.

Предыдущая запись: 10 мая 2026 года — очередь доставки Telegram по сменам: таблица `telegram_outbox`, RPC `enqueue_telegram_outbox_opening`, триггер при закрытии смены, Edge Function `process_telegram_outbox` (ретраи); клиент после постановки в очередь вызывает воркер; опциональный cron с секретом `OUTBOX_WORKER_SECRET`.

Предыдущая запись: 16 апреля 2026 года — Presentation-слой: мобильный вид модуля выделен в отдельный экран `WorksListMobileScreen`; общие действия вынесены в миксин `WorksScreenActionsMixin`.

## Важное замечание о структуре данных
> **Внимание:**
> - Модуль полностью переведен на модель **Multi-tenancy**. Таблицы `works`, `work_items`, `work_hours`, `work_plans`, `work_plan_blocks`, `work_plan_items` изолированы через `company_id`.
> - Таблица `work_materials` **удалена** (28.07.2026). Не путать с модулем **Materials** и модалкой `NewMaterialModal` (создание позиции **сметы** из формы работ).
> - Все операции выполняются через Supabase (REST, Realtime, Storage). RLS завязан на членство в компании (`public.get_my_company_ids()`) и **доступные пользователю объекты** (`profile.object_ids`).
> - Критические зависимости: справочники `objects`, `employees`, `estimates`, `profiles`, опционально `contractors`; Storage bucket `works`.

## Детальное описание модуля
Модуль **Works** объединяет ежедневные смены (Shifts) и планы работ (Work Plans). Меню: **«Работы»** (`/works`). Планы переключаются внутри того же экрана (отдельного пункта drawer нет).

1. **Смены (Works/Shifts):** учёт факта — работы из сметы, часы сотрудников, утреннее/вечернее фото, закрытие по чек-листу.
2. **Планы работ (Work Plans):** план на дату/объект: блоки (система/участок/этаж) → позиции сметы с плановым объёмом.

**Ключевые функции:**
- ✅ Список смен и планов с группировкой по месяцам; фильтр «Все / Мои» (desktop по умолчанию — Все, mobile — Мои).
- ✅ Сводка месяца: клик по объекту в блоке «По объектам» фильтрует график, KPI и системы; список смен слева не зависит от выбора.
- ✅ Desktop master-detail; mobile — отдельные routes деталей смены и месяца.
- ✅ Фотофиксация: утро (обязательно при открытии), вечер (обязательно для закрытия).
- ✅ Вкладки смены: **Данные** | **Работы** | **Сотрудники** (часы; массовые пресеты 8/10/12).
- ✅ Строка работы: участок → этаж → система → подсистема → смета; подрядчик и `specialists_count`.
- ✅ Планы: создание / просмотр / правка (desktop) / удаление; блоки с ответственными и работниками.
- ✅ Валидация: нельзя открыть вторую open-смену; закрытие только при выполнении чек-листа.
- ✅ Уведомления: `AppSnackBar`; FCM админам; очередь Telegram (`telegram_outbox`).
- ✅ Модалки: `MobileBottomSheetContent` / `DesktopDialogContent`; поля — Design System (`GT*`).

## Зависимости
**Таблицы модуля (Owner):**
- `works`, `work_items`, `work_hours` (смены)
- `work_plans`, `work_plan_blocks`, `work_plan_items` (планы)
- `telegram_outbox` (очередь уведомлений по сменам)

**Таблицы других модулей (Usage):**
- `objects`, `profiles` — объект и открывший смену.
- `employees` — часы в смене; ответственные/работники в планах.
- `estimates` — позиции работ и планов.
- `contractors` — опционально на `work_items.contractor_id`.

## Слой Presentation
**Экраны и виджеты:**
- `WorksMasterDetailScreen` — точка входа; desktop → `WorksMasterDetailDesktopView`, mobile → `WorksListMobileScreen`.
- `WorksScreenActionsMixin` — `showOpenShiftModal`, create/edit/delete плана, delete смены.
- `WorkDetailsPanel` — детали смены: вкладки Данные / Работы / Сотрудники (`WorkDataTab`, список `WorkItem` (номер позиции уже в `item.number` — без отдельной загрузки смет), `WorkHoursTab`).
- `WorkDetailsScreen` — полноэкранные детали (mobile route `/works/:workId`).
- `WorkValidationBlock` — чек-лист закрытия смены.
- `MonthDetailsPanel` / `MonthDetailsMobileScreen` — KPI и график месяца. Клик по объекту в «По объектам» задаёт фильтр сводки (локальный `_selectedObjectId`); сброс — повторный клик, `GTTextButton` «Все объекты», смена месяца или уход с панели. Список смен слева не затрагивается.
- `WorkPlanDetailsScreen`, `WorkPlanFormModal` / `WorkPlanFormContent` — планы (`features/work_plans`).
- `NewMaterialModal` — **не** материалы смены: добавление позиции в **смету** из формы работ.
- Design System: `GTTextField`, `GTDropdown`, `GTPrimaryButton` / `GTSecondaryButton` / `GTTextButton`, `AppSnackBar`.

**Провайдеры (Riverpod):**
- `workRepositoryProvider`, `workItemRepositoryProvider`, `workHourRepositoryProvider`.
- `worksProvider`, `workItemsProvider`, `workHoursProvider`.
- `monthGroupsProvider`, `monthChartDataProvider`, сводки месяца: `objectsSummaryProvider`, `systemsSummaryProvider` / `monthTotalHoursProvider` / `monthTotalEmployeesProvider` (`MonthSummaryQuery`: месяц + опциональный `objectId`).
- `hasOpenWorkProvider`, `myOpenWorkIdProvider`.
- `workPlanMonthGroupsProvider` + `workPlanNotifierProvider` (core DI).

## Слой Domain/Data
- **Entities (смены):** `Work`, `LightWork` (поля `id`, `date`, `objectId`, `totalAmount`, `employeesCount` — для графика месяца), `WorkItem` (поле `number` — номер позиции из сметы, подтягивается JOIN'ом при чтении, не хранится в БД), `WorkHour`, summary DTO в `work_summaries.dart`.
- **Repositories:** `WorkRepository`, `WorkItemRepository`, `WorkHourRepository` (+ impl в `data/`). DI — `presentation/providers/repositories_providers.dart` (единственная точка; дубль в `core/di` удалён 02.08.2026).
- **DataSources:** `WorkDataSourceImpl`, `WorkItemDataSourceImpl` (`fetchWorkItems` / `fetchWorkItemById` — `select('*, estimates!estimate_id(number)')`, номер достаётся из вложенного объекта JOIN'а и проставляется в модель через `copyWith`), `WorkHourDataSourceImpl`.
- **Планы:** domain/data в глобальных `lib/domain`, `lib/data` (legacy layout); UI в `lib/features/work_plans/`. После чистки 02.08.2026: usecases — только `GetWorkPlansUseCase`, `CreateWorkPlanUseCase`, `UpdateWorkPlanUseCase`, `DeleteWorkPlanUseCase`; `WorkPlanNotifier` — `loadWorkPlans` + `deleteWorkPlan` (create/update идут из формы через usecase-провайдеры напрямую).
- Агрегаты смены (`total_amount`, `own_total_amount`, `items_count`, `employees_count`) считает **БД** (триггеры на `work_items` / `work_hours`); клиент при update смены их не перезаписывает. Функция `update_work_aggregates` блокирует строку `works` (`FOR UPDATE`) — защита от гонки при параллельных вставках/удалениях. Вкладка «Данные» берёт число сотрудников из живого списка `work_hours`, кэш — fallback.

## Дерево файлов
```
lib/features/
├── works/
│   ├── data/
│   │   ├── datasources/   # work, work_item, work_hour
│   │   ├── models/        # Work*, LightWork, MonthGroup
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/      # Work, WorkItem, WorkHour, LightWork, summaries
│   │   └── repositories/
│   └── presentation/
│       ├── providers/     # works, items, hours, month_groups, summaries
│       ├── screens/
│       │   ├── works_master_detail_screen.dart
│       │   ├── works_list_mobile_screen.dart
│       │   ├── works_screen_actions_mixin.dart
│       │   ├── work_details_screen.dart / work_details_panel.dart
│       │   ├── work_form_screen.dart, work_item_form_improved.dart
│       │   ├── new_material_modal.dart   # смета, не work_materials
│       │   ├── tabs/ work_data_tab.dart, work_hours_tab.dart
│       │   └── desktop/ works_master_detail_desktop_view.dart
│       ├── widgets/       # month_details_panel, validation, stats, lists, photos, charts
│       └── utils/         # works_strings, photo_upload_helper
└── work_plans/
    ├── data/models/       # WorkPlanMonthGroup
    └── presentation/      # details, form, blocks, providers
```

## База данных (Audit)

### 1. `works` (заголовок смены)
| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| id | uuid | NO | PK |
| date | date | NO | Дата смены |
| object_id | uuid | NO | FK → `objects.id` |
| opened_by | uuid | NO | FK → `profiles.id` |
| status | text | NO | `open` / `closed` |
| photo_url | text | YES | Утреннее фото |
| evening_photo_url | text | YES | Вечернее фото |
| total_amount | numeric | YES | Сумма всех строк (триггер) |
| own_total_amount | numeric | NO | Сумма строк без подрядчика (триггер) |
| items_count | integer | YES | Число `work_items` |
| employees_count | integer | YES | Уникальные сотрудники по часам |
| telegram_message_id | integer | YES | Id утреннего сообщения Telegram |
| company_id | uuid | NO | FK → `companies.id` |
| created_at / updated_at | timestamptz | NO | Аудит |

**RLS:** ✅ Включён (Strict + политики для timesheet read).

### 2. `work_items`
| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| id | uuid | NO | PK |
| work_id | uuid | NO | FK → `works.id` CASCADE |
| section / floor / system / subsystem | text | NO | Каскад места/системы |
| estimate_id | uuid | NO | FK → `estimates.id` (`ON DELETE RESTRICT` — смету с работами удалить нельзя) |
| name / unit | text | NO | Денормализация из сметы |
| quantity | numeric | NO | Объём |
| price / total | float8 | YES | Цена и сумма строки |
| contractor_id | uuid | YES | NULL — собственное выполнение |
| specialists_count | integer | YES | Специалисты подрядчика |
| contract_act_id | uuid | YES | Связь с актом договора |
| company_id | uuid | NO | Tenant |

> **Номер позиции (`number`)** — **не колонка** `work_items`. Берётся из `estimates.number` через LEFT JOIN `estimates!estimate_id(number)` в `fetchWorkItems` / `fetchWorkItemById` (один запрос). В `WorkItem`/`WorkItemModel` поле `number` существует только в памяти (`includeFromJson/toJson: false` в модели) — не пишется в БД. Если смета не найдена (фактически невозможно из-за `ON DELETE RESTRICT`) — показывается `-`.

**RLS:** ✅ через `check_work_access(work_id)`.

### 3. `work_hours`
| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| id | uuid | NO | PK |
| work_id | uuid | NO | FK → `works.id` |
| employee_id | uuid | NO | FK → `employees.id` |
| hours | numeric | NO | Часы |
| comment | text | YES | Комментарий |
| company_id | uuid | NO | Tenant |

**RLS:** ✅ через `check_work_access(work_id)`.

### 4. `telegram_outbox`
| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| id | uuid | NO | PK |
| company_id / work_id | uuid | NO | Контекст |
| kind | text | NO | `work_opening_telegram` / `work_close_telegram` |
| payload | jsonb | NO | Для opening: `worker_names` |
| status | text | NO | `pending` / `processing` / `sent` / `failed` |
| attempts / max_attempts | integer | NO | Ретраи |
| next_run_at | timestamptz | NO | Backoff |
| last_error | text | YES | Текст ошибки воркера |
| idempotency_key | text | NO | `{work_id}:{kind}` |
| created_at / updated_at | timestamptz | NO | Аудит |

**RLS:** ✅ SELECT по компании / праву `works` read; insert — SECURITY DEFINER / триггер.

### 5. Планы: `work_plans`, `work_plan_blocks`, `work_plan_items`
- План: `date`, `object_id`, `created_by`, `company_id`.
- Блок: `system`, `section`, `floor`, `responsible_id`, `worker_ids[]`.
- Позиция: `estimate_id`, `name`, `unit`, `price`, `planned_quantity`, `actual_quantity` (автоиз смен — в roadmap).

**RLS:** ✅ company-scoped.

### Удалено
- **`work_materials`** — DROP TABLE (28.07.2026), файл миграции `supabase/migrations/20260728061000_drop_work_materials.sql`.

### Триггеры (ключевые)
- `work_items` / `work_hours` → пересчёт агрегатов смены через `update_work_aggregates` (с row-level блокировкой `works` `FOR UPDATE` — защита от гонки при параллельных изменениях).
- `works` UPDATE → `works_enqueue_telegram_close` при закрытии.

### RPC (клиент / статистика)
- `get_months_summary(p_company_id, p_opened_by)` — заголовки месяцев для списка слева (фильтр «Мои смены»).
- `get_month_objects_summary(p_month, p_company_id)` — список объектов сводки (без `p_object_id`; UI фильтрует по клику локально).
- `get_month_systems_summary(p_month, p_company_id, p_object_id DEFAULT NULL)`
- `get_month_hours_summary(p_month, p_company_id, p_object_id DEFAULT NULL)`
- `get_month_employees_summary(p_month, p_company_id, p_object_id DEFAULT NULL)`
- `enqueue_telegram_outbox_opening`, `check_work_access`
- смежные: `calculate_contract_works`, search/export work_items (модуль Export)

```sql
-- Фильтр сводки: NULL = все объекты (как до 18.08.2026)
AND (p_object_id IS NULL OR w.object_id = p_object_id)
```

## Бизнес-логика
1. **Жизненный цикл смены:** Open → Items + Hours + Photos → Validation → Closed.
2. **Добавление сотрудника:** часы можно не указывать — запись создаётся с `hours = 0` (сценарий: добавили утром, проставили часы позже). Часы проставляются через редактирование записи или массовые пресеты 8/10/12 ч.
3. **Закрытие запрещено, если:** нет работ; нет сотрудников; quantity ≤ 0; hours ≤ 0; нет вечернего фото; уже closed.
4. **Доступ:** объекты из `profile.object_ids`; Owner компании — все объекты.
5. **Удаление:** Owner — любые; пользователь — свои open + RBAC `works.delete` / `work_plans.delete`.
6. **Итоги:** `work_items.total` на клиенте; header-агрегаты — триггеры БД.
7. **Сводка месяца по объекту:** выбор объекта в «По объектам» не меняет список смен. График фильтруется по `LightWork.objectId`; сумма и число смен — из выбранного `ObjectSummary`; системы/часы/специалисты — RPC с `p_object_id`. Сброс: повторный клик или «Все объекты».

## Интеграции
**Edge Functions:**
- `send_admin_work_event` — FCM open/close (см. [admin_notifications.md](../admin_notifications.md)).
- `process_telegram_outbox` — воркер очереди.
- `send_work_opening_report_to_telegram`, `update_work_opening_report_to_telegram`, `send_work_report_to_telegram`.
- `export-work-search-pto`, `export-work-search-all`.

**Поток Telegram:** после часов → RPC `enqueue_telegram_outbox_opening` + `kickProcessTelegramOutbox` (async). При `closed` — триггер `work_close_telegram`.

**Прочее:** Storage bucket `works`; ФОТ/табель читают часы смен; договоры — `calculate_contract_works` / `contract_act_id`.

## Roadmap
- ✅ **Завершено (18.08.2026, фильтр сводки по объекту):** клик по объекту в `MonthDetailsPanel` фильтрует график, KPI и системы. Список смен слева не меняется. RPC `get_month_systems_summary` / `get_month_hours_summary` / `get_month_employees_summary` — опциональный `p_object_id`. Миграция `20260818210000_month_summary_object_filter.sql` применена на сервере.
- ✅ **Завершено (02.08.2026, часы при добавлении сотрудника):** поле «Часы» в `WorkHourFormModal` стало необязательным — пустое значение сохраняется как `0`. Валидатор пропускает пустое поле, при вводе проверяет неотрицательное число. Обновлён поясняющий текст. Проверка закрытия смены (`hours ≤ 0`) не затронута. Миграций нет.
- ✅ **Завершено (02.08.2026, номера позиций):** устранение «висящих» спиннеров номеров во вкладке «Работы». Номер теперь приезжает одним запросом через LEFT JOIN `estimates!estimate_id(number)` в `fetchWorkItems`/`fetchWorkItemById`; поле `number` добавлено в `WorkItem`/`WorkItemModel` (в модели не сериализуется в БД). В `WorkDetailsPanel` удалены: спиннеры номеров, `_areEstimatesLoading`, per-item `ref.watch(estimateNotifierProvider)`, загрузка всех смет при инициализации. Миграций нет. `dart analyze` чист.
- ✅ **Завершено (02.08.2026, агрегаты):** защита `update_work_aggregates` от гонки (`FOR UPDATE` строки `works`); вкладка «Данные» считает сотрудников из live `work_hours`; открытие смены — один пакетный insert вместо N параллельных. Разовый пересчёт всех смен.
- ✅ **Завершено (02.08.2026):** чистка мёртвого кода по аудиту: удалены файл `work_item_form_modal.dart`, неиспользуемые методы репозиториев/datasource (`getAllWorkItems`, `addWorkItem`, `fetchWorkHoursByEmployeeAndPeriod`, 7 методов `WorkPlanRepository`/`WorkPlanDataSource`), `GetWorkPlanUseCase`, осиротевший DI work_hours в `core/di`, мёртвые провайдеры/константы/поля. `dart analyze` чист, тесты фич зелёные.
- ✅ **Завершено (28.07.2026):** удаление неиспользуемого контура `work_materials` (код + таблица).
- ✅ **Завершено (28.06.2026):** FCM push при open/close, включая PWA.
- ✅ **Завершено (16.04.2026):** mobile/desktop split, `WorksScreenActionsMixin`.
- ✅ Редактирование/удаление планов на desktop; склонения специалистов; унификация модалок; оптимизация `MonthDetailsPanel`.
- 🔴 **Приоритет:** синхронизация `actual_quantity` в планах из данных смен.
- 🟡 Интеграция стоимости работ с финансами.
- 🟡 Мониторинг/очистка `telegram_outbox` (live 18.08.2026: `failed` 859, `pending` 9).
