# Модуль Estimates (Сметы)

---

## Детальное описание модуля

Модуль **Estimates** отвечает за управление сметами: создание, просмотр, редактирование, удаление, импорт и экспорт позиций сметы, интеграцию с объектами, договорами и Supabase. Поддерживает работу с Excel, группировку, фильтрацию, детальный просмотр и редактирование позиций. Реализован по принципам Clean Architecture с разделением на data/domain/presentation/features, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение списка смет
- Детальный просмотр и редактирование позиций сметы (PlutoGrid)
- Импорт и экспорт смет через Excel
- Создание, редактирование, удаление сметы
- Фильтрация, поиск, группировка по объекту, договору, системе
- Интеграция с объектами и договорами
- Адаптивный и минималистичный UI
- Валидация и обработка ошибок
- Интеграция с Supabase (таблица estimates, RLS)

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
- `lib/features/estimates/presentation/screens/estimates_list_screen.dart` — Экран списка смет: просмотр, фильтрация, экспорт/импорт, переход к деталям.
- `lib/features/estimates/presentation/screens/estimate_details_screen.dart` — Экран детального просмотра и редактирования позиций сметы (PlutoGrid).
- `lib/features/estimates/presentation/screens/estimate_form_screen.dart` — Экран создания/редактирования сметы.
- `lib/features/estimates/presentation/screens/import_estimate_form_modal.dart` — Модальное окно для импорта сметы из Excel, предпросмотр, парсинг.
- `lib/features/estimates/presentation/widgets/estimate_item_card.dart` — Виджет карточки позиции сметы для списка/деталей.
- `lib/presentation/state/estimate_state.dart` — StateNotifier и состояние смет: хранит список, выбранную смету, статусы загрузки, ошибки.

### Domain (бизнес-логика)
- `lib/domain/entities/estimate.dart` — Доменная сущность сметы (Freezed), отражает структуру таблицы estimates.
- `lib/domain/repositories/estimate_repository.dart` — Абстракция репозитория для DI и тестирования.
- `lib/domain/usecases/estimate/get_estimate_usecase.dart` — UseCase для получения сметы по id.
- `lib/domain/usecases/estimate/get_estimates_usecase.dart` — UseCase для получения списка смет.
- `lib/domain/usecases/estimate/create_estimate_usecase.dart` — UseCase для создания сметы.
- `lib/domain/usecases/estimate/update_estimate_usecase.dart` — UseCase для обновления сметы.
- `lib/domain/usecases/estimate/delete_estimate_usecase.dart` — UseCase для удаления сметы.

### Data (работа с БД/Supabase)
- `lib/data/models/estimate_model.dart` — Data-модель сметы для сериализации/десериализации, преобразование в доменную модель.
- `lib/data/models/estimate_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/data/models/estimate_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/data/datasources/estimate_data_source.dart` — Абстракция и реализация источника данных для смет (Supabase).
- `lib/data/repositories/estimate_repository_impl.dart` — Имплементация репозитория: преобразует модели, делегирует data source.
- `lib/data/services/excel_estimate_service.dart` — Сервис для генерации и парсинга Excel-файлов смет.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, usecase, провайдер состояния.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── estimates/
│       └── presentation/
│           ├── screens/
│           │   ├── estimates_list_screen.dart
│           │   ├── estimate_details_screen.dart
│           │   ├── estimate_form_screen.dart
│           │   └── import_estimate_form_modal.dart
│           └── widgets/
│               └── estimate_item_card.dart
├── presentation/
│   └── state/
│       └── estimate_state.dart
├── domain/
│   ├── entities/
│   │   └── estimate.dart
│   ├── repositories/
│   │   └── estimate_repository.dart
│   └── usecases/
│       └── estimate/
│           ├── get_estimate_usecase.dart
│           ├── get_estimates_usecase.dart
│           ├── create_estimate_usecase.dart
│           ├── update_estimate_usecase.dart
│           └── delete_estimate_usecase.dart
├── data/
│   ├── models/
│   │   ├── estimate_model.dart
│   │   ├── estimate_model.g.dart
│   │   └── estimate_model.freezed.dart
│   ├── datasources/
│   │   └── estimate_data_source.dart
│   ├── repositories/
│   │   └── estimate_repository_impl.dart
│   └── services/
│       └── excel_estimate_service.dart
└── core/
    └── di/
        └── providers.dart
```

---

## Связи и интеграции
- **Supabase:** таблица estimates, связь с объектами (object_id), договорами (contract_id), интеграция с импортом/экспортом Excel
- **RLS:** только участники объекта или админ могут видеть/редактировать сметы
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Импорт/экспорт:** поддержка Excel (xlsx), предпросмотр, парсинг, экспорт
- **Доступность:** поддержка Semantics, адаптивность, alt text

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблицы `estimates`

| Колонка        | Тип         | Описание                                                        |
|----------------|-------------|-----------------------------------------------------------------|
| id             | UUID, PK    | Уникальный идентификатор сметы                                  |
| contract_id    | UUID        | Внешний ключ на contracts.id                                    |
| object_id      | UUID        | Внешний ключ на objects.id                                      |
| system         | TEXT        | Система (например, электрика)                                   |
| subsystem      | TEXT        | Подсистема                                                      |
| name           | TEXT        | Наименование позиции                                            |
| article        | TEXT        | Артикул                                                         |
| manufacturer   | TEXT        | Производитель                                                   |
| unit           | TEXT        | Единица измерения                                               |
| quantity       | DOUBLE      | Количество                                                      |
| price          | DOUBLE      | Цена за единицу                                                 |
| total          | DOUBLE      | Итоговая сумма                                                  |
| created_at     | TIMESTAMP   | Дата и время создания записи                                    |
| updated_at     | TIMESTAMP   | Дата и время последнего обновления записи                       |
| estimate_title | TEXT        | Заголовок сметы                                                 |
| number         | TEXT        | Номер сметы                                                     |

**Связи:**
- contract_id → contracts.id (FK)
- object_id → objects.id (FK)
- id → work_items.estimate_id (FK)

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать 