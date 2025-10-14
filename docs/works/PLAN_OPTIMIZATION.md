# Чек-лист оптимизации модуля Works
**Дата создания:** 10 октября 2025 года  
**Цель:** Масштабирование до тысяч смен (триггеры + денормализация + группировка по месяцам)  
**Время реализации:** 6-8 часов  
**Критический путь:** Этап 1 → Этап 3 → Этап 5

---

## 📋 ЭТАП 1: База данных (Supabase) — 1 час

### ☐ 1.1 Создать миграцию добавления колонок
- Файл: `supabase/migrations/YYYYMMDDHHMMSS_add_work_aggregates.sql`
- Выполнить: `ALTER TABLE works ADD COLUMN total_amount NUMERIC DEFAULT 0 NOT NULL, ADD COLUMN items_count INTEGER DEFAULT 0 NOT NULL, ADD COLUMN employees_count INTEGER DEFAULT 0 NOT NULL;`
- Проверка: `SELECT column_name FROM information_schema.columns WHERE table_name='works';` → должны появиться 3 новые колонки

### ☐ 1.2 Заполнить агрегаты для существующих смен
- В той же миграции выполнить: `UPDATE works w SET total_amount = ..., items_count = ..., employees_count = ...`
- Проверка: `SELECT id, total_amount, items_count, employees_count FROM works LIMIT 5;` → значения не NULL, корректные

### ☐ 1.3 Создать функцию пересчёта агрегатов
- В миграции создать: `CREATE OR REPLACE FUNCTION update_work_aggregates(work_uuid UUID) RETURNS VOID`
- Проверка: `SELECT proname FROM pg_proc WHERE proname = 'update_work_aggregates';` → функция существует

### ☐ 1.4 Создать триггерную функцию для work_items
- В миграции создать: `CREATE OR REPLACE FUNCTION trigger_update_work_aggregates_items() RETURNS TRIGGER`
- Проверка: `SELECT proname FROM pg_proc WHERE proname = 'trigger_update_work_aggregates_items';`

### ☐ 1.5 Создать триггерную функцию для work_hours
- В миграции создать: `CREATE OR REPLACE FUNCTION trigger_update_work_aggregates_hours() RETURNS TRIGGER`
- Проверка: `SELECT proname FROM pg_proc WHERE proname = 'trigger_update_work_aggregates_hours';`

### ☐ 1.6 Создать триггер на work_items
- В миграции выполнить: `CREATE TRIGGER work_items_aggregate_trigger AFTER INSERT OR UPDATE OR DELETE ON work_items`
- Проверка: `SELECT tgname FROM pg_trigger WHERE tgname = 'work_items_aggregate_trigger';`

### ☐ 1.7 Создать триггер на work_hours
- В миграции выполнить: `CREATE TRIGGER work_hours_aggregate_trigger AFTER INSERT OR UPDATE OR DELETE ON work_hours`
- Проверка: `SELECT tgname FROM pg_trigger WHERE tgname = 'work_hours_aggregate_trigger';`

### ☐ 1.8 Применить миграцию через Supabase CLI
- Команда: `supabase db push` или через dashboard
- Проверка: миграция в списке выполненных, ошибок нет

### ☐ 1.9 Тест триггеров: добавление work_item
- Выполнить: `INSERT INTO work_items (work_id, ..., total) VALUES (...);`
- Проверка: `SELECT total_amount, items_count FROM works WHERE id = '...';` → значения обновились

### ☐ 1.10 Тест триггеров: удаление work_hour
- Выполнить: `DELETE FROM work_hours WHERE id = '...';`
- Проверка: `SELECT employees_count FROM works WHERE id = '...';` → значение пересчиталось

**✅ Критерий завершения Этапа 1:** Все 3 колонки добавлены, триггеры работают, тесты пройдены

---

## 📋 ЭТАП 2: Domain Layer — 30 минут

### ☐ 2.1 Обновить Work entity
- Файл: `lib/features/works/domain/entities/work.dart`
- Добавить поля: `double? totalAmount`, `int? itemsCount`, `int? employeesCount` (nullable для обратной совместимости)
- Проверка: компиляция без ошибок после добавления

### ☐ 2.2 Запустить генерацию Freezed
- Команда: `flutter pub run build_runner build --delete-conflicting-outputs`
- Проверка: `work.freezed.dart` обновлён, содержит новые поля в copyWith

**✅ Критерий завершения Этапа 2:** Entity содержит новые поля, Freezed сгенерирован успешно

---

## 📋 ЭТАП 3: Data Layer — 1.5 часа

### ☐ 3.1 Обновить WorkModel
- Файл: `lib/features/works/data/models/work_model.dart`
- Добавить: `@JsonKey(name: 'total_amount') double? totalAmount`, аналогично для `items_count`, `employees_count`
- Проверка: компиляция без ошибок

### ☐ 3.2 Запустить генерацию Freezed и JSON
- Команда: `flutter pub run build_runner build --delete-conflicting-outputs`
- Проверка: `work_model.freezed.dart` и `work_model.g.dart` обновлены

### ☐ 3.3 Создать модель MonthGroup
- Файл: `lib/features/works/data/models/month_group.dart`
- Создать класс: `class MonthGroup { DateTime month; int worksCount; double totalAmount; bool isExpanded; List<Work>? works; }`
- Проверка: импортируется без ошибок

### ☐ 3.4 Обновить интерфейс WorkDataSource
- Файл: `lib/features/works/data/datasources/work_data_source.dart`
- Добавить: `Future<List<MonthGroup>> getMonthsHeaders();`, `Future<List<WorkModel>> getMonthWorks(DateTime month, {int offset = 0, int limit = 30});`
- Проверка: интерфейс компилируется

### ☐ 3.5 Реализовать getMonthsHeaders в WorkDataSourceImpl
- Файл: `lib/features/works/data/datasources/work_data_source_impl.dart`
- Реализация: загрузить все works с `select('id, date, total_amount, items_count, employees_count')`, группировать по месяцам
- Проверка: метод возвращает List<MonthGroup> с корректными агрегатами

### ☐ 3.6 Реализовать getMonthWorks в WorkDataSourceImpl
- В том же файле: `work_data_source_impl.dart`
- Реализация: фильтрация `.gte('date', startDate).lt('date', endDate).order('date', descending: true).range(offset, limit)`
- Проверка: метод возвращает смены только заданного месяца с пагинацией

### ☐ 3.7 Обновить интерфейс WorkRepository
- Файл: `lib/features/works/domain/repositories/work_repository.dart`
- Добавить: `Future<List<MonthGroup>> getMonthsHeaders();`, `Future<List<Work>> getMonthWorks(DateTime month, {int offset, int limit});`
- Проверка: интерфейс компилируется

### ☐ 3.8 Реализовать методы в WorkRepositoryImpl
- Файл: `lib/features/works/data/repositories/work_repository_impl.dart`
- Реализация: делегировать вызовы в datasource, преобразовать WorkModel → Work
- Проверка: методы работают, возвращают корректные данные

**✅ Критерий завершения Этапа 3:** Datasource и Repository возвращают данные с агрегатами, группировка по месяцам работает

---

## 📋 ЭТАП 4: Presentation Providers — 1 час

### ☐ 4.1 Создать MonthGroupsState
- Файл: `lib/features/works/presentation/providers/month_groups_provider.dart`
- Создать класс: `class MonthGroupsState { List<MonthGroup> groups; bool isLoading; String? error; }`
- Проверка: класс компилируется

### ☐ 4.2 Создать MonthGroupsNotifier
- В том же файле: `month_groups_provider.dart`
- Реализация: `class MonthGroupsNotifier extends StateNotifier<MonthGroupsState>`
- Методы: `loadMonths()`, `expandMonth(DateTime month)`, `collapseMonth(DateTime month)`
- Проверка: провайдер управляет состоянием, методы работают

### ☐ 4.3 Создать провайдер monthGroupsProvider
- В том же файле
- Реализация: `final monthGroupsProvider = StateNotifierProvider<MonthGroupsNotifier, MonthGroupsState>(...)`
- Проверка: провайдер доступен в ref.watch

### ☐ 4.4 Зарегистрировать провайдер (если нужно)
- Файл: `lib/features/works/presentation/providers/repositories_providers.dart`
- Проверка: провайдер экспортируется и доступен

**✅ Критерий завершения Этапа 4:** Провайдер создан, управляет группами месяцев, методы работают

---

## 📋 ЭТАП 5: Presentation UI — 2 часа

### ☐ 5.1 Создать MonthGroupHeader widget
- Файл: `lib/features/works/presentation/widgets/month_group_header.dart`
- Компоненты: Row с иконкой expand/collapse, Text названия месяца, счётчики (worksCount • totalAmount)
- Стиль: Card с onTap, адаптивный под desktop/mobile
- Проверка: виджет отображается корректно, реагирует на клик

### ☐ 5.2 Создать MonthWorksList widget
- Файл: `lib/features/works/presentation/widgets/month_works_list.dart`
- Логика: если works == null → CircularProgressIndicator, иначе ListView карточек смен
- Infinite scroll: ScrollController с listener для loadMore при достижении конца
- Проверка: список смен отображается, скролл работает

### ☐ 5.3 Обновить works_master_detail_screen (удалить Consumer)
- Файл: `lib/features/works/presentation/screens/works_master_detail_screen.dart`
- Найти строки 477-552 с Consumer(workItemsProvider/workHoursProvider)
- Удалить Consumer и расчёты items.fold, hours.map
- Заменить на прямое использование: `work.totalAmount ?? 0`, `work.employeesCount ?? 0`
- Проверка: карточки отображают суммы без провайдеров, нет задержек

### ☐ 5.4 Обновить works_master_detail_screen (ListView → MonthGroups)
- В том же файле
- Заменить `ListView.builder(filteredWorks)` на `ListView.builder(monthGroups)`
- Для каждой группы: MonthGroupHeader + (если expanded) MonthWorksList
- Проверка: список отображается группами, текущий месяц развёрнут

### ☐ 5.5 Обновить work_data_tab (заменить расчёты)
- Файл: `lib/features/works/presentation/screens/tabs/work_data_tab.dart`
- Найти строки 62-68: `items.fold`, `hours.map().toSet().length`, `items.length`
- Заменить на: `work.totalAmount ?? 0`, `work.employeesCount ?? 0`, `work.itemsCount ?? 0`
- Удалить зависимости от workItemsProvider/workHoursProvider для метрик
- Проверка: вкладка "Данные" показывает корректные значения без провайдеров

### ☐ 5.6 Проверить поиск и фильтрацию
- В `works_master_detail_screen.dart` обновить фильтрацию для работы с MonthGroups
- Проверка: поиск работает по названию объекта и дате внутри групп

**✅ Критерий завершения Этапа 5:** UI отображает группы месяцев, агрегаты из work, провайдеры удалены из списка

---

## 📋 ЭТАП 6: Тестирование — 1 час

### ☐ 6.1 Тест триггеров БД: добавление work_item
- Действие: в UI добавить работу к смене
- Проверка: в БД `total_amount` и `items_count` обновились автоматически
- Проверка UI: карточка смены мгновенно показывает новую сумму

### ☐ 6.2 Тест триггеров БД: удаление work_hour
- Действие: в UI удалить сотрудника из смены
- Проверка: в БД `employees_count` уменьшился
- Проверка UI: карточка смены показывает обновлённое количество сотрудников

### ☐ 6.3 Тест UI: отображение текущего месяца
- Действие: открыть список смен
- Проверка: текущий месяц развёрнут автоматически, смены отображаются
- Проверка: агрегаты (сумма, количество) корректны, нет задержек загрузки

### ☐ 6.4 Тест UI: раскрытие архивного месяца
- Действие: кликнуть на заголовок архивного месяца
- Проверка: появился индикатор загрузки, затем список смен
- Проверка: смены только этого месяца, данные корректны

### ☐ 6.5 Тест UI: сворачивание месяца
- Действие: кликнуть на развёрнутый месяц
- Проверка: список смен скрылся, заголовок остался
- Проверка: память освободилась (works = null в MonthGroup)

### ☐ 6.6 Тест производительности: загрузка списка
- Подготовка: создать 1000+ тестовых смен в БД
- Действие: открыть список смен
- Проверка: список загружается < 1 сек, отображаются только заголовки месяцев
- Проверка: UI не лагает, скролл плавный

### ☐ 6.7 Тест производительности: скролл и раскрытие
- Действие: скроллить список, раскрывать разные месяцы
- Проверка: нет задержек, нет утечек памяти
- Проверка: Realtime-каналов в сети 0 (только когда открываешь детали)

### ☐ 6.8 Тест детального режима: Realtime работает
- Действие: открыть детали смены
- Проверка: workItemsProvider и workHoursProvider создались
- Проверка: добавление работы в другом окне → обновление в текущем через Realtime

### ☐ 6.9 Тест детального режима: агрегаты из work
- Действие: открыть вкладку "Данные" в деталях смены
- Проверка: метрики (сумма, сотрудники, работы) берутся из work, а не из расчётов
- Проверка: значения соответствуют реальным данным

### ☐ 6.10 Регрессионное тестирование: CRUD операции
- Тест: создание смены → проверка агрегатов (должны быть 0)
- Тест: редактирование смены → проверка сохранения агрегатов
- Тест: удаление смены → проверка каскадного удаления
- Проверка: все операции работают стабильно

**✅ Критерий завершения Этапа 6:** Все тесты пройдены, производительность подтверждена

---

## 📋 ЭТАП 7: Документация — 30 минут

### ☐ 7.1 Обновить works_module.md: структура БД
- Файл: `docs/works/works_module.md`
- Добавить в таблицу works: `total_amount NUMERIC`, `items_count INTEGER`, `employees_count INTEGER`
- Описать назначение колонок: автоматически обновляемые агрегаты
- Проверка: документация актуальна

### ☐ 7.2 Обновить works_module.md: функции и триггеры
- В том же файле в разделе "Функции, триггеры"
- Документировать: `update_work_aggregates()`, триггерные функции, триггеры на work_items/work_hours
- Описать механизм работы: INSERT/UPDATE/DELETE → автопересчёт
- Проверка: описание полное и понятное

### ☐ 7.3 Создать MIGRATION_GUIDE.md
- Файл: `docs/works/MIGRATION_GUIDE.md`
- Разделы: Подготовка, Резервная копия, Применение миграции, Проверка, Откат
- Чек-лист проверки после миграции (SQL-запросы)
- Проверка: инструкция пошаговая и исчерпывающая

### ☐ 7.4 Обновить ANALYSIS_FILES.md
- Файл: `docs/works/ANALYSIS_FILES.md`
- Добавить запись о завершении оптимизации
- Указать изменённые файлы, новые компоненты
- Проверка: история изменений актуальна

**✅ Критерий завершения Этапа 7:** Документация обновлена, инструкция по миграции готова

---

## 🎯 ФИНАЛЬНАЯ ПРОВЕРКА

### ☐ Проверка 1: Агрегаты в БД актуальны
- SQL: `SELECT id, total_amount, items_count, employees_count FROM works WHERE id = '...'`
- Ожидаемо: значения соответствуют реальным суммам и количествам

### ☐ Проверка 2: Триггеры работают
- Действие: добавить/удалить work_item или work_hour
- Ожидаемо: агрегаты обновляются автоматически в течение 1 сек

### ☐ Проверка 3: UI список смен
- Действие: открыть список смен
- Ожидаемо: группировка по месяцам, текущий месяц развёрнут, агрегаты корректны

### ☐ Проверка 4: Производительность
- Действие: скролл списка, раскрытие месяцев
- Ожидаемо: нет лагов, загрузка < 1 сек, Realtime-каналов 0 в списке

### ☐ Проверка 5: Детальный режим
- Действие: открыть детали смены
- Ожидаемо: Realtime работает, агрегаты из work, расчёты корректны

---

## 📊 МЕТРИКИ УСПЕХА

**До оптимизации:**
- Загрузка списка: ~5-10 сек при 100+ сменах
- Realtime-каналы: 40+ для 20 смен
- Сетевые запросы: N * 2 для каждой карточки

**После оптимизации:**
- Загрузка списка: < 1 сек для любого количества смен
- Realtime-каналы: 0 в списке, 2 в деталях
- Сетевые запросы: 1 для заголовков месяцев + 1 на раскрытие месяца

**Целевые показатели:**
- ✅ Поддержка 10,000+ смен без деградации производительности
- ✅ Моментальное обновление агрегатов (триггеры < 100ms)
- ✅ Плавный скролл (60 FPS) на всех платформах
- ✅ Минимальная сетевая нагрузка (ленивая загрузка)

---

**Статус:** ☐ Не начато  
**Последнее обновление:** 10 октября 2025 года
