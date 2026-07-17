# Структура интерфейса модуля ФОТ

**Дата актуализации:** 17 июля 2026 года

> **Изменения 17.07.2026 (правка 3):** Клик по ФИО сотрудника в таблице ФОТ открывает карточку сотрудника (`EmployeeDetailsModal` / `EmployeesMobileEmployeeDetailsSheet`), как в модуле «Табель». Доступ по праву `employees` / `read`. Контекстное меню по правому клику сохранено.

> **Изменения 17.07.2026 (правка 2):** Контекстное меню строки ФОТ (Премия / Штраф / Выплата / Детали) теперь вызывается **только правой кнопкой мыши** (`onRowSecondaryTapDown`). Левый клик по строке больше не открывает меню (`onRowTapDown` удалён). Затронут файл `payroll_table_view.dart`.

> **Изменения 17.07.2026:** Актуализированы ссылки на файлы Presentation-слоя. Удалены из документации пути к несуществующим `payroll_search_action.dart` и `payroll_filter_helpers.dart`; добавлена таблица миграции «устаревший компонент → актуальный файл». Дополнены провайдеры баланса в справочнике Riverpod.

> **Изменения 16.07.2026 (вечер):** Stale-while-revalidate на вкладке ФОТ — таблица не исчезает при пересчёте; `PayrollRefreshingAmount` (Cupertino) в денежных ячейках; централизованная инвалидация `invalidatePayrollFotTableDependents` / `invalidatePayrollPayoutDependents`.

> **Изменения 16.07.2026:** Панель управления унифицирована с модулем «Табель». Вкладки, период, поиск, объекты и действия собраны в **одну строку** внутри `MobileAtmosphereMainSurface`. Удалены устаревшие `GTMonthPicker`, `GTObjectPicker`, `PayrollSearchAction`, `PayrollFilterHelpers` (см. таблицу миграции ниже).

---

## Общая компоновка экрана

Экран `PayrollListScreen` повторяет визуальный язык модуля «Табель»:

| Зона | Виджет / файл | Назначение |
|------|---------------|------------|
| Фон | `MobileAtmosphereBackdrop` | Градиент атмосферы |
| Шапка (chrome) | `payroll_list_screen.dart` | Меню, заголовок, экспорт, тема; на телефоне — поиск |
| Карточка контента | `MobileAtmosphereMainSurface` | Единая панель фильтров + тело вкладки |
| Тело вкладки | `IndexedStack` | ФОТ / Премии / Штрафы / Выплаты |

### Шапка экрана (`PayrollListScreen`)

- **Заголовок:** статичный текст «Фонд оплаты труда» (период **не** дублируется в шапке).
- **Desktop / планшет (не mobile-list):** меню · заголовок · `PayrollExportAction` · переключатель темы.
- **Телефон (`EmployeesLayoutUtils.useEmployeesMobileList`):** меню · `PayrollMobileSearchField` · экспорт · тема.
- **Экспорт:** `PayrollExportAction` скрыт на вкладке «Выплаты» (`_selectedTabIndex == 3`). Право: `payroll` / `export`.

Поиск синхронизируется через `payrollSearchQueryProvider` (`payroll_filter_providers.dart`).

---

## Панель фильтров (единая строка)

**Файл:** `lib/features/fot/presentation/widgets/payroll_filters_toolbar.dart`  
**Точка входа:** `PayrollFiltersToolbar` — рендерится **внутри** `MobileAtmosphereMainSurface`, над `IndexedStack`.

### Состав строки (слева направо)

| # | Виджет | Файл | Desktop | Mobile-list |
|---|--------|------|---------|-------------|
| 1 | Вкладки | `PayrollTabSegment` | ✓ | ✓ (гориз. скролл кластера) |
| 2 | Период | `PayrollCompactMonthSwitcher` | ✓ | ✓ |
| 3 | Поиск ФИО | `PayrollToolbarSearch` | ✓ | — (поиск в шапке) |
| 4 | Объекты | `PayrollObjectsBarDropdown` | ✓ | ✓ |
| 5 | Spacer | — | ✓ | — |
| 6 | Действия | `PayrollTabToolbarActions` | ✓ | ✓ (закреплены справа) |

Ширина поля поиска рассчитывается функцией `payrollToolbarSearchWidth()` с учётом вкладок, переключателя месяца и правого блока.

### Геометрия панели

Общие константы — `PayrollToolbarMetrics` (`payroll_toolbar_metrics.dart`):

| Параметр | Значение |
|----------|----------|
| Высота контролов | `34` px |
| Радиус капсулы | `18` px |
| Отступ трека сегментов | `2` px |
| Шрифт сегментов | `11.5` pt, `FontWeight.w600` |

Переиспользуемые примитивы:

- `PayrollToolbarSegmentTrack` — оболочка сегментированного контрола.
- `PayrollToolbarSegmentChip` — один сегмент (вкладка / статус).
- `PayrollToolbarTextButton` — кнопки «Добавить» / «Импорт» той же высоты.

### Вкладки (`PayrollTabSegment`)

Индексы: `0` ФОТ · `1` Премии · `2` Штрафы · `3` Выплаты.  
Состояние: локальный `setState(_selectedTabIndex)` в `PayrollListScreen`.

### Период (`PayrollCompactMonthSwitcher`)

- Источник: `payrollFilterProvider` (`selectedYear`, `selectedMonth`).
- Навигация: стрелки «предыдущий / следующий месяц» (`setYearAndMonth`).
- Подпись: `formatMonthYear` → «Июль-2026» (пробел заменяется на дефис).
- Внешняя ширина: `kPayrollMonthSwitcherOuterWidth = 184`.

### Объекты (`PayrollObjectsBarDropdown`)

- Данные: `availableObjectsForPayrollProvider` → `objectProvider`.
- Мультивыбор через `MenuAnchor`; коммит: `payrollFilterProvider.notifier.setSelectedObjects`.
- Подписи: «Все объекты» / имя объекта / «Объекты · N».
- На вкладке **«Выплаты»** (`selectedTabIndex == 3`) фильтр **отключён** (`enabled: false`).

### Правый блок (`PayrollTabToolbarActions`)

| Вкладка | Содержимое | Право |
|---------|------------|-------|
| ФОТ | `PayrollEmployeeStatusFilterSegment` (Все / Работает / Уволен) | — |
| Премии | `PayrollToolbarTextButton` «Добавить» | `payroll` / `create` |
| Штрафы | `PayrollToolbarTextButton` «Добавить» | `payroll` / `create` |
| Выплаты | «Импорт из Excel» + «Добавить» | `payroll` / `create` |

Фильтр статуса: `payrollEmployeeStatusFilterProvider` (`payroll_employee_status_filter_segment.dart`).  
Функции `filterEmployeesByPayrollStatus` / `filterPayrollsByEmployeeStatus` применяются в `PayrollTableWidget`.

### Поиск по ФИО

| Платформа | Виджет | Провайдер |
|-----------|--------|-----------|
| Телефон | `PayrollMobileSearchField` (шапка) | `payrollSearchQueryProvider` |
| Desktop / планшет | `PayrollToolbarSearch` (панель) | `payrollSearchQueryProvider` |

**Утилиты фильтрации по ФИО** (`payroll_name_search_filters.dart`):

| Функция | Назначение |
|---------|------------|
| `filterPayrollsByEmployeeName` | Строки расчёта ФОТ |
| `filterTransactionsByEmployeeName` | Премии и штрафы |
| `filterPayoutsByEmployeeName` | Выплаты |
| `filterEmployeesBySearchQuery` | Список сотрудников (экспорт, массовые выплаты) |

**Фильтр статуса сотрудника** (`payroll_employee_status_filter_segment.dart`):

| Функция / провайдер | Назначение |
|---------------------|------------|
| `payrollEmployeeStatusFilterProvider` | Все / Работает / Уволен |
| `filterEmployeesByPayrollStatus` | Список сотрудников по статусу |
| `filterPayrollsByEmployeeStatus` | Строки ФОТ по статусу |

Состояние периода и объектов — `payrollFilterProvider` (`payroll_filter_providers.dart`).

---

## Содержимое вкладок

Виджеты таблиц **не** содержат собственных панелей фильтров — только данные и empty/loading states.

### 1. Вкладка «ФОТ»

| Слой | Виджет | Описание |
|------|--------|----------|
| Экран | `PayrollListScreen` | `skipLoadingOnReload: true` — при пересчёте RPC таблица не заменяется спиннером |
| Обёртка | `PayrollTableWidget` | FIFO, фильтр статуса, флаги `isPayrollsRefreshing` / `isSettlementRefreshing` |
| Desktop / Tablet | `PayrollTableView` | `GTAdaptiveTable` |
| Mobile | `PayrollMobileView` + `PayrollCard` | Карточки без внешних `Card` |
| Индикатор сумм | `PayrollRefreshingAmount` | Cupertino-спиннер вместо суммы при фоновом пересчёте |

**Колонки (desktop):** Сотрудник, Часы, Ставка, База, Премии, Штрафы, Суточные, К выплате, Выплаты, Остаток, Баланс.

**Особенности:**

- **Состав списка:** RPC + сотрудники «в штате / с балансом» без начислений (`_groupPayrolls` в `payroll_table_view.dart`).
- **Чекбоксы:** `PayrollGridCheckbox`, `payrollGridSelectedEmployeeIdsProvider`.
- **Контекстное меню строки:** открывается **правой кнопкой мыши** (ПКМ) по строке сотрудника — пункты Премия, Штраф, Выплата, Детали (PDF). Левый клик меню не вызывает.
- **Клик по ФИО:** открывает карточку сотрудника (`EmployeeDetailsModal` на desktop, `EmployeesMobileEmployeeDetailsSheet` на mobile) — аналогично модулю «Табель». Доступ по праву `employees` / `read`; без права имя не кликабельно. При наведении мыши имя плавно увеличивается (`_HoverableEmployeeName`, `AnimatedScale`, масштаб 1.08, центр масштабирования — левый край `Alignment.centerLeft`, чтобы не перекрывать чекбокс).
- **Итоги:** строка «ИТОГО», пересчёт при поиске.
- **Loading (первый вход):** полноэкранный «Загрузка данных ФОТ...» (`filteredPayrollsProvider`, `PayrollListScreen`).
- **Loading (пересчёт после операции):** таблица и список сотрудников **остаются видимыми**; предыдущие суммы сохраняются до ответа RPC/FIFO; в колонках «К выплате», «Выплаты», «Остаток», «Баланс» и в строке ИТОГО — `PayrollRefreshingAmount` (`CupertinoActivityIndicator`, ~14 px). Флаги: `isPayrollsRefreshing` (RPC месяца), `isSettlementRefreshing` (FIFO + RPC).
- **Источник «Выплаты» / «Баланс»:** `payoutsByEmployeeAndMonthFIFOProvider(year)` → срез на `selectedMonth` в `PayrollTableWidget`.

### 2. Вкладка «Премии»

`PayrollTabBonuses` → `PayrollBonusTableWidget` → `PayrollBonusTableView`.

- Колонки: Дата, Сотрудник, Сумма, Объект, Примечание.
- Таблица: `FOTTransactionTable` / `GTAdaptiveTable`.
- CRUD: контекстное меню строки; создание — кнопка в панели фильтров.

### 3. Вкладка «Штрафы»

`PayrollTabPenalties` → `PayrollPenaltyTableWidget` → `PayrollPenaltyTableView`.

- Структура аналогична премиям; данные из `payroll_penalty`.

### 4. Вкладка «Выплаты»

`PayrollTabPayouts` → `PayrollPayoutTableWidget` → `PayrollPayoutTableView`.

- Колонки: Дата, Сотрудник, Сумма, Способ, Тип, Комментарий.
- Таблица: `FOTPayoutTable`.
- Импорт Excel и ручное добавление — кнопки в `PayrollTabToolbarActions`.

#### Импорт из Excel

| Шаг | Экран | Действие |
|-----|--------|----------|
| 1 | `PayrollPayoutExcelImportDialog` | Дата, способ, тип, комментарий → «Выбрать файл» |
| 2 | `PayrollPayoutImportPreviewDialog` | Стр. · Статус · ФИО · Сумма |
| 3 | Подтверждение | При расхождениях — «Импортировать только найденных» |
| 4 | БД | Записи в `payroll_payout`; файл не сохраняется; `invalidatePayrollPayoutDependents` |

**Статусы предпросмотра:** `Найден` · `Не найден` · `Неоднозначно`.

---

## Экспорт и импорт

| Операция | Где в UI | Механизм |
|----------|----------|----------|
| **Экспорт ведомости ФОТ** | Шапка (`PayrollExportAction`), вкладки ФОТ / Премии / Штрафы | Edge Function `export-payroll` |
| **Импорт выплат** | Панель фильтров, вкладка «Выплаты» | Клиент: `file_picker` + `excel` |

### Экспорт ведомости (детали)

**Параметры выгрузки** (как на экране): год, месяц, компания, `objectIds`, `searchQuery`, опционально `employeeIds`.

| Сценарий | Действие | Результат |
|----------|----------|-----------|
| Весь ФОТ | Скачивание без чекбоксов | Все строки за период |
| Только выбранные | Чекбоксы + пункт меню | Только `employeeIds`, включая «нулевые» строки |

**Колонки Excel** синхронизированы с `PayrollTableView` + строка ИТОГО.  
После выгрузки: snackbar; desktop — диалог сохранения, mobile — «Поделиться».

---

## Провайдеры фильтрации и кэша (Riverpod)

| Провайдер | Файл | Назначение |
|-----------|------|------------|
| `payrollFilterProvider` | `payroll_filter_providers.dart` | Год, месяц, `selectedObjectIds` |
| `payrollSearchQueryProvider` | `payroll_filter_providers.dart` | Текст поиска ФИО |
| `payrollEmployeeStatusFilterProvider` | `payroll_employee_status_filter_segment.dart` | Все / Работает / Уволен |
| `availableObjectsForPayrollProvider` | `payroll_filter_providers.dart` | Список объектов для dropdown |
| `filteredPayrollsProvider` | `payroll_providers.dart` | Расчёты за период (RPC / fallback) |
| `payoutsByEmployeeAndMonthFIFOProvider` | `payroll_providers.dart` | FIFO за год: выплаты и балансы по месяцам 1–12 |
| `allPayoutsProvider` | `payroll_providers.dart` | Все выплаты компании (вход FIFO) |
| `employeeAggregatedBalanceProvider` | `balance_providers.dart` | Баланс за всё время (форма массовых выплат) |
| `singleEmployeeBalanceProvider` | `balance_providers.dart` | Баланс одного сотрудника (профиль) |
| `employeeBalanceAtDateProvider` | `balance_providers.dart` | Баланс на дату (заготовка под фильтр «закрытых» сотрудников; RPC `calculate_employee_balances_at_date`) |
| `payrollGridSelectedEmployeeIdsProvider` | `payroll_grid_selection_providers.dart` | Выбранные чекбоксами сотрудники (экспорт) |
| `bonusesByFilterProvider` / `filteredBonusesProvider` | `bonus_providers.dart` | Список премий с учётом периода, объектов и поиска |
| `penaltiesByFilterProvider` / `filteredPenaltiesProvider` | `penalty_providers.dart` | Список штрафов с учётом периода, объектов и поиска |
| `payrollPayoutsByFilterProvider` / `filteredPayrollPayoutsProvider` | `payroll_providers.dart` | Список выплат с учётом фильтров |

### Инвалидация после мутаций

| Функция | Файл | Когда вызывать |
|---------|------|----------------|
| `invalidatePayrollFotTableDependents` | `payroll_providers.dart` | Премия, штраф |
| `invalidatePayrollPayoutDependents` | `payroll_providers.dart` | Выплата (включая импорт Excel); включает `invalidatePayrollFotTableDependents` |

Новые точки сохранения в модуле ФОТ должны вызывать одну из этих функций, а не отдельные `ref.invalidate(...)` по списку провайдеров.

---

## Связь с модулем «Табель»

| Аспект | Табель | ФОТ |
|--------|--------|-----|
| Шапка | `TimesheetScreen` + `MobileAtmosphere*` | `PayrollListScreen` + те же виджеты |
| Панель | `TimesheetCalendarView._buildTimesheetTitleRow` | `PayrollFiltersToolbar` |
| Высота контролов | `34` px | `PayrollToolbarMetrics.height = 34` |
| Поиск mobile | `TimesheetMobileSearchField` | `PayrollMobileSearchField` |
| Поиск desktop | `TimesheetToolbarSearch` | `PayrollToolbarSearch` (`payroll_filters_toolbar.dart`) |
| Состояние поиска | `timesheetSearchQueryProvider` | `payrollSearchQueryProvider` |
| Фильтр по ФИО | helpers в модуле «Табель» | `payroll_name_search_filters.dart` |
| Фильтр статуса | — | `PayrollEmployeeStatusFilterSegment` (только ФОТ) |
| Период | `TimesheetCompactMonthSwitcher` | `PayrollCompactMonthSwitcher` |
| Объекты | `TimesheetObjectsBarDropdown` | `PayrollObjectsBarDropdown` |
| Адаптивность | `EmployeesLayoutUtils` | `EmployeesLayoutUtils` |

---

## Миграция устаревших компонентов (16.07.2026)

В новом коде **не восстанавливать** удалённые виджеты. Использовать только актуальные файлы из правой колонки.

| Устаревший компонент | Актуальная замена | Файл |
|----------------------|-------------------|------|
| `GTMonthPicker` | `PayrollCompactMonthSwitcher` | `payroll_filters_toolbar.dart` |
| `GTObjectPicker` | `PayrollObjectsBarDropdown` | `payroll_objects_bar_dropdown.dart` |
| `PayrollSearchAction` (раскрываемый поиск в AppBar) | `PayrollToolbarSearch` (desktop) + `PayrollMobileSearchField` (mobile) | `payroll_filters_toolbar.dart`, `payroll_mobile_search_field.dart` |
| `payrollSearchVisibleProvider` | Поиск всегда виден: в шапке (mobile) или в панели (desktop) | `payrollSearchQueryProvider` в `payroll_filter_providers.dart` |
| `PayrollFilterHelpers` | Фильтры периода/объектов + поиск по ФИО + статус | `payroll_filter_providers.dart`, `payroll_name_search_filters.dart`, `payroll_employee_status_filter_segment.dart` |

> Файлы `payroll_search_action.dart` и `payroll_filter_helpers.dart` **удалены из репозитория** и не должны фигурировать в импортах и документации как существующие пути.

---

## Дерево файлов Presentation (аудит 17.07.2026)

```
lib/features/fot/presentation/
├── screens/
│   ├── payroll_list_screen.dart          # PayrollListScreen — корневой экран
│   └── tabs/
│       ├── payroll_tab_bonuses.dart      # PayrollTabBonuses
│       ├── payroll_tab_penalties.dart    # PayrollTabPenalties
│       └── payroll_tab_payouts.dart      # PayrollTabPayouts
├── widgets/
│   ├── payroll_filters_toolbar.dart      # PayrollFiltersToolbar, PayrollCompactMonthSwitcher, PayrollToolbarSearch
│   ├── payroll_tab_segment.dart          # PayrollTabSegment
│   ├── payroll_objects_bar_dropdown.dart # PayrollObjectsBarDropdown
│   ├── payroll_tab_toolbar_actions.dart
│   ├── payroll_toolbar_metrics.dart      # PayrollToolbarMetrics, PayrollToolbarSegmentTrack
│   ├── payroll_mobile_search_field.dart  # PayrollMobileSearchField
│   ├── payroll_employee_status_filter_segment.dart
│   ├── payroll_export_action.dart        # PayrollExportAction
│   ├── payroll_table_widget.dart         # PayrollTableWidget
│   ├── payroll_table_view.dart           # PayrollTableView
│   ├── payroll_mobile_view.dart          # PayrollMobileView
│   ├── payroll_card.dart                 # PayrollCard
│   ├── payroll_refreshing_amount.dart    # PayrollRefreshingAmount
│   ├── payroll_grid_checkbox.dart        # PayrollGridCheckbox
│   ├── payroll_bonus_table_widget.dart / payroll_bonus_table_view.dart
│   ├── payroll_penalty_table_widget.dart / payroll_penalty_table_view.dart
│   ├── payroll_payout_table_widget.dart / payroll_payout_table_view.dart
│   ├── fot_transaction_table_widget.dart / fot_transaction_mobile_view.dart
│   ├── fot_payout_table_widget.dart / fot_payout_mobile_view.dart
│   ├── payroll_transaction_form_modal.dart
│   ├── payroll_payout_form_modal.dart / payroll_payout_amount_modal.dart
│   └── payroll_payout_excel_import_dialog.dart / payroll_payout_import_preview_dialog.dart
├── providers/
│   ├── payroll_filter_providers.dart
│   ├── payroll_providers.dart
│   ├── balance_providers.dart
│   ├── bonus_providers.dart
│   ├── penalty_providers.dart
│   └── payroll_grid_selection_providers.dart
├── services/
│   ├── employee_financial_report_service.dart
│   ├── payroll_pdf_service.dart
│   └── payroll_payout_excel_import_service.dart
└── utils/
    ├── payroll_name_search_filters.dart
    ├── payroll_payout_batch_save.dart
    ├── balance_utils.dart
    ├── payout_converters.dart
    └── payout_utils.dart
```

См. также общий модульный документ: `docs/fot/fot_module.md`.
