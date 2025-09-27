# Документация ProjectGT

В этой директории содержится техническая документация проекта ProjectGT.

## Содержание

1. [Архитектура](architecture.md) - общая архитектура проекта, структура директорий, слои архитектуры и принципы расширения.

2. [Технологический стек](tech_stack.md) - используемые библиотеки, зависимости и инструменты разработки.

3. [Система аутентификации и профилей](auth_system.md) - аутентификация (OTP по email), авторизация, структура пользовательских данных и рабочий процесс подтверждения администратором.

4. [Руководство по разработке](development_guide.md) - практические рекомендации по стилю кода, UI/UX, работе с Riverpod и Supabase.

5. [API Reference](api_reference.md) - справочник по ключевым классам, методам и провайдерам.

6. [Полная API-документация (Dartdoc, автогенерация)](api/index.html) — подробная документация по всем классам, функциям и структуре проекта (открыть в браузере).

7. [Модуль сотрудников](#форма-сотрудника-employeformscreen) — структура и особенности формы добавления/редактирования сотрудников.

## Структура папки `lib/`

> Ниже приведена структура папки `lib/` с кратким описанием назначения каждой папки и ключевых файлов.  
> Поддерживайте этот раздел в актуальном состоянии при изменениях структуры проекта.

## Полная структура папки `lib/` (tree)

```
lib/
├── main.dart
├── core/
│   ├── common/
│   │   └── app_router.dart
│   ├── di/
│   │   └── providers.dart
│   ├── services/
│   │   └── photo_service.dart
│   └── utils/
│       └── notifications_service.dart
├── data/
│   ├── common/
│   ├── datasources/
│   │   ├── auth_data_source.dart
│   │   ├── contract_data_source.dart
│   │   ├── contractor_data_source.dart
│   │   ├── employee_data_source.dart
│   │   ├── estimate_data_source.dart
│   │   ├── object_data_source.dart
│   │   └── profile_data_source.dart
│   ├── migrations/
│   │   ├── contractors_migration.sql
│   │   ├── employees_migration.sql
│   │   └── storage_policy_migration.sql
│   ├── models/
│   │   ├── contract_model.dart
│   │   ├── contract_model.freezed.dart
│   │   ├── contract_model.g.dart
│   │   ├── contractor_model.dart
│   │   ├── contractor_model.freezed.dart
│   │   ├── contractor_model.g.dart
│   │   ├── employee_model.dart
│   │   ├── employee_model.freezed.dart
│   │   ├── employee_model.g.dart
│   │   ├── estimate_model.dart
│   │   ├── estimate_model.freezed.dart
│   │   ├── estimate_model.g.dart
│   │   ├── object_model.dart
│   │   ├── object_model.freezed.dart
│   │   ├── object_model.g.dart
│   │   ├── profile_model.dart
│   │   ├── profile_model.freezed.dart
│   │   ├── profile_model.g.dart
│   │   ├── user_model.dart
│   │   ├── user_model.freezed.dart
│   │   └── user_model.g.dart
│   ├── repositories/
│   │   ├── auth_repository_impl.dart
│   │   ├── contract_repository_impl.dart
│   │   ├── contractor_repository_impl.dart
│   │   ├── employee_repository_impl.dart
│   │   ├── estimate_repository_impl.dart
│   │   ├── object_repository_impl.dart
│   │   └── profile_repository_impl.dart
│   └── services/
│       └── excel_estimate_service.dart
├── domain/
│   ├── common/
│   ├── entities/
│   │   ├── contract.dart
│   │   ├── contract.freezed.dart
│   │   ├── contractor.dart
│   │   ├── contractor.freezed.dart
│   │   ├── employee.dart
│   │   ├── employee.freezed.dart
│   │   ├── estimate.dart
│   │   ├── estimate.freezed.dart
│   │   ├── object.dart
│   │   ├── object.freezed.dart
│   │   ├── profile.dart
│   │   ├── profile.freezed.dart
│   │   ├── user.dart
│   │   └── user.freezed.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── contract_repository.dart
│   │   ├── contractor_repository.dart
│   │   ├── employee_repository.dart
│   │   ├── estimate_repository.dart
│   │   ├── object_repository.dart
│   │   └── profile_repository.dart
│   └── usecases/
│       ├── auth/
│       │   ├── get_current_user_usecase.dart
│       │   ├── login_usecase.dart
│       │   ├── logout_usecase.dart
│       │   └── register_usecase.dart
│       ├── contract/
│       │   ├── create_contract_usecase.dart
│       │   ├── delete_contract_usecase.dart
│       │   ├── get_contract_usecase.dart
│       │   ├── get_contracts_usecase.dart
│       │   └── update_contract_usecase.dart
│       ├── contractor/
│       │   ├── create_contractor_usecase.dart
│       │   ├── delete_contractor_usecase.dart
│       │   ├── get_contractor_usecase.dart
│       │   ├── get_contractors_usecase.dart
│       │   └── update_contractor_usecase.dart
│       ├── employee/
│       │   ├── create_employee_usecase.dart
│       │   ├── delete_employee_usecase.dart
│       │   ├── get_employee_usecase.dart
│       │   ├── get_employees_usecase.dart
│       │   └── update_employee_usecase.dart
│       ├── estimate/
│       │   ├── create_estimate_usecase.dart
│       │   ├── delete_estimate_usecase.dart
│       │   ├── get_estimate_usecase.dart
│       │   ├── get_estimates_usecase.dart
│       │   └── update_estimate_usecase.dart
│       ├── object/
│       │   ├── create_object_usecase.dart
│       │   ├── delete_object_usecase.dart
│       │   ├── get_objects_usecase.dart
│       │   └── update_object_usecase.dart
│       └── profile/
│           ├── get_profile_usecase.dart
│           ├── get_profiles_usecase.dart
│           └── update_profile_usecase.dart
├── features/
│   ├── auth/
│   ├── contracts/
│   ├── contractors/
│   ├── employees/
│   ├── estimates/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── estimate_details_screen.dart
│   │           ├── estimate_form_screen.dart
│   │           ├── estimates_list_screen.dart
│   │           ├── import_estimate_excel_template.dart
│   │           └── import_estimate_form_modal.dart
│   ├── home/
│   ├── notifications/
│   ├── objects/
│   └── profile/
├── presentation/
│   ├── common/
│   ├── state/
│   │   ├── auth_state.dart
│   │   ├── contractor_state.dart
│   │   ├── contract_state.dart
│   │   ├── employee_state.dart
│   │   ├── estimate_state.dart
│   │   ├── object_state.dart
│   │   └── profile_state.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_provider.dart
│   └── widgets/
│       ├── app_badge.dart
│       ├── app_bar_widget.dart
│       ├── app_drawer.dart
│       ├── drawer_item_widget.dart
│       └── photo_picker_avatar.dart
```

---

## Описание файлов и папок lib/

### main.dart
- Точка входа приложения, инициализация Supabase, загрузка env, запуск Riverpod, настройка тем и роутинга.

### core/
- **common/app_router.dart** — Конфигурация маршрутизации (go_router), описание всех маршрутов приложения.
- **di/providers.dart** — DI-провайдеры для Riverpod, регистрация всех зависимостей.
- **services/photo_service.dart** — Работа с фото (Supabase Storage), загрузка/удаление/получение ссылок.
- **utils/notifications_service.dart** — Сервис для локальных и push-уведомлений.

### data/
- **common/** — Общие утилиты и базовые классы data-слоя (если есть).
- **datasources/** — Источники данных (Supabase, Excel, локальные): CRUD-операции, интеграция с API.
  - **auth_data_source.dart** — Источник данных для аутентификации.
  - **contract_data_source.dart** — Источник данных для договоров.
  - **contractor_data_source.dart** — Источник данных для контрагентов.
  - **employee_data_source.dart** — Источник данных для сотрудников.
  - **estimate_data_source.dart** — Источник данных для смет.
  - **object_data_source.dart** — Источник данных для объектов.
  - **profile_data_source.dart** — Источник данных для профилей.
- **migrations/** — SQL-миграции для Supabase (структура таблиц, политики безопасности).
  - **contractors_migration.sql** — Миграция для таблицы контрагентов.
  - **employees_migration.sql** — Миграция для таблицы сотрудников.
  - **storage_policy_migration.sql** — Миграция для политик хранения файлов.
- **models/** — Data-модели (Freezed, json_serializable, *.g.dart — автогенерируемые).
  - **contract_model.dart** — Модель договора.
  - **contractor_model.dart** — Модель контрагента.
  - **employee_model.dart** — Модель сотрудника.
  - **estimate_model.dart** — Модель сметы.
  - **object_model.dart** — Модель объекта.
  - **profile_model.dart** — Модель профиля пользователя.
  - **user_model.dart** — Модель пользователя.
  - **.freezed.dart, .g.dart** — Автогенерируемые файлы для сериализации и иммутабельности.
- **repositories/** — Реализации репозиториев для работы с БД/API.
  - **auth_repository_impl.dart** — Реализация репозитория аутентификации.
  - **contract_repository_impl.dart** — Реализация репозитория договоров.
  - **contractor_repository_impl.dart** — Реализация репозитория контрагентов.
  - **employee_repository_impl.dart** — Реализация репозитория сотрудников.
  - **estimate_repository_impl.dart** — Реализация репозитория смет.
  - **object_repository_impl.dart** — Реализация репозитория объектов.
  - **profile_repository_impl.dart** — Реализация репозитория профилей.
- **services/** — Сервисы для работы с файлами, Excel и др.
  - **excel_estimate_service.dart** — Генерация и обработка Excel-файлов для смет.

### domain/
- **common/** — Общие абстракции или утилиты domain-слоя (если есть).
- **entities/** — Доменные сущности (Freezed, чистые модели бизнес-логики).
  - **contract.dart** — Сущность договора.
  - **contractor.dart** — Сущность контрагента.
  - **employee.dart** — Сущность сотрудника.
  - **estimate.dart** — Сущность сметы.
  - **object.dart** — Сущность объекта.
  - **profile.dart** — Сущность профиля пользователя.
  - **user.dart** — Сущность пользователя.
  - **.freezed.dart** — Автогенерируемые файлы для иммутабельности.
- **repositories/** — Абстракции репозиториев для DI и тестирования.
  - **auth_repository.dart** — Абстракция репозитория аутентификации.
  - **contract_repository.dart** — Абстракция репозитория договоров.
  - **contractor_repository.dart** — Абстракция репозитория контрагентов.
  - **employee_repository.dart** — Абстракция репозитория сотрудников.
  - **estimate_repository.dart** — Абстракция репозитория смет.
  - **object_repository.dart** — Абстракция репозитория объектов.
  - **profile_repository.dart** — Абстракция репозитория профилей.
- **usecases/** — UseCase для бизнес-операций (CRUD, авторизация и др.), разбиты по сущностям.
  - **auth/** — UseCase для аутентификации (OTP-вход, логаут, получение текущего пользователя).
  - **contract/** — UseCase для договоров (CRUD).
  - **contractor/** — UseCase для контрагентов (CRUD).
  - **employee/** — UseCase для сотрудников (CRUD).
  - **estimate/** — UseCase для смет (CRUD).
  - **object/** — UseCase для объектов (CRUD).
  - **profile/** — UseCase для профилей (CRUD).

### features/
- **estimates/presentation/screens/** — UI-экраны модуля "Сметы".
  - **estimate_details_screen.dart** — Экран детального просмотра сметы (PlutoGrid).
  - **estimate_form_screen.dart** — Экран создания/редактирования сметы.
  - **estimates_list_screen.dart** — Экран списка смет, импорт/экспорт, группировка, переход к деталям.
  - **import_estimate_excel_template.dart** — Документация по шаблону Excel для импорта.
  - **import_estimate_form_modal.dart** — Модальное окно для импорта сметы из Excel.
- **contracts/**, **contractors/**, **objects/**, **employees/**, **notifications/**, **profile/**, **home/**, **auth/** — Аналогичная структура: presentation (экраны, виджеты), domain, data (если есть).

### presentation/
- **common/** — Общие компоненты presentation-слоя (если есть).
- **state/** — Глобальные состояния (StateNotifier, Riverpod).
  - **auth_state.dart** — Состояние аутентификации.
  - **contractor_state.dart** — Состояние контрагентов.
  - **contract_state.dart** — Состояние договоров.
  - **employee_state.dart** — Состояние сотрудников.
  - **estimate_state.dart** — Состояние смет.
  - **object_state.dart** — Состояние объектов.
  - **profile_state.dart** — Состояние профилей.
- **theme/** — Темы приложения.
  - **app_theme.dart** — Описание светлой и тёмной темы.
  - **theme_provider.dart** — Провайдер для управления темой.
- **widgets/** — Глобальные переиспользуемые виджеты.
  - **app_badge.dart** — Виджет бейджа.
  - **app_bar_widget.dart** — Кастомный AppBar.
  - **app_drawer.dart** — Боковое меню.
  - **drawer_item_widget.dart** — Элемент меню.
  - **photo_picker_avatar.dart** — Виджет выбора и отображения аватара.

---

## Примечания

- **Автогенерируемые файлы**:  
  Все файлы с расширениями `.g.dart` и `.freezed.dart` генерируются автоматически (build_runner, freezed, json_serializable).
- **Миграции**:  
  SQL-файлы в `data/migrations/` используются для управления схемой БД Supabase.
- **Фичи**:  
  Для каждой новой фичи рекомендуется создавать аналогичную структуру (presentation/domain/data).
- **Тесты**:  
  Тесты располагаются в папке `test/` с аналогичной структурой.

---

## Для разработчиков

Настоятельно рекомендуется ознакомиться со всеми документами перед началом работы над проектом. Рекомендуемый порядок изучения:

1. `architecture.md` - для понимания общей структуры
2. `tech_stack.md` - для ознакомления с используемыми технологиями
3. `development_guide.md` - для практических рекомендаций
4. `auth_system.md` - для понимания системы аутентификации
5. `api_reference.md` - как справочник при разработке

- В проекте реализован модуль сотрудников с формой, разбитой на логические блоки (основная информация, физические параметры, трудоустройство, паспортные данные, документы) и поддержкой загрузки фото через Supabase Storage. 
+ Модуль объектов реализует форму создания/редактирования с унифицированным UX: форма вынесена в отдельный stateless-виджет, для модального окна используется отдельный stateful-виджет, сохранение происходит через Provider (см. development_guide.md и architecture.md). 
- В модуле сотрудников реализован мультивыбор объектов с современным UX: выбранные объекты отображаются только внутри поля выбора, без лишних визуальных элементов. Цвет текста в выпадающем списке всегда чёрный для читаемости в любой теме. 
+ Модуль контрагентов реализует форму создания/редактирования с унифицированным UX: форма вынесена в отдельный stateless-виджет, для модального окна используется stateful-обёртка, сохранение происходит через Provider. Модальные окна ограничены по ширине и центрированы на десктопе. Стиль полностью совпадает с сотрудниками и объектами. 