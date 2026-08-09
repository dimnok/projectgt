# Модуль Взаиморасчёты (Settlements)

**Дата актуализации:** 9 августа 2026  
**Изменения:**
- **Автосохранение PDF при сохранении счёта:** после «Сохранить» в форме (создание и редактирование) PDF формируется и попадает в «Документы» (без предпросмотра).
- **PDF «Счёт на оплату»:** клиентская генерация из деталей счёта (`Сформировать PDF`); предпросмотр через `PdfPreviewScreen`; данные из счёта, профиля компании, банковского счёта и контрагента.
- **Файлы счетов:** таблица `settlement_files`, bucket `settlement_files` (Storage); прикрепление PDF/сканов в деталях счёта (`SettlementFilesSection`); загрузка/скачивание/удаление; очистка Storage при удалении счёта.
- **Мобильные детали счёта:** `SettlementDetailsDialog` — адаптивная вёрстка в bottom sheet: сводка 2×2, реквизиты столбцом, оплаты карточками (`_PaymentsMobileList`); десктопный диалог и таблица оплат без изменений.
- **Мобильный реестр:** отдельный UI карточками (`SettlementOperationCard`, `SettlementsOperationsMobileView`); поиск в шапке; десктопная таблица и фильтры без изменений.
- Добавлен геттер `invoiceTotal` (`amount + vatAmount`) для отображения суммы счёта на мобильных карточках.
- Оптимизирована синхронизация после CRUD: один вызов `syncSettlementProviders` вместо дублирующих перезагрузок.
- Автономер счёта — RPC `get_next_settlement_invoice_number` (без лимита 500 на клиенте).
- Добавлены `invoice_number_sequence.dart` и тесты нумерации.
- **Рефакторинг (аудит DRY):** устранены дубликаты форматтеров/диалогов между файлами модуля; dead code удалён; явные колонки в выборках оплат; исправлен `BuildContext` после `await`.
  - Общие хелперы вынесены в `core/utils`: `dateOnlyToJson`, `moneyInputFormatters()`, `showAdaptiveModal()`, `pickRuDate()`.
  - Фильтры реестра приведены к стилю модуля «Табель»: `MenuAnchor`, иконки, прокрутка, галочки; тип и оплата объединены в `SettlementsExtraFiltersDropdown`.
  - Удалён неиспользуемый `computeSettlementTotalToPay` (считается в БД GENERATED ALWAYS).

## ⚠️ Важное замечание

- **Owner-таблицы:** `settlement_operations`, `settlement_payments`, `settlement_files`.
- **Изоляция:** `company_id` + RLS (`get_my_company_ids()`, `check_permission(..., 'settlements', ...)`).
- **RBAC:** модуль `settlements` в `app_modules` (`sort_order = 92`).
- `paid_amount` и `payment_status` **не пишутся клиентом** — пересчитываются триггерами из `settlement_payments`.
- **Не путать** с `contract_acts` (акты КС-2) и с начислениями; с **ДДС** связаны только оплаты из выписки (`cash_flow_transaction_id`).

## 📝 Описание

Учёт счетов на оплату по договорам. Одна запись = один счёт. Оплаты — отдельные строки в `settlement_payments`.

**Функции:**
- Типы счёта: акт, аванс, прочее.
- CRUD счетов и ручных оплат; автоподсказка номера счёта по договору.
- НДС: ставка, режим «в сумме» / «сверху».
- Оплаты из банковской выписки (модуль ДДС).
- **Вложения к счёту:** несколько файлов (PDF, DOC/XLS, JPG/PNG) в деталях счёта; Storage bucket `settlement_files`.
- **Формирование PDF счёта на оплату** в приложении (без внешних сервисов): банковский блок, поставщик/покупатель, таблица позиций, итоги, сумма прописью, подписи.
- Реестр компании + вкладка «Финансы» в карточке договора.
- Фильтры и поиск в реестре (клиентская фильтрация загруженного списка).
- **Мобильный реестр:** список карточек с поиском в шапке; расширенные фильтры — только на десктопе (планируется на мобильном).
- **Мобильные детали счёта:** bottom sheet с прокруткой; сводка 2×2, реквизиты столбцом, оплаты карточками; десктоп — диалог с таблицей.

## 🔗 Зависимости

| Роль | Сущности |
|------|----------|
| Owner | `settlement_operations`, `settlement_payments`, `settlement_files` |
| Usage | `contracts`, `contractors`, `objects`, `companies`, `cash_flow` |
| Usage (PDF) | `CompanyProfile`, `CompanyBankAccount` (модуль Company), полные реквизиты `Contractor` |
| Storage | bucket `settlement_files` (приватный) |
| RBAC | `app_modules`, `role_permissions` |
| Не связан | `contract_acts`, Edge `ks2_operations` |

## 🖼️ Presentation

### Экраны и маршруты

| Элемент | Назначение |
|---------|------------|
| `SettlementsListScreen` | Реестр счетов компании; на узком экране — карточки, на широком — таблица в `MobileAtmosphereMainSurface` |
| `/settlements` | Маршрут, право `settlements` / `read` |
| `ContractSettlementsSection` | Вкладка «Финансы» в договоре |

**Адаптивность реестра:** порог — `EmployeesLayoutUtils.useEmployeesMobileList` (`shortestSide < tabletBreakpoint`). Одна логика данных (`settlementListProvider`, `SettlementsListFilters`), разный UI.

| Режим | Шапка | Контент |
|-------|-------|---------|
| Мобильный | Меню · поиск (`SettlementsMobileSearchField`) · «+» (create) · тема | Карточки на фоне `MobileAtmosphereBackdrop`, итоговая панель внизу |
| Десктоп | Заголовок «Взаиморасчёты» | `SettlementsFiltersToolbar` + `SettlementsOperationsTable` |

**Адаптивность деталей счёта:** порог — `ResponsiveUtils.isDesktop` (`width >= desktopBreakpoint`). Показ через `showAdaptiveModal`: десктоп — диалог 960px; мобильный/планшет — bottom sheet.

| Режим | Обёртка | Сводка | Реквизиты | Документы | Оплаты |
|-------|---------|--------|-----------|-----------|--------|
| Мобильный | `MobileBottomSheetContent` | Сетка 2×2 (к оплате / оплачено / остаток / статус) | Подпись сверху, значение снизу | Карточки файлов | Карточки с датой, суммой, примечанием |
| Десктоп | `DesktopDialogContent` | Горизонтальная полоса 4 колонки | Строка: подпись 140px + значение | Список в рамке | Таблица `_PaymentsTable` |

### Виджеты

| Виджет | Назначение |
|--------|------------|
| `SettlementsFiltersToolbar` | Поиск, каскадные фильтры (контрагент / объект / договор), объединённый фильтр тип+оплата, «Сбросить», «Новый» |
| `SettlementsOptionBarDropdown` | Выпадающий фильтр по сущности (стиль `TimesheetObjectsBarDropdown`) |
| `SettlementsExtraFiltersDropdown` | Объединённый фильтр типа операции и статуса оплаты (стиль `TimesheetListFilterDropdown`) |
| `SettlementsToolbarMetrics` | Геометрия панели фильтров (высота 34, радиус 18) |
| `SettlementsOperationsTable` | Таблица счетов (десктоп); `compact` — для вкладки договора |
| `SettlementsOperationsMobileView` | Мобильный список карточек + итоговая панель (к оплате / оплачено / остаток) |
| `SettlementOperationCard` | Карточка счёта: номер, дата, контрагент, объект, тип, сумма (`invoiceTotal`), статус оплаты |
| `SettlementsMobileSearchField` | Компактный поиск в шапке мобильного реестра (`GTTextField`) |
| `SettlementDetailsDialog` | Детали счёта: сводка, реквизиты, документы, оплаты; кнопка **«Сформировать PDF»**; редактирование/удаление |
| `SettlementFilesSection` | Блок «Документы»: список вложений, прикрепить / скачать / удалить |
| `SettlementFormDialog` | Создание/редактирование реквизитов счёта |
| `SettlementPaymentFormDialog` | Ручная оплата по счёту |

### Общие хелперы (core/utils)

Диалоги модуля используют общие утилиты проекта (устранено дублирование между файлами):

| Хелпер | Файл | Назначение |
|--------|------|------------|
| `showAdaptiveModal<T>(context, builder)` | `core/utils/adaptive_dialog.dart` | `Dialog` на десктопе / `showModalBottomSheet` на мобильном. Название намеренно отличается от Flutter `showAdaptiveDialog` |
| `pickRuDate(context, initialDate)` | `core/utils/adaptive_dialog.dart` | Единый `DatePicker` (диапазон 2020–2100) |
| `moneyInputFormatters()` | `core/utils/formatters.dart` | Готовый список форматтеров для ввода сумм |
| `dateOnlyToJson(DateTime?)` | `core/utils/formatters.dart` | Сериализация дат в `yyyy-MM-dd` для JSON-моделей Supabase |
| `formatAmount(num)` | `core/utils/formatters.dart` | Форматирование сумм (замена локальных `_fmtAmount`) |
| `formatPhoneRu(String?)` | `core/utils/formatters.dart` | Телефон для документов: `+7 (495) 120-28-66` |
| `moneyToWordsRu(double)` | `core/utils/money_to_words_ru.dart` | Сумма прописью для PDF счёта |
| `moneyNumericWithUnitsRu(double)` | `core/utils/money_to_words_ru.dart` | Числовая сумма с «рубля / копейки» |
| `saveFileBytesToUserDevice(...)` | `core/utils/attachment_file_save.dart` | Сохранение скачанного файла на устройство |

### Файлы счёта (upload / download)

| Хелпер | Файл | Назначение |
|--------|------|------------|
| `openSettlementFileUploadFlow(...)` | `settlement_file_upload_flow.dart` | Выбор файла, диалог имени/описания, загрузка в Storage |
| `downloadSettlementFileForUser(...)` | `settlement_file_download_flow.dart` | Скачивание из Storage + сохранение пользователю |

Форматы: `pdf`, `doc`, `docx`, `xls`, `xlsx`, `jpg`, `jpeg`, `png`.  
Прикрепление — только после создания счёта (нужен `operation.id`). Права: просмотр/скачивание — `read`; загрузка/удаление — `update`.

### PDF «Счёт на оплату» (генерация на клиенте)

| Компонент | Файл | Назначение |
|-----------|------|------------|
| `openSettlementInvoicePdfPreview(...)` | `settlement_invoice_generate_flow.dart` | Загрузка данных, валидация, автосохранение, переход на предпросмотр |
| `validateSettlementInvoicePdfData(...)` | `settlement_invoice_generate_flow.dart` | Проверка реквизитов компании, банка, контрагента |
| `generateAndPersistSettlementInvoicePdfOnSave(...)` | `settlement_invoice_generate_flow.dart` | PDF при сохранении счёта (создание и редактирование) |
| `prepareSettlementInvoicePdfBytes(...)` | `settlement_invoice_generate_flow.dart` | Загрузка реквизитов и сборка байтов PDF |
| `persistSettlementInvoicePdfIfAllowed(...)` | `settlement_invoice_generate_flow.dart` | Сохранение в Storage при праве `update` |
| `persistGeneratedInvoicePdfToStorage(...)` | `settlement_invoice_pdf_persist.dart` | Сохранение через репозиторий (без autoDispose-notifier) |
| `persistSettlementInvoicePdf(...)` | `settlement_invoice_pdf_persist.dart` | Сохранение + `invalidate` списка документов |
| `buildSettlementInvoicePdfFileName(...)` | `settlement_invoice_pdf_persist.dart` | Имя файла `Счёт на оплату № {номер} от {дата}.pdf` |
| `kSettlementInvoicePdfDescription` | `settlement_invoice_pdf_persist.dart` | Маркер автосгенерированного PDF для перезаписи |
| `SettlementInvoicePdfData` | `services/settlement_invoice_pdf_data.dart` | DTO: операция + компания + банк + контрагент; тексты позиции и назначения платежа |
| `SettlementInvoicePdfService.build(...)` | `services/settlement_invoice_pdf_service.dart` | Сборка PDF (`pdf` + шрифты Inter из assets) |
| `PdfPreviewScreen` | `features/profile/.../pdf_preview_screen.dart` | Предпросмотр, печать, сохранение файла |

**Точки входа:** «Сохранить» в `SettlementFormDialog` (создание и редактирование); «Сформировать PDF» в `SettlementDetailsDialog` (`read`).

**Сценарий (сохранение формы):** «Сохранить» → запись в БД → генерация PDF → автосохранение в «Документы» (при `update`).

**Сценарий (вручную):** валидация реквизитов → генерация PDF → автосохранение → предпросмотр (`PdfPreviewScreen`).

**Автосохранение:**
- Имя файла: `Счёт на оплату № {номер} от {дата}.pdf` (дата `dd.MM.yyyy`).
- Описание в БД: `Счёт на оплату (сформирован автоматически)` (`kSettlementInvoicePdfDescription`).
- Повторное формирование: удаляется предыдущий файл с тем же описанием, загружается новый (одна актуальная версия; ручные вложения не затрагиваются).
- Список в `SettlementFilesSection` обновляется через `settlementFilesProvider` без перезагрузки экрана.
- Без права `update`: только предпросмотр, без записи в Storage.

**Источники данных:**

| Блок PDF | Источник |
|----------|----------|
| Банк, ИНН/КПП, получатель | `companyProfileProvider`, `companyBankAccountsProvider` (основной или первый счёт) |
| Покупатель | `getContractorUseCase` по `contractorId` |
| Суммы, НДС, номер, дата | `SettlementOperation` |
| Наименование в таблице | `note`, иначе стандарт по типу (`act` / `advance` / `other`) |
| Назначение платежа (банк. блок) | `Оплата по счету № … от …` + НДС при наличии |

**Структура PDF:** банковская таблица + назначение платежа → заголовок → поставщик/покупатель (с тел./e-mail при наличии) → основание → таблица (без колонки НДС) → итоги справа → нижний блок (наименования, сумма прописью, НДС прописью) → подписи руководителя и бухгалтера столбцом.

**Ограничения:** одна строка в таблице позиций; удержания отображаются в итогах, если заданы в БД.

### Провайдеры

| Provider | Назначение |
|----------|------------|
| `settlementRepositoryProvider` | DI репозитория |
| `settlementListProvider` | Все счета компании |
| `contractSettlementsProvider(contractId)` | Счета по договору |
| `settlementPaymentsProvider(operationId)` | Оплаты по счёту (autoDispose) |
| `settlementFileRepositoryProvider` | DI репозитория файлов |
| `settlementFilesProvider(operationId)` | Файлы по счёту (autoDispose) |
| `settlementFileDownloadingIdsProvider(operationId)` | Индикация скачивания |

### Синхронизация состояния

После CRUD счёта или оплаты:

1. **Notifier** сразу обновляет локальный список (`_upsertOperation` / `_removeOperation` / локальные оплаты).
2. **`await syncSettlementProviders(ref, contractId: ...)`** — единственная полная перезагрузка: общий реестр + список по договору (параллельно, `quiet: true`).
3. **`findSettlementOperationInProviders`** — обновление деталей счёта из провайдеров без лишнего `getOperation`.

Вызывается из: `SettlementFormDialog`, `SettlementDetailsDialog`, `CashFlowFormDialog` (при привязке к счёту).

### Фильтры реестра

Клиентская фильтрация `SettlementsListFilters.apply()` по данным `settlementListProvider`.

| Фильтр | Поле |
|--------|------|
| Поиск | номер счёта, акт, договор, контрагент, объект |
| Контрагент / Объект / Договор | каскадная связь |
| Тип / Оплата | enum; объединены в одну кнопку «Фильтры» |

Опции выпадающих списков — `SettlementsFilterOptionsBuilder` из загруженных операций.  
UI фильтров — `MenuAnchor` (как в модуле «Табель»): иконки, заголовки секций, галочки, прокрутка длинных списков.

## ⚙️ Domain / Data

### Сущности

- `SettlementOperation` — счёт; `SettlementPayment` — оплата; `SettlementFile` — вложение.
- `SettlementOperationType`: `act` \| `advance` \| `other`.
- `SettlementPaymentStatus`: `unpaid` \| `partial` \| `paid` \| `overpaid`.
- Статус в UI: только `resolvedPaymentStatus` → `computeSettlementPaymentStatus` (eps = 0.005).
- `invoiceTotal` — сумма счёта (база + НДС, без удержаний); на мобильных карточках.
- `SettlementOperationsTotals` — итоги по списку (`totalAmount` = Σ `total_to_pay`, `totalPaid`, `totalDebt`).

### Утилиты

| Файл | Назначение |
|------|------------|
| `invoice_number_sequence.dart` | Парсинг и расчёт следующего номера (зеркало SQL RPC) |
| `settlement_actions.dart` | `syncSettlementProviders`, `findSettlementOperationInProviders`, диалог удаления |
| `settlement_ui_labels.dart` | Подписи и цвета статусов |
| `settlement_invoice_generate_flow.dart` | Сценарий формирования PDF счёта |
| `settlement_invoice_pdf_persist.dart` | Автосохранение PDF в `settlement_files` |
| `settlements_list_filters.dart` | Состояние и логика фильтров |
| `settlements_filter_options.dart` | Опции фильтров из операций |

### Сервисы PDF

| Файл | Назначение |
|------|------------|
| `settlement_invoice_pdf_data.dart` | DTO и бизнес-тексты для шаблона счёта |
| `settlement_invoice_pdf_service.dart` | Вёрстка PDF (A4, `pw.Table`, `pw.MultiPage`) |

### Репозиторий (`SettlementRepositoryImpl`)

**Счета** — select с join `objects`, `contractors`, `contracts`:

| Метод | Описание |
|-------|----------|
| `getOperations({contractId})` | Список; фильтр по договору опционален |
| `getOperation(id)` | Одна операция |
| `createOperation` / `updateOperation` / `deleteOperation` | CRUD |
| `getNextInvoiceNumber(contractId)` | RPC `get_next_settlement_invoice_number` |

**Оплаты** — select с явным перечислением колонок `_paymentSelect` (без `select()` «всё»):

| Метод | Описание |
|-------|----------|
| `getPayments` / `createPayment` / `updatePayment` / `deletePayment` | CRUD оплат |

`toWriteJson` счёта исключает: `total_to_pay`, `payment_status`, `paid_amount`, `created_at`, `created_by`.  
`toUpdateJson` оплаты — только `payment_date`, `amount`, `note`.  
`cash_flow_transaction_id` не пишется клиентом.  
Сериализация дат (`period_from`, `period_to`, `act_date`, `invoice_date`, `payment_date`) — через общий `dateOnlyToJson` из `core/utils/formatters.dart`.

### Репозиторий файлов (`SettlementFileRepositoryImpl`)

| Метод | Описание |
|-------|----------|
| `getFiles(operationId)` | Список вложений по счёту |
| `uploadFile(...)` | Upload в Storage + insert в `settlement_files` |
| `deleteFile(fileId, filePath)` | Удаление метаданных и объекта Storage |
| `deleteAllForOperation(operationId)` | Удаление всех вложений счёта (перед удалением счёта) |
| `downloadFile(filePath)` | Байты из Storage |

Путь в Storage: `{company_id}/{operation_id}/{timestamp}_{safe_name}`.  
Оригинальное имя (кириллица) — в колонке `name`; в пути — ASCII-safe.

## 📂 Дерево файлов

```
lib/features/settlements/
├── domain/
│   ├── entities/
│   │   ├── settlement_operation.dart
│   │   ├── settlement_payment.dart
│   │   └── settlement_file.dart
│   ├── repositories/
│   │   ├── settlement_repository.dart
│   │   └── settlement_file_repository.dart
│   └── utils/invoice_number_sequence.dart
├── data/
│   ├── datasources/settlement_file_data_source.dart
│   ├── models/
│   │   ├── settlement_operation_model.dart
│   │   ├── settlement_payment_model.dart
│   │   └── settlement_file_model.dart
│   └── repositories/
│       ├── settlement_repository_impl.dart
│       └── settlement_file_repository_impl.dart
└── presentation/
    ├── screens/settlements_list_screen.dart
    ├── services/
    │   ├── settlement_invoice_pdf_data.dart
    │   └── settlement_invoice_pdf_service.dart
    ├── state/
    │   ├── settlement_state.dart
    │   └── settlement_files_state.dart
    ├── utils/
    │   ├── settlement_actions.dart
    │   ├── settlement_file_download_flow.dart
    │   ├── settlement_file_upload_flow.dart
    │   ├── settlement_invoice_generate_flow.dart
    │   ├── settlement_invoice_pdf_persist.dart
    │   ├── settlement_ui_labels.dart
    │   ├── settlements_filter_options.dart
    │   └── settlements_list_filters.dart
    └── widgets/
        ├── contract_settlements_section.dart
        ├── settlement_details_dialog.dart
        ├── settlement_files_section.dart
        ├── settlement_form_dialog.dart
        ├── settlement_payment_form_dialog.dart
        ├── settlements_extra_filters_dropdown.dart
        ├── settlements_filters_toolbar.dart
        ├── settlements_mobile_search_field.dart
        ├── settlement_operation_card.dart
        ├── settlements_operations_mobile_view.dart
        ├── settlements_option_bar_dropdown.dart
        ├── settlements_operations_table.dart
        └── settlements_toolbar_metrics.dart

test/features/settlements/
├── compute_settlement_payment_status_test.dart
└── invoice_number_sequence_test.dart
```

## 🗄️ База данных (Audit)

**RLS:** ✅ на `settlement_operations`, `settlement_payments` и `settlement_files`.

### `settlement_files`

| Колонка | Тип | Примечание |
|---------|-----|------------|
| `id` | UUID | PK |
| `company_id` | UUID | FK → `companies` |
| `settlement_operation_id` | UUID | FK → `settlement_operations`, ON DELETE CASCADE |
| `name` | TEXT | Отображаемое имя |
| `file_path` | TEXT | Путь в bucket `settlement_files` |
| `size` | BIGINT | Размер в байтах |
| `type` | TEXT | MIME-тип |
| `description` | TEXT | Необязательное описание |
| `created_at` | TIMESTAMPTZ | |
| `created_by` | UUID | FK → `auth.users` |

**Индексы:** `(settlement_operation_id, created_at DESC)`, `(company_id)`.

**Storage:** приватный bucket `settlement_files`; путь `{company_id}/{operation_id}/{timestamp}_{safe_name}`; RLS по `company_id` + `check_permission(..., 'settlements', ...)`.

### `settlement_operations`

| Колонка | Тип | Примечание |
|---------|-----|------------|
| `id` | UUID | PK |
| `company_id` | UUID | FK → `companies` |
| `operation_type` | TEXT | `act` \| `advance` \| `other` |
| `object_id`, `contractor_id`, `contract_id` | UUID | FK |
| `invoice_number`, `invoice_date` | TEXT, DATE | Номер и дата счёта |
| `act_number` | TEXT | Обязателен для `act` |
| `amount`, `vat_amount` | NUMERIC | База и НДС |
| `is_vat_included`, `vat_rate` | BOOL, NUMERIC | Режим НДС |
| `advance_retention`, `warranty_retention` | NUMERIC | Удержания (в UI не редактируются) |
| `total_to_pay` | NUMERIC | GENERATED STORED |
| `paid_amount`, `payment_status` | NUMERIC, TEXT | Триггеры из оплат |
| `period_from/to`, `act_date`, `purpose` | — | В UI не редактируются |
| `note` | TEXT | Примечание |

**Индексы:** `(company_id)`, `(contract_id, invoice_date DESC)`, `(company_id, payment_status)`, `(company_id, operation_type)`.

### `settlement_payments`

| Колонка | Тип | Примечание |
|---------|-----|------------|
| `settlement_operation_id` | UUID | FK, ON DELETE CASCADE |
| `payment_date`, `amount` | DATE, NUMERIC | amount > 0 |
| `cash_flow_transaction_id` | UUID | FK → `cash_flow`, UNIQUE (partial) |
| `note` | TEXT | |

**Индексы:** `(settlement_operation_id, payment_date DESC)`, `(company_id)`, UNIQUE `(cash_flow_transaction_id)` WHERE NOT NULL.

### Триггеры

| Триггер | Назначение |
|---------|------------|
| `trg_settlement_payments_sync_paid` | `paid_amount` из суммы оплат |
| `trg_settlement_payment_status` | `payment_status` по суммам |
| `trg_guard_linked_settlement_payment` | Защита оплат из выписки от ручного UPDATE/DELETE |
| `trg_settlement_*_updated_at` | `updated_at` |

### Функции

| Функция | Назначение |
|---------|------------|
| `get_next_settlement_invoice_number(company_id, contract_id)` | Подсказка следующего номера: max завершающей цифровой группы + 1 |
| `process_bank_statement_entry` | Создание ДДС + оплаты (параметр `p_settlement_operation_id`) |

### RLS-права

| Таблица | SELECT | INSERT | UPDATE | DELETE |
|---------|--------|--------|--------|--------|
| `settlement_operations` | read | create | update | delete |
| `settlement_payments` | read | update | update | update |
| `settlement_files` | read | update | — | update |

### Edge Functions

Нет.

## 🧠 Бизнес-логика

### Формулы

```
total_to_pay = max(0, amount + vat_amount - advance_retention - warranty_retention)
```

Статус оплаты — `computeSettlementPaymentStatus(total_to_pay, paid_amount)`; в БД дублируется триггером `sync_settlement_payment_status`.

### Автономер счёта

Алгоритм (Dart `computeNextInvoiceNumber` = SQL RPC):

1. Scope: `(company_id, contract_id)`.
2. Из каждого `invoice_number` берётся последняя группа цифр (`(\d+)\s*$`).
3. Выбирается **максимальное** число; префикс — из строки-победителя.
4. Результат: `prefix + (max + 1)` (без дополнения нулями).

Примеры: `сч-13` → `сч-14`; при `сч-13` и `217-20` → `217-21`.

**Ограничение:** подсказка, не резервирование. Параллельное создание с одним номером возможно (UNIQUE на `invoice_number` нет).

### Сценарии

1. **Новый счёт** → форма → `syncSettlementProviders`.
2. **Детали** → тап по строке/карточке; при открытии — `getOperation` + загрузка оплат; UI адаптируется под ширину экрана.
3. **Оплата** → вручную в деталях или из выписки ДДС.
4. **Документы** → в деталях счёта: прикрепить / скачать / удалить файл.
5. **PDF счёта** → «Сохранить» в форме (создание/редактирование) или «Сформировать PDF» в деталях → автосохранение в «Документы»; в деталях дополнительно — предпросмотр.
6. **Удаление счёта** → только из деталей; каскадно удаляет оплаты; файлы удаляются из Storage через `deleteAllForOperation` до удаления счёта.

### Оплаты из выписки (ДДС)

- Создание: `CashFlowFormDialog` → RPC `process_bank_statement_entry`.
- В UI: пометка «Из выписки», edit/delete заблокированы.
- Удаление транзакции ДДС → CASCADE оплаты → пересчёт `paid_amount`.

## 🔌 Интеграции

| Модуль | Связь |
|--------|-------|
| Договоры | FK, вкладка «Финансы», наследование НДС |
| Компания | Реквизиты и банковский счёт для PDF |
| Контрагенты | Полные реквизиты покупателя для PDF |
| Профиль (UI) | `PdfPreviewScreen` для предпросмотра PDF |
| ДДС | `cash_flow_transaction_id`, RPC при обработке выписки |
| Storage | bucket `settlement_files` для вложений счетов |
| Роли | `settlements` в матрице прав |
| Акты КС-2 | Нет связи |

## 🗺 Roadmap

### Реализовано

- CRUD счетов и оплат, RLS, RBAC
- Реестр, фильтры, вкладка «Финансы»
- **Мобильный реестр:** карточки, поиск в шапке, итоги внизу экрана
- **Мобильные детали счёта:** bottom sheet, сводка 2×2, реквизиты столбцом, оплаты карточками
- **Файлы счетов:** `settlement_files` + Storage, UI в деталях счёта
- **PDF счёта на оплату:** клиентская генерация, автосохранение в документы, предпросмотр, печать/сохранение
- Статусы оплаты (Dart + SQL)
- Интеграция с ДДС
- Оптимизированная синхронизация провайдеров
- RPC автономера счёта
- Тесты: статус оплаты, нумерация
- Рефакторинг DRY: общие хелперы в `core/utils`, унифицированный chip-фильтр, явные колонки в выборках оплат, удалён dead code (`computeSettlementTotalToPay`), исправлен `BuildContext` после `await`

### Планы

- 🟡 Мобильные фильтры реестра (контрагент, объект, тип, статус)
- 🟡 Серверные фильтры и пагинация реестра (эталон — Cash Flow)
- 🟡 UNIQUE на `(company_id, contract_id, invoice_number)` + обработка конфликта
- 🟡 UI для удержаний, периода, назначения
- 🟢 Иконка «есть вложения» в реестре счетов

### Известные ограничения

- Файлы прикрепляются только после создания счёта (нужен `id` операции).
- Для PDF обязательны: ИНН и название компании, банковский счёт, ИНН и название контрагента.
- Реестр загружает все счета компании; фильтрация на клиенте; лимит PostgREST ~1000 строк.
- Дубликаты номеров счёта при одновременном создании не блокируются.
- `contract_acts.payment_status` не связан с Settlements.
- Итог «Остаток» в таблице — сумма положительных долгов (`totalDebt`).
