# Модуль ФОТ (Фонд оплаты труда, Payroll)

---

## Детальное описание модуля

Модуль **ФОТ** (payroll/fot) отвечает за динамический расчёт фонда оплаты труда сотрудников за выбранный месяц. Включает агрегацию данных по отработанным часам, ставкам, премиям, штрафам, удержаниям, командировочным выплатам. Все данные берутся из Supabase (таблицы work_hours, employees, objects, payroll_bonus, payroll_penalty, payroll_deduction, payroll_payout). Модуль реализован по принципам Clean Architecture, с разделением на data/domain/presentation, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Динамический расчёт ФОТ по сотрудникам за месяц
- Учёт часов, ставок, премий, штрафов, удержаний, командировочных
- CRUD для премий, штрафов, удержаний, выплат
- Адаптивный UI: фильтрация, группировка, таблица, обработка ошибок
- Интеграция с табелем (timesheet), сотрудниками, объектами
- Безопасность через RLS, строгая типизация, DI

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- **Нет отдельной основной таблицы payroll_fot** — расчёт всегда динамический, агрегируется из связанных таблиц (см. ниже)
- Вся работа с БД — через Supabase DataSource

---

## Архитектурные и бизнес-нюансы модуля ФОТ

### Отсутствие основной таблицы
- В модуле **нет единой таблицы** payroll_fot или payroll_main. Все расчёты строятся на лету, на основании связанных таблиц.
- Основная агрегатная таблица — `payroll_calculation`, но она не хранит детализацию начислений/удержаний, а только агрегаты по сотруднику/месяцу.
- Детализация (премии, штрафы, удержания, выплаты) хранится в отдельных таблицах: `payroll_bonus`, `payroll_penalty`, `payroll_deduction`, `payroll_payout` (все связаны по payroll_id).

### Динамическая агрегация
- Расчёт ФОТ — это всегда агрегация данных из:
  - `work_hours` (отработанные часы)
  - `employees` (ставки, статусы)
  - `objects` (командировочные)
  - `payroll_bonus`/`penalty`/`deduction`/`payout` (детализация начислений/удержаний/выплат)
- Нет CRUD для payroll_calculation — запись создаётся только при необходимости (например, для фиксации расчёта или выплат).
- Все суммы по премиям, штрафам, удержаниям, выплатам агрегируются для расчёта итогового ФОТ.

### Взаимосвязи таблиц
- `work_hours` → `employees` (employee_id)
- `work_hours` → `works` (work_id) → `objects` (object_id)
- `payroll_calculation` → `employees` (employee_id)
- `payroll_bonus`/`penalty`/`deduction`/`payout` → `payroll_calculation` (payroll_id)

### Плюсы подхода
- Нет дублирования данных, расчёт всегда актуален
- Гибкая детализация: можно добавлять новые типы начислений/удержаний без изменения основной структуры
- Легко расширять бизнес-логику (например, добавить новые типы выплат)

### Минусы и ограничения
- Нет фиксации расчёта на момент выплаты (если нужны "замороженные" данные — требуется отдельная логика)
- Высокая нагрузка на агрегацию при большом объёме данных (требуется кэширование или материализация для отчётов)
- RLS не включён для payroll_* — потенциальный риск безопасности

### Рекомендации по развитию
- Для крупных данных — реализовать кэширование итоговых расчётов на месяц (materialized view или отдельная таблица с фиксацией)
- Включить RLS для всех payroll_* таблиц
- Добавить механизм "заморозки" расчёта (approve/lock payroll_calculation)
- Реализовать аудит изменений (кто и когда добавил/изменил премию/штраф/удержание/выплату)
- Для интеграции с бухгалтерией — добавить экспорт в 1С/Excel

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/fot/presentation/screens/payroll_list_screen.dart` — Экран списка расчётов ФОТ за месяц: инициализация, фильтры, таблица, обработка ошибок, загрузка данных.
- `lib/features/fot/presentation/widgets/payroll_table_widget.dart` — Адаптивная таблица расчётов ФОТ: группировка, сортировка, кастомизация UI.
- `lib/features/fot/presentation/widgets/payroll_filter_widget.dart` — Виджет фильтрации: сотрудники, объекты, должности, период.
- `lib/features/fot/presentation/providers/payroll_providers.dart` — Провайдеры состояния, бизнес-логики, мемоизация, интеграция с табелем и сотрудниками.
- `lib/features/fot/presentation/providers/payroll_filter_provider.dart` — Провайдер фильтров: хранит состояние фильтрации, методы обновления.
- `lib/features/fot/presentation/providers/bonus_providers.dart` — Провайдеры премий.
- `lib/features/fot/presentation/providers/penalty_providers.dart` — Провайдеры штрафов.
- `lib/features/fot/presentation/providers/deduction_providers.dart` — Провайдеры удержаний.
- `lib/features/fot/presentation/providers/payout_providers.dart` — Провайдеры выплат.

### Domain (бизнес-логика)
- `lib/features/fot/domain/entities/payroll_calculation.dart` — Доменная сущность расчёта ФОТ (Freezed): все суммы, ставки, командировочные, итоговые значения.
- `lib/features/fot/domain/repositories/payroll_repository.dart` — Абстракция репозитория расчётов ФОТ.
- `lib/features/fot/domain/usecases/get_payrolls_by_month_usecase.dart` — UseCase для получения расчётов ФОТ за месяц.
- `lib/features/fot/domain/usecases/create_payout_usecase.dart` — UseCase для создания выплаты.
- `lib/features/fot/domain/usecases/update_payout_usecase.dart` — UseCase для обновления выплаты.
- `lib/features/fot/domain/usecases/delete_payout_usecase.dart` — UseCase для удаления выплаты.
- `lib/features/fot/domain/usecases/get_payouts_by_payroll_id_usecase.dart` — UseCase для получения выплат по расчёту ФОТ.
- (Аналогично для bonus, penalty, deduction — CRUD usecase для каждого типа.)

### Data (работа с БД/Supabase)
- `lib/features/fot/data/models/payroll_payout_model.dart` — Data-модель выплаты по ФОТ (Freezed/JsonSerializable).
- `lib/features/fot/data/models/payroll_bonus_model.dart` — Data-модель премии по ФОТ.
- `lib/features/fot/data/models/payroll_penalty_model.dart` — Data-модель штрафа по ФОТ.
- `lib/features/fot/data/models/payroll_deduction_model.dart` — Data-модель удержания по ФОТ.
- (Автогенерируемые файлы: *.g.dart, *.freezed.dart)
- `lib/features/fot/data/repositories/payroll_repository_impl.dart` — Имплементация репозитория расчётов ФОТ: агрегирует данные из work_hours, employees, objects, payroll_bonus/penalty/deduction/payout.
- `lib/features/fot/data/repositories/payroll_payout_repository_impl.dart` — CRUD-операции для выплат по ФОТ.
- `lib/features/fot/data/repositories/payroll_bonus_repository_impl.dart` — CRUD-операции для премий по ФОТ.
- `lib/features/fot/data/repositories/payroll_penalty_repository_impl.dart` — CRUD-операции для штрафов по ФОТ.
- `lib/features/fot/data/repositories/payroll_deduction_repository_impl.dart` — CRUD-операции для удержаний по ФОТ.
- (Интерфейсы репозиториев: *_repository.dart)

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── fot/
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── payroll_list_screen.dart
│       │   ├── widgets/
│       │   │   ├── payroll_table_widget.dart
│       │   │   └── payroll_filter_widget.dart
│       │   └── providers/
│       │       ├── payroll_providers.dart
│       │       ├── payroll_filter_provider.dart
│       │       ├── bonus_providers.dart
│       │       ├── penalty_providers.dart
│       │       ├── deduction_providers.dart
│       │       └── payout_providers.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── payroll_calculation.dart
│       │   ├── repositories/
│       │   │   └── payroll_repository.dart
│       │   └── usecases/
│       │       ├── get_payrolls_by_month_usecase.dart
│       │       ├── create_payout_usecase.dart
│       │       ├── update_payout_usecase.dart
│       │       ├── delete_payout_usecase.dart
│       │       ├── get_payouts_by_payroll_id_usecase.dart
│       │       └── ... (аналогично для bonus, penalty, deduction)
│       └── data/
│           ├── models/
│           │   ├── payroll_payout_model.dart
│           │   ├── payroll_bonus_model.dart
│           │   ├── payroll_penalty_model.dart
│           │   ├── payroll_deduction_model.dart
│           │   └── ... (автогенерируемые *.g.dart, *.freezed.dart)
│           └── repositories/
│               ├── payroll_repository_impl.dart
│               ├── payroll_payout_repository_impl.dart
│               ├── payroll_bonus_repository_impl.dart
│               ├── payroll_penalty_repository_impl.dart
│               ├── payroll_deduction_repository_impl.dart
│               ├── payroll_payout_repository.dart
│               ├── payroll_bonus_repository.dart
│               ├── payroll_penalty_repository.dart
│               └── payroll_deduction_repository.dart
```

---

## Связи и интеграции
- **Supabase:** таблицы work_hours, employees, objects, payroll_bonus, payroll_penalty, payroll_deduction, payroll_payout
- **Timesheet:** интеграция с табелем для получения отработанных часов
- **Employees:** интеграция с сотрудниками для ставок, ФИО, позиций
- **Objects:** интеграция с объектами для расчёта командировочных
- **RLS:** все операции защищены политиками безопасности Supabase
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.
- Для крупных данных рекомендуется кэширование итоговых расчётов на месяц.

---

## Краткое описание используемых таблиц

| Таблица                | Назначение                                      |
|------------------------|-------------------------------------------------|
| work_hours             | Табель: смены, часы, сотрудник, объект          |
| employees              | Сотрудники: id, ФИО, ставка, позиция            |
| objects                | Объекты: id, название, командировочные          |
| payroll_bonus          | Премии по расчёту ФОТ                           |
| payroll_penalty        | Штрафы по расчёту ФОТ                           |
| payroll_deduction      | Удержания по расчёту ФОТ                        |
| payroll_payout         | Выплаты по расчёту ФОТ                          |

--- 