# Анализ расчётов: Виджеты календаря смен и договоров

**Дата анализа:** 17 октября 2025

## 📋 Обзор

На главном экране находятся **два основных виджета** с расчётами:
1. **ShiftsCalendarFlipCard** - Календарь смен (передняя сторона)
2. **ContractProgressWidget** - Прогресс договоров

---

## 1️⃣ ShiftsCalendarFlipCard (Виджет календаря смен)

### Файл
```
lib/features/home/presentation/widgets/shifts_calendar_widgets.dart (441 строк)
```

### Источник данных
```dart
final List<dynamic> reports; // ExportReport - из export модуля
```

### Как работает

#### Структура данных в памяти
```dart
// При клике на дату - расчёты на клиенте
final Map<String, double> objectTotals = {};          // По объектам
final Map<String, Map<String, double>> systemsByObject = {}; // По системам в объектах
```

#### Логика расчёта (строки 60-87)
```dart
if (d != null) {
  final DateTime selected = DateTime(d.year, d.month, d.day);
  for (final r in widget.reports) {  // ⚠️ Цикл по всем отчётам
    final DateTime rw = DateTime(r.workDate.year, r.workDate.month, r.workDate.day);
    if (rw == selected) {              // ⚠️ Фильтр по дате на клиенте
      final double total = (r.total ?? 0).toDouble();
      final String obj = (r.objectName ?? '—').toString();
      final String sys = (r.system ?? '—').toString();
      
      // ✅ Сумма по объектам
      objectTotals[obj] = (objectTotals[obj] ?? 0) + total;
      
      // ✅ Сумма по системам в объекте
      final m = systemsByObject.putIfAbsent(obj, () => <String, double>{});
      m[sys] = (m[sys] ?? 0) + total;
    }
  }
}
```

### ⚠️ ПРОБЛЕМЫ

| Проблема | Тип | Последствие |
|----------|:---:|-----------|
| **Цикл по всем отчётам** | O(N) на клиенте | Медленно на больших объёмах |
| **Фильтр по дате на клиенте** | Логика в UI | Не кэшируется |
| **Дублирование с контрактом** | Нет синхронизации | Разные суммы по одним данным |
| **Хранится в State** | Локальная память | Теряется при перестроении |

### ✅ Что считается правильно
- Сумма по объектам за день ✓
- Сумма по системам за день ✓
- Базовая структура логики ✓

---

## 2️⃣ ContractProgressWidget (Виджет договоров)

### Файл
```
lib/features/home/presentation/widgets/contract_progress_widget.dart (515 строк)
```

### Источник данных

#### Провайдер 1: `allContractsProgressProvider` (строки 54-110)
```dart
// Запрос 1: Суммы смет по договорам
final estimatesResp = await client
    .from('estimates')
    .select('contract_id, total, quantity, price');

// Запрос 2: Выполнено по работам
final workItemsResp = await client
    .from('work_items')
    .select('total, quantity, price, estimates!inner(contract_id)');
```

#### Провайдер 2: `contractProgressProvider` (строки 118-135)
```dart
// Fallback с дополнительным запросом если нужна информация по конкретному договору
return allProgressAsync.when(
  data: (allProgress) {
    if (allProgress.byContract.containsKey(contractId)) {
      return allProgress.byContract[contractId]!;
    }
    return _fetchContractProgress(ref, contractId); // ⚠️ Отдельный запрос
  },
  loading: () => _fetchContractProgress(ref, contractId),
  error: (_, __) => _fetchContractProgress(ref, contractId),
);
```

### Логика расчёта

#### Расчёт суммы (строки 44-48)
```dart
double _calculateRowTotal(Map<String, dynamic> row) {
  final double quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
  final double price = (row['price'] as num?)?.toDouble() ?? 0;
  return (row['total'] as num?)?.toDouble() ?? (quantity * price);
}
```

#### Алгоритм (строки 62-86)
```dart
// Шаг 1: Загружаем все сметы, считаем по договорам
for (final row in (estimatesResp as List)) {
  final String? contractId = row['contract_id'] as String?;
  if (contractId == null) continue;
  final double rowTotal = _calculateRowTotal(row);
  estimatesTotalByContract[contractId] =
      (estimatesTotalByContract[contractId] ?? 0) + rowTotal;
}

// Шаг 2: Загружаем все выполненные работы, считаем по договорам
for (final row in (workItemsResp as List)) {
  final Map<String, dynamic>? estimates = row['estimates'] as Map<String, dynamic>?;
  if (estimates == null) continue;
  final String? contractId = estimates['contract_id'] as String?;
  if (contractId == null) continue;
  final double rowTotal = _calculateRowTotal(row);
  executedTotalByContract[contractId] =
      (executedTotalByContract[contractId] ?? 0) + rowTotal;
}

// Шаг 3: Определяем договор с лучшим прогрессом
byContract.forEach((cid, prog) {
  final double ratio = prog.estimatesTotal > 0
      ? (prog.executedTotal / prog.estimatesTotal)
      : 0;
  if (ratio > bestRatio) {
    bestRatio = ratio;
    best = cid;
  }
});
```

### ⚠️ ПРОБЛЕМЫ

| Проблема | Тип | Последствие |
|----------|:---:|-----------|
| **Два запроса к БД** | SELECT estimates + SELECT work_items | N+1 проблема |
| **LEFT JOIN вместо INNER** | Может загрузить сметы без работ | Неправильный расчёт выполнения |
| **Fallback запросы** | При ошибке делает ещё запросы | Перегруз БД |
| **Отсутствует GROUP BY** | Данные не агрегированы на БД | Нагружает память клиента |
| **Нет кэширования** | FutureProvider пересчитывает всё | Лишние запросы при перестроении |

### ✅ Что считается правильно
- Расчёт сметы: `quantity * price` ✓
- Расчёт прогресса: `executed / estimated` ✓
- Выбор лучшего договора ✓

### ❌ Что считается неправильно
- Два отдельных запроса вместо одного ✗
- Клиентский цикл вместо GROUP BY ✗
- Отсутствует обработка NULL ✗
- Fallback запросы создают лишнюю нагрузку ✗

---

## 🔄 Сравнение двух виджетов

| Аспект | Календарь смен | Договоры |
|--------|:-:|:-:|
| **Источник данных** | ExportReport (память) | Supabase (БД) |
| **Агрегация** | Клиент | Частично клиент |
| **Фильтрация** | Клиент (по дате) | Клиент (по договору) |
| **Производительность** | 🟡 Средняя | 🟡 Средняя |
| **Масштабируемость** | ❌ Плохая | ❌ Плохая |
| **Кэширование** | ❌ Нет | ✅ FutureProvider |

---

## 📊 Рекомендации по оптимизации

### Для ShiftsCalendarFlipCard
```dart
// ❌ БЫЛО (на клиенте)
for (final r in widget.reports) {
  if (DateTime(r.workDate.year, r.workDate.month, r.workDate.day) == selected) {
    objectTotals[obj] = (objectTotals[obj] ?? 0) + r.total;
  }
}

// ✅ ДОЛЖНО БЫТЬ (на сервере)
// RPC функция: get_day_summary(date) -> по объектам + системам
// Одна загрузка данных вместо цикла
```

### Для ContractProgressWidget
```dart
// ❌ БЫЛО (два запроса + цикл)
final estimatesResp = await client.from('estimates').select(...);
final workItemsResp = await client.from('work_items').select(...);

// ✅ ДОЛЖНО БЫТЬ (один GROUP BY запрос)
// SELECT 
//   contract_id,
//   SUM(estimates.total) as estimates_total,
//   SUM(work_items.total) as executed_total
// FROM estimates
// LEFT JOIN work_items ...
// GROUP BY contract_id
```

---

## 🎯 Критические точки

### 1. Синхронизация данных между виджетами
- Календарь считает по `reports` (ExportReport)
- Договоры считают по `estimates` + `work_items`
- **Нет гарантии, что это одни и те же данные!**

### 2. Перестроения
- Календарь: State + Map в памяти
- Договоры: FutureProvider (кэширование)
- **При изменении данных календарь не обновляется автоматически**

### 3. Производительность на больших объёмах
- 1000+ смен → медленный цикл в календаре
- 100+ договоров → медленные запросы контрактов
- Нет пагинации, нет лимитов

---

## 🔧 План улучшений

### Краткосрочные (быстрые)
1. ✅ Добавить `LIMIT` в запросы договоров
2. ✅ Кэшировать `reports` в провайдер вместо State
3. ✅ Использовать `GROUP BY` на БД для договоров

### Среднесрочные (1-2 недели)
1. Создать RPC функцию для календаря: `get_day_summary(date)`
2. Создать RPC функцию для договоров: `get_contracts_progress()`
3. Переместить расчёты на сервер

### Долгосрочные (архитектура)
1. Унифицировать источники данных (только БД)
2. Использовать Riverpod везде вместо State
3. Добавить websocket для real-time обновлений

---

## ✅ Статус

**Текущее состояние:** 🟡 Работает, но неоптимально  
**Критичность:** 🟡 Средняя (влияет на UX при больших объёмах)  
**Рекомендуемая дата внедрения улучшений:** Конец октября 2025
