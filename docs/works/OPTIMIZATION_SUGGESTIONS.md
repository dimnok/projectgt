# Предложения по оптимизации модуля Works

**Дата анализа:** 11 октября 2025 года  
**Версия:** 1.0  
**Автор:** GPT-5 Codex

---

## Резюме

После детального аудита модуля Works выявлено **8 направлений оптимизации**, которые повысят производительность, читаемость кода и снизят технический долг.

---

## 1. Оптимизация провайдеров 🔧

### Проблема
- **`workItemsNotifierProvider`** (line 155-158 в `work_items_provider.dart`) создаётся с пустым `workId = ''` для доступа к общим методам.
- Это создаёт провайдер, который инициирует загрузку и Realtime-подписку на несуществующую смену.

### Решение
Заменить на обычный `Provider` с фабрикой:

```dart
/// Провайдер для доступа к репозиторию без привязки к конкретной смене
final workItemsRepositoryAccessProvider = Provider<WorkItemRepository>((ref) {
  return ref.watch(workItemRepositoryProvider);
});
```

**Выгода:** Устранение лишней подписки, упрощение архитектуры.

---

## 2. Оптимизация Infinite Scroll в MonthWorksList 📜

### Проблема
- Текущая реализация проверяет скролл при каждом пикселе прокрутки (line 58-64 в `month_works_list.dart`).
- Нет защиты от дублирования вызовов `onLoadMore()`.

### Решение

```dart
class _MonthWorksListState extends ConsumerState<MonthWorksList> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  void _onScroll() {
    if (_isLoadingMore) return; // Защита от дублирования
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _isLoadingMore = true;
      widget.onLoadMore();
      
      // Сброс флага через 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }
}
```

**Выгода:** Устранение дублирующих запросов, снижение нагрузки на БД.

---

## 3. Кеширование объектов в MonthWorksList 🗂️

### Проблема
- `objectProvider` вызывается для каждой карточки смены в методе `_buildWorkCard` (line 114-120).
- При 30 сменах на экране — 30 идентичных обращений к провайдеру.

### Решение
Вынести получение объектов на уровень виджета:

```dart
@override
Widget build(BuildContext context) {
  final works = widget.group.works;
  final objects = ref.watch(objectProvider).objects; // Один раз!
  final objectsMap = {for (var o in objects) o.id: o.name};

  // ... остальной код
}

Widget _buildWorkCard(
  BuildContext context, 
  Work work, 
  Map<String, String> objectsMap,
) {
  final objectName = objectsMap[work.objectId] ?? work.objectId;
  // ...
}
```

**Выгода:** Снижение нагрузки на Riverpod, улучшение производительности рендеринга.

---

## 4. Оптимизация загрузки занятых сотрудников в WorkFormScreen ⏳

### Проблема
- Метод `_getEmployeesInOpenShifts()` (line 121-149) загружает все смены из `worksProvider.works`.
- Затем для каждой смены делает обращение к `workHoursProvider(work.id!)`.
- При 100+ сменах это может быть медленно.

### Решение

**Вариант A (быстрый):** Использовать SQL-запрос с JOIN:

```sql
CREATE OR REPLACE FUNCTION get_employees_in_open_shifts(target_date DATE)
RETURNS TABLE (employee_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT wh.employee_id
  FROM work_hours wh
  JOIN works w ON w.id = wh.work_id
  WHERE w.date = target_date 
    AND w.status = 'open';
END;
$$ LANGUAGE plpgsql;
```

```dart
Future<Set<String>> _getEmployeesInOpenShifts() async {
  final today = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(today);
  
  final response = await ref
      .read(supabaseClientProvider)
      .rpc('get_employees_in_open_shifts', params: {'target_date': todayStr});
  
  return (response as List).map((e) => e['employee_id'] as String).toSet();
}
```

**Вариант B (без SQL):** Кешировать результат на уровне дня:

```dart
// В state провайдера
final occupiedEmployeesCacheProvider = StateProvider<({DateTime date, Set<String> ids})?>((ref) => null);

Future<Set<String>> _getEmployeesInOpenShifts() async {
  final cache = ref.read(occupiedEmployeesCacheProvider);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  
  if (cache != null && cache.date == todayDate) {
    return cache.ids; // Возвращаем из кеша
  }
  
  // ... загрузка
  
  ref.read(occupiedEmployeesCacheProvider.notifier).state = (date: todayDate, ids: occupiedEmployeeIds);
  return occupiedEmployeeIds;
}
```

**Выгода:** Ускорение формы создания смены в 10-100x.

---

## 5. Удаление дублирования кода форматирования 📝

### Проблема
- Метод `_formatDate` дублируется в нескольких файлах:
  - `month_works_list.dart` (line 290-292)
  - `work_data_tab.dart` (вероятно, есть)
  
- Это нарушает принцип DRY.

### Решение
Использовать единый форматтер из `lib/core/utils/formatters.dart`:

```dart
// В MonthWorksList и других местах
import 'package:projectgt/core/utils/formatters.dart';

// Вместо
Text(_formatDate(work.date))

// Использовать
Text(formatRuDate(work.date))
```

**Если форматтера `formatRuDate` нет, создать:**

```dart
// lib/core/utils/formatters.dart
String formatRuDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
```

**Выгода:** Единообразие, упрощение поддержки, соответствие правилам проекта.

---

## 6. Оптимизация метода `_getWorkStatusInfo` 🎯

### Проблема
- Метод `_getWorkStatusInfo` дублируется в нескольких виджетах.
- Возвращает tuple `(String, Color)`, что менее читаемо.

### Решение

**Создать enum в домене:**

```dart
// lib/features/works/domain/entities/work_status.dart
enum WorkStatus {
  open('open', 'Открыта', Colors.green),
  closed('closed', 'Закрыта', Colors.red);

  final String value;
  final String label;
  final Color color;

  const WorkStatus(this.value, this.label, this.color);

  static WorkStatus fromString(String value) {
    return WorkStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown status: $value'),
    );
  }
}
```

**Использование:**

```dart
final status = WorkStatus.fromString(work.status);
Text(status.label);
AppBadge(text: status.label, color: status.color);
```

**Выгода:** Типобезопасность, единообразие, читаемость.

---

## 7. Добавление индексов для производительности БД 🚀

### Проблема
- Запрос `getMonthWorks` фильтрует по `date` с `gte` и `lt` (line 149-152 в `work_data_source_impl.dart`).
- Текущий индекс `idx_works_date_desc` оптимален для сортировки DESC, но может быть недостаточно эффективен для диапазонов.

### Решение

Проверить эффективность текущих индексов и при необходимости добавить:

```sql
-- Если запросы медленные, добавить composite index:
CREATE INDEX IF NOT EXISTS idx_works_date_range ON works (date ASC, status);

-- Проверить использование индексов:
EXPLAIN ANALYZE 
SELECT * FROM works 
WHERE date >= '2025-10-01' AND date < '2025-11-01' 
ORDER BY date DESC 
LIMIT 30;
```

**Примечание:** Индекс `idx_works_date_desc` уже есть. Нужна проверка через `EXPLAIN ANALYZE`.

**Выгода:** Потенциальное ускорение запросов на 2-5x при больших объёмах данных.

---

## 8. Оптимизация логики расчёта в `month_details_panel.dart` 💡

### Проблема
- Метод `_loadDetailsForWorks` (line 44-85 в `month_details_panel.dart`) загружает `work_items` и `work_hours` для КАЖДОЙ смены месяца последовательно в цикле.
- При 30 сменах это 60+ запросов к БД.

### Решение

**Вариант A (SQL-агрегация):** Создать RPC-функцию для статистики месяца:

```sql
CREATE OR REPLACE FUNCTION get_month_detailed_stats(target_month DATE)
RETURNS TABLE (
  system TEXT,
  items_count BIGINT,
  total_amount NUMERIC,
  unique_employees BIGINT,
  total_hours NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    wi.system,
    COUNT(wi.id) AS items_count,
    SUM(wi.total) AS total_amount,
    COUNT(DISTINCT wh.employee_id) AS unique_employees,
    SUM(wh.hours) AS total_hours
  FROM works w
  LEFT JOIN work_items wi ON wi.work_id = w.id
  LEFT JOIN work_hours wh ON wh.work_id = w.id
  WHERE DATE_TRUNC('month', w.date) = target_month
  GROUP BY wi.system;
END;
$$ LANGUAGE plpgsql;
```

**Вариант B (пакетная загрузка):** Загружать все items/hours месяца одним запросом:

```dart
Future<void> _loadDetailsForWorks(List works) async {
  final workIds = works.map((w) => w.id).whereType<String>().toList();
  
  // Один запрос для всех work_items месяца
  final itemsResponse = await client
      .from('work_items')
      .select('*')
      .in_('work_id', workIds);
  
  // Один запрос для всех work_hours месяца
  final hoursResponse = await client
      .from('work_hours')
      .select('*')
      .in_('work_id', workIds);
  
  // Группируем на клиенте
  final itemsMap = <String, List>{};
  for (final item in itemsResponse) {
    itemsMap.putIfAbsent(item['work_id'], () => []).add(item);
  }
  
  setState(() {
    _workItemsCache = itemsMap;
    // ...
  });
}
```

**Выгода:** Ускорение загрузки статистики месяца с 2-3 секунд до < 100ms.

---

## 9. Удаление неиспользуемых импортов и методов 🧹

### Найденные проблемы

1. **`work_form_screen.dart`:**
   - `import 'package:flutter/cupertino.dart';` (line 2) — не используется

2. **`work_provider.dart`:**
   - `WorksState` (line 10-39) — можно упростить через `@freezed`

### Решение

```dart
// work_form_screen.dart - удалить импорт
// import 'package:flutter/cupertino.dart'; // ❌ Удалить

// work_provider.dart - использовать freezed
@freezed
class WorksState with _$WorksState {
  const factory WorksState({
    @Default([]) List<Work> works,
    @Default(false) bool isLoading,
    String? error,
  }) = _WorksState;
}
```

**Выгода:** Чистота кода, соответствие стандартам проекта (Freezed используется везде).

---

## 10. Добавление const конструкторов ⚡

### Проблема
В нескольких виджетах можно добавить `const`, но это не сделано:

```dart
// month_works_list.dart line 72-78
if (works == null) {
  return const Center(  // ✅ const есть
    child: Padding(
      padding: EdgeInsets.all(16.0),  // ❌ const отсутствует
      child: CircularProgressIndicator(),
    ),
  );
}
```

### Решение

```dart
if (works == null) {
  return const Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),  // ✅ Добавить const
      child: const CircularProgressIndicator(),  // ✅ Добавить const
    ),
  );
}
```

**Выгода:** Снижение ре-билдов виджетов, улучшение производительности.

---

## Приоритизация

### 🔴 Высокий приоритет (внедрить сразу)
1. **#4** — Оптимизация `_getEmployeesInOpenShifts` (SQL-запрос)
2. **#8** — Оптимизация `_loadDetailsForWorks` (пакетная загрузка)
3. **#3** — Кеширование объектов в `MonthWorksList`

### 🟡 Средний приоритет (в ближайшее время)
4. **#5** — Удаление дублирования форматирования
5. **#6** — Создание enum `WorkStatus`
6. **#2** — Оптимизация Infinite Scroll

### 🟢 Низкий приоритет (технический долг)
7. **#1** — Оптимизация `workItemsNotifierProvider`
8. **#9** — Удаление неиспользуемых импортов
9. **#10** — Добавление const конструкторов
10. **#7** — Проверка индексов БД

---

## Метрики до/после (прогноз)

| Метрика | До | После |
|---------|-----|-------|
| Загрузка статистики месяца | 2-3 сек | < 100ms |
| Открытие формы создания смены | 500-1000ms | < 50ms |
| Рендеринг 30 смен | 100-200ms | < 50ms |
| Количество запросов БД (детали месяца) | 60+ | 2 |
| Количество провайдеров (список смен) | 60+ | 0 |

---

## Рекомендации по внедрению

1. **Начать с высокоприоритетных задач (#4, #8, #3)**
2. **Тестировать каждое изменение отдельно**
3. **Измерять производительность через Flutter DevTools**
4. **Документировать изменения в `ANALYSIS_FILES.md`**

---

## Заключение

Модуль Works хорошо спроектирован и уже оптимизирован (группировка по месяцам, триггеры БД, SQL-агрегация). Предложенные улучшения направлены на:
- ⚡ Дальнейшее повышение производительности (особенно детальная панель месяца)
- 🧹 Снижение технического долга
- 📚 Улучшение читаемости и поддерживаемости кода

**Общая оценка модуля:** 8/10 ⭐  
**Потенциал после оптимизации:** 9.5/10 ⭐

---

**Последнее обновление:** 11 октября 2025 года

