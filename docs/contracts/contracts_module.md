# Модуль Contracts (Договоры)

---

## Детальное описание модуля

Модуль **Contracts** отвечает за управление договорами с контрагентами по объектам: создание, просмотр, редактирование, удаление, фильтрация и поиск. Позволяет фиксировать номер, даты, сумму, статус, связь с объектом и контрагентом. Реализован по принципам Clean Architecture с разделением на data/domain/presentation/features, DI через Riverpod, строгой типизацией и поддержкой тестируемости.

**Ключевые функции:**
- Получение и отображение списка договоров (мастер-детейл, поиск, фильтрация)
- Создание нового договора
- Редактирование существующего договора
- Удаление договора
- Просмотр деталей договора (в т.ч. связанные объект и контрагент)
- Адаптивный UI (desktop/mobile)
- Валидация и обработка ошибок
- Интеграция с Supabase (таблица contracts, join contractors/objects)

**Архитектурные особенности:**
- Clean Architecture: разделение на data/domain/presentation/features
- DI через Riverpod
- Freezed/JsonSerializable для моделей
- Все зависимости регистрируются в core/di/providers.dart
- Иммутабельные модели, строгая типизация
- Вся работа с БД — через Supabase DataSource

---

## Структура и файлы модуля

### Presentation/UI
- `lib/features/contracts/presentation/screens/contracts_list_screen.dart` — Экран списка договоров: мастер-детейл, поиск, фильтрация, детали, модальные окна.
- `lib/features/contracts/presentation/screens/contract_details_screen.dart` — Экран подробной информации о договоре.
- `lib/features/contracts/presentation/screens/contract_form_screen.dart` — Экран формы создания/редактирования договора: валидация, адаптивность, обработка ошибок.
- `lib/features/contracts/presentation/screens/contract_form_content.dart` — Stateless-контент формы договора для переиспользования в разных сценариях (модальное окно, отдельный экран).
- `lib/presentation/state/contract_state.dart` — StateNotifier и состояние договоров: хранит список, выбранный договор, статусы загрузки, ошибки. Управляет логикой загрузки/обновления/удаления.

### Domain (бизнес-логика)
- `lib/domain/entities/contract.dart` — Доменная сущность договора (Freezed), отражает структуру таблицы contracts.
- `lib/domain/repositories/contract_repository.dart` — Абстракция репозитория для DI и тестирования.
- `lib/domain/usecases/contract/get_contracts_usecase.dart` — UseCase для получения списка договоров.
- `lib/domain/usecases/contract/get_contract_usecase.dart` — UseCase для получения одного договора по id.
- `lib/domain/usecases/contract/create_contract_usecase.dart` — UseCase для создания договора.
- `lib/domain/usecases/contract/update_contract_usecase.dart` — UseCase для обновления договора.
- `lib/domain/usecases/contract/delete_contract_usecase.dart` — UseCase для удаления договора.

### Data (работа с БД/Supabase)
- `lib/data/models/contract_model.dart` — Data-модель договора для сериализации/десериализации, преобразование в доменную модель.
- `lib/data/models/contract_model.g.dart` — Автогенерируемый файл сериализации (json_serializable).
- `lib/data/models/contract_model.freezed.dart` — Автогенерируемый файл иммутабельности (Freezed).
- `lib/data/datasources/contract_data_source.dart` — Абстракция и реализация источника данных для договоров (Supabase, join contractors/objects).
- `lib/data/repositories/contract_repository_impl.dart` — Имплементация репозитория: преобразует модели, делегирует data source.

### DI/Providers
- `lib/core/di/providers.dart` — Регистрация всех зависимостей: data source, репозиторий, usecase, провайдер состояния.

---

## Дерево структуры модуля

```
lib/
├── features/
│   └── contracts/
│       └── presentation/
│           └── screens/
│               ├── contracts_list_screen.dart
│               ├── contract_details_screen.dart
│               ├── contract_form_screen.dart
│               └── contract_form_content.dart
├── presentation/
│   └── state/
│       └── contract_state.dart
├── domain/
│   ├── entities/
│   │   └── contract.dart
│   ├── repositories/
│   │   └── contract_repository.dart
│   └── usecases/
│       └── contract/
│           ├── get_contracts_usecase.dart
│           ├── get_contract_usecase.dart
│           ├── create_contract_usecase.dart
│           ├── update_contract_usecase.dart
│           └── delete_contract_usecase.dart
├── data/
│   ├── models/
│   │   ├── contract_model.dart
│   │   ├── contract_model.g.dart
│   │   └── contract_model.freezed.dart
│   ├── datasources/
│   │   └── contract_data_source.dart
│   └── repositories/
│       └── contract_repository_impl.dart
└── core/
    └── di/
        └── providers.dart
```

---

## Связи и интеграции
- **Supabase:** таблица contracts, join с contractors и objects, связь с estimates (по contract_id)
- **UI:** интеграция с общими виджетами, темами, роутингом (go_router)
- **Валидация:** все формы используют встроенную валидацию и обработку ошибок
- **Доступность:** поддержка Semantics, адаптивность, alt text

---

## Примечания
- Все файлы снабжены подробными комментариями и поддерживают строгую типизацию.
- Модуль легко расширяется и тестируется благодаря архитектуре и DI.
- Для актуализации — обновлять структуру при изменениях в БД или бизнес-логике.

---

## Структура таблицы `contracts`

| Колонка        | Тип         | Описание                                                        |
|----------------|-------------|-----------------------------------------------------------------|
| id             | UUID, PK    | Уникальный идентификатор договора                               |
| number         | TEXT        | Номер договора                                                  |
| date           | DATE        | Дата заключения договора                                        |
| end_date       | DATE        | Дата окончания действия договора                                |
| contractor_id  | UUID        | Внешний ключ на contractors.id                                  |
| amount         | NUMERIC     | Сумма по договору                                               |
| object_id      | UUID        | Внешний ключ на objects.id                                      |
| status         | TEXT        | Статус договора (`active`, `suspended`, `completed`)            |
| created_at     | TIMESTAMP   | Дата и время создания записи                                    |
| updated_at     | TIMESTAMP   | Дата и время последнего обновления записи                       |

**Связи:**
- contractor_id → contractors.id (FK)
- object_id → objects.id (FK)
- id → estimates.contract_id (FK)

**RLS-политики:**
- Только участники объекта или админ могут видеть/редактировать

--- 