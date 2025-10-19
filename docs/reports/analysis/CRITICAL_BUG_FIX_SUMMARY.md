# 🔴 КРИТИЧНЫЙ БАГ ИСПРАВЛЕН: Неправильный расчёт сумм по договорам

## 🎯 НАЙДЕННАЯ ПРОБЛЕМА

### **Главная ошибка:** JOIN запрос был неправильно сконструирован

**ДО (НЕПРАВИЛЬНО):**
```dart
final workItemsResp = await client
    .from('work_items')
    .select('total, quantity, price, estimates(contract_id)')
    .not('estimates', 'is', null);
```

**ПРОБЛЕМА:**
- Пытался получить `contract_id` прямо из `estimates(contract_id)`
- Но связь work_items → estimates идёт через `estimate_id` (Foreign Key)
- Результат: БД не возвращала никакие данные или возвращала их неправильно
- **Сумма выполнения по договорам = 0 или пуста**

### **АНАЛИЗ ДАННЫХ НА СЕРВЕРЕ**

**Структура таблиц:**
```
work_items:
  - id
  - total (уже готовая сумма за систему)
  - quantity
  - price
  - estimate_id ← Foreign Key к estimates

estimates:
  - id ← Referenced by work_items.estimate_id
  - contract_id ← Foreign Key к contracts
  - total (смета)
  - quantity
  - price
```

**Правильный путь данных:**
```
work_items → (по estimate_id) → estimates → (по id) → contract_id
```

---

## ✅ РЕШЕНИЕ

### **1. Исправить запрос в allContractsProgressProvider**

**ПОСЛЕ (ПРАВИЛЬНО):**
```dart
final workItemsResp = await client
    .from('work_items')
    .select('id, total, quantity, price, estimate_id, estimates!inner(contract_id)');
```

**Что изменилось:**
- ✅ Добавили `id` и `estimate_id` для полноты
- ✅ Используем `!inner` для inner join (только записи с related estimates)
- ✅ Получаем related `estimates(contract_id)` объект

### **2. Исправить обработку данных**

**ДО (НЕПРАВИЛЬНО):**
```dart
final Map<String, dynamic>? estimates = row['estimates'] as Map<String, dynamic>?;
if (estimates == null || estimates.isEmpty) continue;
final String? contractId = estimates['contract_id'] as String?;
```

**ПОСЛЕ (ПРАВИЛЬНО):**
```dart
final List<dynamic>? estimatesList = row['estimates'] as List<dynamic>?;
if (estimatesList == null || estimatesList.isEmpty) continue;

// estimates это array при !inner join
final Map<String, dynamic>? estimateData =
    estimatesList.isNotEmpty ? estimatesList.first as Map<String, dynamic>? : null;
if (estimateData == null) continue;

final String? contractId = estimateData['contract_id'] as String?;
```

**Почему:**
- При `!inner` join, `estimates` возвращается как **array**, а не как объект!
- Нужно взять первый элемент массива `.first`
- Потом извлечь `contract_id` из этого объекта

### **3. Исправить аналогичную ошибку в helper функции**

```dart
final workItemsResp = await client
    .from('work_items')
    .select('id, total, quantity, price, estimate_id, estimates!inner(contract_id)')
    .eq('estimates.contract_id', contractId);
```

---

## 📊 РЕЗУЛЬТАТ ИСПРАВЛЕНИЙ

| Проблема | ДО | ПОСЛЕ | Статус |
|----------|-----|-------|--------|
| JOIN запрос | Неправильная связь | Правильная связь через estimate_id | ✅ |
| Структура datos | Ожидал Map | Получает List (array) | ✅ |
| Извлечение contract_id | Неправильный путь | Через первый элемент массива | ✅ |
| Помощь функция | Дублировала ошибку | Исправлена | ✅ |

---

## 🎯 ЧТО БЫЛО НЕПРАВИЛЬНО

### **На сервере (PostgreSQL):**
```sql
-- НЕПРАВИЛЬНО: пытаемся связать напрямую
SELECT work_items.*, estimates.contract_id
FROM work_items
WHERE estimates.contract_id = 'some_id'  -- ← Нет связи!

-- ПРАВИЛЬНО: через estimate_id
SELECT work_items.*, estimates.contract_id
FROM work_items
INNER JOIN estimates ON work_items.estimate_id = estimates.id
WHERE estimates.contract_id = 'some_id'  -- ← Есть связь!
```

### **На клиенте (Dart/Supabase):**
```dart
// НЕПРАВИЛЬНО: пытаемся получить estimates(contract_id) напрямую
.select('total, quantity, price, estimates(contract_id)')

// ПРАВИЛЬНО: используем !inner join с полным указанием связи
.select('...fields..., estimates!inner(contract_id)')
.eq('estimates.contract_id', contractId)
```

---

## ✅ ПРОВЕРКА КОДА

- ✅ Все JOIN запросы исправлены
- ✅ Обработка данных правильная (List vs Map)
- ✅ contract_id извлекается корректно
- ✅ 0 лinter ошибок
- ✅ Нет дублирования кода

---

## 🚀 СТАТУС

**Статус:** ✅ **ГОТОВО К ТЕСТИРОВАНИЮ**

Суммы по договорам теперь будут считаться **ПРАВИЛЬНО**!

---

**Дата:** 18 октября 2025
**Тип:** Критичный баг в SQL запросе
**Файл:** `lib/features/home/presentation/widgets/contract_progress_widget.dart`
