# Модуль Employees (Сотрудники)

_Обновлено: 08.01.2026_ (Интеграция Multi-tenancy)

## Назначение

Модуль **Employees** обеспечивает полный цикл управления персоналом: хранение анкетных данных, назначение ставок, привязку к объектам, планирование работ и участие в расчёте заработной платы. Реализация построена по принципам Clean Architecture, использует Riverpod для управления состоянием, Freezed/JsonSerializable для моделей и Supabase в качестве единого источника данных. 

**Поддержка Multi-tenancy**: Все данные изолированы на уровне компании через `company_id`.

## Архитектура и состав

### Presentation (`lib/features/employees/presentation`)
- `screens/employees_list_screen.dart` — мастер-детейл список сотрудников с поиском, фильтрами, адаптивным layout и быстрыми действиями.
- `screens/employee_details_screen.dart` — карточка сотрудника c вкладками по документам, объектам, ставкам и действиям.
- `screens/employee_form_screen.dart` — форма создания/редактирования с валидацией, асинхронной загрузкой и обработкой ошибок. Теперь учитывает `activeCompanyIdProvider`.
- `widgets/employee_card.dart` — карточка списка (compact/regular режимы, подсветка текущего выбора).
- `widgets/employee_statistics_modal.dart` — модальное окно со статистикой по статусам и должностям.
- `widgets/employee_rate_history_widget.dart` — исторический граф ставок с данными из `employee_rates`.
- `widgets/employee_statistics_modal.dart`, `form_widgets.dart`, `master_detail_layout.dart`, `search_field.dart` — переиспользуемые элементы UI (адаптивные, используют `Color.withValues`).

### Domain (`lib/domain`)
- `entities/employee.dart` — доменная модель, включает `companyId`.
- `entities/employee_rate.dart` — ставки сотрудников, включают `companyId`.
- `repositories/employee_repository.dart` — контракт для управления сотрудниками.
- `repositories/employee_rate_repository.dart` — контракт для управления ставками.

### Data (`lib/data`)
- `models/employee_model.dart` — JSON-адаптер с поддержкой `company_id`.
- `models/employee_rate_model.dart` — JSON-адаптер с поддержкой `company_id`.
- `datasources/employee_data_source.dart` — `SupabaseEmployeeDataSource` с принудительной фильтрацией по `activeCompanyId`.
- `repositories/employee_repository_impl.dart` — реализация с поддержкой Multi-tenancy.

### Core/DI
- `core/di/providers.dart` — регистрация провайдеров с учетом `activeCompanyIdProvider`.
- `presentation/state/employee_state.dart` — `EmployeeNotifier`, управляет состоянием сотрудников внутри текущей компании.

## Пользовательские сценарии
- Просмотр каталога сотрудников текущей компании.
- Создание сотрудника с автоматической привязкой к активной компании.
- Управление ставками и посещаемостью в контексте Multi-tenancy.

## Управление состоянием и зависимости
- `activeCompanyIdProvider` — обязательная зависимость для всех запросов к БД.
- `employeeProvider` — основное состояние модуля.

## Supabase: структура данных

### Таблица `employees`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Уникальный идентификатор сотрудника |
| `company_id` | uuid (FK) | NO | — | Ссылка на компанию (Multi-tenancy) |
| `last_name` | text | NO | — | Фамилия |
| `first_name` | text | NO | — | Имя |
| ... | ... | ... | ... | ... |

**RLS-политики**
- `Users can view employees of their companies` — SELECT на основе `company_id IN (public.get_my_company_ids())`.
- `Users can manage employees of their companies` — ALL на основе `company_id IN (public.get_my_company_ids())`.

### Таблица `employee_rates`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Идентификатор записи |
| `company_id` | uuid (FK) | NO | — | Ссылка на компанию |
| `employee_id` | uuid (FK) | NO | — | Ссылка на сотрудника |
| `hourly_rate` | numeric | NO | — | Почасовая ставка |
| ... | ... | ... | ... | ... |

**RLS**
- Изоляция данных по `company_id`.

### Таблица `employee_attendance`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Идентификатор записи |
| `company_id` | uuid (FK) | NO | — | Ссылка на компанию |
| `employee_id` | uuid (FK) | NO | — | Ссылка на сотрудника |
| ... | ... | ... | ... | ... |

**RLS**
- Изоляция данных по `company_id`.

### Таблица `profiles`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK, FK → `auth.users.id`) | NO | — | Пользователь Supabase Auth |
| `full_name` | text | YES | — | Полное ФИО |
| `short_name` | text | YES | — | Сокращённое ФИО (генерируется триггером) |
| `photo_url` | text | YES | — | Аватар |
| `email` | text (unique) | NO | — | Email |
| `phone` | text | YES | — | Телефон |
| `role` | text | YES | `'user'::text` | Роль (`user`, `admin`, др.) |
| `status` | boolean | YES | `false` | Флаг одобрения/активации |
| `object` | jsonb | YES | — | Дополнительные данные |
| `created_at` | timestamptz | YES | `timezone('utc', now())` | Создание |
| `updated_at` | timestamptz | YES | `timezone('utc', now())` | Обновление |
| `object_ids` | uuid[] | YES | — | Доступные объекты |
| `approved_at` | timestamptz | YES | — | Время одобрения |
| `disabled_at` | timestamptz | YES | — | Время отключения |
| `slot_times` | text[] | YES | — | Диапазоны доступности |
| `employee_id` | uuid (FK → `employees.id`) | YES | — | Привязанный сотрудник |

**Триггеры**
- `before_profiles_insert_update` → `generate_short_name()` — заполняет `short_name` из `full_name`.
- `profiles_updated_at` → `handle_updated_at()` — обновляет `updated_at`.
- `profiles_status_ts` → `profile_status_timestamps()` — следит за `approved_at`/`disabled_at`.

**RLS**
- SELECT доступ для аутентифицированных.
- UPDATE: владелец профиля или администратор.
- INSERT: допускается через сервисную функцию.

### Таблица `work_plans`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | План работ |
| `created_at` | timestamptz | NO | `timezone('utc', now())` | Создание |
| `updated_at` | timestamptz | NO | `timezone('utc', now())` | Обновление |
| `created_by` | uuid (FK → `auth.users.id`) | NO | — | Автор |
| `date` | date | NO | — | Дата плана |
| `object_id` | uuid (FK → `objects.id`) | NO | — | Объект |

### Таблица `work_plan_blocks`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Блок плана |
| `created_at` | timestamptz | NO | `timezone('utc', now())` | Создание |
| `updated_at` | timestamptz | NO | `timezone('utc', now())` | Обновление |
| `work_plan_id` | uuid (FK → `work_plans.id`) | NO | — | Связь с планом |
| `system` | text | NO | — | Система (trim > 0) |
| `section` | text | YES | — | Секция |
| `floor` | text | YES | — | Этаж |
| `responsible_id` | uuid (FK → `employees.id`) | YES | — | Ответственный |
| `worker_ids` | uuid[] | NO | `'{}'::uuid[]` | Исполнители |

**Триггеры**
- `trg_work_plan_blocks_updated_at` → `set_updated_at()` — обновление `updated_at`.
- `trg_work_plan_block_responsible_check` → `ensure_responsible_is_allowed()` — проверка допуска ответственного к объекту и статуса.

**RLS**
- INSERT/UPDATE/DELETE: автор плана или администратор (`user_roles.role = 'admin'`).
- SELECT: автор, администратор или пользователи с доступом к объекту (`profiles.object_ids @> object_id`).

### Таблица `work_hours`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Запись учёта часов |
| `work_id` | uuid (FK → `works.id`) | NO | — | Смена |
| `employee_id` | uuid (FK → `employees.id`) | NO | — | Сотрудник |
| `hours` | numeric | NO | — | Количество часов |
| `comment` | text | YES | — | Комментарий |
| `created_at` | timestamptz | NO | `timezone('utc', now())` | Создание |
| `updated_at` | timestamptz | NO | `timezone('utc', now())` | Обновление |

**RLS**
- Набор политик `Allow ... via works/shifts` ограничивает доступ администраторами и пользователями, привязанными к объекту смены (`profiles.object_ids`).

### Таблицы `payroll_calculation`, `payroll_bonus`, `payroll_penalty`, `payroll_deduction`, `payroll_payout`

- Все таблицы содержат FK `employee_id` → `employees.id` и относятся к модулю ФОТ.
- `payroll_calculation`: расчёт зарплаты за период (месяц), хранит часы, ставки, суммы начислений и удержаний, статус (`draft` по умолчанию).
- `payroll_bonus` / `payroll_penalty`: дополнительные начисления и штрафы (опционально привязаны к объекту и расчёту).
- `payroll_deduction`: удержания с обязательной ссылкой на `payroll_id`.
- `payroll_payout`: зарегистрированные выплаты (`method`, `type`, `is_official`).

RLS на payroll-таблицах пока отключён — доступ предоставляется сервисными ключами.

### Дополнительные связи
- `profiles.employee_id` ↔ `employees.id` — привязка пользователя к карточке сотрудника.
- `work_plan_blocks.worker_ids` — список исполнителей (uuid) для распределения работ.
- `work_hours.employee_id` — учёт часов по сотруднику.
- `employee_rates.employee_id` — история ставок, синхронизируется с UI модуля сотрудников и ФОТ.

## Функции и триггеры Supabase
- `ensure_responsible_is_allowed()` — проверяет, что ответственный активен (`status = 'working'`), имеет `can_be_responsible = true` и привязан к объекту плана.
- `set_updated_at()` — унифицированно обновляет `updated_at` в блоках плана (UTC).
- `generate_short_name()` — формирует `short_name` в профиле из `full_name` (формат «Фамилия И.О.»).
- `handle_updated_at()` — записывает `NOW()` в `profiles.updated_at`.
- `profile_status_timestamps()` — управляет `approved_at` и `disabled_at` при смене статуса профиля.

## Потоки данных
1. UI вызывает методы `EmployeeNotifier` → use-case → репозиторий → Supabase DataSource.
2. DataSource выполняет SQL через `supabase_flutter` (PostgREST): JSON → `EmployeeModel` → `Employee`.
3. Изменения `can_be_responsible` записываются в БД и обновляют локальный кэш `canBeResponsibleMap`.
4. Work Plans и Works используют общий провайдер, избегая повторных запросов и обеспечивая согласованность.

## Тестирование и контроль качества
- Юнит-тесты для use-case (валидация данных, обработка ошибок Supabase).
- Интеграционные тесты (Flutter `integration_test`) — сценарии CRUD, фильтрация, статистика.
- RLS smoke-тесты под ролями `admin` и `user` для проверки политик.
- Performance: сортировка/поиск выполняются на клиенте, кэш `EmployeeNotifier` снижает нагрузку.

## Рекомендации по развитию
- Перенести часть фильтрации по статусу/объекту на уровне PostgREST для оптимизации при росте базы.
- Добавить аудит изменений ставок (отдельная таблица логов или расширение `employee_rates`).
- Рассмотреть Edge Function для пакетного обновления статусов и привязок к объектам.

