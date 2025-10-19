# 📊 Руководство: Несколько уровней группировки

## 📋 Доступные уровни агрегации

### 1️⃣ `AggregationLevel.detailed` (по умолчанию)
**Группировка по 9 полям:**
```
Объект | Договор | Система | Подсистема | Участок | Этаж | № позиции | Наименование | Ед. изм.
```

**Пример строк:**
```
Дом А | Д-1 | ВК | Электро | Зал | 1 | 1.1 | Монтаж проводки | м
Дом А | Д-1 | ВК | Электро | Зал | 2 | 1.1 | Монтаж проводки | м
↓ агрегируется
Дом А | Д-1 | ВК | Электро | Зал | 1 | 1.1 | Монтаж проводки | м (итого: кол-во + количество)
Дом А | Д-1 | ВК | Электро | Зал | 2 | 1.1 | Монтаж проводки | м (отдельная строка)
```

---

### 2️⃣ `AggregationLevel.summary` (новое!)
**Группировка по 6 полям:**
```
Объект | Договор | Система | Подсистема | № позиции | Наименование
```

**Пример строк:**
```
Дом А | Д-1 | ВК | Электро | 1.1 | Монтаж проводки
↓ агрегируется со всеми:
Дом А | Д-1 | ВК | Электро | Зал | 1 | 1.1 | Монтаж проводки | м
Дом А | Д-1 | ВК | Электро | Зал | 2 | 1.1 | Монтаж проводки | м
↓ итог
Дом А | Д-1 | ВК | Электро | 1.1 | Монтаж проводки (total quantity + total sum)
```

---

## 🔧 Использование

### В коде (при загрузке отчёта):

```dart
// Детальная группировка (по умолчанию)
final filter1 = ExportFilter(
  dateFrom: DateTime.now(),
  dateTo: DateTime.now(),
  aggregationLevel: AggregationLevel.detailed,  // ← ВСЕ 9 полей
);
ref.read(exportProvider.notifier).loadReportData(filter1);

// Сокращённая группировка
final filter2 = ExportFilter(
  dateFrom: DateTime.now(),
  dateTo: DateTime.now(),
  aggregationLevel: AggregationLevel.summary,  // ← ТОЛЬКО 6 полей
);
ref.read(exportProvider.notifier).loadReportData(filter2);
```

---

## 🎯 Как добавить в UI

### Вариант 1: RadioButton в фильтрах

```dart
// В _ExportFiltersPanel добавить:
SizedBox(height: 16),
Text('Уровень группировки:', 
    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Row(
  children: [
    Expanded(
      child: RadioListTile<AggregationLevel>(
        contentPadding: EdgeInsets.zero,
        title: const Text('Детальная (все поля)'),
        value: AggregationLevel.detailed,
        groupValue: st.aggregationLevel,  // ← нужно добавить в state
        onChanged: (value) {
          if (value != null) {
            ref.read(exportFilterProvider.notifier)
                .setAggregationLevel(value);
          }
        },
      ),
    ),
    Expanded(
      child: RadioListTile<AggregationLevel>(
        contentPadding: EdgeInsets.zero,
        title: const Text('Краткая (6 полей)'),
        value: AggregationLevel.summary,
        groupValue: st.aggregationLevel,
        onChanged: (value) {
          if (value != null) {
            ref.read(exportFilterProvider.notifier)
                .setAggregationLevel(value);
          }
        },
      ),
    ),
  ],
),
```

### Вариант 2: SegmentedButton (более красиво)

```dart
import 'package:flutter/material.dart';

SegmentedButton<AggregationLevel>(
  segments: const [
    ButtonSegment(
      value: AggregationLevel.detailed,
      label: Text('Детальная'),
    ),
    ButtonSegment(
      value: AggregationLevel.summary,
      label: Text('Краткая'),
    ),
  ],
  selected: {st.aggregationLevel},
  onSelectionChanged: (newSelection) {
    ref.read(exportFilterProvider.notifier)
        .setAggregationLevel(newSelection.first);
  },
)
```

---

## 🔄 Полный поток

```
User выбирает уровень (Detailed/Summary)
    ↓
ExportFilterNotifier.setAggregationLevel(level)
    ↓
ExportFilterState.aggregationLevel = level
    ↓
ExportFilter создаётся с aggregationLevel
    ↓
ExportRepositoryImpl.getExportData(filter)
    ↓
aggregateReports(reports, level: filter.aggregationLevel)
    ↓
UI/Excel получает агрегированные по выбранному уровню данные
```

---

## 📝 Примеры в ExportFilterState

Добавьте в `ExportFilterState`:

```dart
class ExportFilterState {
  // ... существующие поля ...
  
  /// Выбранный уровень агрегации.
  final AggregationLevel aggregationLevel;

  ExportFilterState({
    // ... существующие параметры ...
    this.aggregationLevel = AggregationLevel.detailed,
  });

  /// Создаёт копию состояния с изменёнными полями.
  ExportFilterState copyWith({
    // ... существующие параметры ...
    AggregationLevel? aggregationLevel,
  }) =>
      ExportFilterState(
        // ... существующие поля ...
        aggregationLevel: aggregationLevel ?? this.aggregationLevel,
      );
}

class ExportFilterNotifier extends StateNotifier<ExportFilterState> {
  // ...
  
  /// Установить уровень агрегации.
  void setAggregationLevel(AggregationLevel level) {
    state = state.copyWith(aggregationLevel: level);
  }
}
```

---

## ✅ Плюсы подхода

1. ✅ **Легко добавить новые уровни** — просто добавить ещё один case в enum
2. ✅ **Гибкость** — пользователь выбирает нужный уровень детализации
3. ✅ **Централизованная логика** — всё в `aggregateReports()`
4. ✅ **Совместимость** — отлично работает с Excel и UI
5. ✅ **Масштабируемость** — можно добавить ещё уровни (ultra_brief, detailed_with_custom_field и т.д.)

