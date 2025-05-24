# Структура базы данных Supabase (актуально)

---

## Таблица `profiles`

**Описание:**
Профили пользователей приложения. Хранит расширенную информацию о каждом пользователе, включая контактные данные, роль, статус, связанные объекты.

**Структура:**
- id: UUID, PK — уникальный идентификатор профиля, связь с auth.users
- full_name: TEXT — полное ФИО пользователя
- short_name: TEXT — сокращённое ФИО (например, инициалы)
- photo_url: TEXT — URL фотографии/аватара пользователя
- email: TEXT — email пользователя (уникальный)
- phone: TEXT — номер телефона в формате +7-(XXX)-XXX-XXXX
- role: TEXT — роль пользователя в системе (`user`, `admin`)
- status: BOOLEAN — статус активности (true — активен, false — неактивен)
- object: JSONB — JSON-объект для хранения дополнительных данных
- object_ids: ARRAY(UUID) — список id объектов, связанных с профилем пользователя
- created_at: TIMESTAMP — дата и время создания записи (UTC)
- updated_at: TIMESTAMP — дата и время последнего обновления записи (UTC)

**Связи:**
- id → auth.users.id (FK)
- object_ids → objects.id (FK)
- opened_by (в works) → profiles.id (FK)

**RLS-политики:**
- Только владелец или админ может читать/обновлять свой профиль

---

## Таблица `employees`

**Описание:**
Справочник сотрудников. Хранит ФИО, паспортные данные, контакты, параметры для расчёта зарплаты, статус, связанные объекты.

**Структура:**
- id: UUID, PK — уникальный идентификатор сотрудника
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
- hourly_rate: NUMERIC — почасовая ставка
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

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать

---

## Таблица `contractors`

**Описание:**
Справочник контрагентов (организаций). Хранит реквизиты, контактные данные, тип, лого.

**Структура:**
- id: UUID, PK — уникальный идентификатор контрагента
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

**RLS-политики:**
- Любой аутентифицированный пользователь (auth.role() = 'authenticated') может читать, создавать, обновлять и удалять записи в таблице contractors.

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
Справочник строительных объектов. Содержит адрес, описание, сумму командировочных выплат.

**Структура:**
- id: UUID, PK — уникальный идентификатор объекта
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

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать

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
- contract_id → contracts.id (FK)
- object_id → objects.id (FK)
- id → work_items.estimate_id (FK)

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать

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
Выплаты по расчёту зарплаты (факт перевода денег сотруднику).

**Структура:**
- id: UUID, PK — уникальный идентификатор выплаты
- payroll_id: UUID, FK — внешний ключ на payroll_calculation.id
- employee_id: UUID, FK — внешний ключ на employees.id (новое поле, 2024-05-21)
- amount: NUMERIC — сумма выплаты
- payout_date: DATE — дата выплаты
- method: TEXT — способ выплаты
- status: TEXT — статус выплаты (`pending`, `paid`)
- created_at: TIMESTAMP — дата и время создания записи

**Связи:**
- payroll_id → payroll_calculation.id (FK)
- employee_id → employees.id (FK)

**RLS-политики:**
- (RLS не включён)

---

## Примечания
- Для таблиц из схемы storage (файлы) и auth (пользователи) — см. документацию Supabase.
- Все политики RLS реализуют строгую безопасность на уровне строк, если включены.
- Для расширения документации — сообщи, какие таблицы или схемы добавить. 