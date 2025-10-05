# Модуль Employees (Сотрудники)

_Обновлено: 02.10.2025_

## Назначение

Модуль **Employees** обеспечивает полный цикл управления персоналом: хранение анкетных данных, назначение ставок, привязку к объектам, планирование работ и участие в расчёте заработной платы. Реализация построена по принципам Clean Architecture, использует Riverpod для управления состоянием, Freezed/JsonSerializable для моделей и Supabase в качестве единого источника данных.

## Архитектура и состав

### Presentation (`lib/features/employees/presentation`)
- `screens/employees_list_screen.dart` — мастер-детейл список сотрудников с поиском, фильтрами, адаптивным layout и быстрыми действиями.
- `screens/employee_details_screen.dart` — карточка сотрудника c вкладками по документам, объектам, ставкам и действиям.
- `screens/employee_form_screen.dart` — форма создания/редактирования с валидацией, асинхронной загрузкой и обработкой ошибок.
- `widgets/employee_card.dart` — карточка списка (compact/regular режимы, подсветка текущего выбора).
- `widgets/employee_statistics_modal.dart` — модальное окно со статистикой по статусам и должностям.
- `widgets/employee_rate_history_widget.dart` — исторический граф ставок с данными из `employee_rates`.
- `widgets/employee_statistics_modal.dart`, `form_widgets.dart`, `master_detail_layout.dart`, `search_field.dart` — переиспользуемые элементы UI (адаптивные, используют `Color.withValues`).

### Domain (`lib/domain`)
- `entities/employee.dart` — доменная модель, enum `EmploymentType`, `EmployeeStatus`.
- `entities/employee_rate.dart` — ставки сотрудников (история тарифов).
- `repositories/employee_repository.dart` — контракт для use-cases и тестирования.
- Use-cases `create/get/update/delete_employee_usecase.dart`, сценарии `employee_rate` — оборачивают доступ к репозиторию и инкапсулируют бизнес-правила.

### Data (`lib/data`)
- `models/employee_model.dart` — JSON-адаптер (Freezed + JsonSerializable, snake_case поля, списки объектов).
- `datasources/employee_data_source.dart` — реализация `SupabaseEmployeeDataSource`, отвечает за CRUD, кэширование `can_be_responsible`, фильтрацию ответственных.
- `repositories/employee_repository_impl.dart` — перевод доменных сущностей в модели и обратно, оборачивание Supabase вызовов в доменный слой.
- `migrations` (например, `employees_migration.sql`, `20250911140600_add_employee_fields_to_work_plans.sql`) — поддерживают схемы таблиц и политики безопасности.

### Core/DI
- `core/di/providers.dart` — регистрация data source, репозитория, use-case и `employeeProvider`.
- `presentation/state/employee_state.dart` — `EmployeeNotifier` (Riverpod `StateNotifier`), кэширует список, детали, флаг `can_be_responsible`, поиск.

## Пользовательские сценарии
- Просмотр каталога сотрудников с поиском по ФИО, должности и телефону.
- Детальный просмотр с историей ставок и быстрым переходом к связанным объектам.
- Создание и редактирование карточек (включая паспортные данные и привязку к объектам).
- Управление флагом «может быть ответственным» (desktop-тоггл, проверка на стороне БД).
- Масштабируемая статистика по статусам и должностям (модальное окно).
- Интеграция с Work Plans (назначение ответственных/исполнителей), Work Hours (учёт часов), FOT/Payroll (начисления, удержания, выплаты).

## Управление состоянием и зависимости
- `employeeProvider` (`StateNotifierProvider`) — единая точка доступа к состоянию сотрудников.
  - Кэш `Employee` и `canBeResponsibleMap`, повторное использование между экранами.
  - Ленивая загрузка, `refreshEmployees()` для принудительного обновления.
  - Методы CRUD, переключатель `toggleCanBeResponsible`, защищён повторным чтением Supabase.
- Взаимодействие с другими провайдерами: `authProvider` (роль пользователя, RLS), `objectProvider` (подтягивание объектов для фильтров и проверки доступов).
- Обработка ошибок централизована: ошибки Supabase попадают в `errorMessage`, UI отображает `SnackBar`/диалоги.

## Интеграции с другими модулями
- **Work Plans:** выбор ответственных и исполнителей через кэш сотрудников; триггер `ensure_responsible_is_allowed` предотвращает назначение недоступных сотрудников.
- **Works / Timesheet:** вкладка «Сотрудники» и формы учёта часов используют общий `employeeProvider`.
- **Profiles:** связка профиля приложения с сотрудником по `profiles.employee_id`; авто-генерация `short_name` и слежение за статусом.
- **FOT (финансовый модуль):** таблицы расчётов (`payroll_*`) завязаны на `employees.id` как FK для начислений, штрафов, удержаний и выплат.

## Supabase: структура данных

### Таблица `employees`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Уникальный идентификатор сотрудника |
| `photo_url` | text | YES | — | Ссылка на фото в Supabase Storage |
| `last_name` | text | NO | — | Фамилия |
| `first_name` | text | NO | — | Имя |
| `middle_name` | text | YES | — | Отчество |
| `birth_date` | timestamptz | YES | — | Дата рождения (UTC) |
| `birth_place` | text | YES | — | Место рождения |
| `citizenship` | text | YES | — | Гражданство |
| `phone` | text | YES | — | Номер телефона |
| `clothing_size` | text | YES | — | Размер одежды |
| `shoe_size` | text | YES | — | Размер обуви |
| `height` | text | YES | — | Рост (строка, учитывает единицы) |
| `employment_date` | timestamptz | YES | — | Дата приёма |
| `employment_type` | text | NO | `'official'::text` | Тип занятости (`official`, `contract`, `unofficial`) |
| `position` | text | YES | — | Должность |
| `status` | text | NO | `'working'::text` | Текущий статус (см. `EmployeeStatus`) |
| `passport_series` | text | YES | — | Серия паспорта |
| `passport_number` | text | YES | — | Номер паспорта |
| `passport_issued_by` | text | YES | — | Орган, выдавший паспорт |
| `passport_issue_date` | timestamptz | YES | — | Дата выдачи |
| `passport_department_code` | text | YES | — | Код подразделения |
| `registration_address` | text | YES | — | Адрес регистрации |
| `inn` | text | YES | — | ИНН |
| `snils` | text | YES | — | СНИЛС |
| `created_at` | timestamptz | YES | `now()` | Дата создания (UTC) |
| `updated_at` | timestamptz | YES | `now()` | Дата последнего обновления (UTC) |
| `object_ids` | text[] | YES | `ARRAY[]::text[]` | Массив идентификаторов объектов (UUID в текстовом виде) |
| `can_be_responsible` | boolean | NO | `false` | Признак допуска к роли ответственного |

**RLS-политики**
- `Users can view employees` — SELECT доступ для всех аутентифицированных.
- `Only admins can create/update/delete employees` — INSERT/UPDATE/DELETE доступны только пользователям с ролью `admin` в `profiles`.

### Таблица `employee_rates`

| Колонка | Тип | Nullable | По умолчанию | Описание |
| --- | --- | --- | --- | --- |
| `id` | uuid (PK) | NO | `gen_random_uuid()` | Идентификатор записи |
| `employee_id` | uuid (FK → `employees.id`) | NO | — | Ссылка на сотрудника |
| `hourly_rate` | numeric(10,2) | NO | — | Почасовая ставка |
| `valid_from` | date | NO | — | Дата начала действия |
| `valid_to` | date | YES | — | Дата окончания (null — открытый период) |
| `created_at` | timestamptz | YES | `now()` | Время создания |
| `created_by` | uuid (FK → `profiles.id`) | YES | — | Автор изменения |

**RLS**
- `Users can view employee rates` — SELECT для аутентифицированных.
- `Only admins can modify employee rates` — любые изменения доступны только администраторам.

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

