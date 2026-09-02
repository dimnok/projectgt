# Модуль Contractors (Контрагенты)
*Дата: 02.09.2026*

**Список последних изменений:**
- **Чтение null из БД, 02.09.2026:**
    * Flutter: пустые `phone` / `email` / адреса / директор / тип больше не роняют весь список. `null` читается как пустая строка (как в web `text()`).
- **activity_description (ОКВЭД), 02.09.2026:**
    * Web (`react_app`): в форме вводится только код ОКВЭД. Название берётся из справочника ОК 029-2014 (изменение №89 от 01.08.2026), `react_app/src/lib/okved/`. В колонку пишется код (`43.29`).
    * Читаются и старые значения: код, `[код] название` (DaData / `dadata-proxy`), `название (код)`.
    * Flutter по-прежнему показывает сырое значение поля, без справочника.
- **Mobile UI Adaptive Layout:**
    * Реализована адаптивная верстка разделов информации: на мобильных устройствах подписи располагаются над значениями (вертикально), на десктопе — сбоку (горизонтально).
    * Это устраняет проблему «пустых мест» под короткими подписями и дает больше пространства для длинных значений (например, адресов).
    * Оптимизирован хедер мобильной версии: полное наименование скрывается из верхней части, если оно слишком длинное или совпадает с кратким, так как оно представлено в детальном списке ниже.
- Рефакторинг модуля под Feature-first Clean Architecture.
- Перевод стейт-менеджмента на Riverpod 2.0 с генераторами (`@riverpod`).
- Внедрение Freezed для иммутабельности стейта и доменных моделей.
- Полное приведение UI к Design System (использование `GTTextField`, `GTSectionTitle`, `GTPrimaryButton`).
- **Унификация модальных окон:** переход на `DesktopDialogContent` и `MobileBottomSheetContent`.
- **Оптимизация структуры:** удаление дублирующего файла `ContractorDetailsDesktopView` в пользу универсального `ContractorDetailsPanel`.
- **Shared-компоненты:** создание `ContractorDetailsSections` и `ContractorAvatar` для исключения дублирования логики отображения между Mobile и Desktop.
- **Централизованная логика удаления:** внедрение `ContractorDialogs.showConfirmDelete` для единообразного подтверждения деструктивных действий.
- **Интеграция Multi-tenancy:** добавлена привязка всех данных к `company_id`, внедрена изоляция на уровне БД (RLS) и бизнес-логики.
- Делегация управления датами `created_at`/`updated_at` на уровень БД (триггеры Supabase).

---

## 2. Важное замечание
Модуль является владельцем таблиц `contractors` и `contractor_bank_accounts`. Любые изменения в схеме этих таблиц должны сопровождаться обновлением моделей в `lib/features/contractors/data/models/` и типов в `react_app`. Модуль интегрирован с внешним сервисом DaData через Edge Function `dadata-proxy`. Все данные изолированы по `company_id` в рамках Multi-tenancy архитектуры. Веб-экран: `react_app/docs/contractors.md`.

## 3. Описание
Модуль предназначен для управления базой контрагентов (Заказчики, Подрядчики, Поставщики) с привязкой к конкретной компании.
**Ключевые функции:**
- Ведение реестра юридических лиц и ИП с изоляцией по компаниям.
- Автоматический поиск и заполнение данных по ИНН (DaData).
- Управление банковскими счетами контрагентов (неограниченное количество).
- Хранение логотипов и контактных данных.
- Интеграция с модулями Договоров (Contracts) и Движения денежных средств (Cash Flow).

## 4. Зависимости
- **Owner (Владелец):** `contractors`, `contractor_bank_accounts`.
- **Usage (Использует):** 
    - `companies` (внешний ключ `company_id`).
    - `contracts` (внешний ключ `contractor_id`).
    - `cash_flow_entries` (связь через `contractor_id`).
    - `estimates` (связь через `contractor_id`).

## 5. Слой Presentation
### Экраны (Screens):
- `ContractorsListScreen`: Главный экран со списком и поиском.
- `ContractorDetailsScreen`: Карточка контрагента (адаптивная обертка).
    - `ContractorDetailsMobileView`: Мобильное представление.
    - `ContractorDetailsPanel`: Универсальная панель деталей (используется на Desktop и в модальных окнах).
- `ContractorFormScreen`: Форма создания/редактирования (адаптивный диалог/экран).

### Виджеты (Widgets):
- `ContractorDetailsSections`: Единый компонент со всеми информационными разделами.
- `ContractorAvatar`: Универсальный виджет логотипа с поддержкой Hero-анимации.
- `ContractorInfoRow`: Универсальный виджет строки информации (label/value).
- `ContractorSection`: Контейнер для группировки `ContractorInfoRow`.
- `ContractorBankAccountsList`: Централизованный виджет управления счетами.
- `ContractorBankAccountFormDialog`: Адаптивный диалог добавления/редактирования счета.

### Провайдеры (Providers):
- `contractorNotifierProvider`: Управление состоянием и CRUD операциями.
- `filteredContractorsProvider`: Реактивный поиск по списку контрагентов.
- `contractorBankAccountNotifierProvider`: Управление счетами (family по `contractorId`).

## 6. Слой Domain/Data
- **Entities:** `Contractor`, `ContractorBankAccount` (с использованием Freezed).
- **Use Cases:** 
    - `GetContractorsUseCase`, `GetContractorUseCase`.
    - `CreateContractorUseCase`, `UpdateContractorUseCase`, `DeleteContractorUseCase`.
- **Repositories:** `ContractorRepository` (interface) -> `ContractorRepositoryImpl`.
- **DataSources:** `SupabaseContractorDataSource`.

## 7. Дерево файлов
```
lib/features/contractors/
├── data/
│   ├── datasources/        # Работа с Supabase API
│   ├── models/             # JSON-маппинг
│   └── repositories/       # Реализация интерфейсов
├── domain/
│   ├── entities/           # Бизнес-сущности + Extensions
│   ├── repositories/       # Интерфейсы репозиториев
│   └── usecases/           # Атомарные бизнес-операции
├── presentation/
│   ├── screens/
│   │   ├── desktop/        # Десктопные представления (списки)
│   │   ├── mobile/         # Мобильные представления (детали, списки)
│   │   └── *.dart          # Основные экраны-контроллеры
│   ├── state/              # Riverpod Notifiers (Generated)
│   └── widgets/            # Виджеты и Shared-компоненты
```

## 8. База данных (Audit)
### Таблица `contractors`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | uuid | Primary Key |
| company_id | uuid | Foreign Key -> companies.id |
| full_name | text | Полное наименование |
| short_name | text | Краткое наименование |
| inn | text | ИНН (10 или 12 цифр) |
| kpp | text | КПП |
| ogrn | text | ОГРН |
| okpo | text | ОКПО |
| type | text | Тип (customer, contractor, supplier) |
| director | text | ФИО Директора |
| director_phone | text | Телефон директора |
| director_basis | text | Основание полномочий (Устав и т.д.) |
| legal_address | text | Юридический адрес |
| actual_address | text | Фактический адрес |
| phone | text | Общий телефон |
| email | text | Электронная почта |
| website | text | Веб-сайт |
| activity_description | text | Код ОКВЭД (предпочтительно). Допустимы исторические форматы: `43.29`, `[43.29] название`, `название (43.29)` |
| taxation_system | text | Система налогообложения |
| chief_accountant_name | text | ФИО главного бухгалтера |
| chief_accountant_phone | text | Телефон бухгалтера |
| contact_person | text | Контактное лицо |
| director_position | text | Должность руководителя (в вебе не используется) |
| is_vat_payer | bool | Плательщик НДС |
| vat_rate | numeric | Ставка НДС |
| logo_url | text | Ссылка на Storage |
| created_at | timestamptz | Дата создания (DB Default) |
| updated_at | timestamptz | Дата обновления (Trigger) |

### Таблица `contractor_bank_accounts`
| Колонка | Тип | Описание |
|---------|-----|----------|
| id | uuid | Primary Key |
| company_id | uuid | Foreign Key -> companies.id |
| contractor_id | uuid | Foreign Key -> contractors.id |
| bank_name | text | Наименование банка |
| bank_city | text | Город банка |
| bik | text | БИК |
| account_number | text | Расчетный счет |
| corr_account | text | Корреспондентский счет |
| is_primary | bool | Основной счет |

- **RLS:** ✅ Включён. Доступ изолирован по `company_id` (через `get_my_company_ids()`) и дополнительно регулируется через функцию `check_permission(auth.uid(), 'contractors', permission)`.
- **Триггеры:** `updated_at` обновляется автоматически.

## 9. Бизнес-логика
- **Чтение карточки (Flutter):** поля `phone`, `email`, `legal_address`, `actual_address`, `director`, `full_name`, `short_name`, `inn` при `null` в JSON становятся пустой строкой. Неизвестный или пустой `type` → `customer`. Иначе одна неполная карточка (например после сохранения из web) обнуляла весь справочник, в том числе список поставщиков в заявках на закупку.
- **ОКВЭД (`activity_description`):**
    - Web: пользователь вводит код; название подставляется из JSON-справочника; в БД сохраняется код.
    - Flutter + `dadata-proxy`: при заполнении по ИНН пишется `[код] название`.
    - Web при сохранении нормализует известные форматы к коду.
- **Адаптивность UI:** 
    - Разделы информации используют адаптивную верстку (класс `ContractorInfoRow`): на мобильных устройствах метки отображаются над значениями (вертикально), на десктопе — сбоку (горизонтально, `labelWidth: 200`). Это обеспечивает оптимальное использование пространства для длинных строк (ИНН, адреса, email).
    - Оптимизация мобильного хедера: длинные полные наименования скрываются из шапки, чтобы не загромождать экран, так как они доступны в основном списке данных.
- **Унификация UI:** Все информационные блоки строятся на базе `ContractorDetailsSections`, что гарантирует идентичный состав полей на всех платформах.
- **Модальные окна:** Автоматически переключаются между `DesktopDialogContent` (центр экрана) и `MobileBottomSheetContent` (выезд снизу).
- **Форматирование:** Локализация типов контрагентов вынесена в `ContractorTypeX.label`.
- **Удаление:** Для подтверждения удаления используется общий метод `ContractorDialogs.showConfirmDelete`, соответствующий Design System.

## 10. Интеграции
- **Edge Functions:** `dadata-proxy` — проксирование запросов к DaData. Поле деятельности: `activityDescription = [okved] name` либо только код.
- **Web:** `react_app/src/lib/okved/` — локальный справочник названий по коду (без вызова DaData).
- **Storage:** Баскет `contractors` для хранения логотипов.
- **Design System:** Использование `GT`-виджетов из `lib/core/widgets/`.

## 11. Roadmap
- 🟢 Полный переход на Feature-first (Завершено).
- 🟢 Унификация UI компонентов и модальных окон (Завершено).
- 🟢 Рефакторинг на Riverpod Generator (Завершено).
- 🟡 История изменений контрагента (В планах).
- 🟡 Flutter: подстановка названия ОКВЭД по коду (как в web).
- 🟡 Web: поиск по ИНН через DaData.
- 🔴 Интеграция с черными списками контрагентов (В планах).
