# ⚡ Быстрый старт: Добавить новый уровень агрегации

## 📌 Задача
Добавить новый уровень группировки, например по только **объект + договор + система + подсистема + наименование** (5 полей)

## ✅ Шаги

### 1. Добавить в enum (aggregate_reports.dart)
```dart
enum AggregationLevel {
  detailed,   // 9 полей (текущее)
  summary,    // 6 полей (текущее)
  ultraBrief, // 5 полей (новое) ← ДОБАВИТЬ
}
```

### 2. Добавить генератор ключей
```dart
class _AggregatedReportData {
  // ... существующие методы ...
  
  /// Генерирует ключ для ультра-краткой группировки.
  static String generateUltraBriefKey({
    required String objectName,
    required String contractName,
    required String system,
    required String subsystem,
    required String workName,
  }) =>
      [
        objectName,
        contractName,
        system,
        subsystem,
        workName,
      ].join('||');
}
```

### 3. Добавить case в функцию aggregateReports()
```dart
List<ExportReport> aggregateReports(
  List<ExportReport> reports, {
  AggregationLevel level = AggregationLevel.detailed,
}) {
  // ... 
  for (final report in reports) {
    final key = level == AggregationLevel.detailed
        ? /* ... detailed ... */
        : level == AggregationLevel.summary
            ? /* ... summary ... */
            : level == AggregationLevel.ultraBrief
                ? _AggregatedReportData.generateUltraBriefKey(
                    objectName: report.objectName,
                    contractName: report.contractName,
                    system: report.system,
                    subsystem: report.subsystem,
                    workName: report.workName,  // ← ТОЛЬКО ЭТИ 5 ПОЛЕЙ
                  )
                : /* ... другие уровни ... */;
    // ...
  }
}
```

### 4. Это всё!

Теперь работает:
```dart
aggregateReports(reports, level: AggregationLevel.ultraBrief)
```

---

## 🎯 Как это использовать в UI

```dart
// Выбор уровня пользователем
SegmentedButton<AggregationLevel>(
  segments: const [
    ButtonSegment(value: AggregationLevel.detailed, label: Text('Детальная')),
    ButtonSegment(value: AggregationLevel.summary, label: Text('Краткая')),
    ButtonSegment(value: AggregationLevel.ultraBrief, label: Text('Супер краткая')), // ← НОВОЕ
  ],
  selected: {st.aggregationLevel},
  onSelectionChanged: (newSelection) {
    ref.read(exportFilterProvider.notifier)
        .setAggregationLevel(newSelection.first);
  },
)
```

---

## ✨ Преимущества

- ✅ 1 место изменения в коде (aggregate_reports.dart)
- ✅ Автоматически работает везде (UI + Excel)
- ✅ Масштабируемо (легко добавить 10й уровень)
- ✅ Чисто и понятно

