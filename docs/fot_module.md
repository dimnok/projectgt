# Модуль ФОТ (Фонд оплаты труда, Payroll)

---

## Детальное описание модуля

Модуль **ФОТ** (payroll/fot) отвечает за динамический расчёт фонда оплаты труда сотрудников за выбранный месяц. Включает агрегацию данных по отработанным часам, ставкам, премиям, штрафам, командировочным выплатам. Все данные берутся из Supabase (таблицы work_hours, employees, objects, payroll_bonus, payroll_penalty, payroll_payout). Модуль реализован по принципам Clean Architecture, с разделением на data/domain/presentation, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Динамический расчёт ФОТ по сотрудникам за месяц
- Учёт часов, ставок, премий, штрафов, командировочных
- CRUD для премий, штрафов, выплат
- Адаптивный UI с табами: ФОТ, Штрафы, Премии, Выплаты
- Многоуровневая фильтрация и группировка данных
- Расчёт балансов сотрудников (начислено - выплачено)
- Независимая загрузка данных work_hours (не зависит от модуля табеля)
- Безопасность через RLS, строгая типизация, DI

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- **Полностью динамический расчёт** — нет основной таблицы payroll_calculation
- Независимость от модуля табеля — собственная загрузка work_hours
- Вся работа с БД — через Supabase DataSource

---

## Архитектурные и бизнес-нюансы модуля ФОТ

### Полностью динамический расчёт
- В модуле **нет основной таблицы** для хранения расчётов ФОТ. Все расчёты строятся на лету.
- Расчёт происходит в провайдере `filteredPayrollsProvider` на основе агрегации данных.
- Детализация (премии, штрафы, выплаты) хранится в отдельных таблицах: `payroll_bonus`, `payroll_penalty`, `payroll_payout`.

### Независимость от модуля табеля
- Модуль имеет собственный провайдер `payrollWorkHoursProvider` для загрузки данных work_hours.
- Не зависит от состояния и фильтров модуля табеля.
- Загружает данные work_hours напрямую из Supabase по выбранному периоду ФОТ.

### Динамическая агрегация
- Расчёт ФОТ — это агрегация данных из:
  - `work_hours` (отработанные часы) — через независимый провайдер
  - `employees` (ставки, статусы)
  - `objects` (командировочные выплаты)
  - `payroll_bonus`/`penalty`/`payout` (детализация начислений/удержаний/выплат)
- Формула расчёта: `netSalary = baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal`
- Все суммы агрегируются в реальном времени.

### Система балансов
- Модуль рассчитывает балансы сотрудников: начислено - выплачено.
- Используется провайдер `employeeAggregatedBalanceProvider` для оптимизированного расчёта.
- Балансы отображаются с цветовой индикацией (положительный/отрицательный/нулевой).

### Взаимосвязи таблиц
- `work_hours` → `employees` (employee_id)
- `work_hours` → `works` (work_id) → `objects` (object_id)
- `payroll_bonus`/`penalty`/`payout` → `employees` (employee_id)

### Плюсы подхода
- Нет дублирования данных, расчёт всегда актуален
- Гибкая детализация: можно добавлять новые типы начислений без изменения основной структуры
- Независимость от других модулей
- Высокая производительность благодаря оптимизированным провайдерам

### Минусы и ограничения
- Нет фиксации расчёта на момент выплаты (если нужны "замороженные" данные — требуется отдельная логика)
- Высокая нагрузка на агрегацию при большом объёме данных
- RLS не включён для payroll_* — потенциальный риск безопасности

### Рекомендации по развитию
- Для крупных данных — реализовать кэширование итоговых расчётов на месяц
- Включить RLS для всех payroll_* таблиц
- Добавить механизм "заморозки" расчёта
- Реализовать аудит изменений
- Добавить экспорт в Excel/PDF

---

## Структура и файлы модуля

### Presentation/UI

#### Экраны
- `lib/features/fot/presentation/screens/payroll_list_screen.dart` — Основной экран с табами: ФОТ, Штрафы, Премии, Выплаты. Инициализация данных, фильтры, обработка ошибок.

#### Табы
- `lib/features/fot/presentation/screens/tabs/payroll_tab_bonuses.dart` — Таб "Премии" с таблицей и формой добавления.
- `lib/features/fot/presentation/screens/tabs/payroll_tab_penalties.dart` — Таб "Штрафы" с таблицей и формой добавления.
- `lib/features/fot/presentation/screens/tabs/payroll_tab_payouts.dart` — Таб "Выплаты" с таблицей и формой добавления.

#### Виджеты таблиц
- `lib/features/fot/presentation/widgets/payroll_table_widget.dart` — Основная адаптивная таблица расчётов ФОТ с группировкой по сотрудникам.
- `lib/features/fot/presentation/widgets/payroll_table_cells.dart` — Утилиты для создания ячеек таблицы с правильным форматированием.
- `lib/features/fot/presentation/widgets/payroll_table_row_builder.dart` — Строитель строк таблицы с адаптивной логикой для разных устройств.
- `lib/features/fot/presentation/widgets/payroll_bonus_table_widget.dart` — Таблица премий.
- `lib/features/fot/presentation/widgets/payroll_penalty_table_widget.dart` — Таблица штрафов.
- `lib/features/fot/presentation/widgets/payroll_payout_table_widget.dart` — Таблица выплат.

#### Виджеты фильтров
- `lib/features/fot/presentation/widgets/payroll_filter_widget.dart` — Основной виджет фильтрации: сотрудники, объекты, должности, период.
- `lib/features/fot/presentation/widgets/payroll_payout_filter_widget.dart` — Специальный фильтр для выплат.

#### Модальные формы
- `lib/features/fot/presentation/widgets/payroll_bonus_form_modal.dart` — Форма добавления/редактирования премий.
- `lib/features/fot/presentation/widgets/payroll_penalty_form_modal.dart` — Форма добавления/редактирования штрафов.
- `lib/features/fot/presentation/widgets/payroll_payout_form_modal.dart` — Форма создания выплат (первый этап).
- `lib/features/fot/presentation/widgets/payroll_payout_amount_modal.dart` — Форма указания сумм выплат (второй этап).

#### Провайдеры
- `lib/features/fot/presentation/providers/payroll_providers.dart` — Основные провайдеры: расчёт ФОТ, загрузка work_hours, выплаты, use cases.
- `lib/features/fot/presentation/providers/payroll_filter_provider.dart` — Провайдер фильтров с каскадными обновлениями.
- `lib/features/fot/presentation/providers/balance_providers.dart` — Провайдеры для расчёта балансов сотрудников.
- `lib/features/fot/presentation/providers/bonus_providers.dart` — Провайдеры для работы с премиями.
- `lib/features/fot/presentation/providers/penalty_providers.dart` — Провайдеры для работы со штрафами.
- `lib/features/fot/presentation/providers/payroll_payout_filter_provider.dart` — Специальные фильтры для выплат.

#### Утилиты
- `lib/features/fot/presentation/utils/balance_utils.dart` — Утилиты для отображения балансов с цветовой индикацией.

### Domain (бизнес-логика)

#### Сущности
- `lib/features/fot/domain/entities/payroll_calculation.dart` — Доменная сущность расчёта ФОТ (Freezed): employeeId, periodMonth, hoursWorked, hourlyRate, baseSalary, bonusesTotal, penaltiesTotal, businessTripTotal, netSalary.

#### Репозитории (интерфейсы)
- `lib/features/fot/domain/repositories/payroll_repository.dart` — Абстракция репозитория расчётов ФОТ.

#### Use Cases
- `lib/features/fot/domain/usecases/create_payout_usecase.dart` — UseCase для создания выплаты.
- `lib/features/fot/domain/usecases/update_payout_usecase.dart` — UseCase для обновления выплаты.
- `lib/features/fot/domain/usecases/delete_payout_usecase.dart` — UseCase для удаления выплаты.
- `lib/features/fot/domain/usecases/create_penalty_usecase.dart` — UseCase для создания штрафа.
- `lib/features/fot/domain/usecases/update_penalty_usecase.dart` — UseCase для обновления штрафа.
- `lib/features/fot/domain/usecases/delete_penalty_usecase.dart` — UseCase для удаления штрафа.

### Data (работа с БД/Supabase)

#### Модели данных
- `lib/features/fot/data/models/payroll_payout_model.dart` — Data-модель выплаты (Freezed/JsonSerializable): id, employeeId, amount, payoutDate, method, type, createdAt.
- `lib/features/fot/data/models/payroll_bonus_model.dart` — Data-модель премии: id, employeeId, type, amount, reason, createdAt, objectId.
- `lib/features/fot/data/models/payroll_penalty_model.dart` — Data-модель штрафа: id, employeeId, type, amount, reason, date, createdAt, objectId.

#### Репозитории (реализации)
- `lib/features/fot/data/repositories/payroll_payout_repository_impl.dart` — CRUD-операции для выплат через Supabase.
- `lib/features/fot/data/repositories/payroll_bonus_repository_impl.dart` — CRUD-операции для премий через Supabase.
- `lib/features/fot/data/repositories/payroll_penalty_repository_impl.dart` — CRUD-операции для штрафов через Supabase.

#### Интерфейсы репозиториев
- `lib/features/fot/data/repositories/payroll_payout_repository.dart` — Интерфейс репозитория выплат.
- `lib/features/fot/data/repositories/payroll_bonus_repository.dart` — Интерфейс репозитория премий.
- `lib/features/fot/data/repositories/payroll_penalty_repository.dart` — Интерфейс репозитория штрафов.

---

## Дерево структуры модуля (актуальное)

```
lib/
├── features/
│   └── fot/
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── payroll_list_screen.dart
│       │   │   └── tabs/
│       │   │       ├── payroll_tab_bonuses.dart
│       │   │       ├── payroll_tab_penalties.dart
│       │   │       └── payroll_tab_payouts.dart
│       │   ├── widgets/
│       │   │   ├── payroll_table_widget.dart
│       │   │   ├── payroll_table_cells.dart
│       │   │   ├── payroll_table_row_builder.dart
│       │   │   ├── payroll_filter_widget.dart
│       │   │   ├── payroll_payout_filter_widget.dart
│       │   │   ├── payroll_bonus_form_modal.dart
│       │   │   ├── payroll_bonus_table_widget.dart
│       │   │   ├── payroll_penalty_form_modal.dart
│       │   │   ├── payroll_penalty_table_widget.dart
│       │   │   ├── payroll_payout_form_modal.dart
│       │   │   ├── payroll_payout_amount_modal.dart
│       │   │   └── payroll_payout_table_widget.dart
│       │   ├── providers/
│       │   │   ├── payroll_providers.dart
│       │   │   ├── payroll_filter_provider.dart
│       │   │   ├── balance_providers.dart
│       │   │   ├── bonus_providers.dart
│       │   │   ├── penalty_providers.dart
│       │   │   └── payroll_payout_filter_provider.dart
│       │   └── utils/
│       │       └── balance_utils.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── payroll_calculation.dart
│       │   ├── repositories/
│       │   │   └── payroll_repository.dart
│       │   └── usecases/
│       │       ├── create_payout_usecase.dart
│       │       ├── update_payout_usecase.dart
│       │       ├── delete_payout_usecase.dart
│       │       ├── create_penalty_usecase.dart
│       │       ├── update_penalty_usecase.dart
│       │       └── delete_penalty_usecase.dart
│       └── data/
│           ├── models/
│           │   ├── payroll_payout_model.dart
│           │   ├── payroll_bonus_model.dart
│           │   └── payroll_penalty_model.dart
│           └── repositories/
│               ├── payroll_payout_repository.dart
│               ├── payroll_payout_repository_impl.dart
│               ├── payroll_bonus_repository.dart
│               ├── payroll_bonus_repository_impl.dart
│               ├── payroll_penalty_repository.dart
│               └── payroll_penalty_repository_impl.dart
```

---

## Ключевые особенности реализации

### Независимая загрузка work_hours
```dart
/// Провайдер для независимой загрузки данных work_hours по периоду ФОТ.
final payrollWorkHoursProvider = FutureProvider<List<dynamic>>((ref) async {
  final filterState = ref.watch(payrollFilterProvider);
  // Загружает данные work_hours напрямую из Supabase
  // Не зависит от модуля табеля
});
```

### Динамический расчёт ФОТ
```dart
/// Провайдер отфильтрованных расчетов ФОТ
final filteredPayrollsProvider = FutureProvider<List<PayrollCalculation>>((ref) async {
  // Агрегирует данные из work_hours, employees, objects
  // Рассчитывает: baseSalary = hours * hourlyRate
  // Добавляет премии, командировочные, вычитает штрафы
  // Формула: netSalary = baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal
});
```

### Система балансов
```dart
/// Провайдер агрегированного баланса сотрудников
final employeeAggregatedBalanceProvider = FutureProvider<Map<String, double>>((ref) async {
  // Рассчитывает: начислено - выплачено для каждого сотрудника
  // Используется для отображения задолженностей
});
```

### Адаптивные таблицы
- **Desktop**: все колонки (сотрудник, часы, ставка, базовая сумма, премии, штрафы, командировочные, к выплате, выплаты, баланс)
- **Tablet**: сокращённый набор (сотрудник, часы, базовая сумма, премии, командировочные, к выплате, выплаты, баланс)
- **Mobile**: минимальный набор (сотрудник, часы, командировочные, к выплате, выплаты, баланс)

### Каскадные фильтры
- Доступные сотрудники зависят от выбранных объектов и должностей
- Доступные объекты зависят от выбранных сотрудников и должностей
- Доступные должности зависят от выбранных сотрудников и объектов

---

## Связи и интеграции
- **Supabase:** таблицы work_hours, employees, objects, payroll_bonus, payroll_penalty, payroll_payout
- **Employees:** интеграция с модулем сотрудников для получения ставок, ФИО, должностей
- **Objects:** интеграция с модулем объектов для расчёта командировочных выплат
- **Независимость от Timesheet:** собственная загрузка work_hours, не зависит от состояния табеля
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **RLS:** операции защищены политиками безопасности Supabase

---

## Используемые таблицы Supabase

| Таблица                | Назначение                                      | Поля                                           |
|------------------------|-------------------------------------------------|------------------------------------------------|
| work_hours             | Отработанные часы                               | id, work_id, employee_id, hours                |
| employees              | Сотрудники                                      | id, firstName, lastName, middleName, position, hourlyRate |
| objects                | Объекты                                         | id, name, businessTripAmount                   |
| payroll_bonus          | Премии                                          | id, employee_id, type, amount, reason, created_at, object_id |
| payroll_penalty        | Штрафы                                          | id, employee_id, type, amount, reason, date, created_at, object_id |
| payroll_payout         | Выплаты                                         | id, employee_id, amount, payout_date, method, type, created_at |

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль полностью независим от других модулей благодаря собственной загрузке данных.
- Использует современные подходы Flutter: Color.withValues() вместо withOpacity().
- Адаптивный UI поддерживает все платформы (iOS, Android, Web).
- Легко расширяется благодаря Clean Architecture и DI через Riverpod.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике. 