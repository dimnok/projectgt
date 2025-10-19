# ✅ ФИЛЬТРАЦИЯ ПО СТАТУСУ ДОГОВОРА

## 🎯 ЧТО СДЕЛАНО

### 1️⃣ Договоры фильтруются по статусу
- ✅ Отображаются только договоры со статусом **`ContractStatus.active`** ("в работе")
- ✅ Договоры со статусами `suspended` (приостановлен) и `completed` (завершён) **НЕ отображаются**

### 2️⃣ Объекты фильтруются по наличию активных договоров
- ✅ Отображаются только объекты, у которых **есть хотя бы 1 активный договор**
- ✅ Объекты без активных договоров **НЕ отображаются** в фильтре

### 3️⃣ Каскадная фильтрация сохраняется
- ✅ При выборе объекта → показываются только его активные договоры
- ✅ Системы фильтруются по выбранным объектам и договорам

---

## 💻 ЧТО ИЗМЕНИЛОСЬ

### `estimate_completion_filter_provider.dart`

```dart
// Импорт типа ContractStatus
import 'package:projectgt/domain/entities/contract.dart';
```

#### 1. Провайдер объектов — только с активными договорами

```dart
/// Провайдер объектов — только с активными договорами
final availableObjectsForCompletionProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(estimateCompletionFilterProvider);
  final contractState = ref.watch(contractProvider);

  // Получаем только активные договоры
  final activeContracts = contractState.contracts
      .where((c) => c.status == ContractStatus.active)
      .toList();

  // Собираем уникальные ID объектов с активными договорами
  final objectIds = activeContracts.map((c) => c.objectId).toSet();

  // Возвращаем только объекты которые есть в активных договорах
  return filter.objects.where((o) => objectIds.contains(o.id)).toList();
});
```

#### 2. Провайдер договоров — только активные

```dart
/// Провайдер договоров — только активные (в работе)
final availableContractsForCompletionProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(estimateCompletionFilterProvider);
  final contractState = ref.watch(contractProvider);

  final selectedObjectIds = filter.objectIds;

  // Фильтруем договоры: только активные со статусом "в работе"
  return contractState.contracts
      .where((c) {
        // Должен быть активный статус
        if (c.status != ContractStatus.active) return false;

        // Если выбраны объекты, договор должен быть для них
        if (selectedObjectIds.isNotEmpty &&
            !selectedObjectIds.contains(c.objectId)) {
          return false;
        }

        return true;
      })
      .toList();
});
```

---

## 📊 ЛОГИКА РАБОТЫ

### Статусы договоров (ContractStatus enum)
```dart
enum ContractStatus {
  active,      // ✅ В работе (показывается)
  suspended,   // ❌ Приостановлен (НЕ показывается)
  completed,   // ❌ Завершён (НЕ показывается)
}
```

### Примеры фильтрации

#### Пример 1: У объекта есть активные и завершённые договоры
```
Объект "Стройка №1"
├─ Договор A (active) → ✅ ПОКАЗЫВАЕТСЯ
├─ Договор B (completed) → ❌ НЕ ПОКАЗЫВАЕТСЯ
└─ Договор C (active) → ✅ ПОКАЗЫВАЕТСЯ
```

#### Пример 2: Объект без активных договоров
```
Объект "Старая стройка"
├─ Договор D (completed)
├─ Договор E (suspended)
└─ Договор F (completed)

↓ РЕЗУЛЬТАТ: Объект НЕ ПОКАЗЫВАЕТСЯ в фильтре
```

#### Пример 3: Объект с только активными договорами
```
Объект "Новая стройка"
├─ Договор X (active)
├─ Договор Y (active)
└─ Договор Z (active)

↓ РЕЗУЛЬТАТ: Объект ПОКАЗЫВАЕТСЯ, все 3 договора доступны
```

---

## ✅ ПРОВЕРКА

```
✅ estimate_completion_filter_provider.dart - NO LINTER ERRORS
✅ Импорт ContractStatus корректен
✅ Логика фильтрации по статусу работает
✅ Объекты фильтруются правильно
✅ Договоры фильтруются правильно
✅ Каскадная фильтрация сохранена
```

---

## 🎯 РЕЗУЛЬТАТ

### Пользователь видит:
1. ✅ **В выпадающем списке объектов** — только объекты с активными договорами
2. ✅ **В выпадающем списке договоров** — только активные договоры (статус = "в работе")
3. ❌ **НЕ видит** договоры со статусами:
   - `suspended` (приостановлен)
   - `completed` (завершён)

---

**Статус:** 🎉 **ГОТОВО**

**Дата:** 2025-10-19
