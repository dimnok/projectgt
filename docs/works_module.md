# Модуль Works (Смены)

---

## Просмотр и управление фотографиями смены (UI)

- Полноэкранный просмотр фотографий:
  - Заголовок отображает тип фото и время загрузки: "Фото на начало смены • HH:mm" или "Фото на конец смены • HH:mm".
  - Добавлена кнопка возврата назад (Back), которая возвращает к предыдущему экрану.
  - Доступна кнопка «Редактировать» только для автора открытой смены (см. Правила доступа).

- Замена фото (только автор открытой смены):
  - При нажатии «Редактировать» открывается нижнее модальное окно выбора источника с круглыми кнопками:
    - Камера
    - Галерея
  - Дизайн совпадает со стилем добавления вечернего фото (круглые кнопки).
  - После выбора источник → загрузка в Supabase Storage (bucket `works`, папка по `object_id`).
  - Имена файлов фото содержат timestamp и тип (`morning`/`evening`): `YYYY-MM-DD_HH-mm-ss_morning.jpg`.
  - После успешной загрузки обновляется запись `works.photo_url` или `works.evening_photo_url` и UI.

- Отображение времени:
  - На карточках фото (в списке) справа в заголовке показывается время загрузки фото в формате `HH:mm`.
  - Время извлекается из имени файла URL (парсинг по шаблону `YYYY-MM-DD_HH-mm-ss_*`).

Ссылки на реализацию:
- `lib/features/works/presentation/widgets/work_photo_view.dart`
- Сервис загрузки: `lib/core/services/photo_service.dart`
- Обновление смен: `lib/features/works/presentation/providers/work_provider.dart`

Безопасность/доступ:
- Замена фото доступна только владельцу открытой смены (UI-проверка + рекомендуется RLS/Storage политики на сервере).

---

## Детальное описание модуля

Модуль **Works** отвечает за управление сменами на строительных объектах: создание, просмотр, редактирование, удаление смен, а также учёт работ, материалов и отработанных часов сотрудников в рамках смены. Поддерживает мастер-детейл UI, фильтрацию, интеграцию с объектами, сметами, сотрудниками и Supabase. Реализован по принципам Clean Architecture с разделением на data/domain/presentation/features, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение списка смен
- Детальный просмотр и редактирование смены (работы, материалы, часы)
- Создание, редактирование, удаление смены
- Учёт работ, материалов, часов сотрудников в смене
- Фильтрация, поиск, группировка по объекту, статусу, системе, участку
- Интеграция с объектами, сметами, сотрудниками
- Адаптивный и минималистичный UI
- Валидация и обработка ошибок
- Интеграция с Supabase (таблицы works, work_items, work_materials, work_hours, RLS)

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation/features
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- Иммутабельные модели, строгая типизация
- Вся работа с БД — через Supabase DataSource
- RLS и безопасность на уровне БД

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/works/presentation/screens/works_master_detail_screen.dart` — Главный экран списка смен (мастер-детейл, поиск, фильтрация, адаптивность).
- `lib/features/works/presentation/screens/work_details_screen.dart` — Экран детального просмотра смены (информация, действия, переход к деталям).
- `lib/features/works/presentation/screens/work_details_panel.dart` — Панель с вкладками: работы, материалы, часы; фильтрация, редактирование.
- `lib/features/works/presentation/screens/work_item_form_modal.dart` — Модальное окно для добавления/редактирования работы в смене.
- `lib/features/works/presentation/screens/work_hour_form_modal.dart` — Модальное окно для добавления/редактирования часов сотрудника.
- `lib/features/works/presentation/screens/work_material_form_modal.dart` — Модальное окно для добавления/редактирования материала.
- `lib/features/works/presentation/widgets/work_photo_view.dart` — Виджет для отображения фотографий смены (утро/вечер, Supabase Storage).
- `lib/features/works/presentation/providers/work_provider.dart` — StateNotifier и провайдер состояния списка смен.
- `lib/features/works/presentation/providers/work_items_provider.dart` — StateNotifier и провайдер работ в смене.
- `lib/features/works/presentation/providers/work_hours_provider.dart` — StateNotifier и провайдер учёта часов.
- `lib/features/works/presentation/providers/work_materials_provider.dart` — StateNotifier и провайдер учёта материалов.
- `lib/features/works/presentation/providers/repositories_providers.dart` — Провайдеры для инициализации репозиториев.

### Domain (бизнес-логика)
- `lib/features/works/domain/entities/work.dart` — Доменная сущность смены (Freezed).
- `lib/features/works/domain/entities/work_item.dart` — Доменная сущность работы в смене (Freezed).
- `lib/features/works/domain/entities/work_hour.dart` — Доменная сущность учёта часов (Freezed).
- `lib/features/works/domain/entities/work_material.dart` — Доменная сущность материала (Freezed).
- `lib/features/works/domain/repositories/work_repository.dart` — Абстракция репозитория смен.
- `lib/features/works/domain/repositories/work_item_repository.dart` — Абстракция репозитория работ.
- `lib/features/works/domain/repositories/work_hour_repository.dart` — Абстракция репозитория часов.
- `lib/features/works/domain/repositories/work_material_repository.dart` — Абстракция репозитория материалов.

### Data (работа с БД/Supabase)
- `lib/features/works/data/models/work_model.dart` — Data-модель смены для сериализации/десериализации.
- `lib/features/works/data/models/work_item_model.dart` — Data-модель работы в смене.
- `lib/features/works/data/models/work_hour_model.dart` — Data-модель учёта часов.
- `lib/features/works/data/models/work_material_model.dart` — Data-модель материала.
- `lib/features/works/data/datasources/work_data_source.dart` — Абстракция источника данных для смен.
- `lib/features/works/data/datasources/work_data_source_impl.dart` — Реализация источника данных для смен (Supabase).
- `lib/features/works/data/datasources/work_item_data_source.dart` — Абстракция источника данных для работ.
- `lib/features/works/data/datasources/work_item_data_source_impl.dart` — Реализация источника данных для работ.
- `lib/features/works/data/datasources/work_hour_data_source.dart` — Абстракция источника данных для часов.
- `lib/features/works/data/datasources/work_hour_data_source_impl.dart` — Реализация источника данных для часов.
- `lib/features/works/data/datasources/work_material_data_source.dart` — Абстракция источника данных для материалов.
- `lib/features/works/data/datasources/work_material_data_source_impl.dart` — Реализация источника данных для материалов.
- `lib/features/works/data/repositories/work_repository_impl.dart` — Имплементация репозитория смен.
- `lib/features/works/data/repositories/work_item_repository_impl.dart` — Имплементация репозитория работ.
- `lib/features/works/data/repositories/work_hour_repository_impl.dart` — Имплементация репозитория часов.
- `lib/features/works/data/repositories/work_material_repository_impl.dart` — Имплементация репозитория материалов.
- `lib/data/migrations/works_migration.sql` — SQL-миграция для создания и настройки таблиц смен, работ, материалов, часов, RLS, индексы.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, провайдеры состояния.
- `lib/core/services/photo_service.dart` — Сервис для работы с фотографиями через Supabase Storage.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── works/
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── works_master_detail_screen.dart
│       │   │   ├── work_details_screen.dart
│       │   │   ├── work_details_panel.dart
│       │   │   ├── work_item_form_modal.dart
│       │   │   ├── work_hour_form_modal.dart
│       │   │   └── work_material_form_modal.dart
│       │   ├── widgets/
│       │   │   └── work_photo_view.dart
│       │   └── providers/
│       │       ├── work_provider.dart
│       │       ├── work_items_provider.dart
│       │       ├── work_hours_provider.dart
│       │       ├── work_materials_provider.dart
│       │       └── repositories_providers.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── work.dart
│       │   │   ├── work_item.dart
│       │   │   ├── work_hour.dart
│       │   │   └── work_material.dart
│       │   └── repositories/
│       │       ├── work_repository.dart
│       │       ├── work_item_repository.dart
│       │       ├── work_hour_repository.dart
│       │       └── work_material_repository.dart
│       └── data/
│           ├── models/
│           │   ├── work_model.dart
│           │   ├── work_item_model.dart
│           │   ├── work_hour_model.dart
│           │   └── work_material_model.dart
│           ├── datasources/
│           │   ├── work_data_source.dart
│           │   ├── work_data_source_impl.dart
│           │   ├── work_item_data_source.dart
│           │   ├── work_item_data_source_impl.dart
│           │   ├── work_hour_data_source.dart
│           │   ├── work_hour_data_source_impl.dart
│           │   ├── work_material_data_source.dart
│           │   └── work_material_data_source_impl.dart
│           └── repositories/
│               ├── work_repository_impl.dart
│               ├── work_item_repository_impl.dart
│               ├── work_hour_repository_impl.dart
│               └── work_material_repository_impl.dart
├── data/
│   └── migrations/
│       └── works_migration.sql
├── core/
│   ├── di/
│   │   └── providers.dart
│   └── services/
│       └── photo_service.dart
```

---

## Связи и интеграции
- **Supabase:** таблицы works, work_items, work_materials, work_hours; связь с объектами (object_id), сметами (estimate_id), сотрудниками (employee_id)
- **RLS:** только участники объекта или админ могут видеть/редактировать смены и связанные сущности
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Валидация:** все формы используют встроенную валидацию и обработку ошибок
- **Доступность:** поддержка Semantics, адаптивность, alt text

---

## Правила доступа и редактирования (UI)

- Только автор открытой смены (opened_by = текущий пользователь, статус = `open`) может:
  - редактировать/удалять смену;
  - добавлять/редактировать/удалять работы и часы;
  - загружать/удалять вечернее фото;
  - закрывать смену.
- Остальные пользователи видят данные смены в режиме только чтения (действия недоступны).

Техническая реализация (клиент):
- Проверка права на модификацию через флаг `canModify = isOwner && status == 'open'`.
- Применено в:
  - `lib/features/works/presentation/screens/work_details_screen.dart` — показ кнопок "Редактировать/Удалить" только при `canModify`;
  - `lib/features/works/presentation/screens/work_details_panel.dart` — отключение свайпов/редактирования и скрытие FAB на вкладках работ и часов при отсутствии `canModify`;
  - кнопка "Добавить вечернее фото" активна только при `canModify`; прямой вызов загрузки вечернего фото также защищён дополнительной проверкой внутри обработчика.

Рекомендации по серверной стороне (БД/Storage):
- RLS для таблицы `works`: ограничить `UPDATE` полей смены (включая `evening_photo_url`) владельцу открытой смены и/или админу.
- RLS/политики Storage (bucket `works`): ограничить `upload/remove` файлов смен только участникам с правами на объект/смену.

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблиц модуля works

### Таблица `works`
| Колонка           | Тип         | Описание                                      |
|-------------------|-------------|-----------------------------------------------|
| id                | UUID, PK    | Уникальный идентификатор смены                |
| date              | DATE        | Дата смены                                    |
| object_id         | UUID        | Внешний ключ на objects.id                    |
| opened_by         | UUID        | Внешний ключ на profiles.id (кто открыл смену)|
| status            | TEXT        | Статус смены (`open`, `draft`, `closed`)      |
| photo_url         | TEXT        | URL фотографии смены (утро)                   |
| evening_photo_url | TEXT        | URL фотографии смены (вечер)                  |
| created_at        | TIMESTAMP   | Дата и время создания записи                  |
| updated_at        | TIMESTAMP   | Дата и время последнего обновления            |

### Таблица `work_items`
| Колонка         | Тип         | Описание                                      |
|-----------------|-------------|-----------------------------------------------|
| id              | UUID, PK    | Уникальный идентификатор работы               |
| work_id         | UUID        | Внешний ключ на works.id                     |
| section         | TEXT        | Секция                                       |
| floor           | TEXT        | Этаж                                         |
| estimate_id     | UUID        | Внешний ключ на estimates.id                 |
| name            | TEXT        | Наименование работы                          |
| system          | TEXT        | Система                                      |
| subsystem       | TEXT        | Подсистема                                   |
| unit            | TEXT        | Единица измерения                            |
| quantity        | NUMERIC     | Количество                                   |
| price           | DOUBLE      | Цена за единицу                              |
| total           | DOUBLE      | Итоговая сумма                               |
| created_at      | TIMESTAMP   | Дата и время создания записи                 |
| updated_at      | TIMESTAMP   | Дата и время последнего обновления           |

### Таблица `work_materials`
| Колонка         | Тип         | Описание                                      |
|-----------------|-------------|-----------------------------------------------|
| id              | UUID, PK    | Уникальный идентификатор материала            |
| work_id         | UUID        | Внешний ключ на works.id                     |
| name            | TEXT        | Наименование материала                       |
| unit            | TEXT        | Единица измерения                            |
| quantity        | NUMERIC     | Количество                                   |
| comment         | TEXT        | Комментарий                                  |
| created_at      | TIMESTAMP   | Дата и время создания записи                 |
| updated_at      | TIMESTAMP   | Дата и время последнего обновления           |

### Таблица `work_hours`
| Колонка         | Тип         | Описание                                      |
|-----------------|-------------|-----------------------------------------------|
| id              | UUID, PK    | Уникальный идентификатор записи о часах       |
| work_id         | UUID        | Внешний ключ на works.id                     |
| employee_id     | UUID        | Внешний ключ на employees.id                 |
| hours           | NUMERIC     | Количество отработанных часов                |
| comment         | TEXT        | Комментарий                                  |
| created_at      | TIMESTAMP   | Дата и время создания записи                 |
| updated_at      | TIMESTAMP   | Дата и время последнего обновления           |

**RLS-политики:**
- `works`: только участники объекта или админ могут видеть/редактировать
- `work_items`, `work_materials`, `work_hours`: только участники смены или админ могут видеть/редактировать
- Индексы: по work_id, employee_id, статусу

--- 