# Отчёт: Разделение реализаций календаря смен и модуля выгрузки 📋

**Дата:** 18 октября 2025  
**Статус:** ✅ Завершено

---

## 📌 Проблема

**Один источник данных для двух разных сценариев:**
- Модуль **выгрузки в Excel** (Export) использовал `ExportDataSourceImpl`
- Календарь **смен на главном экране** (Home) использовал тот же `ExportDataSourceImpl`
- Это вызывало **конфликты требований**:
  - Выгрузка: нужны **RAW данные** (каждый work_item отдельно)
  - Календарь: нужны **агрегированные данные** (по датам месяца)

**Баг группировки:**
```
export_data_source_impl.dart (строки 117-151)
├─ groupKey БЕЗ даты
├─ Работы от разных дней объединялись
└─ Результат: неправильные суммы по датам в календаре ❌
```

---

## ✅ Решение: Clean Architecture Разделение

### Архитектура ДО:
```
┌─ ExportDataSourceImpl
│  ├─ Группировка (баг!)
│  └─ Повреждённые данные
│
├─ exportProvider ← календарь + выгрузка
│  ├─ ShiftsCalendarFlipCard ❌
│  └─ ExportScreen ❌
```

### Архитектура ПОСЛЕ:
```
┌─ Модуль КАЛЕНДАРЬ (Home)
│  ├─ ShiftsDataSource.dart (интерфейс)
│  ├─ ShiftsDataSourceImpl.dart (реализация)
│  ├─ ShiftsRepository.dart (интерфейс)
│  ├─ ShiftsRepositoryImpl.dart (реализация)
│  ├─ shiftsProvider.dart (Riverpod)
│  └─ ShiftsCalendarFlipCard ✅
│
└─ Модуль ВЫГРУЗКА (Export)
   ├─ ExportDataSourceImpl ✅ (БЕЗ группировки!)
   ├─ ExportRepository
   ├─ exportProvider (Riverpod)
   └─ ExportScreen ✅
```

---

## 📁 Созданные файлы

### 1. Слой Domain (логика календаря)
```
lib/features/home/domain/repositories/
└─ shifts_repository.dart ✅ (NEW)
```

**Содержит:** Абстрактный интерфейс `ShiftsRepository`

### 2. Слой Data (источники данных календаря)
```
lib/features/home/data/datasources/
├─ shifts_data_source.dart ✅ (NEW)
└─ shifts_data_source_impl.dart ✅ (NEW)

lib/features/home/data/repositories/
└─ shifts_repository_impl.dart ✅ (NEW)
```

**Содержит:**
- `ShiftsDataSource` — интерфейс для получения данных
- `ShiftsDataSourceImpl` — реализация с правильной агрегацией ПО ДАТАМ
- `ShiftsRepositoryImpl` — делегирует запросы datasource

### 3. Слой Presentation (провайдеры и виджеты)
```
lib/features/home/presentation/providers/
└─ shifts_provider.dart ✅ (NEW)

lib/features/home/presentation/widgets/
└─ shifts_calendar_widgets.dart ✅ (ОБНОВЛЕНО)

lib/features/home/presentation/screens/
└─ home_screen.dart ✅ (ОБНОВЛЕНО)
```

---

## 🔧 Ключевые изменения

### ShiftsDataSourceImpl - правильная агрегация

```dart
/// Группировка ВКЛЮЧАЕТ дату!
final dateKey = '${workDate.year}-${workDate.month}-${workDate.day}';

// Каждая дата имеет свой ключ
// Работы от разных дней НЕ объединяются ✅
```

### ExportDataSourceImpl - удаление группировки

**ДО:**
```dart
// Группировка БЕЗ даты — баг! ❌
final groupKey = '${report.objectName}_${report.contractName}_...';
// Работы от разных дней объединялись
```

**ПОСЛЕ:**
```dart
// Возвращаем RAW данные БЕЗ группировки ✅
return reports;
```

### ShiftsCalendarFlipCard - новый провайдер

**ДО:**
```dart
class ShiftsCalendarFlipCard extends StatefulWidget {
  final List<dynamic> reports; // из exportProvider ❌
}
```

**ПОСЛЕ:**
```dart
class ShiftsCalendarFlipCard extends ConsumerStatefulWidget {
  // Получает данные из shiftsProvider ✅
  final shiftsAsync = ref.watch(shiftsForMonthProvider(now));
}
```

---

## 📊 Схема данных

### ShiftsDataSourceImpl.getShiftsForMonth()

**Входные данные:**
```sql
SELECT works.date, works.total_amount, objects.name, work_items.system
WHERE DATE_TRUNC('month', works.date) = p_month
```

**Агрегация (на клиенте):**
```dart
// Группируем по дате
final dateKey = '2025-10-05'; // ← ДАТА в ключе!
aggregated[dateKey]['total'] += total_amount;
```

**Выходные данные:**
```dart
[
  {
    'date': DateTime(2025, 10, 5),
    'total': 15000.0,
    'objectName': 'Офис А',
  },
  {
    'date': DateTime(2025, 10, 6),
    'total': 8500.0,
    'objectName': 'Офис Б',
  },
  // ... остальные дни месяца
]
```

### ShiftsDataSourceImpl.getShiftsForDate()

**Входные данные:**
```sql
SELECT works.*, objects.name, work_items.system, work_items.total
WHERE DATE(works.date) = p_date
```

**Агрегация (на клиенте):**
```dart
// Группируем по объектам и системам для выбранной даты
objectTotals['Офис А'] = 15000.0
systemsByObject['Офис А']['Электромонтаж'] = 15000.0
```

**Выходные данные:**
```dart
{
  'date': DateTime(2025, 10, 5),
  'totalAmount': 15000.0,
  'objectTotals': {'Офис А': 15000.0},
  'systemsByObject': {
    'Офис А': {'Электромонтаж': 15000.0}
  },
}
```

---

## 🎯 Влияние на функциональность

### Календарь смен ✅
- **ДО:** Неправильные суммы по датам ❌
- **ПОСЛЕ:** Правильные суммы, каждый день считается отдельно ✅

### Выгрузка в Excel ✅
- **ДО:** Данные объединены неправильно ❌
- **ПОСЛЕ:** RAW данные, каждый work_item — отдельная строка ✅

### Детали смен за день ✅
- **ДО:** Пустые детали (т.к. данные объединены) ❌
- **ПОСЛЕ:** Полные детали по объектам и системам ✅

---

## 🏗️ Структура папок

```
lib/features/
├─ home/
│  ├─ data/
│  │  ├─ datasources/
│  │  │  ├─ shifts_data_source.dart ✅
│  │  │  └─ shifts_data_source_impl.dart ✅
│  │  └─ repositories/
│  │     └─ shifts_repository_impl.dart ✅
│  │
│  ├─ domain/
│  │  └─ repositories/
│  │     └─ shifts_repository.dart ✅
│  │
│  └─ presentation/
│     ├─ providers/
│     │  └─ shifts_provider.dart ✅
│     ├─ widgets/
│     │  └─ shifts_calendar_widgets.dart ✅ (обновлено)
│     └─ screens/
│        └─ home_screen.dart ✅ (обновлено)
│
└─ export/
   └─ data/
      └─ datasources/
         └─ export_data_source_impl.dart ✅ (удалена группировка!)
```

---

## 📋 Чек-лист реализации

- [x] Создана `ShiftsDataSource` (абстрактный интерфейс)
- [x] Создана `ShiftsDataSourceImpl` (с правильной агрегацией по датам)
- [x] Создана `ShiftsRepository` (абстрактный интерфейс)
- [x] Создана `ShiftsRepositoryImpl` (делегирование datasource)
- [x] Созданы Riverpod провайдеры (`shiftsProvider`, `shiftsForMonthProvider`, `shiftsForDateProvider`)
- [x] Обновлена `ShiftsCalendarFlipCard` для использования новых провайдеров
- [x] Обновлена `ShiftsHeatmap` (работает с новой структурой данных)
- [x] Обновлена `_CalendarBackSide` (получает детали из нового datasource)
- [x] Удалена `_ShiftsHeatmap` из `home_screen.dart` (логика перемещена в виджет)
- [x] Обновлена `home_screen.dart` (использует новый `ShiftsCalendarFlipCard`)
- [x] Удалена группировка из `ExportDataSourceImpl` (теперь возвращает RAW данные)
- [x] Код чистый, нет дублирования ✅

---

## 🚀 Результаты

### Рефакторинг принципов
- ✅ **Single Responsibility** — каждый модуль отвечает за одно
- ✅ **Dependency Injection** — провайдеры явно внедряют зависимости
- ✅ **Clean Architecture** — четкое разделение слоев
- ✅ **No Duplication** — нет дублирования логики

### Качество кода
- ✅ Полная документация всех методов
- ✅ Типизация везде (никаких `dynamic` где можно избежать)
- ✅ Ошибки обработаны правильно
- ✅ Нет unused imports/переменных

---

## ⚠️ Следующие шаги

1. **Контрактный виджет** — имеет свой баг с фильтрацией `work_items`
2. **Оптимизация** — рассмотреть серверные RPC функции для агрегации
3. **Тестирование** — покрыть юнит-тестами новые datasources

---

## 📝 Примечания

> **Архитектурный принцип:** Каждый модуль пользуется теми данными, в которых он нуждается, в форме, которая ему удобна. Если разные части приложения требуют разных трансформаций данных — это признак того, что нужны разные datasources!

