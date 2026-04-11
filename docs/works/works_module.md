# Модуль Works (Shifts & Work Plans)
**Дата актуализации:** 12 апреля 2026 года — в `work_items` добавлено поле `specialists_count` (число специалистов подрядчика по строке; см. миграцию `20260412120000_work_items_specialists_count.sql`).

## Важное замечание о структуре данных
> **Внимание:**
> - Модуль полностью переведен на модель **Multi-tenancy**. Таблицы `works`, `work_items`, `work_materials`, `work_hours`, `work_plans`, `work_plan_blocks`, `work_plan_items` изолированы через `company_id`.
> - Все операции выполняются через Supabase (REST, Realtime, Storage). RLS-политики завязаны на членство в компании (`public.get_my_company_ids()`) и **доступные пользователю объекты** (`profile.object_ids`).
> - Критические зависимости: справочники `objects`, `employees`, `estimates`, `profiles`, Supabase Storage bucket `works`.

## Детальное описание модуля
Модуль **Works** объединяет функционал ежедневных смен (Shifts) и долгосрочного планирования (Work Plans).

1.  **Смены (Works/Shifts):** Обеспечивают учёт фактически выполненных работ, материалов и трудозатрат по факту.
2.  **Планы работ (Work Plans):** Позволяют формировать детальный план по системам и участкам на будущие периоды.

**Ключевые функции:**
- ✅ Загрузка списка смен и планов с фильтрацией по компании и объектам.
- ✅ Детальный просмотр смены/плана с разбивкой по работам.
- ✅ Фотофиксация для смен (утренние/вечерние фото).
- ✅ Многоуровневое планирование: План → Блоки (Системы/Участки) → Работы.
- ✅ **Интеграция планов:** Планы работ полностью доступны в десктопной версии `WorksMasterDetailScreen` с поддержкой Master-Detail.
- ✅ **Управление планами на Desktop:** Добавлены функции редактирования и удаления планов напрямую из AppBar в десктопном режиме.
- ✅ **Валидация смен:** Кнопки "Открыть смену" и "Составить план" всегда видимы. При попытке открытия новой смены выполняется асинхронная проверка наличия уже открытой смены.
- ✅ **Система уведомлений:** Полный переход на `AppSnackBar` для отображения тостов и системных сообщений.
- ✅ **Стандартные модальные окна:** Использование `MobileBottomSheetContent` и `DesktopDialogContent` для всех форм модуля.
- ✅ **Оптимизация списков:** В списках планов (Desktop/Mobile) отображается количество уникальных специалистов с корректным склонением (1 специалист, 2 специалиста, 5 специалистов).
- ✅ **Оптимизация (10.01.2026):** Использование `RepaintBoundary` для тяжелых графиков и `const` виджетов для KPI в деталях месяца.

## Зависимости
**Таблицы модуля (Owner):** 
- `works`, `work_items`, `work_materials`, `work_hours` (Смены)
- `work_plans`, `work_plan_blocks`, `work_plan_items` (Планы)

**Таблицы других модулей (Usage):**
- `objects`, `profiles` — контекст, владелец, объект.
- `employees` — сотрудники в сменах и ответственные в планах.
- `estimates` — сметные позиции.

## Слой Presentation
**Экраны и виджеты:**
- `WorksMasterDetailScreen` — основной экран смен и планов (адаптивный мастер-детейл).
- `WorkDetailsScreen` — экран деталей смены для мобильных устройств.
- `WorkPlanDetailsScreen` — экран деталей плана работ (используется как правая панель на десктопе).
- `DesktopMonthWorkPlansList` — оптимизированный список планов для десктопа (показывает количество специалистов вместо блоков).
- `WorkDetailsPanel` — центральный компонент управления данными смены.
- `MonthDetailsPanel` — панель статистики за месяц с графиками и KPI.
- `MobileBottomSheetContent` / `DesktopDialogContent` — базовые обертки для модальных окон.
- `GTTextField` — используется для всех полей ввода, включая компактные инлайн-редакторы.
- `GTDropdown` — выпадающие списки для выбора объектов, сотрудников и материалов.
- `GTPrimaryButton`, `GTSecondaryButton`, `GTTextButton` — стандартные кнопки действий.

**Провайдеры (Riverpod) и Логика:**
- `worksProvider`, `workItemsProvider`, `workHoursProvider`.
- `monthGroupsProvider` — управление группами смен.
- `workPlanMonthGroupsProvider` — управление группами планов.
- `pluralization` — логика склонения существительных (специалисты, планы) реализована внутри виджетов списка.
- `MonthGroupController` (Core) — общая логика управления раскрывающимися списками по месяцам (DRY).
- `ModalUtils` — утилиты вызова унифицированных модальных окон модуля.

## Слой Domain/Data
- **Entities:** `Work`, `WorkItem`, `WorkHour`, `WorkPlan`, `WorkPlanBlock`, `WorkPlanItem`.
- **Repositories:** `WorkRepository`, `WorkPlanRepository`.
- **DataSources:** `WorkDataSourceImpl`, `WorkPlanDataSourceImpl`.
- **Models:** Модели на базе `BaseMonthGroup` (Core) для унификации группировки.

## Дерево файлов
```
lib/features/
├── works/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/ (MonthGroup)
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   └── presentation/
│       ├── providers/ (works, items, hours, month_groups)
│       ├── screens/
│       └── widgets/ (month_details_panel, charts)
└── work_plans/
    ├── data/
    │   └── models/ (WorkPlanMonthGroup)
    ├── domain/
    └── presentation/
        ├── providers/ (work_plan_month_groups)
        ├── screens/
        └── widgets/
```

## База данных (Audit)

### Таблицы Смен (Works)
#### 1. `works` (Заголовок смены)
| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| id | uuid | NO | PK |
| date | date | NO | Дата смены |
| object_id | uuid | NO | FK → `objects.id` |
| status | text | NO | 'open' / 'closed' |
| opened_by | uuid | NO | FK → `profiles.id` |
| total_amount | numeric | YES | Денатурализованная сумма работ |
| company_id | uuid | NO | FK → `companies.id` |

#### 2. `work_items` (Выполненные работы)
| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| id | uuid | NO | PK |
| work_id | uuid | NO | FK → `works.id` (CASCADE) |
| estimate_id | uuid | NO | FK → `estimates.id` |
| quantity | numeric | NO | Объем |
| total | float8 | YES | Сумма (quantity * price) |
| company_id | uuid | NO | FK → `companies.id` |
| contractor_id | uuid | YES | FK → `contractors.id`; NULL — собственное выполнение |
| specialists_count | integer | YES | Число специалистов подрядчика на строке; NULL — не задано |

### RLS-политики
- ✅ **Включён** для всех таблиц модуля.
- **Strict Mode:** Используются строгие политики (SELECT, INSERT, UPDATE, DELETE), которые проверяют:
    1. Изоляцию по `company_id`.
    2. Права доступа через `check_permission`.
    3. Доступ к объекту: Пользователь должен быть либо **Владельцем компании** (Owner), либо `object_id` смены должен входить в его `profile.object_ids`.
- Дочерние таблицы (`work_hours`, `work_items`, `work_materials`) защищены через проверку доступа к родительской смене (`public.check_work_access`).
- **RPC функции:** Функции статистики (`get_months_summary`, `get_month_employees_summary` и др.) выполняют явную фильтрацию по разрешенным объектам пользователя.

## Бизнес-логика
1.  **Жизненный цикл смены:** Open → (Add Items/Hours/Photos) → Validation → Closed.
2.  **Доступ к данным:** Пользователь видит смены только по тем объектам, которые привязаны к его профилю. Владелец компании видит все смены компании.
3.  **Удаление смен/планов:** 
    - **Владелец компании (Owner):** имеет полное право на удаление любых смен и планов.
    - **Обычный пользователь:** может удалять только свои открытые смены или планы (при наличии соответствующих прав в RBAC и доступа к объекту).
3.  **Склонения в UI:** При отображении списков используется логика pluralization для корректного вывода количества специалистов.
4.  **Расчеты:** Суммы по работам (`total`) рассчитываются на стороне клиента и дублируются в `works.total_amount` для быстрой загрузки списков.

## Интеграции
**Edge Functions (Supabase):**
- `send_admin_work_event` — уведомление о событиях смены.
- `send_work_report_to_telegram` — ежедневный отчет по закрытой смене.
- `send_work_opening_report_to_telegram` — уведомление об открытии смены.
- `export-work-search-pto` — экспорт данных для ПТО.
- `export-work-search-all` — полный экспорт данных.

## Roadmap
- ✅ **Завершено:** Редактирование и удаление планов в десктопной версии `WorksMasterDetailScreen`.
- ✅ **Завершено:** Переход на отображение количества специалистов в списках планов с корректным склонением.
- ✅ **Завершено:** Унификация модальных окон через `MobileBottomSheetContent` и `DesktopDialogContent`.
- ✅ **Завершено:** Оптимизация производительности `MonthDetailsPanel`.
- 🔴 **Приоритет:** Синхронизация `actual_quantity` в Планах на основе данных из Смен.
- 🟡 **Планы:** Интеграция с финансовым модулем для учета стоимости работ.
