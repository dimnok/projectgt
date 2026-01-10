# Модуль Objects (Объекты)

**Дата последнего обновления:** 09.01.2026 (RBAC Fix & Error Handling)
**Версия:** 1.5.2

### Список изменений
- **RBAC Fix for Company Owners:**
    *   Исправлена критическая ошибка доступа: владельцы компании (`is_owner = true`) теперь имеют полный доступ ко всем операциям модуля, даже если им не назначена конкретная роль в `company_members`.
    *   Обновлена SQL-функция `check_permission` для автоматического предоставления прав владельцам активной компании.
- **Improved Form Error Handling:**
    *   Внедрена расширенная обработка ошибок в `ObjectFormModal`. Теперь форма не закрывается при возникновении ошибки на стороне БД, а отображает понятное уведомление (SnackBar).
    *   Добавлена проверка `ObjectStatus.error` после выполнения асинхронных операций `addObject` и `updateObject`.
- **Desktop UI Polish:**
    *   Унифицировано поведение уведомлений: на десктопе теперь корректно отображается Snackbar при успешном создании или обновлении объекта (ранее колбэк `onSuccess` был пустым).
- **Mobile UI Adaptive Layout:**
    *   Реализована адаптивная верстка разделов информации: на мобильных устройствах подписи располагаются над значениями (вертикально), на десктопе — сбоку (горизонтально).
    *   Это устраняет проблему «пустых мест» под короткими подписями и дает больше пространства для длинных значений (например, кадастровых номеров в адресе).
    *   Оптимизирован хедер мобильной версии: длинные адреса скрываются из верхней части, если они представлены в детальном списке ниже.
- **UI Unification with Contractors:**
    *   Отображение деталей объекта приведено к единому стандарту с модулем контрагентов.
    *   Внедрен `ObjectAvatar` и `ObjectHelper` для унификации иконок и цветов.
    *   Обновлен дизайн `ObjectDetailsPanel` и `ObjectDetailsView` (центрированный заголовок с аватаром на мобильных, лаконичный заголовок на десктопе).
- **Code Consolidation & DRY:**
    *   Удалены дублирующие файлы `object_details_widgets.dart` и `object_dialogs.dart`.
    *   Все вспомогательные компоненты (Avatar, Sections, InfoRow, Dialogs, Helper) консолидированы в `object_list_shared.dart` по аналогии с модулем контрагентов.
- **Desktop & Mobile View Unification:**
    *   Реализовано разделение на `ObjectsListDesktopView` и `ObjectsListMobileView` по аналогии с модулем контрагентов.
    *   Внедрен двухпанельный интерфейс для Desktop (Master-Detail).
- **Total Presentation Refactoring:** 
    - Объем файла `ObjectsListScreen` сокращен за счет выноса логики в платформенные View.
    - Внедрена чистая архитектура в UI-слое: разделение на платформенные компоненты.
- **Action Consolidation & Action Unification:**
    - Создан единый контроллер `ObjectActions` для инкапсуляции бизнес-логики редактирования и удаления (устранение дублей).
    - Унифицирован UI кнопок действий через `ObjectAppBarActions`, обеспечивающий идентичное поведение и проверку прав (`PermissionGuard`) во всем модуле.
- **Multi-tenancy:** Модуль полностью интегрирован в многопользовательскую среду. Добавлена изоляция данных по `company_id` на уровне БД (RLS) и в приложении.

---

## Важное замечание
Модуль является центральным реестром (справочником) объектов. Изменения в структуре данных объектов требуют синхронизации с модулями `Employees`, `Estimates`, `Works` и `Cash Flow`. Вся работа ведется в контексте активной компании (`company_id`).

---

## Описание
Модуль **Objects** предназначен для управления строительными объектами. Объект является ключевой аналитической единицей, к которой привязываются сотрудники, сметы, фактически выполненные работы и финансовые транзакции. Все данные изолированы на уровне компаний.

**Ключевые функции:**
- Просмотр списка объектов (адаптивная верстка Master-Detail, фильтрация по активной компании).
- Создание и редактирование объектов (наименование, адрес, описание) с автоматической привязкой к текущей компании.
- Удаление объектов (с проверкой прав доступа и принадлежности компании).
- Фильтрация и поиск (на стороне UI).

---

## Зависимости
### Таблицы модуля (owner)
- `objects` — хранение основной информации об объектах. Содержит обязательное поле `company_id`.

### Таблицы других модулей (usage)
- `companies` — родительская сущность для всех объектов.
- `profiles` — связь пользователей с объектами через массив `object_ids`.
- `works` — привязка рабочих смен к конкретному объекту (`object_id`).
- `estimates` — привязка сметной документации к объекту.
- `cash_flow` — аналитика платежей в разрезе объектов.

---

## Слой Presentation
### Экраны
- `ObjectsListScreen` — основной экран со списком объектов. Использует платформенные View.
- `ObjectsListDesktopView` — двухпанельный интерфейс для десктопа.
- `ObjectsListMobileView` — список объектов для мобильных устройств.
- `_ObjectDetailsScreen` — (private) экран детальной информации для мобильных устройств, использующий `ObjectDetailsView`.
- `ObjectFormScreen` — отдельный экран формы для сценариев, где не подходят модальные окна.

### Виджеты (Module UI)
- `ObjectListItemDesktop` — строка списка для десктопа.
- `ObjectRowItemMobile` — карточка списка для мобильных устройств.
- `ObjectDetailsPanel` — правая панель деталей для десктопа.
- `ObjectDetailsView` — композиция заголовка и детальной информации (мобильная версия).
- `ObjectFormModal` — интеллектуальное модальное окно формы.
- `ObjectFormContent` — компонент формы (только поля ввода).
- `ObjectActions` — статический контроллер бизнес-логики действий.
- `ObjectAppBarActions` — унифицированные кнопки действий (Edit/Delete) для AppBar.
- `ObjectAvatar` — унифицированный виджет иконки/аватара объекта.
- `ObjectDetailsSections` — консолидированный виджет всех разделов информации.

### Дизайн-система (Core)
- `GTConfirmationDialog` — используется для подтверждения деструктивных действий.
- `DesktopDialogContent` / `MobileBottomSheetContent` — базовые обертки модальных окон.
- `GTTextField` / `GTPrimaryButton` / `GTSecondaryButton`.

### Провайдеры
- `objectProvider` (`StateNotifierProvider`) — основной провайдер состояния объектов.
- `activeCompanyIdProvider` — контекст текущей компании.

---

## Слой Domain/Data
- **Сущность:** `ObjectEntity` (Domain) — иммутабельная модель данных (включает `companyId`).
- **Модель:** `ObjectModel` (Data) — расширенная модель с методами `fromJson/toJson` и маппингом в Entity.
- **Репозиторий:** `ObjectRepository` — интерфейс (Domain), `ObjectRepositoryImpl` — реализация через Supabase (Data).
- **Use Cases:** `GetObjectsUseCase`, `CreateObjectUseCase`, `UpdateObjectUseCase`, `DeleteObjectUseCase`.

---

## Дерево файлов
```
lib/features/objects/
├── data/
│   ├── datasources/
│   │   └── object_data_source.dart
│   ├── models/
│   │   ├── object_model.dart
│   │   ├── object_model.freezed.dart
│   │   └── object_model.g.dart
│   └── repositories/
│   │   └── object_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── object.dart
│   │   └── object.freezed.dart
│   ├── repositories/
│   │   └── object_repository.dart
│   └── usecases/
│       ├── create_object_usecase.dart
│       ├── delete_object_usecase.dart
│       ├── get_objects_usecase.dart
│       └── update_object_usecase.dart
└── presentation/
    ├── screens/
    │   ├── desktop/
    │   │   └── objects_list_desktop_view.dart
    │   ├── mobile/
    │   │   └── objects_list_mobile_view.dart
    │   ├── object_form_screen.dart
    │   └── objects_list_screen.dart
    ├── state/
    │   ├── object_state.dart
    │   ├── object_state.freezed.dart
    │   └── object_state.g.dart
    └── widgets/
        ├── object_actions.dart
        ├── object_details_panel.dart
        ├── object_details_view.dart
        ├── object_form_content.dart
        ├── object_form_modal.dart
        ├── object_list_item_desktop.dart
        ├── object_list_shared.dart
        └── object_row_item_mobile.dart
```

---

## База данных (Audit)
### Таблица `public.objects`
| Колонка     | Тип         | Описание                                |
|-------------|-------------|-----------------------------------------|
| id          | UUID, PK    | Уникальный идентификатор (Primary Key) |
| company_id  | UUID, FK    | Ссылка на компанию (Multi-tenancy)      |
| name        | TEXT        | Наименование объекта (Not Null)         |
| address     | TEXT        | Юридический/фактический адрес (Not Null)|
| description | TEXT        | Дополнительная информация               |
| created_at  | TIMESTAMPTZ | Дата создания                           |
| updated_at  | TIMESTAMPTZ | Дата последнего изменения               |

**RLS:** ✅ Включён.
- **SELECT (`objects_select`):** Разрешен пользователям компании ИЛИ если ID объекта в `profiles.object_ids`.
- **INSERT/UPDATE/DELETE:** Разрешен пользователям компании с соответствующими правами. 
    * *Примечание:* Функция `check_permission` автоматически предоставляет доступ владельцам компании (`is_owner = true`).

---

## Бизнес-логика
1. **Multi-tenancy:** Принудительная изоляция по `company_id`.
2. **Action Consolidation:** Все операции изменения состояния (Edit/Delete) централизованы в `ObjectActions` для гарантии идентичного поведения во всех частях UI.
3. **Безопасность:** Двойная проверка прав: `PermissionGuard` (UI) + RLS (DB). Функция `check_permission` в БД является "источником истины" для прав доступа.
4. **Обработка ошибок:** Форма `ObjectFormModal` реализует реактивную обработку ошибок: при неудачной попытке записи (RLS violation, network error) состояние `ObjectStatus.error` отображается пользователю через Snackbar без закрытия формы.

---

## Roadmap
- [x] Рефакторинг на Clean Architecture.
- [x] Тотальный рефакторинг Presentation-слоя (атомарные виджеты).
- [x] Унификация действий (ObjectActions).
- [x] Внедрение GTConfirmationDialog.
- [x] Разделение на Desktop и Mobile View (Master-Detail).
- [x] Удаление табов в деталях объекта.
- [x] Приведение отображения деталей к стандарту модуля контрагентов.
- [x] Исправление RBAC для владельцев компаний.
- [ ] Добавление поиска и расширенной фильтрации в `ObjectsListScreen`.
- [ ] Реализация архивного состояния объекта (soft delete).
- [ ] Добавление возможности прикрепления фото и документов к объекту.
