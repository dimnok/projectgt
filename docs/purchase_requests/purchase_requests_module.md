# Модуль Заявки на закупку (Purchase Requests)

**Дата:** 15.08.2026  
**Изменения:** первичная документация модуля; аудит кода (`lib/features/purchase_requests/`), миграций Supabase и live БД (`api.progt.ru`).

---

## Важное замечание

- **Owner таблиц:** все таблицы с префиксом `purchase_request_*` — собственность модуля.
- **Смена статуса заявки** возможна **только через RPC** (`SECURITY DEFINER`). Для роли `authenticated` на `purchase_requests` отозваны `INSERT/UPDATE/DELETE`; прямое изменение статуса через PostgREST запрещено.
- **Настройки маршрута** (`purchase_request_settings`) — одна строка на `company_id`. Сохранение — **только владелец компании** (`purchase_request_internal_is_company_owner`). Создание заявки блокируется, пока не заполнены все четыре роли и правило получателя.
- **Пользователи в настройках** — участники `company_members` с активным профилем, **не** сотрудники HR (`employees`). Список для dropdown: RPC `purchase_request_company_users`.
- **Поставщики** — контрагенты из `contractors` с типом supplier (использование, не owner).
- **Нумерация:** `ЗП-YYYY-NNNNN` через `purchase_request_number_seq`.
- **Edge Functions:** для модуля не зарегистрированы (проверка MCP `list_tables` / миграции).

---

## Описание

Модуль управляет жизненным циклом **заявок на закупку** внутри компании: от черновика с позициями до оплаты и подтверждения получения. Каждая заявка имеет **текущего ответственного** (`current_assignee_id`), историю переходов и уведомления.

### Ключевые функции

| Функция | Статус |
|---------|--------|
| Список заявок с фильтрами (мои / на мне / все / архив) | ✅ |
| Создание черновика с объектом, комментарием и позициями | ✅ |
| Редактирование позиций в `draft` / `revision` | ✅ |
| Workflow-кнопки (согласование, счета, оплата, получение) | ✅ |
| Настройки маршрута (owner-only) | ✅ |
| История переходов | ✅ |
| Счета (CRUD + PDF) в UI | 🔴 не реализовано |
| Файлы / документы в UI | 🔴 не реализовано |
| UI уведомлений | 🔴 не реализовано |

---

## Зависимости

### Таблицы модуля (owner)

- `purchase_requests`
- `purchase_request_items`
- `purchase_request_invoices`
- `purchase_request_files`
- `purchase_request_history`
- `purchase_request_notifications`
- `purchase_request_settings`
- `purchase_request_number_seq`

### Таблицы других модулей (usage)

| Таблица | Модуль | Использование |
|---------|--------|---------------|
| `objects` | Objects | Объект закупки (`object_id`) |
| `contractors` | Contractors | Поставщик в счетах (`supplier_id`, type = supplier) |
| `companies` | Company | `company_id`, owner gate для settings |
| `company_members` | Auth | Участники компании для dropdown настроек |
| `profiles` | Profile | ФИО в списке, `is_active` |
| `app_modules` | RBAC | Модуль `purchase_requests` в матрице прав |

### Связанные модули

- **Roles** — коды прав: `read`, `create`, `approve`, `prepare_invoice`, `approve_invoice`, `payment`, `receive`, `view_all`
- **Company** — `activeCompanyId`, `activeCompanyProvider`
- **Objects** — выбор объекта при создании
- **Contractors** — поставщики (планируется в UI счетов)

---

## Presentation

### Экраны

| Файл | Назначение |
|------|------------|
| `screens/purchase_requests_list_screen.dart` | Список, поиск, фильтры; placeholder до настройки маршрута; кнопка настроек (owner); создание заявки |
| `screens/purchase_request_details_screen.dart` | Карточка заявки: мета, позиции, история, панель действий |

### Виджеты

| Файл | Назначение |
|------|------------|
| `widgets/purchase_request_card.dart` | Карточка в списке |
| `widgets/purchase_request_create_dialog.dart` | Создание: объект, комментарий, inline-позиции |
| `widgets/purchase_request_settings_dialog.dart` | Настройки маршрута (4 роли + режим получателя) |
| `widgets/purchase_request_actions_bar.dart` | Кнопки workflow по статусу и правам |
| `utils/purchase_request_ui_labels.dart` | Лейблы статусов и действий |
| `utils/purchase_request_module_utils.dart` | `isPurchaseRequestSettingsConfigured()` |

### Провайдеры

| Провайдер | Назначение |
|-----------|------------|
| `purchaseRequestListProvider` | Список через RPC `purchase_request_list` |
| `purchaseRequestDetailsProvider` | Детали заявки |
| `purchaseRequestItemsProvider` | Позиции |
| `purchaseRequestHistoryProvider` | История |
| `purchaseRequestSettingsProvider` | Настройки компании |
| `purchaseRequestCompanyUsersProvider` | Пользователи для dropdown |

**DI:** `supabaseClientProvider` из `lib/core/di/providers.dart`. Ошибки списка — `formatSupabaseErrorMessage` (`lib/core/utils/supabase_error_message.dart`).

### Навигация и доступ

- **Маршруты:** `/purchase_requests`, `/purchase_requests/:id` (`app_router.dart`)
- **Drawer:** пункт «Заявки на закупку» (`app_drawer.dart`)
- **Матрица прав:** для `purchase_requests` отключены TMC-специфичные коды (`issue`, `move`, `repair`, …) в `permissions_matrix.dart`

### Design System

- `GTPrimaryButton`, `GTSecondaryButton`, `GTTextField`, `GTDropdown`
- `DesktopDialogContent`, `MobileBottomSheetContent`, `ModalContainerWrapper`
- `AppSnackBar`, `EdgeToEdgeScaffold`
- Форматтеры: `formatRuDate`, `formatRuDateTime`, `formatQuantity`, `formatCurrency`

---

## Domain / Data

### Сущности (domain)

| Сущность | Файл | Описание |
|----------|------|----------|
| `PurchaseRequest` | `purchase_request.dart` | Заявка (Freezed) |
| `PurchaseRequestItem` | `purchase_request_item.dart` | Позиция |
| `PurchaseRequestStatus` | `purchase_request_status.dart` | Enum статусов |
| `PurchaseRequestListItem` | `purchase_request_list_item.dart` | Строка списка |
| `PurchaseRequestSettings` | `purchase_request_settings.dart` | Настройки маршрута |
| `PurchaseRequestHistoryEntry` | `purchase_request_history_entry.dart` | Запись истории |
| `PurchaseRequestCompanyUser` | (models) | Пользователь для настроек |

### Репозиторий

- **Интерфейс:** `domain/repositories/purchase_request_repository.dart`
- **Реализация:** `data/repositories/purchase_request_repository_impl.dart`
- **Модели:** `data/models/purchase_request_models.dart` (маппинг JSON ↔ entity)

Основные операции: list, get, createDraft, submit, workflow RPCs, items CRUD, settings get/upsert, company users, history.

---

## Дерево файлов

```
lib/features/purchase_requests/
├── data/
│   ├── models/
│   │   └── purchase_request_models.dart
│   └── repositories/
│       └── purchase_request_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── purchase_request.dart
│   │   ├── purchase_request.freezed.dart
│   │   ├── purchase_request_item.dart
│   │   ├── purchase_request_item.freezed.dart
│   │   ├── purchase_request_list_item.dart
│   │   ├── purchase_request_settings.dart
│   │   ├── purchase_request_settings.freezed.dart
│   │   ├── purchase_request_history_entry.dart
│   │   └── purchase_request_status.dart
│   └── repositories/
│       └── purchase_request_repository.dart
└── presentation/
    ├── screens/
    │   ├── purchase_requests_list_screen.dart
    │   └── purchase_request_details_screen.dart
    ├── state/
    │   └── purchase_request_providers.dart
    ├── utils/
    │   ├── purchase_request_ui_labels.dart
    │   └── purchase_request_module_utils.dart
    └── widgets/
        ├── purchase_request_actions_bar.dart
        ├── purchase_request_card.dart
        ├── purchase_request_create_dialog.dart
        └── purchase_request_settings_dialog.dart

supabase/migrations/
├── 20260815160000_create_purchase_requests_module.sql
├── 20260815161000_purchase_requests_rpc.sql
├── 20260815170000_remove_purchase_request_required_date.sql
├── 20260815170500_purchase_request_settings_owner_gate.sql
├── 20260815172000_purchase_request_company_users_rpc.sql
└── 20260815172500_fix_purchase_request_list_created_at.sql
```

---

## База данных (Audit)

**Аудит live БД:** 15.08.2026 через MCP `project-0-projectgt-supabase`.

### Таблица `purchase_requests`

| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| `id` | uuid | NO | PK |
| `company_id` | uuid | NO | FK → companies |
| `number` | text | NO | Уникальный номер `ЗП-YYYY-NNNNN` |
| `status` | text | NO | Статус workflow |
| `object_id` | uuid | YES | FK → objects |
| `comment` | text | YES | Комментарий инициатора |
| `created_by` | uuid | NO | FK → profiles |
| `current_assignee_id` | uuid | YES | Текущий ответственный |
| `created_at` | timestamptz | NO | |
| `updated_at` | timestamptz | NO | |
| `submitted_at` | timestamptz | YES | |
| `completed_at` | timestamptz | YES | Финальный статус |
| `cancelled_at` | timestamptz | YES | |
| `cancelled_by` | uuid | YES | |
| `cancel_reason` | text | YES | |
| `payment_date` | date | YES | Из meta при `paid` |
| `received_date` | date | YES | Из meta при `received` |

**Индексы:** `company_id`, `status`, `current_assignee_id`, `created_by`, `(company_id, number)` UNIQUE.

### Таблица `purchase_request_items`

| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| `id` | uuid | NO | PK |
| `request_id` | uuid | NO | FK → purchase_requests |
| `name` | text | NO | Наименование |
| `quantity` | numeric | NO | > 0 |
| `unit` | text | NO | Единица (текст, не FK) |
| `estimated_price` | numeric | YES | Оценочная цена |
| `comment` | text | YES | |
| `sort_order` | int | NO | Порядок |
| `created_at` | timestamptz | NO | |
| `updated_at` | timestamptz | NO | |

### Таблица `purchase_request_invoices`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `request_id`, `supplier_id`, `invoice_number`, `invoice_date`, `amount`, `file_path`, `created_by`, timestamps | | Счета поставщиков (UI 🔴) |

### Таблица `purchase_request_files`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `request_id`, `file_path`, `file_name`, `file_size`, `uploaded_by`, `created_at` | | Доп. файлы (UI 🔴) |

### Таблица `purchase_request_history`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `request_id`, `from_status`, `to_status`, `action`, `actor_id`, `assignee_id`, `comment`, `metadata` (jsonb), `created_at` | | Аудит переходов |

### Таблица `purchase_request_notifications`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `company_id`, `request_id`, `user_id`, `message`, `read_at`, `created_at` | | Уведомления (UI 🔴) |

### Таблица `purchase_request_settings`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `company_id` | uuid PK | |
| `first_approver_id` | uuid | Первый согласующий |
| `invoice_preparer_id` | uuid | Подготовка счетов |
| `invoice_approver_id` | uuid | Согласование счетов |
| `accountant_id` | uuid | Бухгалтер |
| `receiver_mode` | text | `fixed` \| `initiator` |
| `fixed_receiver_id` | uuid | При `receiver_mode = fixed` |
| `created_at`, `updated_at`, `updated_by` | | |

### Таблица `purchase_request_number_seq`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `company_id`, `year`, `last_number` | | Счётчик номеров по году |

### RLS

| Таблица | RLS |
|---------|-----|
| `purchase_requests` | ✅ Включён |
| `purchase_request_items` | ✅ |
| `purchase_request_invoices` | ✅ |
| `purchase_request_files` | ✅ |
| `purchase_request_history` | ✅ |
| `purchase_request_notifications` | ✅ |
| `purchase_request_settings` | ✅ |
| `purchase_request_number_seq` | ✅ (service / internal) |

Политики: чтение по `company_id` + `check_permission`; изменение статуса заявки — только RPC.

### Storage

- Bucket: `purchase-requests` (политики на upload/read по `company_id` в путях файлов)

### RPC (публичные)

| Функция | Назначение |
|---------|------------|
| `purchase_request_list` | Список с фильтром `mine` / `on_me` / `all` / `archive` |
| `purchase_request_create_draft` | Черновик (+ gate: settings configured) |
| `purchase_request_submit` | `draft` → `approval` |
| `purchase_request_approve` | Согласование |
| `purchase_request_return_for_revision` | Возврат на доработку |
| `purchase_request_prepare_invoice` | Переход к подготовке счетов |
| `purchase_request_submit_invoice` | Отправка на согласование счетов |
| `purchase_request_approve_invoice` | Согласование счетов → бухгалтерия |
| `purchase_request_return_invoice` | Возврат счетов |
| `purchase_request_queue_payment` | Очередь оплаты |
| `purchase_request_mark_paid` | Оплачено → получатель |
| `purchase_request_mark_received` | Получено (финал) |
| `purchase_request_cancel` | Отмена |
| `purchase_request_get_settings` | Настройки компании |
| `purchase_request_upsert_settings` | Сохранение (owner only) |
| `purchase_request_company_users` | Список пользователей для dropdown |

### Внутренние функции

- `purchase_request_internal_transition` — единая точка смены статуса + history
- `purchase_request_internal_notify` — записи в notifications
- `purchase_request_internal_resolve_receiver` — получатель по settings
- `purchase_request_internal_settings_configured` — проверка полноты настроек
- `purchase_request_internal_is_company_owner` — gate для settings
- `purchase_request_internal_generate_number` — нумерация

### Статистика live (15.08.2026)

| Таблица | Строк |
|---------|-------|
| `purchase_requests` | 7 |
| `purchase_request_items` | 4 |
| `purchase_request_history` | 8 |
| `purchase_request_settings` | 1 |
| `purchase_request_notifications` | 1 |
| `purchase_request_invoices` | 0 |
| `purchase_request_files` | 0 |

---

## Бизнес-логика

### Статусы

| Код | UI (рус.) |
|-----|-----------|
| `draft` | Черновик |
| `approval` | Согласование |
| `revision` | Доработка |
| `invoice_preparation` | Подготовка счетов |
| `invoice_approval` | Согласование счетов |
| `accounting` | Бухгалтерия |
| `payment_queue` | Очередь оплаты |
| `paid` | Оплачено |
| `received` | Получено |
| `cancelled` | Отменено |

### Workflow (основной путь)

```mermaid
stateDiagram-v2
    [*] --> draft
    draft --> approval: submit
    approval --> invoice_preparation: approve
    approval --> revision: return_for_revision
    revision --> approval: submit
    invoice_preparation --> invoice_approval: submit_invoice
    invoice_approval --> accounting: approve_invoice
    invoice_approval --> invoice_preparation: return_invoice
    accounting --> payment_queue: queue_payment
    payment_queue --> paid: mark_paid
    paid --> received: mark_received
    draft --> cancelled: cancel
    approval --> cancelled: cancel
```

### Ответственные (`current_assignee_id`)

| Этап | Assignee |
|------|----------|
| `draft`, `revision` | `created_by` |
| `approval` | `settings.first_approver_id` |
| `invoice_preparation` | `settings.invoice_preparer_id` |
| `invoice_approval` | `settings.invoice_approver_id` |
| `accounting`, `payment_queue` | `settings.accountant_id` |
| `paid` | Получатель: `fixed_receiver_id` или `created_by` (`receiver_mode`) |
| `received`, `cancelled` | `NULL` |

### Права на действия (RPC)

| Действие | Permission | Assignee check |
|----------|------------|----------------|
| Создание / submit | `create` | автор |
| approve / return revision | `approve` | current |
| prepare / submit invoice | `prepare_invoice` | current |
| approve / return invoice | `approve_invoice` | current |
| queue payment / mark paid | `payment` | current |
| mark received | `receive` | current |
| Список `all` / `archive` | `view_all` | — |
| Чтение своих | `read` | created_by или assignee |

### Gate: настройки перед созданием

`purchase_request_create_draft` вызывает `purchase_request_internal_settings_configured`:

- `first_approver_id`, `invoice_preparer_id`, `invoice_approver_id`, `accountant_id` — NOT NULL
- `receiver_mode = fixed` → `fixed_receiver_id` NOT NULL
- `receiver_mode = initiator` → fixed не требуется

### Позиции

- Добавление/редактирование/удаление — только в `draft` и `revision`
- Submit без позиций — ошибка на клиенте (`actions_bar`) и на сервере
- `unit` — свободный текст (например «шт.», «м»)

### Получение после оплаты

`purchase_request_mark_paid` назначает `current_assignee_id` = resolved receiver и создаёт уведомление. `mark_received` записывает `received_date` в metadata истории и завершает заявку (`completed_at`).

### Нумерация

Формат: `ЗП-{год}-{5 цифр}`. Счётчик в `purchase_request_number_seq` по `(company_id, year)`.

---

## Интеграции

| Компонент | Связь |
|-----------|-------|
| **RBAC** | `app_modules` code `purchase_requests`; `check_permission` в RPC |
| **Objects** | `object_id` при создании |
| **Contractors** | `purchase_request_invoices.supplier_id` (планируется UI) |
| **Supabase Storage** | bucket `purchase-requests` для PDF счетов и файлов |
| **Notifications** | Таблица + RPC notify; in-app UI отсутствует |
| **Edge Functions** | Не используются |

---

## Roadmap

### Реализовано 🟢

- Схема БД, RLS, Storage bucket
- Полный набор workflow RPC
- Список, детали, создание, позиции, история
- Настройки маршрута (owner)
- Матрица прав, drawer, router
- Human-readable ошибки Supabase в UI

### Баги / техдолг 🟡

- UI счетов и загрузки PDF не связан с `purchase_request_invoices`
- Блок «Документы» / `purchase_request_files` не в UI
- Уведомления пишутся в БД, но не отображаются
- E2E сценарий по ТЗ (20 шагов) не автоматизирован

### Планы 🔴

1. Экран/секция «Счета»: CRUD, выбор поставщика, upload PDF
2. Секция «Документы» с Storage
3. Badge / список уведомлений в модуле
4. Экспорт списка заявок (если потребуется `export` permission)
5. Документация в `docs/database_structure.md` — cross-link

---

## Права модуля (RBAC)

Коды в `permissionsList` + использование в RPC:

| Code | Название в UI |
|------|---------------|
| `read` | Просмотр |
| `create` | Создание |
| `approve` | Согласование |
| `prepare_invoice` | Счета |
| `approve_invoice` | Согласование счетов |
| `payment` | Оплата |
| `receive` | Получение |
| `view_all` | Все заявки |

Для модуля **отключены** в матрице: `update`, `delete`, `export`, `import`, `issue`, `move`, `repair`, `write_off`, `inventory`, `view_cost`, `manage_catalogs`.

---

*Документ подготовлен по аудиту кода и live PostgreSQL. При изменении миграций или RPC — обновить этот файл.*
