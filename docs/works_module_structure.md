# Структура модуля Works

Этот документ описывает структуру модуля `works` (смены) во Flutter-приложении, включая все связанные файлы и их основное назначение.

## Слой Domain

### Сущности (Entities)

- **work.dart** - Основная сущность смены с полями для id, даты, объекта, статуса, фото и др.
- **work_item.dart** - Сущность работы в смене (содержит секцию, этаж, систему, подсистему и т.д.)
- **work_hour.dart** - Сущность учета часов сотрудников в смене
- **work_material.dart** - Сущность материалов, использованных в смене

*Замечание: `.freezed.dart` и `.g.dart` файлы генерируются автоматически библиотеками Freezed и json_serializable*

### Репозитории (Repositories)

- **work_repository.dart** - Интерфейс репозитория для работы со сменами
- **work_item_repository.dart** - Интерфейс репозитория для работы со списком работ в смене
- **work_hour_repository.dart** - Интерфейс репозитория для работы с часами сотрудников в смене
- **work_material_repository.dart** - Интерфейс репозитория для работы с материалами в смене

## Слой Data

### Модели (Models)

- **work_model.dart** - Модель данных смены для сериализации и десериализации
- **work_item_model.dart** - Модель данных работы в смене
- **work_hour_model.dart** - Модель данных часов сотрудников
- **work_material_model.dart** - Модель данных материалов

### Репозитории (Repositories)

- **work_repository_impl.dart** - Реализация репозитория смен
- **work_item_repository_impl.dart** - Реализация репозитория работ
- **work_hour_repository_impl.dart** - Реализация репозитория часов
- **work_material_repository_impl.dart** - Реализация репозитория материалов

### Источники данных (DataSources)

- **work_data_source.dart** - Интерфейс источника данных для смен
- **work_data_source_impl.dart** - Реализация источника данных для смен (Supabase)
- **work_item_data_source.dart** - Интерфейс источника данных для работ
- **work_item_data_source_impl.dart** - Реализация источника данных для работ
- **work_hour_data_source.dart** - Интерфейс источника данных для часов
- **work_hour_data_source_impl.dart** - Реализация источника данных для часов
- **work_material_data_source.dart** - Интерфейс источника данных для материалов
- **work_material_data_source_impl.dart** - Реализация источника данных для материалов

## Слой Presentation

### Провайдеры (Providers)

- **work_provider.dart** - Провайдер состояния для списка смен и доступа к конкретной смене
- **work_items_provider.dart** - Провайдер для управления списком работ в смене
- **work_hours_provider.dart** - Провайдер для управления списком часов сотрудников
- **work_materials_provider.dart** - Провайдер для управления списком материалов
- **repositories_providers.dart** - Провайдеры для инициализации репозиториев

### Экраны (Screens)

- **works_master_detail_screen.dart** - Главный экран списка всех смен (мастер-детали)
- **work_details_screen.dart** - Экран детальной информации о смене
- **work_details_panel.dart** - Панель с вкладками для отображения деталей смены
- **work_item_form_modal.dart** - Модальное окно для добавления/редактирования работы
- **work_hour_form_modal.dart** - Модальное окно для добавления/редактирования часов сотрудника
- **work_material_form_modal.dart** - Модальное окно для добавления/редактирования материала

### Виджеты (Widgets)

- **work_photo_view.dart** - Виджет для отображения утренних и вечерних фотографий смены

## Связанные сервисы

- **lib/core/services/photo_service.dart** - Сервис для работы с фотографиями через Supabase Storage
- **lib/core/di/providers.dart** - Содержит определение `photoServiceProvider` для инъекции зависимостей

## База данных

- **lib/data/migrations/works_migration.sql** - SQL-миграция для создания таблиц модуля работ

## Структура таблиц в базе данных

1. **works** - Таблица смен с полями:
   - id, name, description, object_id, start_date, end_date, status, created_at, updated_at

2. **work_items** - Таблица работ в смене с полями:
   - id, work_id, section, floor, estimate_id, name, system, subsystem, unit, quantity, price, total, created_at, updated_at

3. **work_materials** - Таблица материалов в смене с полями:
   - id, work_id, name, unit, quantity, comment, created_at, updated_at

4. **work_hours** - Таблица часов сотрудников в смене с полями:
   - id, work_id, employee_id, hours, comment, created_at, updated_at 