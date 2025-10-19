# 🔍 ПЕРЕАНАЛИЗ: Ошибки расчётов на главном экране

**Дата:** 17 октября 2025  
**Статус:** 🔴 ОБНАРУЖЕНЫ ДВЕ КРИТИЧЕСКИЕ ОШИБКИ

---

## ⚠️ ОШИБКА 1: Календарь смен - неправильная ГРУППИРОВКА на сервере

### Что происходит на сервере (export_data_source_impl.dart, строки 121-150)

```dart
// ШАГ 1: Получаем ВСЕ work_items из БД с датой
// SELECT date, work_items.*, estimates.*, contracts.* 
// FROM works JOIN work_items ... WHERE date BETWEEN dateFrom AND dateTo
// Результат: List<ExportReportModel> с сохранённой датой (workDate)

// ШАГ 2: КРИТИЧЕСКАЯ ОШИБКА - группируем БЕЗ ДАТЫ!
final groupKey = '${report.objectName}_'
    '${report.contractName}_'
    '${report.system}_'
    '${report.subsystem}_'
    '${report.positionNumber}_'
    '${report.workName}_'
    '${report.section}_'
    '${report.floor}_'
    '${report.unit}_'
    '${report.price ?? 0}';
    
// ⚠️ ДАТА НЕ ВХОДИТ В КЛЮЧ! Это значит:
// Одна и та же работа в разные дни считается одной!
```

### Пример ошибки:

```
База данных:
┌─────────┬──────┬───────────────┬─────────────┐
│ date    │ name │ quantity      │ total       │
├─────────┼──────┼───────────────┼─────────────┤
│ 2025-10-01 │ Кабель │ 10 м  │ 1000 ₽  │  ← ПЕРВЫЙ ДЕНЬ
│ 2025-10-02 │ Кабель │ 20 м  │ 2000 ₽  │  ← ВТОРОЙ ДЕНЬ
└─────────┴──────┴───────────────┴─────────────┘

Группировка (НЕПРАВИЛЬНО):
key = "Объект_Договор_Система_..._Кабель_..."
ДВЕ РАЗНЫЕ записи → ОДНА объединённая запись:

❌ ExportReport {
  workDate: 2025-10-01  // ← ОСТАНЕТСЯ ПЕРВАЯ ДАТА!
  quantity: 30 м        // ← СУММАРНОЕ (10 + 20)
  total: 3000 ₽         // ← СУММАРНЫЙ TOTAL
}

Результат: Все смены за 01.10 показывают 3000 ₽
А в действительности:
- 01.10: 1000 ₽  
- 02.10: 2000 ₽
```

### Почему это проявляется на календаре?

```dart
// На клиенте (shifts_calendar_widgets.dart, строки 144-148):
for (final r in reports) {
  if (r.workDate.year == now.year && r.workDate.month == now.month) {
    final d = DateTime(r.workDate.year, r.workDate.month, r.workDate.day);
    final total = (r.total ?? 0).toDouble();
    sumByDate[d] = (sumByDate[d] ?? 0) + total;  // ← СУММИРУЕТ УЖЕ АГРЕГИРОВАННЫЕ ЗНАЧЕНИЯ!
  }
}

Если прилетела одна объединённая запись с total=3000 и workDate=01.10:
✅ sumByDate[01.10] = 3000  // Верно показать за 01.10
❌ ВСЕ остальные дни - не видны!  // За 02.10 будет 0!
```

### Решение

```dart
// ✅ ПРАВИЛЬНО: включить ДАТУ в ключ группировки
final groupKey = '${report.workDate}_'  // ← ДОБАВИТЬ ДАТУ!
    '${report.objectName}_'
    '${report.contractName}_'
    ...
```

---

## ❌ ОШИБКА 2: Договоры - неправильный JOIN в запросе

### Файл
`lib/features/home/presentation/widgets/contract_progress_widget.dart` (строки 72-74)

### Текущий код (НЕПРАВИЛЬНЫЙ)
```dart
// Запрос 2: Выполнено по работам
final workItemsResp = await client
    .from('work_items')
    .select('total, quantity, price, estimates!inner(contract_id)');
    // ⚠️ ОШИБКА: НЕТ ФИЛЬТРА ПО CONTRACT_ID!
```

### Проблема
**Загружается ВСЕ work_items из БД БЕЗ фильтра!**

- ❌ SELECT * FROM work_items JOIN estimates (без WHERE!)
- ❌ Если в БД 10000 work_items - загрузим все 10000!
- ❌ Считаем выполнение ДЛЯ ВСЕХ договоров вместе

### Решение

```dart
// ✅ ПРАВИЛЬНО - С ФИЛЬТРОМ
final workItemsResp = await client
    .from('work_items')
    .select('total, quantity, price, estimates!inner(contract_id)')
    .not('estimates.contract_id', 'is', null);
```

---

## 📊 ИТОГОВАЯ ТАБЛИЦА

| Ошибка | Тип | Влияние | Источник |
|--------|:---:|---------|----------|
| **Календарь** | Группировка БЕЗ даты | 🔴 Суммирует разные дни в один | `export_data_source_impl.dart` (строка 125) |
| **Договоры** | Запрос без WHERE | 🔴 Загружает все 10K+ записей | `contract_progress_widget.dart` (строка 74) |

---

## 🔧 ЧЕК-ЛИСТ ИСПРАВЛЕНИЙ

- [ ] **Календарь:** Добавить `${report.workDate}_` в начало groupKey (строка 125)
- [ ] **Договоры:** Добавить `.not('estimates.contract_id', 'is', null)` (после строки 74)
- [ ] Тестировать календарь за дни с одинаковыми работами
- [ ] Тестировать договоры при выборе разных контрактов  
- [ ] Проверить производительность на больших объёмах
