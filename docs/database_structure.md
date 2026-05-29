# Структура базы данных Supabase (актуально)

---

## Таблица `profiles`

**Описание:**
Профили пользователей приложения. Хранит расширенную информацию о каждом пользователе. В модели Multi-tenancy (v3) данные профиля (ФИО, телефон) являются общими, а права доступа определяются отдельно для каждой компании в `company_members`.

**Структура:**
- id: UUID, PK — уникальный идентификатор профиля, связь с auth.users
- full_name: TEXT — полное ФИО пользователя
- short_name: TEXT — сокращённое ФИО (например, инициалы)
- photo_url: TEXT — URL фотографии/аватара пользователя
- email: TEXT — email пользователя (уникальный)
- phone: TEXT — номер телефона в формате +7-(XXX)-XXX-XXXX
- last_company_id: UUID, FK — ID последней активной компании (связь с companies.id)
- created_at: TIMESTAMP — дата и время создания записи (UTC)
- updated_at: TIMESTAMP — дата и время последнего обновления записи (UTC)

**⚠️ Legacy (Устаревшие поля - НЕ ИСПОЛЬЗОВАТЬ ДЛЯ ОБНОВЛЕНИЯ):**
- role_id: UUID — (Удалено из UPDATE) Использовать `company_members.role_id`. Хранится здесь только для обратной совместимости и системных нужд.
- status: BOOLEAN — (Удалено из UPDATE) Использовать `company_members.is_active`.
- object: JSONB — (Удалить в v4) Перенесено в специализированные таблицы.
- object_ids: ARRAY(UUID) — (Удалить в v4) Перенесено в `employees` или `company_members`.

**Связи:**
- id → auth.users.id (FK)
- object_ids → objects.id (FK)
- opened_by (в works) → profiles.id (FK)
- last_company_id → companies.id (FK)

**RLS-политики:**
- ✅ Пользователь видит только свой профиль и профили коллег (участников тех же компаний).
- ✅ Обновление (`UPDATE`) доступно только владельцу профиля для полей `full_name`, `short_name`, `photo_url`, `phone`. Изменение ролей и статусов через эту таблицу запрещено.
- ✅ Автоматическое создание профиля при регистрации через триггер
- 🔐 Строгая изоляция: пользователи разных компаний не видят друг друга

---

## Таблица `companies`

**Описание:**
Справочник организаций в системе. Является корневым контейнером для всех данных в модели Multi-tenancy.

**Структура:**
- id: UUID, PK — уникальный идентификатор компании
- name_full: TEXT — полное юридическое наименование
- name_short: TEXT — краткое наименование
- owner_id: UUID, FK — ID владельца компании (ссылка на profiles.id)
- invitation_code: TEXT, Unique — уникальный код для вступления сотрудников
- is_active: BOOLEAN — статус активности компании
- logo_url: TEXT — URL логотипа
- inn, kpp, ogrn, okpo: TEXT — юридические реквизиты
- legal_address, actual_address: TEXT — адреса
- taxation_system: TEXT — система налогообложения
- is_vat_payer: BOOLEAN — плательщик НДС
- vat_rate: NUMERIC — ставка НДС
- created_at, updated_at: TIMESTAMPTZ — системные даты

**Связи:**
- owner_id → profiles.id (FK)
- id → company_members.company_id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (изоляция через `get_my_company_ids()`)
- ✅ Редактирование доступно только владельцу (owner_id)

---

## Таблица `company_members`

**Описание:**
Связующая таблица между пользователями и компаниями. **Центральный узел управления доступом (RBAC v3)**. Определяет права доступа пользователя внутри конкретной организации.

**Структура:**
- id: UUID, PK — идентификатор записи
- company_id: UUID, FK — ссылка на компанию
- user_id: UUID, FK — ссылка на профиль пользователя
- system_role: TEXT — системная роль (owner, admin или null)
- role_id: UUID, FK — ссылка на кастомную роль (roles.id)
- is_owner: BOOLEAN — флаг владельца (Legacy, дублирует system_role = 'owner')
- is_active: BOOLEAN — статус доступа пользователя к этой компании (блокировка)
- joined_at: TIMESTAMPTZ — дата вступления

**Связи:**
- company_id → companies.id (FK)
- user_id → profiles.id (FK)
- role_id → roles.id (FK)

**RLS-политики:**
- ✅ Чтение доступно всем активным участникам той же компании (через `get_my_company_ids()`).
- ✅ **Обновление (`UPDATE`)** доступно только **Владельцам компании** (`system_role = 'owner'`). Позволяет изменять `role_id`, `system_role` и `is_active` для участников.
- ✅ Вставка (`INSERT`) доступна при создании компании (авто-назначение owner) или вступлении.

---

## Таблица `company_bank_accounts`

**Описание:**
Банковские реквизиты компаний. Каждая компания может иметь несколько счетов.

**Структура:**
- id: UUID, PK — уникальный идентификатор записи
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- bank_name: TEXT — название банка
- account_number: TEXT — расчетный счет
- corr_account: TEXT — корр. счет
- bik: TEXT — БИК
- bank_city: TEXT — город банка
- is_primary: BOOLEAN — основной счет
- created_at: TIMESTAMPTZ — дата создания

**Связи:**
- company_id → companies.id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (через `get_my_company_ids()`)
- ✅ Управление доступно только участникам этой компании

---

## Таблица `company_documents`

**Описание:**
Юридические документы компании (сканы уставов, свидетельств и т.д.).

**Структура:**
- id: UUID, PK — уникальный идентификатор записи
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- type: TEXT — тип документа
- title: TEXT — заголовок
- number: TEXT — номер документа
- issue_date: DATE — дата выдачи
- expiry_date: DATE — дата окончания действия
- file_url: TEXT — ссылка на файл в Storage
- created_at: TIMESTAMPTZ — дата создания

**Связи:**
- company_id → companies.id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (через `get_my_company_ids()`)
- ✅ Управление доступно только участникам этой компании

---

## Таблица `employees`

**Описание:**
Справочник сотрудников. Хранит ФИО, паспортные данные, контакты, параметры для расчёта зарплаты, статус, связанные объекты. Полностью изолирована по компаниям.

**Структура:**
- id: UUID, PK — уникальный идентификатор сотрудника
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- photo_url: TEXT — URL фотографии сотрудника
- last_name: TEXT — фамилия сотрудника
- first_name: TEXT — имя сотрудника
- middle_name: TEXT — отчество сотрудника
- birth_date: TIMESTAMPTZ — дата рождения
- birth_place: TEXT — место рождения
- citizenship: TEXT — гражданство
- phone: TEXT — номер телефона
- clothing_size: TEXT — размер одежды
- shoe_size: TEXT — размер обуви
- height: TEXT — рост
- employment_date: TIMESTAMPTZ — дата приёма на работу
- employment_type: TEXT — тип занятости (`official`, `contract`)
- position: TEXT — должность
- status: TEXT — статус сотрудника (`working`, `dismissed`)
- passport_series: TEXT — серия паспорта
- passport_number: TEXT — номер паспорта
- passport_issued_by: TEXT — кем выдан паспорт
- passport_issue_date: TIMESTAMPTZ — дата выдачи паспорта
- passport_department_code: TEXT — код подразделения
- registration_address: TEXT — адрес регистрации
- inn: TEXT — ИНН
- snils: TEXT — СНИЛС
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления
- object_ids: ARRAY(UUID) — список id объектов, связанных с сотрудником

**Связи:**
- id → payroll_calculation.employee_id (FK)
- id → work_hours.employee_id (FK)
- company_id → companies.id (FK)

**RLS-политики:**
- ✅ Изоляция по `company_id` + матрица прав: `employees_select` / `employees_insert` / `employees_update` / `employees_delete` через `check_permission(uid(), 'employees', …)` ([`20260529180000_tighten_employees_card_rls.sql`](../supabase/migrations/20260529180000_tighten_employees_card_rls.sql), подробнее — [`employees/employees_module.md`](employees/employees_module.md))

---

## Таблица `employee_rates`

**Описание:**
История изменения ставок сотрудников.

**Структура:**
- id: UUID, PK — идентификатор записи
- company_id: UUID, FK — ссылка на компанию
- employee_id: UUID, FK — ссылка на сотрудника (`employees.id`)
- hourly_rate: NUMERIC — почасовая ставка
- valid_from: DATE — дата начала действия ставки
- valid_to: DATE — дата окончания (null — актуальная)
- created_at: TIMESTAMPTZ — дата создания
- created_by: UUID, FK — кто создал запись (`profiles.id`)

---

## Таблица `employee_attendance`

**Описание:**
Учёт посещаемости сотрудников (ручной ввод вне смен).

**Структура:**
- id: UUID, PK — идентификатор записи
- company_id: UUID, FK — ссылка на компанию
- employee_id: UUID, FK — ссылка на сотрудника (`employees.id`)
- object_id: UUID, FK — ссылка на объект (`objects.id`)
- date: DATE — дата посещения
- hours: NUMERIC — количество часов
- comment: TEXT — комментарий
- attendance_type: TEXT — тип посещения
- created_at: TIMESTAMPTZ — дата создания

---

## Таблица `contractors`

**Описание:**
Справочник контрагентов (организаций). Хранит реквизиты, контактные данные, тип, лого. Полностью изолирован по компаниям.

**Структура:**
- id: UUID, PK — уникальный идентификатор контрагента
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- logo_url: TEXT — URL логотипа организации
- full_name: TEXT — полное наименование организации
- short_name: TEXT — краткое наименование
- inn: TEXT — ИНН организации
- director: TEXT — ФИО директора
- legal_address: TEXT — юридический адрес
- actual_address: TEXT — фактический адрес
- phone: TEXT — контактный телефон
- email: TEXT — контактный email
- type: TEXT — тип контрагента (`customer`, `contractor`, `supplier`)
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- id → contracts.contractor_id (FK)
- company_id → companies.id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (через `get_my_company_ids()`)
- ✅ Изоляция данных гарантирована через `company_id`

---

## Таблица `contracts`

**Описание:**
Договоры с контрагентами по объектам. Фиксирует номер, даты, сумму, статус, связь с объектом и контрагентом.

**Структура:**
- id: UUID, PK — уникальный идентификатор договора
- number: TEXT — номер договора
- date: DATE — дата заключения договора
- end_date: DATE — дата окончания действия договора
- contractor_id: UUID — внешний ключ на contractors.id
- amount: NUMERIC — сумма по договору
- object_id: UUID — внешний ключ на objects.id
- status: TEXT — статус договора (`active`, `suspended`, `completed`)
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- contractor_id → contractors.id (FK)
- object_id → objects.id (FK)
- id → estimates.contract_id (FK)

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать

---

## Таблица `objects`

**Описание:**
Справочник строительных объектов. Содержит адрес, описание, сумму командировочных выплат. Изолирован по компаниям.

**Структура:**
- id: UUID, PK — уникальный идентификатор объекта
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- name: TEXT — наименование объекта
- address: TEXT — адрес объекта
- description: TEXT — описание объекта (опционально)
- business_trip_amount: NUMERIC — сумма командировочных выплат для всех сотрудников, работающих на объекте
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- id → works.object_id (FK)
- id → employees.object_ids (FK)
- id → contracts.object_id (FK)
- id → estimates.object_id (FK)
- company_id → companies.id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (через `get_my_company_ids()`)
- ✅ Изоляция данных гарантирована через `company_id`
- ✅ **`objects_select`:** `objects.read` **или** объект из `profiles.object_ids` **или** `employees.read` / `create` / `update` (picklist в модуле «Сотрудники» без экрана «Объекты») — [`20260529190000_employees_objects_picklist_rls.sql`](../supabase/migrations/20260529190000_employees_objects_picklist_rls.sql), см. [`objects/objects_module.md`](objects/objects_module.md)

---

## Таблица `works`

**Описание:**
Смены (рабочие периоды) на объекте. Фиксирует дату, статус, фото, кто открыл смену.

**Структура:**
- id: UUID, PK — уникальный идентификатор смены
- date: DATE — дата смены
- object_id: UUID — внешний ключ на objects.id
- opened_by: UUID — внешний ключ на profiles.id (кто открыл смену)
- status: TEXT — статус смены (`open`, `draft`, `closed`)
- photo_url: TEXT — URL фотографии смены (утро)
- evening_photo_url: TEXT — URL фотографии смены (вечер)
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- object_id → objects.id (FK)
- opened_by → profiles.id (FK)
- id → work_items.work_id, work_materials.work_id, work_hours.work_id (FK)

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать

---

## Таблица `work_items`

**Описание:**
Позиции работ в рамках смены. Детализация по смете, количеству, стоимости, разделу, этажу.

**Структура:**
- id: UUID, PK — уникальный идентификатор позиции работы
- work_id: UUID — внешний ключ на works.id
- section: TEXT — раздел работ (например, электрика, сантехника)
- floor: TEXT — этаж
- estimate_id: UUID — внешний ключ на estimates.id
- name: TEXT — наименование работы
- system: TEXT — система (например, отопление)
- subsystem: TEXT — подсистема
- unit: TEXT — единица измерения
- quantity: NUMERIC — количество
- price: DOUBLE — цена за единицу
- total: DOUBLE — итоговая сумма
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- work_id → works.id (FK)
- estimate_id → estimates.id (FK)

**RLS-политики:**
- Только участники смены или админ могут видеть/редактировать

---

## Таблица `work_materials`

**Описание:**
Учёт материалов, использованных в смене.

**Структура:**
- id: UUID, PK — уникальный идентификатор записи о материале
- work_id: UUID — внешний ключ на works.id
- name: TEXT — наименование материала
- unit: TEXT — единица измерения
- quantity: NUMERIC — количество
- comment: TEXT — комментарий
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- work_id → works.id (FK)

**RLS-политики:**
- Только участники смены или админ могут видеть/редактировать

---

## Таблица `work_hours`

**Описание:**
Учёт отработанных часов сотрудников в смене.

**Структура:**
- id: UUID, PK — уникальный идентификатор записи о часах
- work_id: UUID — внешний ключ на works.id
- employee_id: UUID — внешний ключ на employees.id
- hours: NUMERIC — количество отработанных часов
- comment: TEXT — комментарий
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- work_id → works.id (FK)
- employee_id → employees.id (FK)

**RLS-политики:**
- Только участники смены или админ могут видеть/редактировать

---

## Таблица `estimates`

**Описание:**
Сметы по объектам и договорам. Детализация по системе, подсистеме, артикулу, производителю, количеству, цене.

**Структура:**
- id: UUID, PK — уникальный идентификатор сметы
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- contract_id: UUID — внешний ключ на contracts.id
- object_id: UUID — внешний ключ на objects.id
- system: TEXT — система (например, электрика)
- subsystem: TEXT — подсистема
- name: TEXT — наименование позиции
- article: TEXT — артикул
- manufacturer: TEXT — производитель
- unit: TEXT — единица измерения
- quantity: DOUBLE — количество
- price: DOUBLE — цена за единицу
- total: DOUBLE — итоговая сумма
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления
- estimate_title: TEXT — заголовок сметы
- number: TEXT — номер сметы

**Связи:**
- company_id → companies.id (FK)
- contract_id → contracts.id (FK)
- object_id → objects.id (FK)
- id → work_items.estimate_id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (через `get_my_company_ids()`)

---

## Таблица `work_plans`

**Описание:**
Планы работ по объектам и системам. Содержит запланированные работы с указанием даты, объекта, участка, этажа, системы и списка выбранных работ.

**Структура:**
- id: UUID, PK — уникальный идентификатор плана работ
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления записи
- created_by: UUID — внешний ключ на auth.users.id (пользователь, создавший план)
- date: DATE — дата выполнения плана работ
- object_id: UUID — внешний ключ на objects.id (объект)
- section: TEXT — участок объекта (опционально)
- floor: TEXT — этаж объекта (опционально)
- system: TEXT — система работ (электрика, сантехника и т.д.)
- selected_works: JSONB — массив выбранных работ (ID из estimates с дополнительными данными)
- status: TEXT — статус плана работ (`draft`, `active`, `completed`, `cancelled`)
- comment: TEXT — комментарий к плану работ (опционально)
- priority: TEXT — приоритет плана работ (`low`, `normal`, `high`, `urgent`)

**Связи:**
- created_by → auth.users.id (FK)
- object_id → objects.id (FK)

**RLS-политики:**
- Только участники объекта или админ могут видеть планы работ
- Пользователи могут создавать планы только для объектов, к которым у них есть доступ
- Пользователи могут обновлять только свои планы работ
- Пользователи могут удалять только свои планы работ

---

## Таблица `payroll_calculation`

**Описание:**
Расчёт заработной платы сотрудника за месяц. Содержит все суммы, ставки, начисления, удержания, итоговые значения.

**Структура:**
- id: UUID, PK — уникальный идентификатор расчёта
- employee_id: UUID — внешний ключ на employees.id
- period_month: DATE — месяц расчёта (YYYY-MM-01)
- hours_worked: NUMERIC — отработано часов за период
- hourly_rate: NUMERIC — почасовая ставка
- base_salary: NUMERIC — базовая сумма начисления
- bonuses_total: NUMERIC — сумма всех премий
- penalties_total: NUMERIC — сумма всех штрафов
- deductions_total: NUMERIC — сумма всех удержаний
- gross_salary: NUMERIC — начисленная сумма (до вычета)
- net_salary: NUMERIC — сумма к выплате (на руки)
- status: TEXT — статус расчёта (`draft`, `approved`)
- created_at: TIMESTAMP — дата и время создания записи
- updated_at: TIMESTAMP — дата и время последнего обновления

**Связи:**
- employee_id → employees.id (FK)
- id → payroll_bonus.payroll_id, payroll_penalty.payroll_id, payroll_deduction.payroll_id, payroll_payout.payroll_id (FK)

**RLS-политики:**
- (RLS не включён)

---

## Таблица `payroll_bonus`

**Описание:**
Бонусы, премии, надбавки по расчёту зарплаты.

**Структура:**
- id: UUID, PK — уникальный идентификатор бонуса
- payroll_id: UUID, FK — внешний ключ на payroll_calculation.id
- employee_id: UUID, FK — внешний ключ на employees.id (новое поле, 2024-05-21)
- type: TEXT — тип бонуса/премии
- amount: NUMERIC — сумма бонуса
- reason: TEXT — причина начисления
- created_at: TIMESTAMP — дата и время создания записи

**Связи:**
- payroll_id → payroll_calculation.id (FK)
- employee_id → employees.id (FK)

**RLS-политики:**
- (RLS не включён)

---

## Таблица `payroll_penalty`

**Описание:**
Штрафы, удержания по расчёту зарплаты.

**Структура:**
- id: UUID, PK — уникальный идентификатор штрафа
- payroll_id: UUID, FK — внешний ключ на payroll_calculation.id
- employee_id: UUID, FK — внешний ключ на employees.id (новое поле, 2024-05-21)
- type: TEXT — тип штрафа
- amount: NUMERIC — сумма штрафа
- reason: TEXT — причина штрафа
- created_at: TIMESTAMP — дата и время создания записи

**Связи:**
- payroll_id → payroll_calculation.id (FK)
- employee_id → employees.id (FK)

**RLS-политики:**
- (RLS не включён)

---

## Таблица `payroll_deduction`

**Описание:**
Прочие удержания (например, алименты, налоги) по расчёту зарплаты.

**Структура:**
- id: UUID, PK — уникальный идентификатор удержания
- payroll_id: UUID, FK — внешний ключ на payroll_calculation.id
- employee_id: UUID, FK — внешний ключ на employees.id (новое поле, 2024-05-21)
- type: TEXT — тип удержания
- amount: NUMERIC — сумма удержания
- comment: TEXT — комментарий
- created_at: TIMESTAMP — дата и время создания записи

**Связи:**
- payroll_id → payroll_calculation.id (FK)
- employee_id → employees.id (FK)

**RLS-политики:**
- (RLS не включён)

---

## Таблица `payroll_payout`

**Описание:**
Фактические выплаты сотрудникам (модуль ФОТ). Создаются вручную, через массовую форму или **импорт из Excel** (клиент, без хранения файла). Подробнее: `docs/fot/fot_module.md`.

**Структура (актуально по коду `PayrollPayoutModel`, 2026):**
- id: UUID, PK — идентификатор (генерируется на клиенте при создании)
- company_id: UUID, FK — компания (RLS, мультикомпания)
- employee_id: UUID, FK — сотрудник (`employees.id`)
- amount: NUMERIC — сумма выплаты
- payout_date: DATE / TIMESTAMPTZ — дата выплаты
- method: TEXT — способ: `card`, `cash`, `bank_transfer`
- type: TEXT — тип: `salary`, `advance`
- comment: TEXT, nullable — комментарий
- created_at: TIMESTAMPTZ, nullable — дата создания записи

**Связи:**
- employee_id → employees.id (FK)
- company_id → companies.id (FK)

**Индексы:**
- `idx_payroll_payout_employee_id (employee_id)`
- `idx_payroll_payout_company_date (company_id, payout_date)`

**RLS-политики:**
- ✅ Включён (доступ по `company_id` / `get_my_company_ids()`)

**Устаревшие поля (удалены из приложения):** `payroll_id`, `status` — в текущем Dart-коде не используются.

---

## Таблица `cash_flow_categories`

**Описание:**
Справочник статей движения денежных средств. Позволяет группировать финансовые операции по категориям. Каждая компания имеет свой уникальный набор категорий.

**Структура:**
- id: UUID, PK — уникальный идентификатор категории
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- name: TEXT — наименование категории
- operation_type: TEXT — тип операций для этой категории (`income`, `expense`, `both`)
- is_active: BOOLEAN — статус активности категории
- sort_order: INTEGER — порядок сортировки при отображении в списках
- created_at: TIMESTAMPTZ — дата и время создания записи

**Связи:**
- company_id → companies.id (FK)

**RLS-политики:**
- ✅ Видна только участникам компании (через `get_my_company_ids()`)
- ✅ Управление доступно только участникам этой компании

---

## Таблица `cash_flow`

**Описание:**
Движение денежных средств (фактические приходы и расходы). Основная таблица финансового учёта. Полностью изолирована по компаниям.

**Структура:**
- id: UUID, PK — уникальный идентификатор записи
- company_id: UUID, FK — ссылка на компанию (`companies.id`)
- date: DATE — дата совершения платежа
- type: TEXT — тип операции (`income` — приход, `expense` — расход)
- amount: NUMERIC — сумма операции
- object_id: UUID, FK — ссылка на объект (`objects.id`)
- contract_id: UUID, FK — ссылка на договор (`contracts.id`)
- contractor_id: UUID, FK — ссылка на контрагента (`contractors.id`)
- category_id: UUID, FK — ссылка на статью движения ДС (`cash_flow_categories.id`)
- comment: TEXT — комментарий к операции
- created_at: TIMESTAMPTZ — дата и время создания записи
- created_by: UUID, FK — ссылка на профиль создателя (`profiles.id`)

**Связи:**
- company_id → companies.id (FK)
- object_id → objects.id (FK)
- contract_id → contracts.id (FK)
- contractor_id → contractors.id (FK)
- category_id → cash_flow_categories.id (FK)
- created_by → profiles.id (FK)

**RLS-политики:**
- ✅ Доступна только участникам компании (через `get_my_company_ids()`)
- ✅ Безопасность гарантирована на уровне БД через `company_id`

---

## Примечания
- Для таблиц из схемы storage (файлы) и auth (пользователи) — см. документацию Supabase.
- Все политики RLS реализуют строгую безопасность на уровне строк, если включены.
- Для расширения документации — сообщи, какие таблицы или схемы добавить. 