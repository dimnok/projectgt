# ✅ ИСПРАВЛЕНА ОШИБКА: TypeError при клике на дату

## 🐛 ОШИБКА

```
TypeError: Instance of 'MapEntry<String, dynamic>': type 'MapEntry<String, dynamic>' is not a
subtype of type 'MapEntry<String, double>'
```

**Где:** При клике на дату в календаре (при перевороте карточки).

**Файл:** `lib/features/home/presentation/widgets/shifts_calendar_widgets.dart` (строка 388-389)

---

## 🔍 ПРИЧИНА

```dart
// ❌ НЕПРАВИЛЬНО
final sortedObjects = objectTotals.entries
    .cast<MapEntry<String, double>>()  // ← Кастует весь MapEntry
    .toList()
```

**Проблема:**
- `objectTotals` имеет тип `Map<String, dynamic>`
- Значения пришли как `num`, а не `double`
- `.cast<MapEntry<String, double>>()` пытается кастовать сам MapEntry, а не значение
- **Результат:** TypeError при работе с данными

---

## ✅ РЕШЕНИЕ

```dart
// ✅ ПРАВИЛЬНО
final sortedObjects = objectTotals.entries
    .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
    .toList()
  ..sort((a, b) => b.value.compareTo(a.value));
```

**Что изменилось:**
1. `.map()` преобразует каждый entry
2. Кастуем значение `e.value as num` → `.toDouble()`
3. Создаём новый `MapEntry` с правильным типом
4. Сортируем по убыванию суммы

---

## ✅ РЕЗУЛЬТАТ

- ✅ Нет TypeError при клике
- ✅ Детали дня отображаются корректно
- ✅ Сортировка по сумме работает
- ✅ Все типы совпадают

---

**Статус:** ✅ **ИСПРАВЛЕНО**
