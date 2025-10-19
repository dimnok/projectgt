# 🔴 КОРНЕВАЯ ПРИЧИНА: Пустой список смен на календаре

## 🎯 ПРОБЛЕМА: Данные загружаются с сервера (HTTP 200), но календарь пуст

**Доказательство:**
- ✅ Логи Supabase: все запросы `works` возвращают **HTTP 200**
- ✅ Таблица works содержит **33 записи**
- ✅ RLS политики пропускают (пользователь админ)
- ❌ Но календарь показывает **пустой список** (все дни красные)

---

## 🐛 НАЙДЕННЫЕ ОШИБКИ В КОДЕ

### Ошибка #1: Агрегирование перезаписывает objectName

**Файл:** `lib/features/home/data/datasources/shifts_data_source_impl.dart` (линия 55)

```dart
// ❌ НЕПРАВИЛЬНО - перезаписывается каждую итерацию
if (!aggregated.containsKey(dateKey)) {
  aggregated[dateKey] = {
    'date': workDate,
    'total': 0.0,
    'objectName': work['objects']?['name'] ?? 'Неизвестный объект',  // ← ОШИБКА
  };
}

// ✅ ПРАВИЛЬНО - установить один раз
if (!aggregated.containsKey(dateKey)) {
  aggregated[dateKey] = {
    'date': workDate,
    'total': 0.0,
    'objectNames': <String>[],  // Список вместо одного
  };
}
// Потом добавлять:
final objectName = work['objects']?['name'] ?? 'Неизвестный объект';
if (!aggregated[dateKey]['objectNames'].contains(objectName)) {
  aggregated[dateKey]['objectNames'].add(objectName);
}
```

### Ошибка #2: Пустой список проверок

**Логический поток:**
1. `getShiftsForMonth` получает данные с сервера (HTTP 200)
2. Проходит цикл `for (final work in response as List)` 
3. Если response **пуст** → цикл не выполняется
4. Возвращает пустой `aggregated` → пустой список
5. `shiftsForMonthProvider` передаёт пустой список в виджет
6. `ShiftsHeatmap` отображает все дни **КРАСНЫМ** (нет данных = 0)

### Ошибка #3: Отсутствует обработка ошибок в провайдере

Если в `ShiftsDataSourceImpl.getShiftsForMonth` произойдёт **исключение**:
- Оно перебрасывается (`rethrow`)
- `shiftsForMonthProvider.when(error:...)` должен это поймать
- Но если ошибка молчаливая, то виджет застревает в `loading()`

---

## ✅ РЕШЕНИЕ

### Шаг 1: Добавить логирование в DataSource

```dart
@override
Future<List<Map<String, dynamic>>> getShiftsForMonth(DateTime month) async {
  try {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = month.month == 12
        ? DateTime(month.year + 1, 1, 1).subtract(const Duration(days: 1))
        : DateTime(month.year, month.month + 1, 1)
            .subtract(const Duration(days: 1));

    final dateFromStr = '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';
    final dateToStr = '${monthEnd.year}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}';

    print('🔍 Запрос смен: от $dateFromStr до $dateToStr');

    final response = await supabaseClient.from('works').select('''
          date,
          total_amount,
          objects(name),
          work_items(
            system,
            total
          )
        ''').gte('date', dateFromStr).lte('date', dateToStr).order('date');

    print('📦 Получено работ: ${response.length}');  // ← ДОБАВИТЬ!

    final Map<String, dynamic> aggregated = {};

    for (final work in response as List) {
      final workDate = DateTime.parse(work['date'] as String);
      final dateKey = '${workDate.year}-${workDate.month.toString().padLeft(2, '0')}-${workDate.day.toString().padLeft(2, '0')}';

      if (!aggregated.containsKey(dateKey)) {
        aggregated[dateKey] = {
          'date': workDate,
          'total': 0.0,
        };
      }

      aggregated[dateKey]['total'] =
          (aggregated[dateKey]['total'] as num).toDouble() +
              ((work['total_amount'] as num?)?.toDouble() ?? 0.0);
    }

    print('📊 Агрегировано дней: ${aggregated.length}');  // ← ДОБАВИТЬ!
    print('📋 Результат: $aggregated');  // ← ДОБАВИТЬ!

    return aggregated.values.cast<Map<String, dynamic>>().toList();
  } catch (e) {
    print('❌ ОШИБКА в getShiftsForMonth: $e');  // ← ДОБАВИТЬ!
    rethrow;
  }
}
```

### Шаг 2: Запустить и проверить логи

Откройте **DevTools Console** или **Logcat** и ищите:
- 🔍 `Запрос смен:`
- 📦 `Получено работ:`
- 📊 `Агрегировано дней:`
- ❌ `ОШИБКА в getShiftsForMonth:`

---

## 🔧 ПОЛНОЕ ИСПРАВЛЕНИЕ shifts_data_source_impl.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shifts_data_source.dart';
import 'package:logger/logger.dart';  // ← ДОБАВИТЬ

final _log = Logger();  // ← ДОБАВИТЬ

class ShiftsDataSourceImpl implements ShiftsDataSource {
  final SupabaseClient supabaseClient;

  ShiftsDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> getShiftsForMonth(DateTime month) async {
    try {
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = month.month == 12
          ? DateTime(month.year + 1, 1, 1).subtract(const Duration(days: 1))
          : DateTime(month.year, month.month + 1, 1)
              .subtract(const Duration(days: 1));

      final dateFromStr = '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';
      final dateToStr = '${monthEnd.year}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}';

      _log.i('Запрос смен: от $dateFromStr до $dateToStr');

      final response = await supabaseClient.from('works').select('''
            date,
            total_amount,
            objects(name),
            work_items(
              system,
              total
            )
          ''').gte('date', dateFromStr).lte('date', dateToStr).order('date');

      _log.i('Получено работ из Supabase: ${(response as List).length}');

      final Map<String, dynamic> aggregated = {};

      for (final work in response as List) {
        final workDate = DateTime.parse(work['date'] as String);
        final dateKey = '${workDate.year}-${workDate.month.toString().padLeft(2, '0')}-${workDate.day.toString().padLeft(2, '0')}';

        if (!aggregated.containsKey(dateKey)) {
          aggregated[dateKey] = {
            'date': workDate,
            'total': 0.0,
          };
        }

        aggregated[dateKey]['total'] =
            (aggregated[dateKey]['total'] as num).toDouble() +
                ((work['total_amount'] as num?)?.toDouble() ?? 0.0);
      }

      _log.i('Агрегировано дней с данными: ${aggregated.length}');
      
      if (aggregated.isEmpty) {
        _log.w('⚠️ ВНИМАНИЕ: Нет данных за месяц $month');
      }

      final result = aggregated.values.cast<Map<String, dynamic>>().toList();
      _log.d('Возвращаем ${result.length} записей');
      
      return result;
    } catch (e, stack) {
      _log.e('❌ ОШИБКА в getShiftsForMonth: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ... rest of code ...
}
```

---

## 📋 ЧЕК-ЛИСТ ДИАГНОСТИКИ

- [ ] Запустить приложение
- [ ] Открыть DevTools Console (или Logcat)
- [ ] Искать сообщения "Получено работ:" или "ОШИБКА"
- [ ] Если `Получено работ: 0` → **проблема с запросом**
- [ ] Если `Получено работ: 33` → **проблема в агрегировании**
- [ ] Если ошибка → **показать нам сообщение об ошибке**

---

**Статус:** 🔴 **ТРЕБУЕТ НЕМЕДЛЕННОГО ДЕЙСТВИЯ** - добавить логирование и запустить диагностику
