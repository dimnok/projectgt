# Модуль Заявки на закупку (Purchase Requests)

**Дата:** 26.08.2026  
**Изменения:** выгрузка позиций заявки в Excel на устройство пользователя (кнопка **Excel** в секции «Позиции»; пакет `excel`; файл в Storage **не** сохраняется). Ранее (25.08.2026): таблица позиций в деталях заявки: «Наименование» и «Артикул» делят ширину (flex 3/2), артикул до 2 строк, при нехватке места — горизонтальный скролл (колонка больше не обрезается на 88 px). Ранее (22.08.2026): минимальная чистка API репозитория: из `list()` убраны неиспользуемые параметры (`objectId`, `status`, `createdBy`, `fromDate`, `toDate`, `offset`); из workflow-методов убраны опциональные параметры, которые UI не передавал (`comment` у `submit`/`approve`/`approveInvoice`/`queuePayment`; `paymentDate`/`comment` у `markPaid`; `receivedDate`/`comment` у `markReceived`). Комментарии остались только у `returnForRevision`, `returnInvoice`, `cancel`. Ранее: чистка модуля (Вариант 1): удалены неиспользуемые поля `itemsPreview` / `itemsCount` из `PurchaseRequestListItem` и из RPC `purchase_request_list` (миграция `20260822110000`, применена на прод через MCP `apply_migration`); агрегация `item_agg` убрана — меньше нагрузка на БД. Поле `currentAssigneeId` удалено из Dart-entity `PurchaseRequest` и `PurchaseRequestListItem` (в БД колонка `current_assignee_id` осталась для индекса `idx_purchase_requests_assignee`; в RPC RETURN сохранена для совместимости). Удалены 2 мёртвых теста на `currentAssigneeId` и 1 дублирующий тест; параметр `assigneeId` убран из builder'а `request()`. Тестов: 28 (было 30). Ранее: мобильная форма «Новая заявка» / правка черновика: лист снизу на всю ширину (`EmployeesLayoutUtils.useEmployeesDesktopModal` + `isDesktopSurface` — телефон в альбоме не получает центрированный диалог); позиции столбиком без серых карточек; ряд 50/50 «− кол-во +» и «ед. изм.»; «добавить»/«удалить» — круги 44×44, шаг количества — квадраты со скруглением как у `GTTextField` (16); при ≥2 позициях — подпись «Позиция N» и тонкий разделитель. Логика сохранения та же. `MobileBottomSheetContent`: опции `fillMaxHeight` / `showDragHandle` (по умолчанию выкл.). Ранее (22.08.2026): mobile-реестр — в шапке нет кнопок темы и настроек (остались меню, заголовок, «+»); карточки шире (`MobileAtmosphereMainSurface` padding 8, карточка horizontal 4); из карточки убрано перечисление позиций (`shortItemsLabel` удалён). Ранее (22.08.2026): desktop-диалог «Настройка согласующих» — ширина 880 px (обход лимита Material 3 Dialog 560 px), таймлайн из 5 этапов с подсказками, компактные dropdown 340 px, подвал «Отмена» / «Сохранить». Ранее (22.08.2026): несколько участников на роли маршрута (таблица `purchase_request_route_members`); на этапе действует **любой** из списка (OR), не цепочка обязательных согласований; настройки **живые** (смена списка сразу действует на заявки в работе); авторизация RPC/RLS/UI — `purchase_request_internal_user_is_assignee`, не `current_assignee_id`; RPC `purchase_request_upsert_settings` принимает массивы `uuid[]`; уведомления следующей роли — всем участникам (`purchase_request_internal_notify_role`). Ещё ранее (16.08.2026): мобильная форма позиций; фильтры реестра по статусу; вкладки «Мои» и «На мне» удалены.

---

## Важное замечание

- **Owner таблиц:** все таблицы с префиксом `purchase_request_*` — собственность модуля.
- **Смена статуса заявки** возможна **только через RPC** (`SECURITY DEFINER`). Для роли `authenticated` на `purchase_requests` отозваны `INSERT/UPDATE/DELETE`; прямое изменение статуса через PostgREST запрещено.
- **Настройки маршрута:** `purchase_request_settings` — одна строка на `company_id`. Колонки: `company_id`, `receiver_mode`, `created_at`, `updated_at`, `updated_by`. Колонок `first_approver_id` / `invoice_preparer_id` / `invoice_approver_id` / `accountant_id` / `fixed_receiver_id` **нет** (сняты миграцией `20260822100000` / live `purchase_request_upsert_settings_arrays`). Участники ролей — `purchase_request_route_members`. Сохранение — RPC `purchase_request_upsert_settings` (**только владелец**, `purchase_request_internal_is_company_owner`). Для `authenticated` на `purchase_request_route_members` есть только SELECT; INSERT/UPDATE/DELETE отозваны — запись только через RPC. Создание заявки блокируется, пока на ролях `first_approver`, `invoice_preparer`, `invoice_approver`, `accountant` есть ≥1 участник и задано правило получателя (`initiator` или ≥1 `receiver`).
- **Несколько участников на роли:** роли `first_approver`, `invoice_preparer`, `invoice_approver`, `accountant`, `receiver`. На этапе действует **любой** участник этой роли (OR). Это не цепочка, где нужны все подряд.
- **Настройки живые:** RPC и RLS читают текущие строки `purchase_request_route_members` (нет снимка состава на заявке). Смена списка сразу применяется к заявкам в работе.
- **Авторизация vs отображение:** источник истины — `purchase_request_internal_user_is_assignee(company_id, status, created_by, user_id)`. В UI то же правило — `isPurchaseRequestStageAssignee` по спискам из settings. `current_assignee_id` по-прежнему пишется в БД при переходе: первый пользователь следующей роли (`purchase_request_internal_first_role_user`, `ORDER BY sort_order, user_id LIMIT 1`) — нужен для индекса `idx_purchase_requests_assignee`. **В Dart-entity (`PurchaseRequest`, `PurchaseRequestListItem`) поле больше не парсится и не используется**; для RPC, RLS и кнопок workflow **не используется**.
- **Чтение заявки:** `purchase_request_can_read(company_id, created_by, status)` — сигнатура **без** `assignee_id` (live: `p_company_id uuid, p_created_by uuid, p_status text`).
- **Пользователи в настройках** — участники `company_members` с активным профилем, **не** сотрудники HR (`employees`). Список для dropdown: RPC `purchase_request_company_users`. Проверка членства при сохранении: `purchase_request_internal_assert_route_users`.
- **Поставщики** — контрагенты из `contractors` с типом `supplier`; выбор в диалоге счёта (`GTDropdown`, `contractorNotifierProvider`).
- **Счета и файлы:** создание счёта — PostgREST INSERT + upload в Storage + INSERT в `purchase_request_files` (type = `invoice`). Если upload прошёл, а INSERT метаданных упал — объект в Storage удаляется, затем DELETE счёта. Отправка на согласование — только RPC `purchase_request_submit_invoices` (≥1 счёт, у каждого — файл). Update счёта в UI **нет** (только удаление + повторное добавление). **Просмотр и скачивание** — `storage.download` по `storage_path` (путь обязан начинаться с `activeCompanyId/`); UI-кнопки у всех, кто видит заявку (`purchase_request_can_read`); Storage SELECT — permission `read`.
- **Нумерация:** `ЗП-YYYY-NNNNN` через `purchase_request_number_seq` + `purchase_request_internal_next_number`.
- **Детали заявки** открываются **в том же экране** (правая панель на desktop, полноэкранная панель на mobile). Отдельный маршрут `/purchase_requests/:id` **удалён**.
- **ФИО в UI:** единая логика `pickProfileDisplayName` / `formatUserDisplayLabel` (`lib/core/utils/user_display_utils.dart`); в списке — RPC `purchase_request_list` (`created_by_name`); в деталях и истории — batch-запрос к `profiles`.
- **Gate «Настройки» в UI:** `isCompanyOwnerProvider` → `Profile.isOwner` из `company_members.is_owner` (не `systemRole`). Кнопка «Настройки» — **только desktop** (левая панель). На mobile её нет: первичная настройка — экран-заглушка `_ModuleSetupPlaceholder` (owner). Смена темы — desktop-шапка; на mobile переключатель темы скрыт.
- **Write без компании:** все мутации репозитория вызывают `_requireCompany()` → `PurchaseRequestCompanyRequiredException`.
- **Свой черновик:** правка шапки/позиций и удаление заявки — только автор, только статус `draft` (RPC + UI). Право `view_all` чужой черновик удалить не может. На этапе `revision` можно менять позиции, но не шапку и не удалять заявку.
- **Отмена:** не финальный статус. RPC `purchase_request_cancel` переводит заявку в `draft`, assignee = автор, причина пишется в историю (`action = cancelled`). Кнопка «Вернуть в черновик» скрыта у черновика и у «Получено». Статус `cancelled` в CHECK остаётся для старых данных; живые строки с ним переведены в `draft` миграцией `20260816194000`.
- **Список после действий:** `invalidatePurchaseRequestCaches` **не** делает `invalidate` notifier списка (это сбрасывало бы фильтр на дефолт «Все»). Вызывается `refreshPurchaseRequestList` → `PurchaseRequestListNotifier.load(quiet: true)` с текущими `filter`/`search`.
- **Excel позиций:** файл собирается **на клиенте** (`PurchaseRequestItemsExcelExportService` + пакет `excel`) и сохраняется через `saveFileBytesToUserDevice`. В Storage и в БД Excel **не** пишется. Кнопка видна любому, кто видит заявку, если есть ≥1 позиция. Специального permission `export` нет (в матрице модуля код `export` отключён).
- **Edge Functions:** в `supabase/functions/` нет функций модуля; инструмент MCP `list_edge_functions` в текущем сервере отсутствует (проверка 26.08.2026: ни одной `purchase_request*` функции в репозитории).

---

## Описание

Модуль управляет жизненным циклом **заявок на закупку** внутри компании: от черновика с позициями до оплаты и подтверждения получения. На каждом этапе может действовать **любой** участник роли из настроек компании. Поле `current_assignee_id` в БД хранит первого пользователя роли этапа (служебное, для индекса; в Dart-entity не используется), история переходов и уведомления пишутся отдельно.

### Ключевые функции

| Функция | Статус |
|---------|--------|
| Реестр с фильтрами (На согласовании / Согласованы / Все / Архив) и поиском | ✅ |
| Дефолтный фильтр «Все» при открытии модуля | ✅ |
| Двухпанельный desktop-UI (sidebar + таблица / детали) | ✅ |
| Mobile-шапка без темы и настроек; карточки без превью позиций | ✅ |
| Таблица: номер, объект, инициатор, дата, сумма, статус | ✅ |
| Общий бейдж статуса (`PurchaseRequestStatusBadge`) | ✅ |
| Цветные бейджи статусов (светлая / тёмная тема) | ✅ |
| Создание черновика: объект, комментарий, многострочные позиции | ✅ desktop-таблица / mobile-карточки |
| Редактирование своего черновика (объект, комментарий, позиции) | ✅ |
| Удаление своего черновика | ✅ |
| Обновление списка сразу после создания заявки | ✅ |
| Фильтр и поиск сохраняются после действий по заявке | ✅ |
| Открытая заявка не закрывается, если её нет в текущем фильтре (напр. черновик при «На согласовании») | ✅ |
| Позиции: наименование, ед. изм., количество, артикул | ✅ |
| Выгрузка позиций заявки в Excel (на устройство, без Storage) | ✅ |
| Панель деталей: KPI-сводка, таблица позиций, таймлайн истории, workflow | ✅ |
| Заголовок деталей: номер крупно + объект · инициатор (подзаголовок) | ✅ |
| Единые design tokens панели деталей (отступы, радиусы, границы) | ✅ |
| История: вертикальный таймлайн (кто → что → когда) | ✅ |
| Добавление / удаление позиций в `draft` / `revision` (в т.ч. артикул из деталей) | ✅ |
| Редактирование позиции (`updateItem`) | ✅ в диалоге правки черновика |
| Workflow-кнопки (согласование, оплата, получение, возврат в черновик) | ✅ |
| Кнопка «Отправить на согласование» (этап `invoice_preparation`) | ✅ |
| Секция «Счета» в панели деталей (добавление / удаление / файл) | ✅ |
| Просмотр файла счёта в приложении (PDF / JPG / PNG) | ✅ |
| Скачивание файла счёта на устройство | ✅ |
| Диалог добавления счёта (поставщик, сумма, номер, дата, PDF/изображение) | ✅ |
| Валидация счетов перед submit (кнопка неактивна без файлов) | ✅ |
| Настройки маршрута (owner-only), несколько пользователей на роли | ✅ (`isCompanyOwnerProvider`, `GTDropdown` `allowMultipleSelection`; desktop — таймлайн этапов) |
| Баннер «Показаны первые 50 заявок» при лимите списка | ✅ |
| Единый виджет фильтров mobile/desktop | ✅ `PurchaseRequestFilterBar` |
| Редактирование счёта после создания | 🔴 только удаление + повторное добавление |
| Отдельный блок «Документы» (не invoice) | 🔴 не реализовано |
| UI уведомлений | 🔴 не реализовано |
| Удаление черновика / правка шапки (объект, комментарий) | ✅ только своя заявка в `draft` |

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
- `purchase_request_route_members`
- `purchase_request_number_seq`

### Таблицы других модулей (usage)

| Таблица | Модуль | Использование |
|---------|--------|---------------|
| `objects` | Objects | Объект закупки (`object_id`), join `objects:object_id(name)` в деталях |
| `contractors` | Contractors | Поставщик в счетах (`supplier_id`, type = supplier) |
| `companies` | Company | `company_id`, owner gate для settings |
| `company_members` | Auth | Участники компании для dropdown настроек |
| `profiles` | Profile | ФИО инициатора и участников истории (`short_name` → `full_name` → `email`) |
| `app_modules` | RBAC | Модуль `purchase_requests` в матрице прав |

### Связанные модули

- **Roles** — коды прав: `read`, `create`, `approve`, `prepare_invoice`, `approve_invoice`, `payment`, `receive`, `view_all`
- **Company** — `activeCompanyIdProvider`, `isCompanyOwnerProvider` (gate кнопки «Настройки» на desktop)
- **Profile** — `Profile.isOwner` (из `company_members.is_owner` при загрузке профиля)
- **Core** — `user_display_utils.dart` (ФИО), `formatSupabaseErrorMessage`, `saveFileBytesToUserDevice` (счета и Excel позиций), `openAttachmentFilePreview`
- **excel** — клиентская сборка xlsx позиций (`PurchaseRequestItemsExcelExportService`)
- **Objects** — выбор объекта при создании
- **Contractors** — поставщики в диалоге счёта (`ContractorType.supplier`)

---

## Presentation

### Экраны

| Файл | Назначение |
|------|------------|
| `screens/purchase_requests_list_screen.dart` | Единый экран модуля: placeholder до настройки маршрута; desktop — двухпанельный layout; mobile — список карточек или панель деталей; state: `_selectedRequestId`. Mobile-шапка: меню / «Назад», заголовок, «+» (без темы и настроек) |
| `screens/desktop/purchase_requests_list_desktop_view.dart` | Desktop: левая панель (поиск, фильтры, «Новая заявка», «Настройки») + правая область (таблица или детали) |

### Виджеты

| Файл | Назначение |
|------|------------|
| `widgets/purchase_requests_table.dart` | Таблица реестра (desktop): `GTSectionTitle`, колонки Номер, Объект, Инициатор, Дата, Сумма, Статус |
| `widgets/purchase_request_filter_bar.dart` | Единые фильтры: mobile — chip-сегменты (`PayrollToolbarSegmentChip`); desktop sidebar — плитки |
| `widgets/purchase_request_list_limit_banner.dart` | Баннер при `isTruncatedByLimit` (лимит 50) |
| `widgets/purchase_request_details_panel.dart` | Панель деталей: шапка, KPI-сводка, секции позиций/**счетов**/истории, закреплённый подвал действий; в секции позиций — кнопки **Excel** (`GTTextButton` + `Icons.download_outlined`) и «Добавить» |
| `widgets/purchase_request_invoices_section.dart` | Секция «Счета»: список карточек, просмотр/скачивание файла, «Добавить» / удаление; `shouldShow(status)` |
| `widgets/purchase_request_invoice_dialog.dart` | Диалог добавления счёта: поставщик (`GTDropdown`), сумма, номер, дата, файл (`file_selector`) |
| `widgets/purchase_request_details_summary.dart` | KPI-карточки: статус (акцентная полоса), сумма, кол-во позиций; баннер доработки, комментарий |
| `widgets/purchase_request_details_tokens.dart` | Единые отступы, радиусы, цвета и `BoxDecoration` для панели деталей |
| `widgets/purchase_request_items_table.dart` | Позиции: desktop — таблица (№, наименование, кол-во, ед., артикул, зебра); наименование и артикул делят ширину, при нехватке места — горизонтальный скролл; ширина &lt; 600 px — карточки |
| `widgets/purchase_request_history_timeline.dart` | Вертикальный таймлайн истории (точка + линия, кто → что → когда) |
| `widgets/purchase_request_card.dart` | Карточка в мобильном списке: номер, объект, дата, сумма, бейдж статуса. Превью позиций **не** показывается |
| `widgets/purchase_request_status_badge.dart` | Общий бейдж статуса для списка и таблицы (единый стиль, `maxLines: 1`) |
| `widgets/purchase_request_create_dialog.dart` | Создание и правка черновика: объект, комментарий, позиции. Desktop — таблица-ряд. Mobile — столбик (`_PurchaseItemMobileCard`); открытие через `useEmployeesDesktopModal` + `isDesktopSurface` |
| `widgets/purchase_request_settings_dialog.dart` | Настройки маршрута (4 роли + режим получателя); desktop — `DesktopDialogContent` 880 px, таймлайн `_DesktopRouteStep` (5 этапов, номер + подсказка + выбранные ФИО + dropdown 340 px), подвал «Отмена» / «Сохранить»; mobile — вертикальная форма в `MobileBottomSheetContent`; мультивыбор `GTDropdown`; пользователи — `purchaseRequestCompanyUsersProvider` |
| `widgets/purchase_request_actions_bar.dart` | Кнопки workflow; `resolvePurchaseRequestActions` (права + `isPurchaseRequestStageAssignee(settings)` + статус); `hasAny`; предупреждения submit только после `AsyncValue.hasValue` |
| `utils/purchase_request_invoice_utils.dart` | `purchaseRequestInvoicesReadyForSubmit()`, `isPurchaseRequestInvoiceFilePreviewable()` |
| `utils/purchase_request_invoice_file_flow.dart` | Скачивание и просмотр файла счёта (`downloadInvoiceFile` + `openAttachmentFilePreview`) |
| `utils/purchase_request_items_excel_export.dart` | Клиентская сборка xlsx позиций (`PurchaseRequestItemsExcelExportService`) и сохранение на устройство (`exportPurchaseRequestItemsToDevice`); лист «Позиции»; имя `Заявка_{номер}.xlsx` |
| `utils/purchase_request_ui_labels.dart` | Цвета статусов (`statusColor`), фразы истории (`historyActionPhrase`), `idleActionsMessage` |
| `utils/purchase_request_module_utils.dart` | `isPurchaseRequestSettingsConfigured()`, `isPurchaseRequestStageAssignee()`, `formatPurchaseRequestAmount()`, `latestPurchaseRequestCancelComment()` |
| `utils/purchase_request_form_dialog.dart` | `showPurchaseRequestFormDialog` — desktop `DesktopDialogContent`, mobile `MobileBottomSheetContent` (`useSafeArea: true`) |

### Провайдеры

| Провайдер | Назначение |
|-----------|------------|
| `purchaseRequestListProvider` | Единый `StateNotifier` списка: фильтр (дефолт **`all`**), поиск (debounce 300 ms), **`kPurchaseRequestListLimit = 50`**, флаг **`isTruncatedByLimit`** |
| `purchaseRequestDetailsProvider` | Детали заявки (`family` по id) |
| `purchaseRequestItemsProvider` | Позиции |
| `purchaseRequestHistoryProvider` | История |
| `purchaseRequestInvoicesProvider` | Счета с прикреплёнными файлами (`family` по id) |
| `purchaseRequestInvoiceFileBusyIdsProvider` | Id файлов счетов, которые сейчас скачиваются или открываются (`family` по `requestId`) |
| `purchaseRequestSettingsProvider` | Настройки компании |
| `purchaseRequestCompanyUsersProvider` | Пользователи для dropdown настроек (используется в `PurchaseRequestSettingsDialog`) |

**Хелперы:**
- `refreshPurchaseRequestList(ref)` — `load(quiet: true)` без пересоздания notifier (фильтр и поиск сохраняются).
- `invalidatePurchaseRequestCaches(ref, requestId)` — сброс кэша деталей, истории, позиций, **счетов** + `refreshPurchaseRequestList`.

**Company:** `isCompanyOwnerProvider` (`company_providers.dart`) — `profile.isOwner == true` для кнопки «Настройки» на desktop.

**DI:** `purchaseRequestRepositoryProvider` → `PurchaseRequestRepositoryImpl(client, activeCompanyId)`; write-методы проверяют `_hasCompany`. Ошибки списка — `formatSupabaseErrorMessage`; в `FutureProvider` деталей/позиций/истории пока сырой `'$e'` (техдолг).

### Навигация и доступ

- **Маршрут:** `/purchase_requests` (`app_router.dart`, name `purchase_requests`). Вложенный маршрут деталей **отсутствует** — выбор заявки через локальный state `_selectedRequestId`. Открытая панель не закрывается автоматически, если заявки нет в текущем фильтре списка (например черновик при «На согласовании»).
- **Drawer:** пункт «Заявки на закупку» (`app_drawer.dart`)
- **Матрица прав:** для `purchase_requests` отключены TMC-специфичные коды (`issue`, `move`, `repair`, …) в `permissions_matrix.dart`

### UX / раскладка

**Desktop (по образцу Cash Flow):**

```
┌───────────────────────┬──────────────────────────────────────┐
│ Поиск                 │  Таблица заявок  ИЛИ  Детали заявки   │
│ На согласовании       │                                      │
│ Согласованы / Все     │  Колонки: Номер | Объект | Инициатор │
│ Архив                 │           Дата | Сумма | Статус      │
│ Новая заявка          │                                      │
│ Настройки             │                                      │
└───────────────────────┴──────────────────────────────────────┘
```

- При смене фильтра обновляется только содержимое таблицы, каркас layout сохраняется.
- Desktop: фильтры — `PurchaseRequestFilterBar.desktopSidebar` в sidebar; при лимите — баннер над таблицей.
- Клик по строке — детали в правой панели; кнопка «назад» в шапке панели деталей (`showCloseButton`).
- После создания заявки список **перезагружается** (`refreshPurchaseRequestList`), заявка открывается в панели деталей (`_selectedRequestId`). Черновик может отсутствовать во вкладке «На согласовании» / «Согласованы» — панель деталей всё равно остаётся открытой, пока пользователь не закроет её.
- `ref.listen` на исчезновение заявки из списка **удалён** (мёртвая ветка: выбор всегда совпадал с «закреплением»).

**Фильтры списка (RPC `purchase_request_list`, миграция `20260816203000` / live `purchase_request_list_status_filters`):**

Вкладки **не** делят заявки на «мои / не мои». Значения `mine` / `on_me` **удалены**. Неизвестный `p_filter` **не** показывает все строки (нет fallback).

| Фильтр UI | Enum | RPC `p_filter` | Семантика |
|-----------|------|----------------|-----------|
| На согласовании | `pendingApproval` | `pending_approval` | Статус **`approval`** |
| Согласованы | `approved` | `approved` | Статусы `invoice_preparation`, `invoice_approval`, `accounting`, `payment_queue`, `paid` |
| Все | `all` | `all` | Все видимые заявки, включая черновики, доработку и архив |
| Архив | `archive` | `archive` | Статус `received` (и устаревший `cancelled`, если останется) |

Черновик (`draft`) и доработка (`revision`) видны **только** во «Все».

Право `view_all` **не привязано** к вкладке «Все» — оно расширяет видимость во **всех** фильтрах. В RPC `purchase_request_list`: если нет `view_all`, показываются свои заявки **или** те, где `purchase_request_internal_user_is_assignee(...)` (не сравнение с `current_assignee_id`).

Дефолт UI: `PurchaseRequestListFilter.all`. Дополнительные фильтры RPC (`p_object_id`, `p_status`, `p_created_by`, даты, `p_offset`) в Dart-репозитории не пробрасываются — при необходимости пагинации/фильтров их нужно вернуть в `list()`.

**Mobile:**

- **Шапка:** меню (или «Назад» в деталях), заголовок «Заявки» / «Заявка», кнопка «+» при `canCreate`. Кнопок смены темы и настроек **нет**.
- **Настройки маршрута:** на mobile недоступны из шапки. Если маршрут ещё не задан — `_ModuleSetupPlaceholder` с кнопкой «Настройка согласующих» (только owner). После настройки состав ролей меняется на desktop.
- Список карточек (`PurchaseRequestCard`): номер, объект, дата, сумма, статус — **без превью позиций и без инициатора** (в desktop-таблице инициатор есть). Позиции видны внутри заявки.
- Список: `MobileAtmosphereMainSurface` padding `8`; карточка — внешний horizontal padding `4` (шире, чем прежние 16+12).
- Фильтры — `PurchaseRequestFilterBar.mobile` (chip-сегменты, не Material `ChoiceChip`).
- При `isTruncatedByLimit` — `PurchaseRequestListLimitBanner`.
- Breakpoint — `EmployeesLayoutUtils.useEmployeesMobileList` (`shortestSide < 600`).
- Тап по карточке — `PurchaseRequestDetailsPanel` на весь экран; **кнопка «Назад»** — в шапке `PurchaseRequestsListScreen` (не внутри панели); обёртка `MobileAtmosphereMainSurface` с `padding: EdgeInsets.zero` (отступы задаёт сама панель).
- Фон экрана: `MobileAtmosphereBackdrop` + `Scaffold` (не `EdgeToEdgeScaffold`).
- Форма «Новая заявка» / правка черновика: `showModalBottomSheet` на всю ширину (`useSafeArea`, `useRootNavigator`, `constraints.maxWidth = screenWidth`). Обёртка — `MobileBottomSheetContent` (высота по контенту, кнопка в `footer`). Выбор окна — `EmployeesLayoutUtils.useEmployeesDesktopModal` (телефон в любом положении — лист, не диалог). Поверхность фиксируется полем `isDesktopSurface`, чтобы узкий `Dialog`/`Sheet` не переключал вёрстку.
- Список позиций в деталях на ширине &lt; 600 px — карточки (`_ItemsMobileList`), не колонки таблицы.
- Логика (фильтры, создание, workflow, права) **та же**, что на desktop; отличается только UI.

**Панель деталей заявки (`PurchaseRequestDetailsPanel`):**

```
┌─────────────────────────────────────────────────────────────┐
│ ←  ЗП-2026-00010                                            │  ← номер крупно
│    ЦОД Дубна ФНС · Тельнов Д.А.                             │  ← объект · инициатор
├─────────────────────────────────────────────────────────────┤
│ ┌──────────┐ ┌─────────┐ ┌─────────┐                        │
│ │ Статус   │ │ Сумма   │ │ Позиций │                        │  ← KPI-карточки
│ │ Черновик │ │    —    │ │    4    │                        │
│ └──────────┘ └─────────┘ └─────────┘                        │
│ [Комментарий инициатора, если есть]                         │
├─────────────────────────────────────────────────────────────┤
│ ПОЗИЦИИ                       [Excel] [+ Добавить]          │
│ ┌───┬──────────────┬──────┬────┬─────────┐                  │
│ │ № │ Наименование │ Кол-во│ Ед.│ Артикул │                  │
│ └───┴──────────────┴──────┴────┴─────────┘                  │
├─────────────────────────────────────────────────────────────┤
│ СЧЕТА                                [+ Добавить]           │  ← invoice_preparation+
│ ┌ Поставщик · сумма · № · дата · файл ✓/✗ ──────────────┐  │
│ └────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│ ИСТОРИЯ                                                     │
│ ● Тельнов Д.А. создал заявку         16.08.2026 07:46     │  ← таймлайн
├─────────────────────────────────────────────────────────────┤
│                              [Отправить]  [Отменить]        │  ← подвал, справа
└─────────────────────────────────────────────────────────────┘
```

- **Design tokens** (`PurchaseRequestDetailsTokens`): `pagePadding` 20, `sectionGap` 20, `cardRadius` 12, единый `borderColor` (`outline` 10%), фон страницы `#F8FAFC` (light), карточки — белые с лёгкой тенью; шапка/подвал — только линия-разделитель (без дублирования тени).
- **Шапка:** номер заявки (`headlineSmall`, жирный); под ним `{objectName} · {initiatorLabel}`; при переполнении — `ellipsis`.
- **KPI-сводка:** три карточки в ряд (на ширине &lt; 520 px — столбец); статус с цветной полосой слева и точкой; сумма и позиции — с иконками; при `revision` — баннер «Возвращено на доработку»; комментарий — отдельная карточка. Дата создания **не дублируется** — она в истории.
- **Позиции:** на ширине ≥ 600 px — bordered-таблица, зебра-строки, заголовок `#F8FAFC`; порядковые номера; удаление — `IconButton` (только `draft`/`revision`). Колонки «Наименование» (flex 3) и «Артикул» (flex 2) делят свободную ширину; длинный текст — до 2 строк; если таблицы не хватает ширины — горизонтальный скролл. На ширине &lt; 600 px — карточки: наименование целиком, ниже количество и единица, артикул при наличии. Кнопка «Excel» (`GTTextButton`, `Icons.download_outlined`) — если есть ≥1 позиция; доступна всем, кто видит заявку (не только автору). Кнопка «Добавить» — `GTTextButton` с иконкой; диалог добавления — `showPurchaseRequestFormDialog` (наименование, количество, ед. изм., **артикул**).
- **Счета:** секция `PurchaseRequestInvoicesSection` — видна при статусах `invoice_preparation` … `received`; управление (добавить/удалить) — только при `canSubmitInvoices` (участник роли этапа + `prepare_invoice` + `invoice_preparation`); карточка показывает поставщика, сумму (`formatCurrency`), номер, дату, имя файла; иконка ✓/✗ по `hasInvoiceFile`. При наличии файла — кнопки **Просмотреть** (`Icons.visibility_outlined`) и **Скачать** (`Icons.download_outlined`) для любого, кто видит заявку; спиннер — `purchaseRequestInvoiceFileBusyIdsProvider`. Просмотр: PDF — `printing.PdfPreview`, JPG/PNG — диалог с `InteractiveViewer`; прочие форматы — snackbar «скачайте файл». Скачивание: `saveFileBytesToUserDevice`. Диалог добавления — `PurchaseRequestInvoiceDialog` (desktop `DesktopDialogContent`, mobile `MobileBottomSheetContent` + `useSafeArea: true`).
- **Подвал действий:** предупреждения «Добавьте позицию» / «Добавьте счёт» и блокировка submit **только если** соответствующий `AsyncValue.hasValue` (во время загрузки кнопки неактивны, ложного текста нет). При `canSubmitInvoices` кнопка «Отправить на согласование» неактивна, пока `purchaseRequestInvoicesReadyForSubmit(invoices) == false`. Если действий нет: `idleActionsMessage` — «Заявка получена» / «Заявка отменена» / «Ожидает действия ответственного».
- **История:** вертикальный таймлайн (точка + соединительная линия); порядок **кто → что → когда**; на клиенте загрузка `ORDER BY created_at ASC` (старые события сверху); комментарий к событию — курсивом под строкой.
- **Подвал:** закреплён внизу (`_ActionsFooter` + `SafeArea`); кнопки workflow выровнены вправо (`Wrap`).

**Диалог создания:**

- Ширина desktop: **980 px**. Открытие: `EmployeesLayoutUtils.useEmployeesDesktopModal` (телефон в альбоме — не диалог). Поверхность задаётся `isDesktopSurface` в `PurchaseRequestCreateDialog.show`.
- Mobile: `showModalBottomSheet` (`isScrollControlled`, `useSafeArea`, `useRootNavigator`, ширина экрана, верхнее скругление 20). Обёртка — `MobileBottomSheetContent` по высоте контента; кнопка «Создать заявку» / «Сохранить» в `footer`.
- Desktop: каждая позиция — одна строка: наименование (flex), ед. изм. (80 px), кол-во (96 px), артикул (128 px). Кнопка «+» в заголовке секции; «−» для удаления дополнительных строк.
- Mobile: те же поля столбиком (`GTTextField` / `GTDropdown`): объект; секция «Что нужно закупить» + круглая кнопка «+» 44×44; наименование на всю ширину; ряд **50/50** — слева «− кол-во +», справа «ед. изм.»; артикул; комментарий. Шаг количества — квадратные кнопки со скруглением **16** (как у поля). «Удалить» — круглая 44×44. При ≥2 позициях: подпись «Позиция N» и тонкий `Divider` (`outline` 12%). Одна позиция — без подписи и без разделителя.
- Логика сохранения та же, что на desktop (`createDraft` / `updateHeader` + add/update/delete позиций).

**Диалог настройки маршрута (`PurchaseRequestSettingsDialog`):**

- **Desktop:** ширина **880 px** (`_kDesktopDialogWidth`); внешний `Dialog` с `constraints: BoxConstraints(maxWidth: 880)` — обход дефолтного лимита Material 3 (560 px). Обёртка — `DesktopDialogContent`; подвал — `GTSecondaryButton` «Отмена» + `GTPrimaryButton` «Сохранить».
- **Desktop layout:** вертикальный таймлайн из 5 этапов (`_DesktopRouteStep` + `_StepIndex`): слева номер этапа (заливка при заполнении), справа — название, краткая подсказка, список выбранных ФИО; поле выбора — `GTDropdown` шириной **340 px** (`_kDesktopFieldWidth`).
- **Этапы:** (1) Первый согласующий, (2) Подготовка счетов, (3) Согласование счетов, (4) Бухгалтер, (5) Получение материала (`initiator` / `fixedUser` + опциональный мультивыбор получателя).
- **Подсказка в шапке:** на каждом этапе достаточно действия любого из выбранных; в списке только пользователи приложения (не карточки «Сотрудники»).
- **Mobile:** `MobileBottomSheetContent` + `useSafeArea: true`; вертикальный список полей с `labelText`; кнопка «Сохранить» в `footer`.
- **Валидация перед сохранением:** все 4 роли непусты; при `receiverMode = fixedUser` — непустой `fixedReceiverIds`. RPC — `purchase_request_upsert_settings`.

### Design System

- `GTPrimaryButton`, `GTSecondaryButton`, `GTTextButton`, `GTTextField`, `GTDropdown`
- `DesktopDialogContent`, `MobileBottomSheetContent` — создание заявки, настройки, **диалог счёта**, комментарий workflow, добавление позиции (`showPurchaseRequestFormDialog`)
- `file_selector` (`openFile`) — выбор файла счёта (PDF / изображение)
- `openAttachmentFilePreview` (`lib/core/widgets/attachment_file_preview.dart`) — просмотр PDF (`printing.PdfPreview`) и изображений
- `saveFileBytesToUserDevice` (`lib/core/utils/attachment_file_save.dart`) — сохранение файла счёта на устройство
- `GTSectionTitle` — заголовок desktop-таблицы реестра
- `AppSnackBar`, `MobileAtmosphereBackdrop`, `MobileAtmosphereMainSurface`, `MobileAtmosphereChromeCircleButton`
- Фильтры: `PurchaseRequestFilterBar` + `PayrollToolbarSegmentChip` (mobile)
- Панель деталей: собственные токены (`PurchaseRequestDetailsTokens`)
- Форматтеры: `formatRuDate`, `formatRuDateTime`, `formatQuantity`, `formatCurrency`, `formatPurchaseRequestAmount`
- ФИО: `pickProfileDisplayName`, `formatUserDisplayLabel` (`lib/core/utils/user_display_utils.dart`)

---

## Domain / Data

### Архитектура слоёв

- **Use Cases:** отсутствуют (`domain/use_cases/` нет). Бизнес-правила кнопок workflow — в `resolvePurchaseRequestActions` (`purchase_request_actions_bar.dart`); gate настроек — `isPurchaseRequestSettingsConfigured()` (дублирует SQL `purchase_request_internal_settings_configured`); проверка «может действовать на этапе» — `isPurchaseRequestStageAssignee()` (дублирует SQL `purchase_request_internal_user_is_assignee`).
- **Domain entities** с `fromRpcRow` / `fromJson`: `PurchaseRequestListItem`, `PurchaseRequestCompanyUser` — `fromRpcRow`; `PurchaseRequestHistoryEntry` — только `fromJson`; `PurchaseRequestInvoice` / `PurchaseRequestFile` — маппинг в `PurchaseRequestInvoiceModel` / `PurchaseRequestFileModel`. Маппинг в domain (техдолг: перенести остальное в `data/models`).
- **Сущности без Dart-кода:** `purchase_request_notifications` — только таблица БД.

### Сущности (domain)

| Сущность | Файл | Описание |
|----------|------|----------|
| `PurchaseRequest` | `purchase_request.dart` | Заявка (Freezed); `initiatorLabel` → `formatUserDisplayLabel(createdByName)` |
| `PurchaseRequestItem` | `purchase_request_item.dart` | Позиция (`article` опционально) |
| `PurchaseRequestStatus` | `purchase_request_status.dart` | Enum статусов (+ `unknown` для ошибок данных), `parseFromDb`, `PurchaseRequestListFilter` (`pendingApproval` / `approved` / `all` / `archive`) |
| `PurchaseRequestListItem` | `purchase_request_list_item.dart` | Строка списка; `initiatorLabel` через `formatUserDisplayLabel`. Поля `items_preview` / `items_count` и `current_assignee_id` **удалены** из entity и RPC `purchase_request_list` (миграция `20260822110000`); карточка/таблица их не показывают |
| `PurchaseRequestSettings` | `purchase_request_settings.dart` | Настройки маршрута: списки `firstApproverIds`, `invoicePreparerIds`, `invoiceApproverIds`, `accountantIds`, `fixedReceiverIds`; `receiverMode`. В entity нет `created_at` / `updated_at` / `updated_by` |
| `PurchaseRequestHistoryEntry` | `purchase_request_history_entry.dart` | Запись истории; `userName`, `userLabel` → `formatUserDisplayLabel`; `fromJson`: `from_status`/`to_status` — `null` → `null`, иначе `parseFromDb`; без `company_id`, `metadata` |
| `PurchaseRequestCompanyUser` | `purchase_request_company_user.dart` | Пользователь для настроек; `displayName` через `pickUserDisplayName` |
| `PurchaseRequestInvoice` | `purchase_request_invoice.dart` | Счёт поставщика; `hasInvoiceFile`, `invoiceFile` |
| `PurchaseRequestFile` | `purchase_request_file.dart` | Метаданные файла (`type`, `storagePath`, `fileName`, `mimeType`, `size`) |
| `PurchaseRequestCompanyRequiredException` | `purchase_request_repository_exception.dart` | Нет активной компании при write |

### Репозиторий

- **Интерфейс:** `domain/repositories/purchase_request_repository.dart`
- **Реализация:** `data/repositories/purchase_request_repository_impl.dart`
- **Модели:** `data/models/purchase_request_models.dart` (маппинг JSON ↔ entity; settings — `fromSettingsAndMembers`).

| Операция | Способ |
|----------|--------|
| `list` | RPC `purchase_request_list` |
| `getRequest` | `SELECT *, objects:object_id(name)` + отдельный запрос `profiles` по `created_by` |
| `getHistory` | `SELECT` из `purchase_request_history` + batch `profiles` по `user_id` |
| `getInvoices` | `SELECT` из `purchase_request_invoices` + join `contractors`; batch `purchase_request_files` (type = `invoice`) |
| `createInvoiceWithFile` | INSERT счёта → upload Storage → INSERT файла; при ошибке после upload — `storage.remove`, затем DELETE счёта |
| `deleteInvoice` | DELETE счёта (CASCADE файлов) + best-effort `storage.remove` (`_removeStoragePaths`) |
| `downloadInvoiceFile` | `storage.download` из bucket `purchase_requests`; путь должен начинаться с `activeCompanyId/` |
| `getSettings` | `SELECT` из `purchase_request_settings` + `SELECT` из `purchase_request_route_members`; маппинг `PurchaseRequestSettingsModel.fromSettingsAndMembers` |
| `getItems` | Прямой `SELECT` из `purchase_request_items` |
| `createDraft`, workflow | RPC (см. раздел БД) |
| `updateHeader` | RPC `purchase_request_update_header` |
| `deleteDraft` | RPC `purchase_request_delete_draft` |
| items add/delete/update | PostgREST insert/delete/update (RLS); `addItem`, `deleteItem`, **`updateItem`** |
| `upsertSettings` | RPC `purchase_request_upsert_settings` с массивами `uuid[]` (`p_first_approver_ids`, `p_invoice_preparer_ids`, `p_invoice_approver_ids`, `p_accountant_ids`, `p_receiver_mode`, `p_fixed_receiver_ids`); проверка `settings.companyId == activeCompanyId`; затем повторный `getSettings` |
| `list` | `filter` + `search` + **`limit=50`** (RPC `purchase_request_list`; расширенные параметры RPC не пробрасываются из Dart) |

**Guard:** все write-методы → `_requireCompany()` → `PurchaseRequestCompanyRequiredException`.

**Парсинг статуса:** `PurchaseRequestStatusX.parseFromDb` — при неизвестном значении лог + `PurchaseRequestStatus.unknown` (не fallback в `draft`).

**Резолвинг ФИО:** `pickProfileDisplayName` / `_fetchUserNames` в репозитории; `user_display_utils.dart` в models/entities.

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
│   │   ├── purchase_request_company_user.dart
│   │   ├── purchase_request_settings.dart
│   │   ├── purchase_request_settings.freezed.dart
│   │   ├── purchase_request_history_entry.dart
│   │   ├── purchase_request_invoice.dart
│   │   ├── purchase_request_file.dart
│   │   ├── purchase_request_repository_exception.dart
│   │   └── purchase_request_status.dart
│   └── repositories/
│       └── purchase_request_repository.dart
└── presentation/
    ├── screens/
    │   ├── purchase_requests_list_screen.dart
    │   └── desktop/
    │       └── purchase_requests_list_desktop_view.dart
    ├── state/
    │   └── purchase_request_providers.dart
    ├── utils/
    │   ├── purchase_request_invoice_utils.dart
    │   ├── purchase_request_invoice_file_flow.dart
    │   ├── purchase_request_items_excel_export.dart
    │   ├── purchase_request_form_dialog.dart
    │   ├── purchase_request_ui_labels.dart
    │   └── purchase_request_module_utils.dart
    └── widgets/
        ├── purchase_request_actions_bar.dart
        ├── purchase_request_card.dart
        ├── purchase_request_create_dialog.dart
        ├── purchase_request_details_panel.dart
        ├── purchase_request_details_summary.dart
        ├── purchase_request_details_tokens.dart
        ├── purchase_request_filter_bar.dart
        ├── purchase_request_history_timeline.dart
        ├── purchase_request_invoice_dialog.dart
        ├── purchase_request_invoices_section.dart
        ├── purchase_request_items_table.dart
        ├── purchase_request_list_limit_banner.dart
        ├── purchase_request_settings_dialog.dart
        ├── purchase_request_status_badge.dart
        └── purchase_requests_table.dart

test/features/purchase_requests/
├── purchase_request_logic_test.dart   # статусы, user_display_utils, resolvePurchaseRequestActions, invoices ready, previewable, idleActionsMessage, history fromJson, latestPurchaseRequestCancelComment, isPurchaseRequestSettingsConfigured (28 тестов)
└── purchase_request_items_excel_export_test.dart  # fileNameFor, xlsx bytes (3 теста)

lib/core/utils/
├── user_display_utils.dart            # pickProfileDisplayName, formatUserDisplayLabel
└── attachment_file_save.dart          # saveFileBytesToUserDevice

lib/core/widgets/
└── attachment_file_preview.dart       # openAttachmentFilePreview (PDF / изображение)

lib/features/company/presentation/providers/
└── company_providers.dart             # isCompanyOwnerProvider

supabase/migrations/
├── 20260815160000_create_purchase_requests_module.sql
├── 20260815161000_purchase_requests_rpc.sql
├── 20260815170000_remove_purchase_request_required_date.sql
├── 20260815170500_purchase_request_settings_owner_gate.sql
├── 20260815172000_purchase_request_company_users_rpc.sql
├── 20260815172500_fix_purchase_request_list_created_at.sql
├── 20260815173000_purchase_request_list_created_by_name.sql
├── 20260815173500_purchase_request_item_article.sql
├── 20260815174000_purchase_request_storage_prepare_invoice_upload.sql
├── 20260816191000_purchase_request_own_draft_edit_delete.sql
├── 20260816194000_purchase_request_cancel_to_draft.sql
├── 20260816203000_purchase_request_list_status_filters.sql
├── 20260822100000_purchase_request_route_members.sql
└── 20260822110000_purchase_request_list_drop_preview.sql
```

---

## База данных (Audit)

**Аудит live БД:** 22.08.2026 через MCP `project-0-projectgt-supabase` (`api.progt.ru`). Миграция маршрута в репозитории: `supabase/migrations/20260822100000_purchase_request_route_members.sql`. На сервере применена как набор версий `purchase_request_route_members` … `purchase_request_upsert_settings_arrays` (live `list_migrations`, 22.08.2026).

### Таблица `purchase_requests`

| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| `id` | uuid | NO | PK |
| `company_id` | uuid | NO | FK → companies |
| `number` | text | NO | Уникальный номер `ЗП-YYYY-NNNNN` |
| `object_id` | uuid | NO | FK → objects |
| `created_by` | uuid | NO | FK → auth.users |
| `current_assignee_id` | uuid | YES | Первый пользователь роли этапа (запись при transition); не используется для авторизации |
| `status` | text | NO | Статус workflow |
| `comment` | text | YES | Комментарий инициатора |
| `total_amount` | numeric | NO | Сумма счетов (default 0) |
| `created_at` | timestamptz | NO | |
| `updated_at` | timestamptz | NO | |
| `submitted_at` | timestamptz | YES | |
| `completed_at` | timestamptz | YES | Финальный статус |

**Индексы:** `purchase_requests_pkey`, `purchase_requests_number_company_uq`, `idx_purchase_requests_company_status`, `idx_purchase_requests_assignee`, `idx_purchase_requests_created_by`, `idx_purchase_requests_object`, `idx_purchase_requests_number_trgm` (GIN).

### Таблица `purchase_request_items`

| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| `id` | uuid | NO | PK |
| `company_id` | uuid | NO | FK → companies |
| `request_id` | uuid | NO | FK → purchase_requests |
| `name` | text | NO | Наименование |
| `quantity` | numeric | NO | > 0 |
| `unit` | text | NO | Единица (default `шт`) |
| `article` | text | YES | Артикул |
| `comment` | text | YES | |
| `sort_order` | int | NO | Порядок |
| `created_at` | timestamptz | NO | |

**Индексы:** `idx_purchase_request_items_request`, `idx_purchase_request_items_name_trgm` (GIN).

### Таблица `purchase_request_invoices`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `company_id`, `request_id`, `supplier_id` | | Счета поставщиков |
| `invoice_number`, `invoice_date`, `amount`, `comment` | | Реквизиты счёта |
| `created_by`, `created_at`, `updated_at` | | Аудит |

**RLS insert/update/delete:** `purchase_request_internal_user_is_assignee` + `prepare_invoice` + статус заявки `invoice_preparation` (delete также в `invoice_approval`).

**Индексы:** `idx_purchase_request_invoices_request`, `idx_purchase_request_invoices_supplier`.

### Таблица `purchase_request_files`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `company_id`, `request_id` | | Файлы заявки |
| `invoice_id` | uuid | Связь со счётом (nullable) |
| `type`, `storage_path`, `file_name`, `mime_type`, `size` | | Метаданные Storage |
| `uploaded_by`, `created_at` | | |

**Типы `type`:** `invoice` (к счёту), прочие — для будущего блока «Документы».

**Индексы:** `idx_purchase_request_files_request`, `idx_purchase_request_files_invoice`.

### Таблица `purchase_request_history`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id` | uuid | PK |
| `company_id` | uuid | FK → companies |
| `request_id` | uuid | FK → purchase_requests |
| `user_id` | uuid | FK → auth.users (автор действия) |
| `action` | text | Код действия (`created`, `submitted`, …) |
| `from_status`, `to_status` | text | Статусы до/после |
| `comment` | text | Комментарий к переходу |
| `metadata` | jsonb | Доп. данные (напр. `received_date`) |
| `created_at` | timestamptz | Время события |

**Индексы:** `idx_purchase_request_history_request (request_id, created_at DESC)`.

Записи **неизменяемы** для `authenticated` (только `SELECT`; insert — через internal RPC).

### Таблица `purchase_request_notifications`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `id`, `company_id`, `request_id`, `user_id` | | Получатель |
| `title` | text | Заголовок |
| `body` | text | Текст (nullable) |
| `is_read` | boolean | Прочитано |
| `created_at` | timestamptz | |

**Индексы:** `idx_purchase_request_notifications_user (user_id, is_read, created_at DESC)`.

### Таблица `purchase_request_settings`

| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| `company_id` | uuid | NO | PK, FK → `companies.id` |
| `receiver_mode` | text | NO | `fixed_user` \| `initiator` (default `initiator`) |
| `created_at` | timestamptz | NO | |
| `updated_at` | timestamptz | NO | |
| `updated_by` | uuid | YES | |

**Индексы:** `purchase_request_settings_pkey`.

### Таблица `purchase_request_route_members`

| Колонка | Тип | NULL | Описание |
|---------|-----|------|----------|
| `company_id` | uuid | NO | FK → `purchase_request_settings(company_id)` ON DELETE CASCADE |
| `role` | text | NO | `first_approver` / `invoice_preparer` / `invoice_approver` / `accountant` / `receiver` |
| `user_id` | uuid | NO | FK → `auth.users` ON DELETE CASCADE |
| `sort_order` | int | NO | Порядок в списке (default 0) |

**PK:** `(company_id, role, user_id)`.

**Индексы:** `purchase_request_route_members_pkey`, `idx_purchase_request_route_members_role` (`company_id, role, sort_order`).

**RLS SELECT:** компания ∈ `get_my_company_ids()` + permission `purchase_requests.read`. Политика: `pr_route_members_select`. Для `authenticated`: GRANT SELECT; INSERT/UPDATE/DELETE нет (live `table_privileges`). Запись состава — RPC `purchase_request_upsert_settings` → `replace_role_members`.

### Таблица `purchase_request_number_seq`

| Колонка | Тип | Описание |
|---------|-----|----------|
| `company_id`, `year` | | PK (составной) |
| `last_value` | int | Счётчик номеров по году |

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
| `purchase_request_route_members` | ✅ |
| `purchase_request_number_seq` | ❌ Отключён (internal) |

**Ключевые политики:**

- `purchase_requests`: `pr_requests_select` — `purchase_request_can_read(company_id, created_by, status)`
- `purchase_request_items`: insert/update/delete — только автор в `draft`/`revision`
- `purchase_request_invoices`: insert/update/delete — `purchase_request_internal_user_is_assignee` в `invoice_preparation` (+ delete в `invoice_approval`) с `prepare_invoice`
- `purchase_request_files`: insert — по этапу (draft/revision, invoice_preparation, payment и др.) с `user_is_assignee` на этапах счетов/оплаты/получения
- `purchase_request_history`: только `SELECT` для authenticated
- `purchase_request_settings`: select — `read`; insert/update — `purchase_request_internal_is_company_owner` (запись состава ролей всё равно через RPC)
- `purchase_request_route_members`: только `SELECT` для authenticated
- `purchase_request_notifications`: select/update — только `user_id = uid()`

### Storage

- Bucket: **`purchase_requests`** (id и name совпадают), **private** (`public = false`, live 22.08.2026)
- **Путь файла счёта:** `{company_id}/{request_id}/invoices/{invoice_id}/{timestamp}_{safeFileName}`
- **Допустимые расширения в UI:** `pdf`, `jpg`, `jpeg`, `png` (`purchaseRequestInvoiceAcceptedExtensions`)
- **Политики `storage.objects` (live, 22.08.2026):**
  - `purchase_requests_bucket_select` — `bucket_id = purchase_requests`, первый сегмент пути ∈ `get_my_company_ids()`, permission **`read`** (нужно для просмотра и скачивания)
  - `purchase_requests_bucket_insert` — тот же company_id + (`create` **или** `prepare_invoice` **или** `payment` **или** `receive`); миграция `20260815174000` расширила INSERT для `prepare_invoice` (ранее только `create`)
  - `purchase_requests_bucket_delete` — те же права, что INSERT

### RPC (публичные, `authenticated`)

| Функция | Назначение |
|---------|------------|
| `purchase_request_list` | Список: `pending_approval` / `approved` / `all` / `archive`; `created_by_name` из `profiles` |
| `purchase_request_create_draft` | Черновик (+ gate: settings configured) |
| `purchase_request_update_header` | Объект/комментарий: только автор, только `draft`, право `create` |
| `purchase_request_delete_draft` | Удаление: только автор, только `draft`, право `create` |
| `purchase_request_submit` | `draft`/`revision` → `approval` |
| `purchase_request_approve` | Согласование → `invoice_preparation` |
| `purchase_request_return` | Возврат на доработку → `revision` |
| `purchase_request_submit_invoices` | Отправка счетов на согласование |
| `purchase_request_approve_invoice` | Согласование счетов → `accounting` |
| `purchase_request_return_invoice` | Возврат счетов → `invoice_preparation` |
| `purchase_request_queue_payment` | Очередь оплаты |
| `purchase_request_mark_paid` | Оплачено → получатель |
| `purchase_request_mark_received` | Получено (финал) |
| `purchase_request_cancel` | Возврат в `draft` с обязательной причиной |
| `purchase_request_upsert_settings` | Сохранение настроек (owner only); параметры: `p_first_approver_ids uuid[]`, `p_invoice_preparer_ids uuid[]`, `p_invoice_approver_ids uuid[]`, `p_accountant_ids uuid[]`, `p_receiver_mode text`, `p_fixed_receiver_ids uuid[]` |
| `purchase_request_company_users` | Список пользователей для dropdown |

**Возврат `purchase_request_list`:** `id`, `number`, `object_id`, `object_name`, `status`, `created_by`, `created_by_name`, `current_assignee_id`, `total_amount`, `created_at`. Поля `items_preview` / `items_count` **удалены** из RPC миграцией `20260822110000` (не использовались в UI); `current_assignee_id` возвращается для совместимости, но Dart-entity его не парсит.

### Внутренние функции

| Функция | Назначение |
|---------|------------|
| `purchase_request_internal_transition` | Единая точка смены статуса |
| `purchase_request_internal_write_history` | Запись в history |
| `purchase_request_internal_notify` | Записи в notifications (один `user_id`) |
| `purchase_request_internal_notify_role` | Уведомление **всех** участников роли (`purchase_request_route_members`); опционально `p_except_user_id` |
| `purchase_request_internal_user_is_assignee` | Авторизация на этапе: автор в `draft`/`revision`; иначе EXISTS член роли по статусу (OR) |
| `purchase_request_internal_first_role_user` | Первый `user_id` роли (`ORDER BY sort_order, user_id LIMIT 1`) — пишется в `current_assignee_id` |
| `purchase_request_internal_replace_role_members` | Замена списка участников роли (вызывается из upsert_settings) |
| `purchase_request_internal_assert_route_users` | Все id ∈ активные `company_members` |
| `purchase_request_internal_resolve_receiver` | Получатель: при `fixed_user` — `first_role_user(..., 'receiver')`, иначе `created_by` |
| `purchase_request_internal_settings_configured` | Проверка полноты: EXISTS участников четырёх ролей + receiver по режиму |
| `purchase_request_internal_is_company_owner` | Gate для settings |
| `purchase_request_internal_next_number` | Нумерация |
| `purchase_request_internal_assert_company` | Проверка company_id |
| `purchase_request_can_read` | RLS helper: `(company_id, created_by, status)` |
| `purchase_request_recalc_total_amount` | Пересчёт `total_amount` по счетам |

### Статистика live (22.08.2026 повторный аудит, MCP `pg_stat_user_tables.n_live_tup`)

| Таблица | Строк (оценка) |
|---------|----------------|
| `purchase_requests` | 3 |
| `purchase_request_items` | 6 |
| `purchase_request_history` | 19 |
| `purchase_request_settings` | 1 |
| `purchase_request_route_members` | 4 |
| `purchase_request_notifications` | 10 |
| `purchase_request_invoices` | 2 |
| `purchase_request_files` | 2 |
| `purchase_request_number_seq` | 1 |

---

## Бизнес-логика

### Статусы

Подписи в UI — `PurchaseRequestStatus.displayName` (extension `PurchaseRequestStatusX`).

| Код | UI (рус.) | Цвет бейджа |
|-----|-----------|-------------|
| `draft` | Черновик | Серый |
| `approval` | На согласовании | Синий |
| `revision` | На доработке | Оранжевый |
| `invoice_preparation` | Формирование счета | Фиолетовый |
| `invoice_approval` | Согласование счета | Голубой |
| `accounting` | Передано бухгалтеру | Бирюзовый |
| `payment_queue` | Заведено на оплату | Янтарный |
| `paid` | Оплачено | Зелёный |
| `received` | Получено | Тёмно-зелёный |
| `cancelled` | Отменено | Красный |
| *(ошибка данных)* | `unknown` → «Неизвестный статус» | Коричневый |

Цвета — `PurchaseRequestUiLabels.statusColor`; отображение — `PurchaseRequestStatusBadge` (список/таблица) или KPI-карточка (детали).

### Workflow (основной путь)

```mermaid
stateDiagram-v2
    [*] --> draft
    draft --> approval: submit
    approval --> invoice_preparation: approve
    approval --> revision: return
    revision --> approval: submit
    invoice_preparation --> invoice_approval: submit_invoices
    invoice_approval --> accounting: approve_invoice
    invoice_approval --> invoice_preparation: return_invoice
    accounting --> payment_queue: queue_payment
    payment_queue --> paid: mark_paid
    paid --> received: mark_received
    approval --> draft: cancel
    revision --> draft: cancel
    invoice_preparation --> draft: cancel
    invoice_approval --> draft: cancel
    accounting --> draft: cancel
    payment_queue --> draft: cancel
    paid --> draft: cancel
```

> **Этап счетов:** переход `invoice_preparation → invoice_approval` требует ≥1 счёта и файла `type = invoice` у **каждого** счёта (валидация RPC + клиент `purchaseRequestInvoicesReadyForSubmit`). UI: секция «Счета», диалог добавления, кнопка «Отправить на согласование» с блокировкой до готовности.

### Счета (формирование и отправка)

**Кто может:** `purchase_request_internal_user_is_assignee` (любой участник роли `invoice_preparer`) + permission `prepare_invoice` + статус `invoice_preparation`. В UI: `isPurchaseRequestStageAssignee` + то же право.

**Добавление счёта (клиент, `createInvoiceWithFile`):**

1. INSERT в `purchase_request_invoices` (`supplier_id`, `amount`, опционально `invoice_number`, `invoice_date`, `comment`).
2. Upload файла в Storage bucket `purchase_requests`.
3. INSERT в `purchase_request_files` (`invoice_id`, `type = 'invoice'`, `storage_path`, `file_name`, `mime_type`, `size`).
4. Если шаг 2 успешен, а шаг 3 падает — `storage.remove` загруженного пути, затем DELETE счёта.
5. Если шаг 2 падает — DELETE счёта (объекта в Storage нет).

**Удаление счёта (`deleteInvoice`):** DELETE строки счёта (CASCADE файлов в БД), затем best-effort `storage.remove`. Если Storage не ответил — запись в БД уже удалена, объект может остаться orphan (логируется).

**Просмотр и скачивание файла (`downloadInvoiceFile`):**

1. Клиент берёт `invoiceFile.storagePath` из `getInvoices`.
2. Репозиторий проверяет `storagePath.startsWith('$activeCompanyId/')`, иначе `ArgumentError`.
3. `client.storage.from('purchase_requests').download(storagePath)` — RLS Storage: `read` + company в пути.
4. **Скачать** (`downloadPurchaseRequestInvoiceFile`) → `saveFileBytesToUserDevice`.
5. **Просмотреть** (`previewPurchaseRequestInvoiceFile`) → если `isPurchaseRequestInvoiceFilePreviewable` (pdf / jpg / jpeg / png или MIME `application/pdf` / `image/*`) → `openAttachmentFilePreview`; иначе snackbar.
6. Пока идёт download — id файла в `purchaseRequestInvoiceFileBusyIdsProvider`; индикатор снимается до открытия окна просмотра.

**Отправка на согласование (`submitInvoices` → RPC `purchase_request_submit_invoices`):**

| Проверка | Ошибка RPC |
|----------|------------|
| Статус `invoice_preparation` | «Недопустимый статус» |
| `purchase_request_internal_user_is_assignee` | «Access denied» |
| Permission `prepare_invoice` | «Access denied» |
| ≥1 счёт | «Добавьте хотя бы один счёт» |
| Файл у каждого счёта | «Для каждого счёта нужен файл» |
| Есть участник роли `invoice_approver` (`first_role_user`) | «Не настроен финальный согласующий» |

После успеха: статус → `invoice_approval`, в `current_assignee_id` пишется первый `invoice_approver`, history `invoices_submitted`, уведомление **всем** участникам роли `invoice_approver` (`purchase_request_internal_notify_role`).

**Клиентская валидация (до RPC):** `purchaseRequestInvoicesReadyForSubmit` — непустой список и `invoices.every((i) => i.hasInvoiceFile)`. Кнопка и предупреждение в `PurchaseRequestActionsBar` только после загрузки списка счетов (`hasValue`).

### Ответственные (роль этапа vs `current_assignee_id`)

Авторизация: любой участник роли (OR). Значение `current_assignee_id` при transition — первый пользователь роли (`first_role_user`).

| Этап | Кто может действовать | Что пишется в `current_assignee_id` |
|------|------------------------|-------------------------------------|
| `draft`, `revision` | `created_by` | `created_by` (`create_draft` пишет `current_assignee_id = auth.uid()`; `return` — `created_by`) |
| `approval` | все `first_approver` | первый `first_approver` |
| `invoice_preparation` | все `invoice_preparer` | первый `invoice_preparer` |
| `invoice_approval` | все `invoice_approver` | первый `invoice_approver` |
| `accounting`, `payment_queue` | все `accountant` | первый `accountant` |
| `paid` | при `receiver_mode = fixed_user` — все `receiver`; иначе `created_by` | `resolve_receiver`: первый `receiver` или `created_by` |
| `received`, `cancelled` | никто (assignee-check = false) | `NULL` на `received`; `cancelled` новым переходам не назначается |

Смена списка в настройках **не** переписывает уже сохранённый `current_assignee_id`, но меняет, кто проходит `user_is_assignee` / UI.

### Права на действия (RPC + UI)

| Действие | Permission | Кто (автор / роль этапа) | Доп. условия |
|----------|------------|--------------------------|--------------|
| Создание / submit | `create` | автор | ≥1 позиция; settings configured |
| Правка / удаление заявки | `create` | **только автор** | только `draft`; UI: `canEditDraft` / `canDeleteDraft` |
| Добавление / удаление позиций | `create` (RLS) | автор | `draft` / `revision`; `canEditItems` в UI |
| approve / return | `approve` | любой `first_approver` | return: обязателен comment |
| submit invoices | `prepare_invoice` | любой `invoice_preparer` | ≥1 счёт + файл у каждого; UI блокирует кнопку до готовности |
| approve / return invoice | `approve_invoice` | любой `invoice_approver` | |
| queue payment / mark paid | `payment` | любой `accountant` | |
| mark received | `receive` | получатель(и) по режиму | |
| cancel (вернуть в черновик) | **нет** / `view_all` для чужих | автор или `view_all` | не `draft` / `received` / `cancelled`; обязателен comment; статус → `draft`; `current_assignee_id` → автор |
| Чтение списка | `read` | — | + правило видимости (`can_read` / list: свои или `user_is_assignee` или `view_all`) |
| Все заявки компании | `view_all` | — | расширяет видимость во всех фильтрах |

Логика кнопок на клиенте — `resolvePurchaseRequestActions` (`purchase_request_actions_bar.dart`). После мутаций — `invalidatePurchaseRequestCaches` (детали + `refreshPurchaseRequestList`).

### Gate: настройки перед созданием

`purchase_request_create_draft` → `purchase_request_internal_settings_configured`:

- EXISTS участник ролей `first_approver`, `invoice_preparer`, `invoice_approver`, `accountant`
- `receiver_mode = fixed_user` → EXISTS роль `receiver`
- `receiver_mode = initiator` → роль `receiver` не обязательна

Клиент: `isPurchaseRequestSettingsConfigured` — те же списки непусты + `fixedReceiverIds` при `fixedUser`. RPC upsert требует непустые массивы четырёх ролей (`«Укажите всех участников маршрута»`).

### Позиции

- **Добавление / удаление** — только в `draft` и `revision` (RLS + `canEditItems`; требуется permission `create`)
- **Изменение полей** существующей позиции — `updateItem` (PostgREST UPDATE); в UI — диалог редактирования черновика (`PurchaseRequestCreateDialog`)
- **Шапка заявки** (объект, комментарий) — RPC `purchase_request_update_header`, только автор и только `draft`
- Submit без позиций — предупреждение на клиенте **после загрузки позиций** + ошибка на сервере
- `unit` — свободный текст; `article` — опциональный; в диалоге из деталей артикул **запрашивается**
- `sort_order` при insert не задаётся клиентом (default 0; порядок по `created_at`)
- **Выгрузка в Excel** — клиент, без RPC и без Storage. Колонки: №, наименование, количество (`DoubleCellValue`), ед. изм., артикул. Лист `Позиции`. Имя файла: `Заявка_{номер}.xlsx` (символы `\ / : * ? " < > |` и пробелы заменяются на `_`). Сохранение: `saveFileBytesToUserDevice`. Кнопка скрыта, если позиций нет.

### История (отображение)

| Элемент | Источник | Формат в UI |
|---------|----------|-------------|
| Кто | `profiles` по `user_id` | `userLabel` (жирный, слева) |
| Что | `action` → `historyActionPhrase` | строчная фраза после ФИО |
| Когда | `created_at` | `formatRuDateTime`, справа, muted |
| Комментарий | `comment` | **отдельная строка** курсивом под действием |

Пример:

```
Тельнов Д.А. создал заявку          16.08.2026 07:46
Причина возврата (курсив, если есть)
```

Коды действий → фразы: `PurchaseRequestUiLabels.historyActionPhrase`. Поля `from_status` / `to_status` маппятся в entity (`null` или `parseFromDb`), но в UI **не отображаются**. Колонка `metadata` (jsonb) есть в БД (`received_date` и др.), в Dart-entity **не маппится**, в UI **не показывается** (техдолг).

### Получение после оплаты

`purchase_request_mark_paid` назначает `current_assignee_id` = `resolve_receiver` (первый `receiver` или инициатор). При `fixed_user` уведомляет **всех** `receiver` (`notify_role`); при `initiator` — одного инициатора через `notify`, если это не текущий пользователь. `mark_received` записывает `received_date` в `metadata` истории и завершает заявку (`completed_at`).

### Уведомления

| Событие | Кому |
|---------|------|
| `submit` / повторная отправка | все `first_approver` (`notify_role`, кроме автора действия) |
| `approve` | все `invoice_preparer` |
| `return` на доработку | инициатор (`notify`) |
| `submit_invoices` | все `invoice_approver` |
| `approve_invoice` | все `accountant` |
| `return_invoice` | все `invoice_preparer` |
| `queue_payment` | нет notify в RPC |
| `mark_paid` | все `receiver` **или** инициатор (см. выше) |
| `cancel` | пользователь из **текущего** `current_assignee_id` (если не автор действия) и инициатор, если отмену сделал не он. Не рассылка всей роли |

In-app UI уведомлений нет.

### Нумерация

Формат: `ЗП-{год}-{5 цифр}`. Счётчик в `purchase_request_number_seq` по `(company_id, year)`, поле `last_value`.

---

## Интеграции

| Компонент | Связь |
|-----------|-------|
| **RBAC** | `app_modules` code `purchase_requests`; `check_permission` в RPC |
| **Objects** | `object_id` при создании; join имени в деталях |
| **Contractors** | `purchase_request_invoices.supplier_id`; UI — `GTDropdown` поставщиков в `PurchaseRequestInvoiceDialog` |
| **Profiles** | ФИО в списке (RPC), деталях и истории (batch SELECT) |
| **Supabase Storage** | приватный bucket **`purchase_requests`**; upload/delete в `createInvoiceWithFile` / `deleteInvoice`; download в `downloadInvoiceFile` (SELECT + `read`). Excel позиций в bucket **не** кладётся |
| **excel** | Клиентская сборка xlsx позиций (`Excel.createExcel`, лист «Позиции») |
| **Notifications** | Таблица + `purchase_request_internal_notify` / `purchase_request_internal_notify_role`; in-app UI отсутствует |
| **Edge Functions** | Не используются (в `supabase/functions/` нет `purchase_request*`) |

---

## Roadmap

### Реализовано 🟢

- Схема БД, RLS, Storage bucket `purchase_requests`
- Полный набор workflow RPC
- Двухпанельный desktop-UI (sidebar + таблица / детали)
- Master-detail в одном экране (без отдельного route)
- Таблица реестра с инициатором и цветными статусами
- Общий бейдж статуса и формат суммы (`formatPurchaseRequestAmount`)
- Многострочное создание заявки с артикулом
- Обновление списка после создания и после workflow **без сброса фильтра/поиска** (`refreshPurchaseRequestList`)
- Открытая заявка не закрывается, если её нет в текущем фильтре
- Единый `PurchaseRequestFilterBar` (mobile chips + desktop sidebar): **На согласовании / Согласованы / Все / Архив**
- Дефолтный фильтр списка — **Все** (`PurchaseRequestListFilter.all`)
- Баннер лимита списка (`kPurchaseRequestListLimit = 50`)
- Кнопка «Отправить на согласование» на этапе `invoice_preparation`
- Секция «Счета»: список, добавление, удаление, прикрепление файла, **просмотр и скачивание**
- Диалог счёта с выбором поставщика и upload PDF/изображения
- Репозиторий: `getInvoices`, `createInvoiceWithFile` (rollback Storage), `deleteInvoice`, `downloadInvoiceFile`
- UI-flow: `purchase_request_invoice_file_flow.dart`; preview — `openAttachmentFilePreview` (также обёртка заявлений сотрудников)
- Domain: `PurchaseRequestInvoice`, `PurchaseRequestFile`; модели в `purchase_request_models.dart`
- Клиентская валидация `purchaseRequestInvoicesReadyForSubmit` + провайдер `purchaseRequestInvoicesProvider`
- Storage RLS: INSERT для `prepare_invoice` (миграция `20260815174000`)
- Guard активной компании для всех write-операций репозитория
- Статус `unknown` + `parseFromDb` (без silent fallback в `draft`); история: null status остаётся null
- Gate «Настройки» через `isCompanyOwnerProvider` / `Profile.isOwner`
- Методы репозитория: `updateHeader`, `deleteDraft`, `updateItem`
- Общие утилиты ФИО (`user_display_utils.dart`)
- Юнит-тесты: `test/features/purchase_requests/purchase_request_logic_test.dart` (**28** `test(`: статусы, ФИО, `resolvePurchaseRequestActions`, invoices, previewable, idle, history, `latestPurchaseRequestCancelComment`, `isPurchaseRequestSettingsConfigured`); `purchase_request_items_excel_export_test.dart` (**3** `test(`)
- Mobile-реестр: шапка без темы/настроек; карточки без превью позиций, увеличенная ширина
- Панель деталей: KPI-сводка, таблица/карточки позиций, **секция счетов**, таймлайн истории, workflow actions, кнопки правки/удаления своего черновика
- Mobile: карточки позиций в форме создания (`_PurchaseItemMobileCard`) и в деталях заявки (`_ItemsMobileList`, ширина &lt; 600 px)
- `invalidatePurchaseRequestCaches` + `idleActionsMessage` + `showPurchaseRequestFormDialog`
- Настройки маршрута (owner), несколько участников на роли, кнопка «Настройки»; desktop-диалог с таймлайном этапов (880 px)
- Матрица прав, drawer, router
- Human-readable ошибки Supabase в списке и диалогах
- Артикул при добавлении позиции из панели деталей
- Выгрузка позиций заявки в Excel на устройство (`purchase_request_items_excel_export.dart`; без Storage; тесты `purchase_request_items_excel_export_test.dart`, 3 `test(`)

### Баги / техдолг 🟡

- Редактирование счёта после создания — только удаление и повторное добавление (нет `updateInvoice` в UI; RLS UPDATE на `invoice_preparation` есть)
- Отдельный блок «Документы» (файлы не типа `invoice`) не в UI
- Уведомления пишутся в БД, но не отображаются
- Нет UI для правки отдельной позиции вне диалога черновика (в `revision` — только «Добавить» / удалить строку)
- Бизнес-логика workflow в presentation, не в domain use cases
- `metadata` истории не маппится в entity и не показывается в таймлайне
- ФИО в деталях/истории — дополнительный round-trip к `profiles`
- Ошибки в `FutureProvider` деталей — сырой текст исключения
- Пагинация: offset/load-more не реализованы (только предупреждение о лимите 50; параметры пагинации убраны из Dart `list()`)
- Orphan в Storage возможен, если DELETE счёта уже прошёл, а `storage.remove` упал
- ~~Часть тестов `resolvePurchaseRequestActions` для этапов согласования не передаёт `settings` (хелпер `request()` всё ещё заполняет `currentAssigneeId`, который UI больше не читает)~~ ✅ Исправлено: поле `currentAssigneeId` удалено из Dart-entity, параметр `assigneeId` убран из builder'а тестов, мёртвые тесты удалены.

### Планы 🔴

1. Редактирование счёта (update полей / замена файла без удаления)
2. Секция «Документы» с Storage (типы кроме `invoice`)
3. Badge / список уведомлений в модуле
4. Domain use cases / перенос `resolvePurchaseRequestActions` из виджета
5. RPC или view для истории с `user_name` (убрать batch на клиенте)
6. Маппинг `metadata` истории в entity и отображение в таймлайне
7. Load-more / offset пагинация списка (потребует расширить `list()` в репозитории)
8. Экспорт **списка** заявок (если потребуется `export` permission; выгрузка **позиций одной заявки** уже есть, без этого права)
9. Cross-link в `docs/database_structure.md`

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

Для модуля **отключены** в матрице (`permissions_matrix.dart`): `export`, `import`, `issue`, `move`, `repair`, `write_off`, `inventory`, `view_cost`, `manage_catalogs`. Коды `update` и `delete` в матрице **отображаются**, но в RPC модуля не используются.

---

*Документ подготовлен по аудиту кода (`lib/features/purchase_requests/`, `lib/core/widgets/attachment_file_preview.dart`, `lib/core/utils/attachment_file_save.dart`), миграций `supabase/migrations/` и live PostgreSQL (`api.progt.ru`, MCP `execute_sql`, 26.08.2026). RLS: все таблицы модуля ✅ кроме `purchase_request_number_seq` ❌. Bucket `purchase_requests` **private**. Edge Functions модуля в `supabase/functions/` нет. Схема БД без изменений (выгрузка Excel — только клиент).*
