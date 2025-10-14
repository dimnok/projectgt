# Модуль Profile (Профиль пользователя)

---

## Детальное описание модуля

Модуль **Profile** отвечает за управление профилями пользователей в системе: просмотр, редактирование, хранение и интеграцию с Supabase Auth. Поддерживает работу с ролями, объектами, аватарами, списком пользователей. Реализован по принципам Clean Architecture, с разделением на data/domain/presentation, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение профиля пользователя
- Редактирование профиля (ФИО, телефон, объекты, фото)
- Смена аватара через Supabase Storage
- Просмотр списка всех пользователей
- Интеграция с Supabase Auth и таблицей profiles
- Поддержка ролей (user/admin), RLS
- Адаптивный и минималистичный UI

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- RLS и безопасность на уровне БД
- UI в едином стиле Apple Settings: группированные меню с цветными иконками, iOS-подобные tap эффекты, минимализм

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/profile/presentation/screens/profile_screen.dart` — Экран просмотра и редактирования профиля пользователя. Адаптивный, поддерживает смену фото, мультивыбор объектов, доступен для admin и пользователя. Выполнен в стиле Apple Settings с группами меню (_AppleMenuGroup) и элементами (_AppleMenuItem). Действия "Редактировать профиль" и "Выйти из аккаунта" реализованы как стандартные пункты меню в отдельной группе.
- `lib/features/profile/presentation/screens/notifications_settings_screen.dart` — Отдельный экран настройки уведомлений профиля.
  - Главный тумблер вкл/выкл уведомлений. При выключении настройки времени скрыты.
  - Три независимых слота уведомлений ("Уведомление 1/2/3"), каждый можно отключить.
  - Время слота выбирается из выпадающего списка (шаг 30 минут). Поддерживаются сохранённые нестандартные значения (добавляются в список опций).
  - Сохранение записывает включённые времена в `profile.object.slot_times` (или удаляет ключ при полном отключении).
- `lib/features/profile/presentation/screens/users_list_screen.dart` — Экран списка пользователей с поиском, фильтрацией и переходом к профилю.
- `lib/presentation/state/profile_state.dart` — StateNotifier и состояние профиля: хранит текущий профиль, список профилей, статусы загрузки, ошибки. Управляет логикой загрузки/обновления.

### Domain (бизнес-логика)
- `lib/domain/entities/profile.dart` — Доменная сущность профиля пользователя (Freezed), отражает структуру таблицы profiles.
- `lib/domain/repositories/profile_repository.dart` — Абстракция репозитория для DI и тестирования.
- `lib/domain/usecases/profile/get_profile_usecase.dart` — UseCase для получения профиля по id.
- `lib/domain/usecases/profile/get_profiles_usecase.dart` — UseCase для получения списка всех профилей.
- `lib/domain/usecases/profile/update_profile_usecase.dart` — UseCase для обновления профиля.

### Data (работа с БД/Supabase)
- `lib/data/models/profile_model.dart` — Data-модель профиля для сериализации/десериализации, преобразование в доменную модель.
- `lib/data/models/profile_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/data/models/profile_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/data/datasources/profile_data_source.dart` — Абстракция и реализация источника данных для профиля (Supabase).
- `lib/data/repositories/profile_repository_impl.dart` — Имплементация репозитория: преобразует модели, делегирует data source.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, usecase, провайдер состояния.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── profile/
│       └── presentation/
│           └── screens/
│               ├── profile_screen.dart
│               └── users_list_screen.dart
├── presentation/
│   └── state/
│       └── profile_state.dart
├── domain/
│   ├── entities/
│   │   └── profile.dart
│   ├── repositories/
│   │   └── profile_repository.dart
│   └── usecases/
│       └── profile/
│           ├── get_profile_usecase.dart
│           ├── get_profiles_usecase.dart
│           └── update_profile_usecase.dart
├── data/
│   ├── models/
│   │   ├── profile_model.dart
│   │   ├── profile_model.g.dart
│   │   └── profile_model.freezed.dart
│   ├── datasources/
│   │   └── profile_data_source.dart
│   └── repositories/
│       └── profile_repository_impl.dart
└── core/
    └── di/
        └── providers.dart
```

---

## Связи и интеграции
- **Supabase:** таблица profiles, Supabase Auth, Supabase Storage (аватары)
- **RLS:** только владелец или админ может читать/обновлять профиль
- **Объекты:** связь профиля с объектами через objectIds
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)

## Изменения по уведомлениям (актуализация)
- Настройки времени уведомлений вынесены из модального редактирования профиля на отдельный экран `notifications_settings_screen.dart`.
- В профиле добавлен контейнер "Уведомления" под картой "Личная информация" для навигации.
- Обновлена логика хранения: используется `profile.object.slot_times` как массив строк времени HH:mm; при отключении главного тумблера ключ удаляется.
- В модальном редактировании профиля удалены поля настройки времени.

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблицы `profiles`

| Колонка      | Тип         | Описание                                                        |
|--------------|-------------|-----------------------------------------------------------------|
| id           | UUID, PK    | Уникальный идентификатор профиля, связь с auth.users            |
| full_name    | TEXT        | Полное ФИО пользователя                                         |
| short_name   | TEXT        | Сокращённое ФИО (например, инициалы)                            |
| photo_url    | TEXT        | URL фотографии/аватара пользователя                             |
| email        | TEXT        | Email пользователя (уникальный)                                 |
| phone        | TEXT        | Номер телефона в формате +7-(XXX)-XXX-XXXX                      |
| role         | TEXT        | Роль пользователя в системе (`user`, `admin`)                   |
| status       | BOOLEAN     | Статус активности (true — активен, false — неактивен)           |
| object       | JSONB       | JSON-объект для хранения дополнительных данных                  |
| object_ids   | ARRAY(UUID) | Список id объектов, связанных с профилем пользователя           |
| created_at   | TIMESTAMP   | Дата и время создания записи (UTC)                              |
| updated_at   | TIMESTAMP   | Дата и время последнего обновления записи (UTC)                 |

**Связи:**
- id → auth.users.id (FK)
- object_ids → objects.id (FK)
- opened_by (в works) → profiles.id (FK)

**RLS-политики:**
- Только владелец или админ может читать/обновлять свой профиль 