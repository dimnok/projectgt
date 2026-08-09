# Модуль Cash Flow (ДДС)

**Дата последнего обновления:** 9 августа 2026 года  
**Список изменений:**
- **Автосопоставление и пакетная обработка выписки:** правила по ключевым словам (`cash_flow_category_rules`), сервис `BankStatementMatchingService`, координатор `BankStatementAutoProcessService`, RPC `get_bank_statement_matching_context` и `batch_process_bank_statement_entries`. Кнопка «Обработать готовые (N)» в `BankStatementView`. Индикаторы уверенности в `BankStatementTable` (high / medium / low).
- **Режим «только статья»:** поле `requires_contract_binding` в правилах. Для налогов и прочих общих платежей операция может автоматически переноситься в реестр без договора, объекта и контрагента. UI: чекбокс в `CategoryRulesPanel`.
- **Настройки выписки:** `BankStatementSettingsDialog` — две вкладки: «Шаблоны Excel» и «Правила автосопоставления».
- **Аналитика по месяцам:** исправлена сортировка колонок в таблице «Аналитика по месяцам». Группировка и порядок месяцев выполняются по числовому ключу `year * 100 + month` в `getYearlyAnalytics`, без повторного парсинга локализованных строк (`янв. 2026`, `мая 2026`). Устранён баг, при котором месяцы отображались вперемешку из-за неудачного `parseDate` без локали `ru_RU`.
- **Поиск в банковских выписках:** реализован клиентский поиск по ИНН контрагента и сумме платежа. Добавлены `bankStatementSearchQuery`, `setBankStatementSearchQuery`, геттер `filteredBankStatementEntries` в `CashFlowState`. Поиск в выписках изолирован от поиска по реестру транзакций (`searchQuery`).
- **Интеграция с Взаиморасчётами:** при обработке выписки можно привязать платёж к счёту (`p_settlement_operation_id` в RPC); создаётся `settlement_payment` с `cash_flow_transaction_id`.
- **CashFlowFormDialog:** поле «Счёт взаиморасчётов» (неоплаченные счета по выбранному договору; `PermissionGuard` `settlements` / `update`).
- **Global On Focus Refresh:** Внедрена система автоматического обновления данных при возврате в фокус (TTL 5 минут).
- **Quiet Background Refresh:** В `CashFlowNotifier` реализован режим `quiet: true`, позволяющий обновлять данные без отображения полноэкранного спиннера загрузки (индикация через AppBar).
- **Bank Statement Deletion:** реализовано физическое удаление записей из буферной таблицы банковских выписок. Добавлен метод `deleteBankStatementEntry` в репозиторий и notifier, реализовано подтверждение удаления через диалоговое окно.
- **DaData Integration:** в форму создания контрагента интегрирован сервис DaData. При создании контрагента из выписки по ИНН автоматически подтягиваются все реквизиты (КПП, ОГРН, Юр. адрес, ФИО директора, описание деятельности).
- **Smart Matching & Quick Create:** реализовано автоматическое сопоставление контрагентов по ИНН при обработке банковских выписок. Добавлена возможность создания нового контрагента в один клик прямо из формы обработки с предзаполнением данных из файла.
- **Контекстная фильтрация (Option B):** реализовано динамическое получение доступных ID (объекты, контрагенты, договоры) из БД на основе выбранного года. Теперь в фильтрах отображаются только те сущности, по которым есть реальные транзакции в текущем периоде.
- Реализован импорт банковских выписок (Excel) через Supabase Edge Function.
- Добавлена буферная таблица `bank_statement_entries` для хранения распарсенных данных.
- Добавлен интерфейс настроек шаблонов импорта с поддержкой раздельных колонок Дебет/Кредит.
- Интегрирована валидация и автоматическое определение типа операции (income/expense) на сервере.
- **Архитектурная оптимизация:** вынос логики координации импорта в `BankImportService` (слой application).
- **Система защиты от дублей:** внедрен `operation_hash` (SHA-256) для каждой строки выписки.
- **Strict Account Validation:** добавлена серверная проверка ИНН и номера счета из заголовка файла.
- **UI & Design System:** внедрен общий виджет `GTSectionTitle`, устранены дубликаты заголовков в таблицах.
- **Унификация UI (Context Menus):** реализован глобальный виджет `GTContextMenu` в core. Все таблицы модуля переведены на единый стиль контекстных меню (скругления 20px, тени, анимации).
- **Очистка кода:** удален неиспользуемый метод `watchTransactions` из репозитория, исправлен парсинг дат через `GtFormatters`.
- **Функционал «Обработать»:** реализован перенос записей из выписки в реестр Cash Flow через атомарную RPC-функцию. Доступ к действию теперь осуществляется строго через контекстное меню.
- **Авто-возврат в выписки:** добавлен триггер БД `tr_on_cash_flow_transaction_deleted`, который автоматически возвращает запись в статус "не обработана" при удалении связанной транзакции из реестра.

---

## 📌 Важное замечание
Модуль является центральным узлом финансового учета. Владеет таблицами транзакций, категорий и правил автосопоставления. Все операции строго изолированы по `company_id` (Multi-tenancy). Импорт выписок: **Client → Edge Function → Staging Table → Client**. Автосопоставление: **Client (matching) → RPC batch → реестр ДДС**. Подключен к глобальному координатору обновления данных.

---

## 📖 Описание
Модуль Cash Flow предназначен для учета движения денежных средств (ДДС). Он позволяет:
- Вести реестр приходов и расходов.
- **Global On Focus Refresh:** автоматически обновлять реестр и аналитику при возврате в приложение (TTL 5 мин).
- Классифицировать операции по статьям ДДС (категориям).
- Привязывать транзакции к объектам строительства, договорам и контрагентам (опционально — только статья, без договора).
- Формировать аналитику по месяцам и статьям.
- **Импортировать банковские выписки** для автоматизации ввода данных.
- **Автосопоставлять** строки выписки с контрагентом, статьей, договором и счётом взаиморасчётов.
- **Пакетно обрабатывать** строки с высокой уверенностью сопоставления одной кнопкой.
- **Искать записи в выписках** по ИНН контрагента или сумме платежа (клиентская фильтрация без перезагрузки).
- **Привязывать платежи из выписки к счетам взаиморасчётов** (опционально, в одном шаге с созданием транзакции ДДС).

---

## 🔗 Зависимости

### Таблицы модуля (Owner)
- `public.cash_flow`: хранит все финансовые транзакции.
- `public.cash_flow_categories`: справочник статей движения ДС.
- `public.bank_import_templates`: шаблоны маппинга колонок Excel для разных банков.
- `public.bank_statement_entries`: буферная таблица для хранения спарсенных данных выписки до их окончательного импорта в систему.
- `public.cash_flow_category_rules`: правила автосопоставления статей ДДС по ключевым словам в назначении платежа.

### Использование внешних таблиц (Usage)
- `public.companies`: привязка к компании (Multi-tenancy).
- `public.objects`: привязка транзакции к объекту.
- `public.contracts`: привязка транзакции к договору.
- `public.contractors`: привязка транзакции к контрагенту.
- `public.company_bank_accounts`: выбор расчетного счета для импорта выписки.
- `public.profiles`: авторство записей.
- `public.settlement_operations` / `public.settlement_payments`: опциональная привязка оплаты при обработке выписки (Usage, не Owner).
- `Infrastructure`: `AppFocusRefreshCoordinator` для автоматического обновления.

---

## 🖼️ Слой Presentation

### Экраны и View
- `CashFlowListScreen`: Основной экран модуля. Точка регистрации `RefreshTarget` ('cash_flow').
- `CashFlowListDesktopView`: Десктопная Master-Detail компоновка. Левая панель — поиск, фильтры (реестр) или список счетов (выписки). Правая панель — детали.
- `CashFlowDetailsPanel`: Правая панель реестра транзакций (таблица + аналитика).
- `BankStatementView`: Экран обработки банковской выписки (загрузка файла, автосопоставление, пакетная обработка, таблица записей).

### Виджеты
- `AppBarWidget`: Отображает индикатор фонового обновления при работе координатора.
- `CashFlowTransactionsTable`: Таблица транзакций. Поддерживает контекстное меню (Редактировать/Удалить) через `GTContextMenu`.
- `BankStatementTable`: Таблица предпросмотра выписки. Индикаторы автосопоставления (зелёный / оранжевый / серый). Контекстное меню (Обработать/Удалить).
- `BankStatementSettingsDialog`: Диалог настроек с вкладками «Шаблоны Excel» и «Правила автосопоставления».
- `CategoryRulesPanel`: CRUD правил ключевое слово → статья ДДС, чекбокс «Только статья (без договора)».
- `CashFlowFormDialog`: Форма создания/редактирования транзакции. При импорте из выписки (`initialEntry`) — дополнительное поле **«Счёт взаиморасчётов»** (после «Договор»).
- `CashFlowCategoriesDialog`: Управление справочником статей ДДС.
- `GTSectionTitle`: Общий виджет заголовка раздела (Design System).
- `GTContextMenu`: Глобальный виджет контекстного меню (Core).

### Провайдеры и Состояние
- `cashFlowProvider` (`CashFlowNotifier`): Центральный стейт-менеджер. Делегирует импорт `BankImportService`, автосопоставление `BankStatementAutoProcessService`. Поддерживает `loadAllData(quiet: true)`.
- `bankStatementAutoProcessServiceProvider`: Провайдер координатора автосопоставления и пакетной обработки.
- `CashFlowState`: Freezed-класс состояния.
  - `searchQuery` — поиск по реестру (серверный, `cash_flow_search_text`).
  - `bankStatementSearchQuery` — поиск по выписке (клиентский).
  - `filteredBankStatementEntries` — отфильтрованные строки выписки.
  - `categoryRules` — правила автосопоставления.
  - `bankStatementMatches` — результаты автосопоставления (`Map<entryId, BankStatementMatchResult>`).
  - `autoProcessableBankStatementCount` — число строк готовых к пакетной обработке.
- `computeBankStatementMatches(...)` — пересчёт автосопоставления (контрагенты и договоры с клиента).
- `batchProcessReadyBankStatementEntries(...)` — пакетный перенос «зелёных» строк в реестр.
- `saveCategoryRule` / `deleteCategoryRule` — CRUD правил.

---

## 🏗️ Слой Domain/Data

### Сущности (Domain)
- `CashFlowTransaction`: Финансовая операция.
- `CashFlowCategory`: Статья ДДС.
- `CashFlowCategoryRule`: Правило автосопоставления (ключевое слово → статья).
- `BankImportTemplate`: Шаблон импорта для конкретного банка.
- `BankStatementEntry`: Запись распарсенной выписки.
- `BankStatementMatchResult`: Результат автосопоставления одной строки (confidence, поля, причины).
- `BankStatementMatchingContext`: Контекст из RPC (история по контрагентам, открытые счета взаиморасчётов).
- `AvailableFilters`: Доступные ID для контекстной фильтрации.
- `MonthlyAnalytics`: Агрегированные данные аналитики по месяцам.

### Use Cases / Services
- `BankImportService` (Application): Координация импорта (дедупликация, парсер).
- `BankStatementAutoProcessService` (Application): Координация автосопоставления и пакетной обработки.
- `BankStatementMatchingService` (Domain): Чистая логика сопоставления строки выписки.
- `BankStatementParser` (Domain): Прокси вызова Edge Function `bank_parse`.

### Репозитории (Data)
- `ICashFlowRepository` / `CashFlowRepository`: Supabase. Методы `getCategoryRules`, `saveCategoryRule`, `deleteCategoryRule`, `getMatchingContext`, `batchProcessBankStatementEntries`, `processBankStatementEntry`, `getYearlyAnalytics` (сортировка по `year * 100 + month`).

---

## 📂 Дерево файлов
```text
lib/features/cash_flow/
├── application/
│   ├── bank_import_service.dart
│   └── bank_statement_auto_process_service.dart
├── data/
│   ├── models/
│   │   ├── bank_import_template_model.dart
│   │   ├── bank_statement_entry_model.dart
│   │   ├── cash_flow_category_model.dart
│   │   ├── cash_flow_category_rule_model.dart
│   │   └── cash_flow_transaction_model.dart
│   └── repositories/
│       └── cash_flow_repository.dart
├── domain/
│   ├── entities/
│   │   ├── available_filters.dart
│   │   ├── bank_import_template.dart
│   │   ├── bank_statement_entry.dart
│   │   ├── bank_statement_match_result.dart
│   │   ├── bank_statement_matching_context.dart
│   │   ├── cash_flow_category.dart
│   │   ├── cash_flow_category_rule.dart
│   │   ├── cash_flow_transaction.dart
│   │   └── monthly_analytics.dart
│   ├── repositories/
│   │   └── cash_flow_repository_interface.dart
│   └── services/
│       ├── bank_statement_matching_service.dart
│       └── bank_statement_parser.dart
└── presentation/
    ├── screens/
    │   ├── cash_flow_list_screen.dart
    │   └── desktop/
    │       ├── bank_statement_view.dart
    │       └── cash_flow_list_desktop_view.dart
    ├── state/
    │   └── cash_flow_state.dart
    └── widgets/
        ├── bank_statement_settings_dialog.dart
        ├── bank_statement_table.dart
        ├── category_rules_panel.dart
        ├── cash_flow_categories_dialog.dart
        ├── cash_flow_details_panel.dart
        ├── cash_flow_form_dialog.dart
        └── cash_flow_transactions_table.dart

supabase/migrations/ (релевантные):
├── 20260805160000_link_settlement_payments_to_cash_flow.sql
├── 20260805170000_fix_settlement_bank_payment_security.sql
├── 20260809170000_cash_flow_category_rules_and_batch.sql
└── 20260809180000_category_rule_contract_optional.sql
```

---

## 🗄️ База данных (Audit)

### Таблица `bank_statement_entries` (Staging)
| Колонка | Тип | Описание |
| :--- | :--- | :--- |
| id | uuid | PK |
| company_id | uuid | FK → companies |
| bank_account_id | uuid | FK → company_bank_accounts |
| date | date | Дата операции из выписки |
| amount | numeric | Сумма (абсолютное значение) |
| type | text | Тип (income/expense) |
| contractor_name | text | Название контрагента из файла |
| contractor_inn | text | ИНН контрагента из файла |
| comment | text | Назначение платежа |
| transaction_number | text | Номер документа в банке |
| is_imported | boolean | Флаг (true, если транзакция создана) |
| linked_transaction_id | uuid | Ссылка на итоговую запись в cash_flow |
| operation_hash | text | Уникальный хеш для дедупликации |
| created_at | timestamptz | Дата создания записи в буфере |

**RLS:** ✅ Включён. Изоляция через `company_id IN (get_my_company_ids())`.

### Таблица `cash_flow_category_rules`
| Колонка | Тип | Описание |
| :--- | :--- | :--- |
| id | uuid | PK |
| company_id | uuid | FK → companies |
| category_id | uuid | FK → cash_flow_categories |
| keyword | text | Ключевое слово (поиск в назначении платежа, без учёта регистра) |
| operation_type | text | income / expense |
| priority | integer | Приоритет правила (выше — проверяется раньше) |
| requires_contract_binding | boolean | `true` — нужны договор и объект; `false` — только статья (налоги и т.п.) |
| created_at | timestamptz | Дата создания |

**Уникальный индекс:** `(company_id, operation_type, lower(trim(keyword)))`.  
**RLS:** ✅ Включён. Политики SELECT/INSERT/UPDATE/DELETE через `get_my_company_ids()`.

### Таблица `bank_import_templates`
| Колонка | Тип | Описание |
| :--- | :--- | :--- |
| bank_name | text | Название (уникально для компании) |
| column_mapping | jsonb | Маппинг (date, amount, amount_debit, amount_credit, …) |
| start_row | integer | С какой строки начинаются данные (1-based) |
| date_format | text | Формат даты (например, dd.MM.yyyy) |

**RLS:** ✅ Включён.

### Функции и Триггеры
- `get_cash_flow_available_filters(p_company_id, p_start_date, p_end_date)`: RPC списков уникальных ID за период.
- `get_bank_statement_matching_context(p_company_id)`: JSON с `contractor_hints` (последняя операция по каждому контрагенту) и `open_settlements` (неоплаченные счета взаиморасчётов). Один запрос вместо множества на клиенте.
- `process_bank_statement_entry(...)`: RPC атомарного переноса одной строки выписки в реестр. Параметр `p_settlement_operation_id` опционален.
- `batch_process_bank_statement_entries(p_company_id, p_items JSONB, p_created_by)`: Пакетный перенос. Ошибки по строкам не прерывают пакет; возвращает `{ processed, failed[] }`.
- `guard_linked_settlement_payment()`: BEFORE UPDATE/DELETE на `settlement_payments`.
- `tr_on_cash_flow_transaction_deleted`: AFTER DELETE на `cash_flow` — сброс `is_imported` в `bank_statement_entries`.
- **Каскад:** DELETE `cash_flow` → CASCADE DELETE `settlement_payments` → пересчёт `paid_amount` счёта.

---

## 🧠 Бизнес-логика

### Процесс импорта выписки
1. **Выбор файла:** `.xlsx` / `.xls`.
2. **Поиск шаблона** по названию банка счёта.
3. **BankImportService:** дедупликация по `operation_hash`, вызов `BankStatementParser`.
4. **Edge Function `bank_parse`:** парсинг Excel, валидация ИНН/счёта, генерация хешей.
5. **Staging:** upsert в `bank_statement_entries` (`UNIQUE (company_id, operation_hash)`).
6. **Отображение** в `BankStatementTable` через `filteredBankStatementEntries`.
7. **Автосопоставление** (после загрузки записей): `computeBankStatementMatches` → `BankStatementAutoProcessService` → `BankStatementMatchingService`.

### Автосопоставление строк выписки
**Источники данных (один RPC):** `get_bank_statement_matching_context` — история ДДС по контрагентам и открытые счета взаиморасчётов.

**Алгоритм для каждой строки:**
1. Пропуск, если строка уже обработана или хеш — дубликат в реестре.
2. **Статья ДДС:**
   - По правилу: ключевое слово в `comment` (приоритет + длина ключевого слова).
   - Fallback: последняя статья из истории операций с тем же контрагентом.
3. **Контрагент:** по ИНН из выписки (если не режим «только статья»).
4. **Договор и объект:**
   - Из истории операций контрагента;
   - Или единственный активный договор контрагента;
   - Или medium confidence при нескольких договорах.
5. **Счёт взаиморасчётов (опционально):** при совпадении суммы с открытым счётом по договору.
6. **Режим «только статья»** (`requires_contract_binding = false` в правиле):
   - Достаточно совпадения правила → **high confidence** без договора, объекта и контрагента.
   - Пример: налоги, комиссии банка.
   - Также: если из истории контрагента последние операции были без договора (`contract_id` и `object_id` = NULL).

**Уровни уверенности (`BankStatementMatchConfidence`):**
| Уровень | Условие | UI |
| :--- | :--- | :--- |
| **high** | Полный набор: статья + контрагент + договор + объект **ИЛИ** режим «только статья» с определённой статьей | Зелёная галочка, доступна пакетная обработка |
| **medium** | Частичное совпадение (статья или контрагент без однозначного договора) | Оранжевый индикатор, ручная проверка |
| **low** | Недостаточно данных | Серый индикатор |

### Пакетная обработка
1. Кнопка **«Обработать готовые (N)»** в `BankStatementView` (видна при `autoProcessableBankStatementCount > 0`).
2. Диалог подтверждения с количеством строк.
3. `batchProcessReadyBankStatementEntries` → RPC `batch_process_bank_statement_entries`.
4. Для каждой строки с `confidence == high` вызывается логика `process_bank_statement_entry` (включая опциональную привязку к взаиморасчётам).
5. Обновление реестра ДДС, выписки и списка взаиморасчётов.
6. Диалог результата: успешно / ошибки по строкам.

### Настройка правил автосопоставления
- Путь: **Настройки выписки → вкладка «Правила автосопоставления»**.
- Поля: ключевое слово, тип операции, статья ДДС, приоритет.
- Чекбокс **«Только статья (без договора и объекта)»** — для налогов и общих платежей.
- Примеры ключевых слов: `налог`, `фнс`, `енп`, `аренда`, `комиссия`.

### Ручная обработка одной строки
- Контекстное меню → «Обработать» → `CashFlowFormDialog(initialEntry)`.
- Автоподстановка контрагента по ИНН, опционально счёт взаиморасчётов.
- RPC `process_bank_statement_entry`.

### Поиск в выписках (клиентский)
- По ИНН и сумме через `bankStatementSearchQuery` / `filteredBankStatementEntries`.

### Аналитика по месяцам (`getYearlyAnalytics`)
- Группировка по `year * 100 + month`, сортировка по числовому ключу.
- UI: `CashFlowDetailsPanel`, горизонтальная таблица ПРИХОД / РАСХОД / САЛЬДО.

---

## 🔌 Интеграции
- **Edge Functions:** `bank_parse`.
- **SheetJS (xlsx):** Парсер Excel на сервере.
- **Riverpod:** `cashFlowProvider`, `bankStatementAutoProcessServiceProvider`.
- **Взаиморасчёты (Settlements):** `settlement_payments.cash_flow_transaction_id`, автоподбор счёта при пакетной обработке. Подробнее: [`settlements/settlements_module.md`](../settlements/settlements_module.md).

---

## 🗺️ Roadmap
- [x] Парсинг Excel на стороне сервера.
- [x] Поддержка сложных заголовков и раздельных колонок Дебет/Кредит.
- [x] Буферная таблица для хранения выписок.
- [x] Система защиты от дублей (`operation_hash`).
- [x] Архитектурное выделение `BankImportService`.
- [x] Кнопка «Обработать» (атомарная RPC).
- [x] Унифицированные контекстные меню (GTContextMenu).
- [x] Автоматическое сопоставление контрагентов по ИНН.
- [x] Привязка платежей из выписки к счетам взаиморасчётов.
- [x] Поиск в банковских выписках по ИНН и сумме.
- [x] Хронологическая сортировка месяцев в аналитике ДДС.
- [x] Автоматическое сопоставление категорий по ключевым словам в назначении платежа.
- [x] Пакетная обработка строк с высокой уверенностью сопоставления.
- [x] Режим «только статья» для операций без договора (налоги и пр.).
- [x] Автоподбор счёта взаиморасчётов при точном совпадении суммы и договора.
- [ ] Автозагрузка выписки (email / API банка).
- [ ] Обучение на истории без явных правил (ML / эвристики по тексту назначения).
