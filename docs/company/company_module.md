# Модуль Компания (Company)
*Дата последнего обновления: 16 января 2026 г.*

## 📌 Список изменений (16.01.2026)
- **Адаптивность:** Все диалоги редактирования реквизитов и документов переведены на адаптивный режим (Dialog на Desktop, BottomSheet на Mobile через `MobileBottomSheetContent`).
- **Рефакторинг:** 
    - Вынос логики запуска URL в глобальную утилиту `UIUtils.launchExternalUrl`.
    - Полный рефакторинг `CompanyScreenMobile`: удаление дублирующего UI-кода, переход на унифицированные виджеты `CompanyInfoCard` и `CompanyInfoRow`.
- **UI/UX:** 
    - Реализация строгого черно-белого минимализма в мобильной версии.
    - Оптимизация карточек: использование тонких границ (border 1px, alpha 0.1) без теней.
    - Добавление отображения юридического и фактического адресов в мобильной версии.
    - Оптимизация навигации: перенос ссылки на профиль компании в блок переключателя организаций (`AppDrawer`).
    - Унификация списков банковских счетов и документов (круглые иконки, шевроны).
    - Исправление хардкодных цветов для корректной поддержки темной темы.
- **Оптимизация:** Переход на `.single()` при получении профиля компании в `CompanyDataSource`.

## 📌 Важное замечание
Модуль является центральным узлом для Multi-tenancy архитектуры. Он управляет организациями, их реквизитами, банковскими счетами и документами. Каждая компания имеет владельца (Owner) и участников (Members) с определёнными ролями. Реализована полная адаптивность для Desktop и Mobile (iOS style).

## 📝 Описание
Модуль предназначен для:
- Создания и настройки профиля организации.
- Управления банковскими реквизитами (поддержка нескольких счетов, выбор основного).
- Хранения лицензий, СРО и других нормативных документов.
- Реализации механизма приглашений через `invitation_code`.
- Связки пользователей с организациями.
- Поиска данных организации по ИНН через DaData API.

## 🔗 Зависимости
- **Таблицы модуля (Owner):** `companies`, `company_bank_accounts`, `company_documents`, `company_members`.
- **Использование (Usage):** `profiles` (last_company_id), `roles`.
- **Edge Functions:** `dadata-proxy` (поиск реквизитов).

## 🎨 Слой Presentation
Модуль использует адаптивную навигацию и разделение экранов по платформам.

- **Экраны:**
    - `CompanyScreen`: Основная точка входа, выполняющая роутинг между Desktop и Mobile версиями.
    - `CompanyScreenMobile`: Специализированная мобильная версия в стиле iOS.
        - Использует кастомный `SliverPersistentHeader` для сложной анимации шапки.
        - **Бесшовная трансформация:** Название компании плавно перемещается из центра хедера в заголовок аппбара при скролле.
        - **Адаптивность тем:** Использование `theme.colorScheme` для всех элементов интерфейса.
    - `CompanyOnboardingScreen`: Экран выбора/создания/вступления в компанию при первом входе.
- **Виджеты:**
    - `CompanyInfoCard`, `CompanyInfoRow`: Компоненты отображения данных.
    - `CompanyFormContent`: Общий контент для форм создания и редактирования (адаптивный).
    - **Адаптивные диалоги:** `CompanyProfileEditDialog`, `CompanyBankAccountEditDialog`, `CompanyDocumentEditDialog`, `CompanyCreateDialog`, `CompanyAddSelectionDialog`, `CompanyJoinDialog`. Используют `DesktopDialogContent` на десктопе и `MobileBottomSheetContent` на мобильных устройствах.
- **Интерактивные процессы:** 
    - Процесс добавления компании (через `AppDrawer`) переведен на унифицированный диалог выбора `CompanyAddSelectionDialog`, заменяющий стандартный `CupertinoActionSheet`.
    - Навигация к профилю компании интегрирована в `_CompanySwitcher` бокового меню (иконка `info_circle` рядом с названием активной компании), что позволило удалить дублирующий пункт основного меню.
- **Providers:**
    - `companyProfileProvider`: FutureProvider профиля текущей компании.
    - `companyBankAccountsProvider`: Список счетов.
    - `companyDocumentsProvider`: Список документов.
    - `activeCompanyIdProvider`: ID активной компании из профиля пользователя.
    - `userCompaniesProvider`: Список всех компаний, в которых состоит пользователь.

## ⚙️ Слой Domain/Data
- **Сущности (Entities):** `CompanyProfile`, `CompanyBankAccount`, `CompanyDocument` (Freezed).
- **Use Cases:** `CreateCompanyUseCase`, `JoinCompanyUseCase`, `UpdateMemberUseCase`.
- **Repositories:** `CompanyRepository`, `CompanyRepositoryImpl`.
- **Data Sources:** `CompanyDataSource` (Supabase реализация).

## 🌳 Дерево файлов
```text
lib/features/company/
├── data/
│   ├── datasources/
│   │   └── company_data_source.dart
│   ├── models/
│   └── repositories/
│       └── company_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── company_bank_account.dart
│   │   ├── company_document.dart
│   │   └── company_profile.dart
│   ├── repositories/
│   │   └── company_repository.dart
│   └── usecases/
│       ├── create_company_usecase.dart
│       ├── join_company_usecase.dart
│       └── update_member_usecase.dart
└── presentation/
    ├── providers/
    │   └── company_providers.dart
    ├── screens/
    │   ├── company_onboarding_screen.dart
    │   ├── company_screen_mobile.dart
    │   └── company_screen.dart
    └── widgets/
        ├── company_add_selection_dialog.dart
        ├── company_bank_account_edit_dialog.dart
        ├── company_create_dialog.dart
        ├── company_document_edit_dialog.dart
        ├── company_form_content.dart
        ├── company_info_widgets.dart
        ├── company_join_dialog.dart
        └── company_profile_edit_dialog.dart
```

## 🗄️ База данных (Audit)

### Таблицы

#### `companies` (Организации)
- `id`: uuid (Primary Key)
- `name_full`, `name_short`: text
- `owner_id`: uuid (FK -> profiles.id)
- `inn`, `kpp`, `ogrn`, `okpo`: text
- `legal_address`, `actual_address`: text
- `director_name`, `director_position`, `director_basis`, `director_phone`: text
- `invitation_code`: text (Unique)
- `is_active`: boolean
- `min_output_per_person_hour`: numeric, nullable — минимум выработки, ₽ / чел. / час (веб-профиль организации; в Flutter-карточке компании поля пока нет)
- **RLS:** ✅ Включён. Изоляция по `get_my_company_ids()` и `owner_id`. UPDATE только `owner_id = uid()`.

#### `company_bank_accounts` (Банковские счета)
- `id`: uuid (PK), `company_id`: uuid (FK)
- `bank_name`, `account_number`, `corr_account`, `bik`, `bank_city`: text
- `is_primary`: boolean
- **RLS:** ✅ Включён. Доступ для участников компании.

#### `company_documents` (Документы)
- `id`: uuid (PK), `company_id`: uuid (FK)
- `type`, `title`, `number`: text
- `issue_date`, `expiry_date`: date
- `file_url`: text
- **RLS:** ✅ Включён. Доступ для участников компании.

#### `company_members` (Участники)
- `company_id`, `user_id`: uuid
- `system_role`: text (owner, admin)
- `role_id`: uuid (FK -> roles.id)
- **RLS:** ✅ Включён.

## 🛠 Интеграции
- **DaData API:** Интеграция через Edge Function `dadata-proxy`.
- **Внешние ссылки:** Обработка через `UIUtils.launchExternalUrl` (url_launcher).
- **Supabase Auth & RLS:** Полная изоляция данных между арендаторами (multi-tenancy).

## 🚀 Roadmap
- [x] Создание организации.
- [x] Вступление по коду.
- [x] Управление реквизитами и документами.
- [x] Адаптивная мобильная версия (iOS style).
- [x] Адаптивные диалоги редактирования (Desktop/Mobile).
- [ ] 🟡 Смена владельца компании.
- [ ] 🟢 Логирование изменений профиля.
