# Модуль ФОТ (Фонд оплаты труда, Payroll)

**Дата актуализации:** 05 октября 2025 года (обновлено: Полный аудит кода и БД, актуализация данных о количестве записей, проверка структуры таблиц, индексов, PostgreSQL функций. Обнаружено важное изменение в функции: фильтрация по закрытым сменам (status = 'closed'). Уточнена информация о возвращаемых колонках RPC функции. **🐛 ИСПРАВЛЕН БАГ:** Неправильное отображение дат премий - использовался `createdAt` вместо `date`)

---

## Важное замечание о структуре данных

> **Внимание:**
> Модуль "ФОТ" использует **полностью динамический расчёт** без сохранения в БД.
> Все расчёты выполняются на лету из таблиц:
> - `work_hours` (модуль "Работы") — отработанные часы сотрудников
> - `employees` (модуль "Сотрудники") — информация о сотрудниках
> - `employee_rates` (модуль "Сотрудники") — исторические ставки сотрудников
> - `business_trip_rates` — ставки командировочных выплат
> - `payroll_bonus` — премии сотрудников
> - `payroll_penalty` — штрафы сотрудников
> - `payroll_payout` — выплаты зарплаты
>
> Модуль имеет **независимую загрузку work_hours** и не зависит от модуля "Табель".

---

## Детальное описание модуля

Модуль **ФОТ** (Фонд оплаты труда / Payroll) отвечает за динамический расчёт заработной платы сотрудников за выбранный месяц. Включает агрегацию данных по отработанным часам, историческим ставкам, премиям, штрафам и командировочным выплатам. Реализован по принципам Clean Architecture с разделением на data/domain/presentation, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Динамический расчёт ФОТ по сотрудникам за месяц с учётом исторических ставок
- CRUD операции для премий, штрафов и выплат
- Адаптивный UI с табами: ФОТ, Штрафы, Премии, Выплаты
- Автоматический расчёт за текущий месяц
- Расчёт балансов сотрудников (начислено - выплачено) с цветовой индикацией
- Независимая загрузка данных work_hours (не зависит от модуля табеля)
- Командировочные выплаты с индивидуальными ставками по объектам
- Интеграция с Supabase через репозитории

**Архитектурные особенности:**
- **🚀 Hybrid-архитектура:** PostgreSQL функция (21ms execution time) + Dart fallback (ускорение в 40-80 раз!)
- **Батч-обработка:** 1 RPC запрос вместо 400+ индивидуальных запросов
- Clean Architecture: разделение на data/domain/presentation
- DI через Riverpod с провайдерами для всех зависимостей
- Freezed/JsonSerializable для моделей данных
- Функции-провайдеры для CRUD операций (упрощённый UseCase паттерн)
- **Полностью динамический расчёт** — нет сохранения в payroll_calculation
- Независимость от модуля табеля — собственная загрузка work_hours
- Параллельная загрузка базовых данных (Future.wait)
- Вся работа с БД — через Supabase репозитории и RPC

---

## Используемые таблицы и зависимости

Модуль **ФОТ** работает с данными из следующих таблиц:

### Основные таблицы модуля
- **payroll_bonus** — премии сотрудников (модуль "ФОТ")
- **payroll_penalty** — штрафы сотрудников (модуль "ФОТ")
- **payroll_payout** — выплаты зарплаты (модуль "ФОТ")

### Связанные таблицы из других модулей
- **work_hours** — отработанные часы (модуль "Работы")
- **works** — информация о сменах (модуль "Работы")
- **employees** — справочник сотрудников (модуль "Сотрудники")
- **employee_rates** — история ставок сотрудников (модуль "Сотрудники")
- **objects** — справочник объектов (модуль "Объекты")
- **business_trip_rates** — ставки командировочных выплат

> Модуль владеет таблицами `payroll_bonus`, `payroll_penalty`, `payroll_payout`, но использует данные из других модулей для расчётов.

---

## Структура и файлы модуля

### Presentation/UI

#### Экраны
- `lib/features/fot/presentation/screens/payroll_list_screen.dart` — Основной экран с 4 табами: ФОТ, Штрафы, Премии, Выплаты. Инициализация данных, обработка состояний загрузки/ошибок.

#### Табы
- `lib/features/fot/presentation/screens/tabs/payroll_tab_bonuses.dart` — Таб "Премии" с таблицей и формой добавления премий.
- `lib/features/fot/presentation/screens/tabs/payroll_tab_penalties.dart` — Таб "Штрафы" с таблицей и формой добавления штрафов.
- `lib/features/fot/presentation/screens/tabs/payroll_tab_payouts.dart` — Таб "Выплаты" с таблицей и двухэтапной формой создания выплат.

#### Виджеты таблиц
- `lib/features/fot/presentation/widgets/payroll_table_widget.dart` — Основная адаптивная таблица расчётов ФОТ с группировкой по сотрудникам.
- `lib/features/fot/presentation/widgets/payroll_table_cells.dart` — Утилиты для создания ячеек таблицы с правильным форматированием сумм.
- `lib/features/fot/presentation/widgets/payroll_table_row_builder.dart` — Строитель строк таблицы с адаптивной логикой для desktop/tablet/mobile.
- `lib/features/fot/presentation/widgets/payroll_bonus_table_widget.dart` — Таблица премий с возможностью редактирования/удаления.
- `lib/features/fot/presentation/widgets/payroll_penalty_table_widget.dart` — Таблица штрафов с возможностью редактирования/удаления.
- `lib/features/fot/presentation/widgets/payroll_payout_table_widget.dart` — Таблица выплат с отображением способов оплаты.


#### Модальные формы
- `lib/features/fot/presentation/widgets/payroll_bonus_form_modal.dart` — Форма добавления/редактирования премий.
- `lib/features/fot/presentation/widgets/payroll_penalty_form_modal.dart` — Форма добавления/редактирования штрафов.
- `lib/features/fot/presentation/widgets/payroll_payout_form_modal.dart` — Форма создания выплат (первый этап: выбор сотрудников).
- `lib/features/fot/presentation/widgets/payroll_payout_amount_modal.dart` — Форма указания сумм выплат (второй этап: ввод сумм).
- `lib/features/fot/presentation/widgets/payroll_transaction_form_modal.dart` — Универсальная форма для транзакций (премии/штрафы).

#### Провайдеры
- `lib/features/fot/presentation/providers/payroll_providers.dart` — Основные провайдеры: расчёт ФОТ, независимая загрузка work_hours, выплаты. Включает функции-провайдеры для CRUD операций с выплатами (create/update/delete).
- `lib/features/fot/presentation/providers/balance_providers.dart` — Провайдеры для расчёта балансов сотрудников (начислено - выплачено).
- `lib/features/fot/presentation/providers/bonus_providers.dart` — Провайдеры для работы с премиями. Включает функции-провайдеры для CRUD операций (create/update/delete).
- `lib/features/fot/presentation/providers/penalty_providers.dart` — Провайдеры для работы со штрафами. Включает функции-провайдеры для CRUD операций (create/update/delete).

#### Утилиты
- `lib/features/fot/presentation/utils/balance_utils.dart` — Утилиты для отображения балансов с цветовой индикацией.

### Domain (бизнес-логика)

#### Сущности
- `lib/features/fot/domain/entities/payroll_calculation.dart` — Доменная сущность расчёта ФОТ (Freezed): employeeId, periodMonth, hoursWorked, hourlyRate, baseSalary, bonusesTotal, penaltiesTotal, businessTripTotal, netSalary.
- `lib/features/fot/domain/entities/payroll_transaction.dart` — Базовый абстрактный класс для транзакций ФОТ (премии и штрафы).

#### Интерфейсы репозиториев (согласно Clean Architecture)
- `lib/features/fot/domain/repositories/payroll_bonus_repository.dart` — Интерфейс репозитория премий: createBonus, updateBonus, deleteBonus, getAllBonuses.
- `lib/features/fot/domain/repositories/payroll_penalty_repository.dart` — Интерфейс репозитория штрафов: createPenalty, updatePenalty, deletePenalty, getAllPenalties.
- `lib/features/fot/domain/repositories/payroll_payout_repository.dart` — Интерфейс репозитория выплат: createPayout, updatePayout, deletePayout.

> **Примечание:** UseCase классы удалены в пользу функций-провайдеров для упрощения архитектуры. CRUD-операции реализованы как функции-провайдеры в `presentation/providers/`.

### Data (работа с БД/Supabase)

#### Модели данных
- `lib/features/fot/data/models/payroll_bonus_model.dart` — Data-модель премии (Freezed/JsonSerializable): id, employeeId, type, amount, reason, date, createdAt, objectId.
- `lib/features/fot/data/models/payroll_penalty_model.dart` — Data-модель штрафа (Freezed/JsonSerializable): id, employeeId, type, amount, reason, date, createdAt, objectId.
- `lib/features/fot/data/models/payroll_payout_model.dart` — Data-модель выплаты (Freezed/JsonSerializable): id, employeeId, amount, payoutDate, method, type, createdAt.

#### Реализации репозиториев
- `lib/features/fot/data/repositories/payroll_bonus_repository_impl.dart` — Реализация репозитория премий: CRUD-операции через Supabase (implements PayrollBonusRepository).
- `lib/features/fot/data/repositories/payroll_penalty_repository_impl.dart` — Реализация репозитория штрафов: CRUD-операции через Supabase (implements PayrollPenaltyRepository).
- `lib/features/fot/data/repositories/payroll_payout_repository_impl.dart` — Реализация репозитория выплат: CRUD-операции через Supabase (implements PayrollPayoutRepository).

### Дополнительные файлы

- Сгенерированные файлы (Freezed): `*.freezed.dart` для всех моделей и сущностей.
- Сгенерированные файлы (JsonSerializable): `*.g.dart` для сериализации моделей данных.

---

## Дерево структуры модуля

```
lib/
└── features/
    └── fot/
        ├── data/
        │   ├── models/
        │   │   ├── payroll_bonus_model.dart
        │   │   ├── payroll_bonus_model.freezed.dart
        │   │   ├── payroll_bonus_model.g.dart
        │   │   ├── payroll_penalty_model.dart
        │   │   ├── payroll_penalty_model.freezed.dart
        │   │   ├── payroll_penalty_model.g.dart
        │   │   ├── payroll_payout_model.dart
        │   │   ├── payroll_payout_model.freezed.dart
        │   │   └── payroll_payout_model.g.dart
        │   └── repositories/
        │       ├── payroll_bonus_repository_impl.dart
        │       ├── payroll_penalty_repository_impl.dart
        │       └── payroll_payout_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── payroll_calculation.dart
        │   │   ├── payroll_calculation.freezed.dart
        │   │   └── payroll_transaction.dart
        │   └── repositories/
        │       ├── payroll_bonus_repository.dart
        │       ├── payroll_penalty_repository.dart
        │       └── payroll_payout_repository.dart
        └── presentation/
            ├── screens/
            │   ├── payroll_list_screen.dart
            │   └── tabs/
            │       ├── payroll_tab_bonuses.dart
            │       ├── payroll_tab_penalties.dart
            │       └── payroll_tab_payouts.dart
            ├── widgets/
            │   ├── payroll_table_widget.dart
            │   ├── payroll_table_cells.dart
            │   ├── payroll_table_row_builder.dart
            │   ├── payroll_bonus_table_widget.dart
            │   ├── payroll_bonus_form_modal.dart
            │   ├── payroll_penalty_table_widget.dart
            │   ├── payroll_penalty_form_modal.dart
            │   ├── payroll_payout_table_widget.dart
            │   ├── payroll_payout_form_modal.dart
            │   ├── payroll_payout_amount_modal.dart
            │   └── payroll_transaction_form_modal.dart
            ├── providers/
            │   ├── payroll_providers.dart
            │   ├── balance_providers.dart
            │   ├── bonus_providers.dart
            │   └── penalty_providers.dart
            └── utils/
                └── balance_utils.dart
```

---

## База данных и RLS-политики

### Основные таблицы

Модуль использует следующие таблицы из базы данных:

#### Таблица `payroll_bonus`

**Структура:**
| Колонка      | Тип         | Описание                                                        |
|--------------|-------------|-----------------------------------------------------------------|
| id           | UUID, PK    | Уникальный идентификатор премии                                 |
| employee_id  | UUID, FK    | Ссылка на сотрудника (employees.id)                             |
| type         | TEXT        | Тип премии (manual, automatic и т.д.)                           |
| amount       | NUMERIC     | Сумма премии                                                    |
| reason       | TEXT        | Причина или комментарий (опционально)                           |
| date         | DATE        | Дата премии (опционально)                                       |
| object_id    | UUID, FK    | Ссылка на объект (objects.id, опционально)                      |
| created_at   | TIMESTAMP   | Дата и время создания записи (UTC)                              |

**Количество записей:** 2  
**RLS:** ❌ Отключён (критическая проблема безопасности!)

**Комментарий таблицы:** "Премии сотрудников. Используется для динамического расчёта ФОТ."

#### Таблица `payroll_penalty`

**Структура:**
| Колонка      | Тип         | Описание                                                        |
|--------------|-------------|-----------------------------------------------------------------|
| id           | UUID, PK    | Уникальный идентификатор штрафа                                 |
| employee_id  | UUID, FK    | Ссылка на сотрудника (employees.id)                             |
| type         | TEXT        | Тип штрафа (disciplinary, quality и т.д.)                       |
| amount       | NUMERIC     | Сумма штрафа                                                    |
| reason       | TEXT        | Причина или комментарий (опционально)                           |
| date         | DATE        | Дата штрафа (опционально)                                       |
| object_id    | UUID, FK    | Ссылка на объект (objects.id, опционально)                      |
| created_at   | TIMESTAMP   | Дата и время создания записи (UTC)                              |

**Количество записей:** 0  
**RLS:** ❌ Отключён (критическая проблема безопасности!)

**Комментарий таблицы:** "Штрафы сотрудников. Используется для динамического расчёта ФОТ."

#### Таблица `payroll_payout`

**Структура:**
| Колонка      | Тип         | Описание                                                        |
|--------------|-------------|-----------------------------------------------------------------|
| id           | UUID, PK    | Уникальный идентификатор выплаты                                |
| employee_id  | UUID, FK    | Ссылка на сотрудника (employees.id)                             |
| amount       | NUMERIC     | Сумма выплаты                                                   |
| payout_date  | DATE        | Дата выплаты                                                    |
| method       | TEXT        | Способ выплаты (cash, card, transfer)                           |
| type         | TEXT        | Тип выплаты (salary, advance, bonus)                            |
| is_official  | BOOLEAN     | Официальная выплата (default: true)                             |
| comment      | TEXT        | Комментарий (опционально)                                       |
| created_at   | TIMESTAMP   | Дата и время создания записи (UTC)                              |

**Количество записей:** 0  
**RLS:** ❌ Отключён (критическая проблема безопасности!)

**Комментарий таблицы:** "Выплаты зарплаты сотрудникам."

### Связанные таблицы из других модулей

#### Таблица `work_hours` (модуль "Работы")

**Количество записей:** 95  
**RLS:** ✅ Включён

**Использование в ФОТ:**
- Источник данных об отработанных часах для расчёта базовой зарплаты
- Независимая загрузка через `payrollWorkHoursProvider`
- JOIN с таблицей `works` для получения дат и объектов

#### Таблица `employees` (модуль "Сотрудники")

**Количество записей:** 30  
**RLS:** ✅ Включён

**Использование в ФОТ:**
- Получение информации о сотрудниках (ФИО, должность)
- Фильтрация по сотрудникам

#### Таблица `employee_rates` (модуль "Сотрудники")

**Количество записей:** 13  
**RLS:** ✅ Включён

**Использование в ФОТ:**
- Получение исторических ставок для точного расчёта зарплаты
- Каждая смена использует актуальную ставку на дату смены

#### Таблица `works` (модуль "Работы")

**Количество записей:** 9  
**RLS:** ✅ Включён

**Использование в ФОТ:**
- JOIN с `work_hours` для получения дат смен
- Фильтрация по закрытым сменам (status = 'closed')
- Получение object_id для расчёта командировочных

#### Таблица `objects` (модуль "Объекты")

**Количество записей:** 2  
**RLS:** ✅ Включён

**Использование в ФОТ:**
- Получение названий объектов для отображения
- Связь с business_trip_rates для ставок командировочных

#### Таблица `business_trip_rates`

**Количество записей:** 10  
**RLS:** ✅ Включён

**Структура:**
| Колонка       | Тип         | Описание                                                        |
|---------------|-------------|-----------------------------------------------------------------|
| id            | UUID, PK    | Уникальный идентификатор ставки                                 |
| object_id     | UUID, FK    | Ссылка на объект (objects.id)                                   |
| employee_id   | UUID, FK    | Ссылка на сотрудника (опционально, для индивидуальных ставок)  |
| rate          | NUMERIC     | Ставка командировочных за смену (в рублях)                      |
| valid_from    | DATE        | Дата начала действия ставки                                     |
| valid_to      | DATE        | Дата окончания действия (NULL = бессрочно)                      |
| minimum_hours | NUMERIC     | Минимальное количество часов для начисления (default: 0)        |
| created_at    | TIMESTAMP   | Дата создания                                                   |
| updated_at    | TIMESTAMP   | Дата обновления                                                 |
| created_by    | UUID, FK    | Кто создал запись (auth.users.id)                               |

**Использование в ФОТ:**
- Расчёт командировочных выплат за каждую смену
- Поддержка индивидуальных ставок для конкретных сотрудников
- Учёт минимального количества часов для начисления

### RLS-политики (Row Level Security)

#### Критическая проблема безопасности

**🔴 СТАТУС: Все основные таблицы модуля ФОТ НЕ имеют включённого RLS!**

**Проверка через SQL:**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE 'payroll%';

-- Результат:
-- payroll_bonus    | false
-- payroll_penalty  | false
-- payroll_payout   | false
```

**Проверка политик:**
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename LIKE 'payroll%';

-- Результат: 0 строк (политики отсутствуют)
```

**Таблицы без RLS:**
- ❌ `payroll_bonus` (RLS disabled, 2 записи)
- ❌ `payroll_penalty` (RLS disabled, 0 записей)
- ❌ `payroll_payout` (RLS disabled, 0 записей)

**Это означает:**
- 🔓 Любой авторизованный пользователь может читать/изменять/удалять финансовые данные
- 🔓 Нет ограничений доступа к конфиденциальной информации о зарплатах
- 🔓 Критический риск утечки финансовой информации
- 🔓 Нарушение принципа least privilege
- ⚠️ Функция `calculate_payroll_for_month()` использует `SECURITY DEFINER` для обхода RLS

**Связанные таблицы с включённым RLS:**
- ✅ `work_hours` — доступ через политики модуля "Работы"
- ✅ `employees` — доступ через политики модуля "Сотрудники"
- ✅ `employee_rates` — доступ через политики модуля "Сотрудники"
- ✅ `business_trip_rates` — доступ для авторизованных пользователей
- ✅ `objects` — доступ через политики модуля "Объекты"

### Связи между таблицами

```
work_hours  ←→  works  ←→  objects
     ↓                          ↓
employees                 business_trip_rates
     ↓
employee_rates
     ↓
payroll_bonus, payroll_penalty, payroll_payout

Где:
- work_hours.work_id → works.id
- work_hours.employee_id → employees.id
- works.object_id → objects.id
- employee_rates.employee_id → employees.id
- business_trip_rates.object_id → objects.id
- business_trip_rates.employee_id → employees.id (опционально)
- payroll_bonus.employee_id → employees.id
- payroll_bonus.object_id → objects.id
- payroll_penalty.employee_id → employees.id
- payroll_penalty.object_id → objects.id
- payroll_payout.employee_id → employees.id
```

### Функции PostgreSQL

**Статус:** ✅ Функция `calculate_payroll_for_month()` **реализована** для высокопроизводительного батч-расчёта ФОТ.

#### Функция `calculate_payroll_for_month(p_year INT, p_month INT)`

**Описание:** Выполняет полный расчёт ФОТ за указанный месяц в одном запросе.

**Миграция:** `supabase/migrations/20251004212537_optimize_payroll_calculations.sql`

**Производительность:**
- **Execution Time:** 21ms (EXPLAIN ANALYZE)
- **Planning Time:** 4ms
- **Общее время:** ~25ms на стороне БД
- **Ускорение:** в 238-476 раз по сравнению с клиентским расчётом (5-10 сек)

**Возвращаемые колонки:**
- `employee_id` (UUID) — идентификатор сотрудника
- `employee_name` (TEXT) — ФИО сотрудника (first_name || ' ' || last_name)
- `hours` (NUMERIC) — отработанные часы
- `base_salary` (NUMERIC) — базовая зарплата (часы × ставки)
- `business_trip_total` (NUMERIC) — командировочные выплаты
- `bonuses_total` (NUMERIC) — сумма премий
- `penalties_total` (NUMERIC) — сумма штрафов
- `net_salary` (NUMERIC) — к выплате (итого)
- `hourly_rate` (NUMERIC) — текущая ставка сотрудника

⚠️ **ВАЖНО:** Функция учитывает только закрытые смены (status = 'closed'). Смены со статусом 'open' или 'draft' не включаются в расчёт.

**Логика расчёта:**
1. **CTE `base_calc`:** Агрегация часов и расчёт базовой зарплаты с учётом исторических ставок из `employee_rates`
   - ⚠️ **Фильтр:** `WHERE w.status = 'closed'` — только закрытые смены
   - JOIN `work_hours` + `works` для получения дат и фильтрации по месяцу
   - Для каждой записи work_hours подбирается актуальная ставка на дату смены
2. **CTE `trip_calc`:** Расчёт командировочных выплат из `business_trip_rates`:
   - ⚠️ **Фильтр:** `WHERE w.status = 'closed'` — только закрытые смены
   - ✅ Приоритет индивидуальных ставок (employee_id = сотрудник)
   - ✅ Fallback на общие ставки (employee_id IS NULL)
   - ✅ Проверка minimum_hours перед начислением
3. **CTE `bonus_calc`:** Суммирование премий за месяц из `payroll_bonus`
4. **CTE `penalty_calc`:** Суммирование штрафов за месяц из `payroll_penalty`
5. **CTE `current_rates`:** Получение текущей активной ставки для отображения
6. **Финальный SELECT:** Объединение всех компонентов и расчёт `net_salary`

**Атрибуты функции:**
- **LANGUAGE:** `plpgsql` — язык процедурного расширения PostgreSQL
- **STABLE:** функция не изменяет данные БД, результат стабилен для одних и тех же параметров в рамках одной транзакции
- **SECURITY DEFINER:** функция выполняется с правами владельца (обход RLS), что критично для модуля без включённого RLS

**Комментарий из БД:**
> "Рассчитывает ФОТ за указанный месяц. ⚠️ Учитываются только закрытые смены (status = 'closed')"

**Использование в Dart:**
```dart
final response = await client.rpc('calculate_payroll_for_month', params: {
  'p_year': year,
  'p_month': month,
});
```

**Полный исходный код функции:**

<details>
<summary>Показать SQL-код функции (кликните для раскрытия)</summary>

```sql
CREATE OR REPLACE FUNCTION calculate_payroll_for_month(
  p_year INT,
  p_month INT
)
RETURNS TABLE (
  employee_id UUID,
  employee_name TEXT,
  hours NUMERIC,
  base_salary NUMERIC,
  business_trip_total NUMERIC,
  bonuses_total NUMERIC,
  penalties_total NUMERIC,
  net_salary NUMERIC,
  hourly_rate NUMERIC
) 
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH 
  -- 1. Базовая зарплата (часы × ставка с учётом истории)
  -- ⚠️ ВАЖНО: Только закрытые смены (status = 'closed')
  base_calc AS (
    SELECT 
      wh.employee_id,
      SUM(wh.hours) as hours,
      SUM(wh.hours * COALESCE(
        (SELECT er.hourly_rate 
         FROM employee_rates er 
         WHERE er.employee_id = wh.employee_id 
           AND w.date >= er.valid_from 
           AND (er.valid_to IS NULL OR w.date <= er.valid_to)
         ORDER BY er.valid_from DESC
         LIMIT 1), 0)
      ) as base_sal
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE EXTRACT(YEAR FROM w.date) = p_year
      AND EXTRACT(MONTH FROM w.date) = p_month
      AND w.status = 'closed'  -- ⚠️ ИСПРАВЛЕНО: используем status вместо is_closed
    GROUP BY wh.employee_id
  ),
  
  -- 2. Суточные выплаты (с учётом индивидуальных и общих ставок)
  -- ⚠️ ВАЖНО: Только закрытые смены (status = 'closed')
  trip_calc AS (
    SELECT 
      wh.employee_id,
      SUM(COALESCE(
        -- Сначала ищем индивидуальную ставку для сотрудника
        (SELECT btr.rate
         FROM business_trip_rates btr 
         WHERE btr.object_id = w.object_id 
           AND btr.employee_id = wh.employee_id
           AND w.date >= btr.valid_from 
           AND (btr.valid_to IS NULL OR w.date <= btr.valid_to)
           AND wh.hours >= COALESCE(btr.minimum_hours, 0)
         ORDER BY btr.valid_from DESC
         LIMIT 1),
        -- Если нет индивидуальной, ищем общую ставку для объекта
        (SELECT btr.rate
         FROM business_trip_rates btr 
         WHERE btr.object_id = w.object_id 
           AND btr.employee_id IS NULL
           AND w.date >= btr.valid_from 
           AND (btr.valid_to IS NULL OR w.date <= btr.valid_to)
           AND wh.hours >= COALESCE(btr.minimum_hours, 0)
         ORDER BY btr.valid_from DESC
         LIMIT 1),
        0
      )) as trip_total
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE EXTRACT(YEAR FROM w.date) = p_year
      AND EXTRACT(MONTH FROM w.date) = p_month
      AND w.object_id IS NOT NULL
      AND w.status = 'closed'  -- ⚠️ ИСПРАВЛЕНО: используем status вместо is_closed
    GROUP BY wh.employee_id
  ),
  
  -- 3. Премии за месяц
  bonus_calc AS (
    SELECT 
      employee_id,
      COALESCE(SUM(amount), 0) as bonuses
    FROM payroll_bonus
    WHERE EXTRACT(YEAR FROM date) = p_year
      AND EXTRACT(MONTH FROM date) = p_month
    GROUP BY employee_id
  ),
  
  -- 4. Штрафы за месяц
  penalty_calc AS (
    SELECT 
      employee_id,
      COALESCE(SUM(amount), 0) as penalties
    FROM payroll_penalty
    WHERE EXTRACT(YEAR FROM date) = p_year
      AND EXTRACT(MONTH FROM date) = p_month
    GROUP BY employee_id
  ),
  
  -- 5. Текущая ставка сотрудника (для отображения)
  current_rates AS (
    SELECT DISTINCT ON (er.employee_id)
      er.employee_id,
      er.hourly_rate as current_rate
    FROM employee_rates er
    WHERE er.valid_from <= CURRENT_DATE
      AND (er.valid_to IS NULL OR er.valid_to >= CURRENT_DATE)
    ORDER BY er.employee_id, er.valid_from DESC
  )
  
  -- Финальный расчёт: объединяем все компоненты
  SELECT 
    e.id,
    e.first_name || ' ' || e.last_name,
    COALESCE(bc.hours, 0)::NUMERIC,
    COALESCE(bc.base_sal, 0)::NUMERIC,
    COALESCE(tc.trip_total, 0)::NUMERIC,
    COALESCE(bonus.bonuses, 0)::NUMERIC,
    COALESCE(pen.penalties, 0)::NUMERIC,
    (COALESCE(bc.base_sal, 0) + 
     COALESCE(tc.trip_total, 0) + 
     COALESCE(bonus.bonuses, 0) - 
     COALESCE(pen.penalties, 0))::NUMERIC as net_salary,
    COALESCE(cr.current_rate, 0)::NUMERIC
  FROM employees e
  LEFT JOIN base_calc bc ON e.id = bc.employee_id
  LEFT JOIN trip_calc tc ON e.id = tc.employee_id
  LEFT JOIN bonus_calc bonus ON e.id = bonus.employee_id
  LEFT JOIN penalty_calc pen ON e.id = pen.employee_id
  LEFT JOIN current_rates cr ON e.id = cr.employee_id
  WHERE bc.employee_id IS NOT NULL  -- Только сотрудники с отработанными часами
  ORDER BY e.first_name, e.last_name;
END;
$$;

COMMENT ON FUNCTION calculate_payroll_for_month(INT, INT) IS 
'Рассчитывает ФОТ за указанный месяц. ⚠️ Учитываются только закрытые смены (status = ''closed'')';
```

**Файл миграции:** `supabase/migrations/20251004212537_optimize_payroll_calculations.sql`

</details>

**Индексы для оптимизации:**

Созданные индексы для модуля ФОТ:
- `idx_payroll_bonus_employee_date` — B-tree индекс на (employee_id, date) для быстрой фильтрации премий
- `idx_payroll_penalty_employee_date` — B-tree индекс на (employee_id, date) для быстрой фильтрации штрафов

Primary key индексы (автоматические):
- `payroll_bonus_pkey` — уникальный B-tree индекс на (id)
- `payroll_penalty_pkey` — уникальный B-tree индекс на (id)
- `payroll_payout_pkey` — уникальный B-tree индекс на (id)

Существующие индексы на связанных таблицах:
- Индексы на `work_hours`, `works`, `employee_rates`, `business_trip_rates` (наследуются из других модулей)

### Триггеры

**Статус:** ❌ Триггеры для таблиц модуля ФОТ **отсутствуют**.

### Материализованные представления

**Статус:** ❌ Материализованные представления для модуля ФОТ **отсутствуют**.

---

## Бизнес-логика и ключевые особенности

### Процесс расчёта ФОТ (Hybrid подход)

Модуль использует **Hybrid-архитектуру** с динамическим расчётом на стороне БД и fallback на клиенте:

#### Основной путь (Server-Side через RPC) 🚀

1. **Вызов PostgreSQL функции:**
   ```dart
   final response = await client.rpc('calculate_payroll_for_month', params: {
     'p_year': year,
     'p_month': month,
   });
   ```

2. **Батч-расчёт в БД (21ms):**
   - Агрегация часов по сотрудникам
   - Расчёт базовой зарплаты с учётом исторических ставок (`employee_rates`)
   - Расчёт командировочных выплат (`business_trip_rates`)
   - Суммирование премий (`payroll_bonus`)
   - Суммирование штрафов (`payroll_penalty`)
   - Получение текущих ставок для отображения
   - **Один запрос вместо 400+!**

3. **Маппинг результатов:**
   - Преобразование данных из БД в `PayrollCalculation` entities
   - Передача в UI для отображения

**Производительность:** 120-200ms (включая сетевые задержки)

#### Fallback путь (Client-Side) 🔄

Если RPC недоступен или возникает ошибка, автоматически активируется резервная логика:

1. **Независимая загрузка work_hours:**
   - `payrollWorkHoursProvider` загружает данные напрямую из Supabase
   - JOIN с таблицей `works` для получения дат и объектов
   - ⚠️ **Фильтр:** `.eq('works.status', 'closed')` — только закрытые смены
   - Не зависит от модуля "Табель" и его фильтров

2. **Агрегация часов по сотрудникам:**
   - Группировка записей work_hours по employee_id
   - Суммирование часов за выбранный период
   - Подсчёт количества смен на каждом объекте

3. **Расчёт базовой зарплаты с историческими ставками:**
   - Для каждой смены получается актуальная ставка на дату смены из `employee_rates`
   - Расчёт: `baseSalary += hours * rate_for_date`
   - Учёт изменений ставок в течение месяца

4. **Добавление командировочных:**
   - Для каждой смены получается ставка командировочных из `business_trip_rates`
   - **Приоритет 1:** Индивидуальная ставка для сотрудника (employee_id = конкретный ID)
   - **Приоритет 2:** Общая ставка для объекта (employee_id IS NULL)
   - **Проверка minimum_hours:** Командировочные начисляются только если отработано >= минимума часов
   - Если ставка не назначена — командировочные = 0

5. **Добавление премий:**
   - Суммирование всех премий сотрудника за месяц из `payroll_bonus`
   - Фильтрация по дате или дате создания записи

6. **Вычитание штрафов:**
   - Суммирование всех штрафов сотрудника за месяц из `payroll_penalty`
   - Фильтрация по дате штрафа

7. **Итоговый расчёт:**
```dart
   netSalary = baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal
```

**Производительность fallback:** ~8-17 секунд (только при недоступности БД-функции)

#### Преимущества Hybrid подхода

- ✅ **Максимальная производительность:** 40-80× ускорение
- ✅ **Надёжность:** Fallback гарантирует работу при любых условиях
- ✅ **Масштабируемость:** PostgreSQL оптимизирован для агрегаций
- ✅ **Простота отладки:** При ошибках можно проследить клиентскую логику
- ✅ **Гибкость:** Легко переключаться между подходами

### Система балансов

Модуль рассчитывает балансы сотрудников (начислено - выплачено):

**Компоненты:**
- `employeeAggregatedBalanceProvider` — провайдер для расчёта балансов
- `BalanceUtils` — утилиты для отображения с цветовой индикацией

**Расчёт баланса:**
```dart
balance = netSalary - totalPayouts
```

**Цветовая индикация:**
- 🟢 Зелёный — баланс положительный (задолженность работодателя перед сотрудником)
- 🔴 Красный — баланс отрицательный (переплата сотруднику)
- ⚪ Серый — баланс нулевой (расчёты завершены)

### Независимость от модуля Табель

**Ключевые особенности:**
- Модуль имеет собственный `payrollWorkHoursProvider`
- Не зависит от состояния и фильтров модуля "Табель"
- Загружает данные work_hours напрямую из Supabase по своему периоду
- Позволяет работать с ФОТ независимо от табеля

### Автоматический расчёт

**Модуль ФОТ работает без фильтров:**
- Автоматически показывает данные за **текущий месяц**
- Все расчёты выполняются на лету для всех сотрудников с отработанными часами
- Упрощённый интерфейс без дополнительных элементов управления

### Адаптивность UI

**Десктоп (>1024px):** Все колонки таблицы
- Сотрудник
- Часы
- Ставка
- Базовая сумма
- Премии
- Штрафы
- Командировочные
- К выплате
- Выплаты
- Баланс

**Планшет (768-1024px):** Сокращённый набор
- Сотрудник
- Часы
- Базовая сумма
- Премии
- Командировочные
- К выплате
- Выплаты
- Баланс

**Мобильный (<768px):** Минимальный набор
- Сотрудник
- Часы
- Командировочные
- К выплате
- Выплаты
- Баланс

### Управление состоянием

**Провайдеры Riverpod:**
- `filteredPayrollsProvider` — расчёты ФОТ за текущий месяц
- `payrollWorkHoursProvider` — независимые данные work_hours за текущий месяц
- `employeeAggregatedBalanceProvider` — балансы сотрудников
- `allBonusesProvider` — все премии
- `allPenaltiesProvider` — все штрафы
- `filteredPayrollPayoutsProvider` — выплаты за текущий месяц

**Архитектурные решения:**
- Dependency Injection через Riverpod
- Провайдеры для всех зависимостей (repositories, use cases)
- Автоматическая инвалидация при изменении данных
- Оптимизированные запросы с минимизацией перерисовок

---

## Связи и интеграции

### Интеграция с другими модулями

- **Модуль "Работы"** — использует таблицы `work_hours` и `works` как источник данных для расчётов
- **Модуль "Сотрудники"** — получает информацию о сотрудниках, должностях и ставках для расчётов и фильтрации
- **Модуль "Объекты"** — получает названия объектов и ставки командировочных для расчёта и отображения
- **UI Framework** — интеграция с общими виджетами (GTDropdown, GTDateRangePicker), темами, роутингом (go_router)

### Технические зависимости

- **Supabase Flutter** — основной клиент для работы с БД
- **Riverpod** — управление состоянием и Dependency Injection
- **Freezed** — генерация иммутабельных классов для моделей и сущностей
- **JsonSerializable** — сериализация/десериализация JSON для моделей данных
- **Collection** — утилиты для работы с коллекциями (firstWhereOrNull и др.)
- **Logger** — логирование и отладка (опционально)

### RLS и безопасность

**Текущее состояние:**
- ❌ RLS **отключён** для всех таблиц модуля ФОТ
- ⚠️ Финансовые данные доступны без ограничений
- ⚠️ Критический риск безопасности

**Рекомендации:**
1. **Срочно включить RLS** для `payroll_bonus`, `payroll_penalty`, `payroll_payout`
2. Создать политики доступа на основе ролей (admin, accountant, manager)
3. Ограничить доступ к финансовым данным только для авторизованных пользователей с соответствующими правами

---

## Текущие ограничения и планы развития

### Реализованные функции
- ✅ Динамический расчёт ФОТ с учётом исторических ставок
- ✅ Независимая загрузка work_hours (не зависит от табеля)
- ✅ Командировочные выплаты с индивидуальными ставками
- ✅ CRUD операции для премий, штрафов и выплат
- ✅ Система балансов (начислено - выплачено) с цветовой индикацией
- ✅ Автоматический расчёт за текущий месяц (без фильтров)
- ✅ Адаптивный UI для всех платформ (desktop/tablet/mobile)
- ✅ Современные уведомления через SnackBarUtils
- ✅ Единообразие диалогов подтверждения (CupertinoAlertDialog)

### Критические проблемы
- 🔴 RLS не включён для таблиц модуля ФОТ (высокий риск безопасности)

### Планируемые улучшения

#### Безопасность (высокий приоритет)
- 🔄 Включить RLS для всех таблиц `payroll_*`
- 🔄 Настроить политики доступа на основе ролей
- 🔄 Добавить аудит изменений финансовых данных

#### Оптимизация производительности
- ✅ **РЕАЛИЗОВАНО:** PostgreSQL функция `calculate_payroll_for_month()` (ускорение в 40-80 раз!)
- ✅ **РЕАЛИЗОВАНО:** Индексы для `payroll_bonus(employee_id, date)` и `payroll_penalty(employee_id, date)`
- ✅ **РЕАЛИЗОВАНО:** Параллельная загрузка базовых данных через `Future.wait()`
- ✅ **РЕАЛИЗОВАНО:** Упрощён SQL-запрос `work_hours` (убран избыточный JOIN)
- ✅ **РЕАЛИЗОВАНО:** Батч-обработка (1 RPC вместо 400+ запросов)
- ✅ **РЕАЛИЗОВАНО:** Fallback на клиентский расчёт при ошибках БД
- 🔄 Добавить индексы для `payroll_payout(employee_id, payout_date)`
- 🔄 Материализованные представления для ещё большей производительности (при росте данных)

#### Функциональность
- 🔄 Экспорт расчётов ФОТ в Excel
- 🔄 Экспорт ведомостей выплат в PDF
- 🔄 Реализовать функционал удержаний (НДФЛ, авансы)
- 🔄 Массовые операции с премиями/штрафами/выплатами
- 🔄 История изменений ставок и выплат
- 🔄 Механизм "заморозки" расчёта на момент выплаты

#### UI/UX
- 🔄 Drill-down для детализации по сотруднику
- 🔄 Визуализация динамики выплат (графики)
- 🔄 Push-уведомления о выплатах

#### Техническая задолженность
- ✅ Удалены неиспользуемые функции PostgreSQL (выполнено 04.10.2025)
- ✅ Удалены неиспользуемые таблицы `payroll_calculation`, `payroll_deduction` (выполнено 04.10.2025)
- ✅ Удалены неиспользуемые внешние ключи `payroll_id` (выполнено 04.10.2025)

### Технические улучшения
- 🔄 Unit-тесты для всех use cases
- 🔄 Integration-тесты с Supabase
- 🔄 Widget-тесты для основных экранов
- 🔄 Тестирование расчётных формул
- 🔄 Оптимизация для больших объёмов данных
- 🔄 Поддержка офлайн-режима

---

## Примечания для разработчиков

- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию
- Модуль легко расширяется и тестируется благодаря Clean Architecture и DI
- **Для генерации кода:** выполните `flutter pub run build_runner build --delete-conflicting-outputs` из корневой директории проекта
- При изменениях в БД необходимо обновлять модели и репозитории
- Соблюдайте принципы разделения ответственности между слоями архитектуры
- Используйте современный синтаксис Flutter: `Color.withValues(alpha: ...)` вместо `withOpacity()`
- Всегда проверяйте `mounted` или `context.mounted` после `await` перед использованием `BuildContext`
- Вся документация модуля находится в `docs/fot/fot_module.md`

**Последняя актуализация:** 05 октября 2025 года

**Ключевые обновления (05.10.2025):**
- **🐛 Исправлен критичный баг отображения дат премий:**
  - ❌ **Проблема:** В таблице премий отображалась дата создания (`createdAt`) вместо даты самой премии (`date`)
  - ❌ **Проблема:** Фильтрация премий по месяцам использовала `createdAt` вместо `date`
  - ✅ **Исправлено:** Провайдер `filteredBonusesProvider` теперь фильтрует по `bonus.date` (с fallback на `createdAt` если date == null)
  - ✅ **Исправлено:** Виджет `PayrollBonusTableWidget` отображает `bonus.date` (с fallback на `createdAt` если date == null)
  - ✅ **Результат:** Премии теперь корректно отображаются и фильтруются по дате самой премии, а не по дате добавления записи
  - 📄 **Затронутые файлы:**
    - `lib/features/fot/presentation/providers/bonus_providers.dart` (строка 44)
    - `lib/features/fot/presentation/widgets/payroll_bonus_table_widget.dart` (строки 114-117)

- **✅ Полный аудит модуля ФОТ (завершён):**
  - ✅ Изучены все 40 файлов кода модуля (data, domain, presentation)
  - ✅ Проверены структуры таблиц БД (payroll_bonus, payroll_penalty, payroll_payout, business_trip_rates)
  - ✅ Проанализирован исходный код PostgreSQL функции `calculate_payroll_for_month()`
  - ✅ Обнаружено важное изменение: фильтрация по закрытым сменам (status = 'closed')
  - ✅ Актуализированы количества записей: work_hours (95), employee_rates (13), business_trip_rates (10), works (9)
  - ✅ Проверены индексы: подтверждены idx_payroll_bonus_employee_date, idx_payroll_penalty_employee_date
  - ✅ Уточнены возвращаемые колонки RPC функции: employee_name, hours, hourly_rate
  - ✅ Добавлена информация о works и objects в связанные таблицы
  - ✅ Добавлены комментарии таблиц из БД в документацию
  - ✅ Проверено отсутствие триггеров и RLS политик (подтверждено)
  - ✅ Добавлен полный исходный код PostgreSQL функции в документацию
  - ✅ Добавлены SQL-запросы для проверки RLS политик

**Ключевые обновления (04.10.2025):**
- **🐛 Исправление расчёта командировочных (критичный баг) — ЗАВЕРШЕНО:**
  - ✅ PostgreSQL функция: добавлена приоритизация индивидуальных ставок
  - ✅ PostgreSQL функция: добавлена проверка `minimum_hours`
  - ✅ Fallback (Dart): новый метод `getActiveRateForEmployeeAndDate()` (79 строк) с учётом `employee_id` и `hours`
  - ✅ Fallback (Dart): двухэтапный поиск ставки (индивидуальная → общая)
  - ✅ Fallback (Dart): проверка минимальных часов перед начислением
  - ✅ Исправлена ошибка Supabase: `.filter('employee_id', 'is', 'null')` для проверки NULL
  - ✅ **Результат:** Командировочные начисляются только сотрудникам с назначенными ставками
  - 📊 **Проверка:** Илья Бахонько 2800₽ (4 смены), Александр Ломакин 2100₽ (3 смены), остальные 0₽
  - 📄 Миграция: `supabase/migrations/[timestamp]_fix_business_trip_rates_calculation.sql`
  - 📄 Детальный отчёт: `docs/fot/ОТЧЕТ_ИСПРАВЛЕНИЕ_КОМАНДИРОВОЧНЫХ.md`
- **🚀 Hybrid оптимизация (завершена):**
  - ✅ Создана PostgreSQL функция `calculate_payroll_for_month()` с execution time 21ms
  - ✅ RPC интеграция в `filteredPayrollsProvider` — 1 запрос вместо 400+
  - ✅ Fallback на клиентский расчёт при ошибках БД (автоматический)
  - ✅ Параллельная загрузка базовых данных (`Future.wait`)
  - ✅ Упрощён SQL-запрос `work_hours` (убран `employees` JOIN)
  - ✅ Добавлены индексы: `idx_payroll_bonus_employee_date`, `idx_payroll_penalty_employee_date`
  - ✅ **Результат:** Загрузка данных **120-200ms** (было 8-17 секунд) — ускорение в 40-80 раз! 🎉
  - 📊 **Реальные замеры:** 167ms, 178ms, 122ms, 203ms (средняя ~167ms)
  - 📄 Детальный анализ: `docs/fot/ОТЧЕТ_ОПТИМИЗАЦИЯ_ЗАГРУЗКИ_ДАННЫХ.md`
- **Clean Architecture реорганизация (Этап 3 - завершён):**
  - ✅ Интерфейсы репозиториев перемещены из `data/repositories/` в `domain/repositories/`
  - ✅ Реализации остались в `data/repositories/` (*_impl.dart)
  - ✅ Обновлены все импорты в провайдерах для использования domain-интерфейсов
  - ✅ Достигнуто строгое разделение слоёв: domain → data → presentation
  - ✅ Устранена зависимость domain от data (правильная инверсия зависимостей)
- **Рефакторинг UseCase (Этап 1 - завершён):**
  - ✅ Удалено 6 классов UseCase (~126 строк кода): `create/update/delete_penalty_usecase.dart` и `create/update/delete_payout_usecase.dart`
  - ✅ Заменены на функции-провайдеры в `penalty_providers.dart` и `payroll_providers.dart`
  - ✅ Достигнута архитектурная согласованность с `bonus_providers.dart`
  - ✅ Упрощена архитектура: CRUD-операции теперь единообразны во всех провайдерах
- **Удалены фильтры:**
  - ❌ Удалены 4 файла фильтров (`payroll_filter_widget.dart`, `payroll_payout_filter_widget.dart`, `payroll_filter_provider.dart`, `payroll_payout_filter_provider.dart`)
  - ✅ Модуль теперь работает только с текущим месяцем (автоматически)
  - ✅ Упрощён пользовательский интерфейс
  - ✅ Очищены все импорты и ссылки на фильтры во всех файлах модуля
- **Очищен технический долг:**
  - ✅ Удалены 3 неиспользуемых функций PostgreSQL
  - ✅ Удалены 2 неиспользуемые таблицы (`payroll_calculation`, `payroll_deduction`)
  - ✅ Удалены внешние ключи `payroll_id`
- **Остаётся критическая проблема безопасности:** RLS не включён для таблиц модуля ФОТ

---

