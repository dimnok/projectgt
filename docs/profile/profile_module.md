1.  **Заголовок и дата:** # Модуль Profile (Профиль пользователя) | 10.09.2026 (Обновление 4)
    - **Веб:** личный кабинет в `react_app`, документ [`react_app/docs/profile.md`](../../react_app/docs/profile.md). Финансы: RPC `get_my_profile_finance`. На экране «Пользователи» — назначение `profiles.object_ids`. Триггер `prevent_unauthorized_profile_objects`. Flutter-код не менялся.
    - **Flutter (без изменений в этом пункте):** экран `FinancialInfoScreen` по-прежнему описан в [`docs/FINANCIAL_INFO.md`](../FINANCIAL_INFO.md).
    - **Баланс в хедере:** В мобильной версии `ProfileScreen` добавлен блок баланса (зеленый шрифт, размер 10).
    - **Типографика:** Увеличены шрифты телефона (15) и почты (14) в главном блоке профиля для лучшей читаемости.
    - **Исправление финансов:** В `FinancialInfoScreen` исправлен расчет выплат (FIFO) и итоговых сумм.
    - **БД (RPC):** Обновлена функция `calculate_employee_balances_before_date` — теперь возвращает полный набор данных (начисления, выплаты, баланс).
    - Удален дублирующий сервис `financial_pdf_service.dart`.
    - Финансовый отчет переведен на использование общего сервиса `EmployeeFinancialReportService` из модуля ФОТ.
    - Внедрена поддержка данных из табеля (`employee_attendance`) и расчеты через RPC.
    - Оптимизирован экран `FinancialInfoScreen` (переход на `calculate_payroll_for_month`).
    - Удален стандартный `AppBarWidget` для мобильной версии в пользу минималистичных плавающих кнопок.

2.  **Важное замечание:** Модуль является центральным узлом для управления персональными данными и интеграции с RBAC v3.

3.  **Описание:** Модуль Profile отвечает за управление профилями пользователей в системе: просмотр, редактирование, хранение и интеграцию с Supabase Auth. Поддерживает работу с ролями, объектами, аватарами, списком пользователей. Реализован по принципам Clean Architecture.

4.  **Зависимости:**
    - Таблицы (owner): `profiles`
    - Таблицы (usage): `company_members`, `roles`, `objects`
    - Хранилище: Supabase Storage (bucket `avatars`)

5.  **Слой Presentation:**
    - **Screens:**
        - `ProfileScreen` — адаптивный экран профиля. Мобильная версия переработана под стиль iOS (горизонтальный хедер, квадратный аватар, инфо-панель).
        - `UsersListScreen` (Mobile/Desktop) — управление списком участников.
        - `NotificationsSettingsScreen` — управление слотами уведомлений.
        - `FinancialInfoScreen` — экран финансовой информации. Отображает баланс, начисления (через RPC), премии, штрафы и историю выплат. Поддерживает генерацию годового отчета.
    - **Widgets:**
        - `ProfileEditForm` — форма редактирования на базе `GTTextField`.
        - `PhotoPickerAvatar` — универсальный компонент с поддержкой круга/квадрата и оверлея камеры.
        - `ProfileStatusSwitch` — переключатель активности (для админов).

6.  **Слой Domain/Data:**
    - **Entities:** `Profile` (immutable, Freezed).
    - **Use Cases:** `GetProfileUseCase`, `UpdateProfileUseCase`, `GetProfilesUseCase`.
    - **Repositories:** `ProfileRepository` (интерфейс) и `ProfileRepositoryImpl`.
    - **Formatters:** Используется централизованный `formatPhone` из `GtFormatters`.

7.  **Дерево файлов:**
```
lib/features/profile/
├── presentation/
│   ├── screens/
│   │   ├── profile_screen.dart
│   │   ├── users_list_screen.dart
│   │   ├── notifications_settings_screen.dart
│   │   └── financial_info_screen.dart
│   └── widgets/
│       ├── profile_edit_form.dart
│       └── photo_picker_avatar.dart (core)
├── domain/
│   └── entities/
│       └── profile.dart
└── data/
    ├── datasources/
    │   └── profile_data_source.dart
    └── repositories/
        └── profile_repository_impl.dart
```

8.  **База данных (Audit):**
    - **Таблицы:** `profiles` (id, full_name, phone, email, photo_url, object_ids, last_company_id).
    - **RLS:** ✅ Включён. Пользователи могут редактировать только свой `full_name` и `phone`.
    - **Функции:** Триггер на обновление `updated_at`. `prevent_unauthorized_employee_link` — смена `employee_id` только при `users.update` / супер-админ. `prevent_unauthorized_profile_objects` — смена `object_ids` по тому же правилу (null и пустой массив считаются одинаковыми).

9.  **Бизнес-логика:**
    - Форматирование телефона: Строгий стандарт `+7 XXX XXX XX XX` через `GtFormatters`.
    - Капитализация: Автоматическая через `TextCapitalization.words` в `GTTextField`.
    - Синхронизация: При обновлении профиля админом данные также обновляются в `company_members`.

10. **Интеграции:**
    - **FOT (Module):** Использование `EmployeeFinancialReportService` и `PayrollPdfService` для финансовой отчетности.
    - **RPC (Supabase):** `calculate_payroll_for_month` и `calculate_employee_balances_before_date`.
    - **Edge Functions:** Используются для обработки сложных изменений статуса (опционально).
    - **FCM:** Интеграция с системой уведомлений через `slot_times`.

11. **Roadmap:**
    - 🟢 Унификация UI полей ввода (Выполнено).
    - 🟢 Редизайн мобильного профиля (Выполнено).
    - 🟢 Единый стандарт телефонов (Выполнено).
    - 🟡 ТМЦ (В разработке).
    - 🔴 Оптимизация кэширования аватаров.

---

## Детальное описание модуля

Модуль **Profile** отвечает за управление профилями пользователей в системе: просмотр, редактирование, хранение и интеграцию с Supabase Auth. Поддерживает работу с ролями, объектами, аватарами, списком пользователей. Реализован по принципам Clean Architecture, с разделением на data/domain/presentation, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение профиля пользователя
- Редактирование профиля (ФИО, телефон, фото)
- Управление правами участников (роли, блокировка) через `company_members` (для Owner/Admin)
- Смена аватара через Supabase Storage
- Просмотр списка всех пользователей
- Просмотр выданного имущества (ТМЦ) — в разработке
- Интеграция с Supabase Auth и таблицами `profiles`, `company_members`
- Поддержка ролей (RBAC v3), RLS
- Адаптивный и минималистичный UI

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- RLS и безопасность на уровне БД
- UI в едином стиле Apple Settings: группированные меню с цветными иконками, iOS-подобные tap эффекты, минимализм
- **Мобильный UI:** Специализированный горизонтальный хедер с квадратным аватаром и инфо-блоком (ФИО, телефон, Email).

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/profile/presentation/screens/profile_screen.dart` — Экран просмотра и редактирования профиля пользователя. Адаптивный, поддерживает смену фото, мультивыбор объектов, доступен для admin и пользователя.
  - **Мобильная версия:** Без стандартного AppBar. Используются плавающие кнопки (меню/назад и тема) поверх контента. Горизонтальный блок с аватаром (radius 44, isSquare, 16px radius) и текстом. Шрифт телефона — 15, email — 14. В нижнем правом углу хедера отображается текущий баланс сотрудника (зеленый цвет, шрифт 10).
  - **Десктопная версия:** Центрированный вертикальный хедер "Профиль" с использованием `AppBarWidget`.
- `lib/features/profile/presentation/screens/financial_info_screen.dart` — Экран финансовой информации сотрудника.
  - **Функционал:** Отображение баланса, начислений за месяц, премий, штрафов и выплат.
  - **Технологии:** Использует RPC `calculate_payroll_for_month` для синхронизации расчетов с бухгалтерией (модуль ФОТ) и `payoutsByEmployeeAndMonthFIFOProvider` для корректного отображения выплат по методу FIFO.
  - **Технологии (Totals):** Использует обновленную RPC-функцию `calculate_employee_balances_before_date` (принимает `p_company_id`), которая возвращает `accruals_sum`, `payouts_sum` и `balance`.
  - **Отчетность:** Генерация PDF-отчета за год через `PayrollPdfService`. Данные собираются через `EmployeeFinancialReportService`, который учитывает как закрытые смены (`work_hours`), так и ручные записи в табеле (`employee_attendance`).
- `lib/features/profile/presentation/screens/notifications_settings_screen.dart` — Отдельный экран настройки уведомлений профиля.
- `lib/features/profile/presentation/screens/users_list_screen.dart` — Экран списка пользователей с поиском, фильтрацией и переходом к профилю.
- `lib/presentation/state/profile_state.dart` — StateNotifier и состояние профиля.

### Domain (бизнес-логика)
- `lib/domain/entities/profile.dart` — Доменная сущность профиля пользователя.
- `lib/domain/repositories/profile_repository.dart` — Абстракция репозитория.

### Data (работа с БД/Supabase)
- `lib/data/models/profile_model.dart` — Data-модель профиля.
- `lib/data/datasources/profile_data_source.dart` — Источник данных (Supabase).
- `lib/data/repositories/profile_repository_impl.dart` — Имплементация репозитория.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей.

---

## Связи и интеграции
- **Supabase:** таблицы `profiles`, `company_members`, `roles`, Supabase Auth, Supabase Storage (аватары)
- **RLS:** 
  - `profiles`: только владелец может обновлять свои ФИО/телефон.
  - `company_members`: только Владелец компании может обновлять роли и статус участников.
- **Объекты:** связь профиля с объектами через objectIds
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Форматирование:** Единый стандарт `+7 XXX XXX XX XX` реализован в `GtFormatters`.

---

## Изменения и актуализация (17.01.2026)
- **Финансовая отчетность:** Полностью переработана система формирования отчетов. Модуль Profile больше не содержит собственного сервиса генерации PDF (`financial_pdf_service.dart`), а использует общий `PayrollPdfService` из модуля ФОТ.
- **EmployeeFinancialReportService:** Данные для отчетов теперь собираются через централизованный сервис, что гарантирует учет всех видов отработанных часов (смены + табель).
- **RPC Расчеты:** На экране финансовой информации внедрены вызовы RPC для получения точных сумм начислений и баланса напрямую из БД.
- **Чистка кода:** Удалено более 400 строк дублирующего кода, связанного с расчетами и PDF.

---

## Изменения и актуализация (16.01.2026)
- **Аппбар (Mobile):** Удален стандартный `AppBarWidget`. Теперь кнопки управления плавают над контентом, что обеспечивает максимальный минимализм и акцент на хедере.
- **Унификация полей:** Все формы модуля переведены на `GTTextField`. Ручная капитализация удалена в пользу системной.
- **Редизайн Хедера:** В мобильной версии `ProfileScreen` внедрен горизонтальный макет.
- **PhotoPickerAvatar:** Расширен функционал виджета — теперь он поддерживает квадратные формы и опциональный оверлей камеры.
- **Телефоны:** Введен строгий стандарт форматирования во всем приложении через `formatPhone`.

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- **Управление доступом (RBAC v3):** Роль, системный статус и статус активности управляются в `company_members`.
- **ТМЦ:** Статус **в разработке**. Пункт меню активен, ведет на экран-заглушку с описанием.