# Анализ загрузки данных пользователя (кто открыл смену)

**Дата:** 10 октября 2025 года

---

## Текущая ситуация

### 1. В списке смен (works_master_detail_screen.dart)

**Подход:** FutureBuilder + локальный кэш

```dart
// Строки 51-67
final Map<String, Profile?> _profileCache = {};

Future<Profile?> _getUserProfile(String userId) async {
  if (_profileCache.containsKey(userId)) {
    return _profileCache[userId];  // Из кэша
  }
  
  final profile = await ref.read(profileRepositoryProvider).getProfile(userId);
  _profileCache[userId] = profile;
  return profile;
}

// Строки 340-346 (для каждой карточки смены)
FutureBuilder<Profile?>(
  future: _getUserProfile(work.openedBy),
  builder: (context, snapshot) {
    final String createdBy = snapshot.hasData ? 
      snapshot.data!.shortName! : 
      'ID: ${work.openedBy.substring(0, 4)}...';
    // Отображение: "Открыл: Иванов И.И."
  }
)
```

**Характеристики:**
- ✅ Локальный кэш живёт пока открыт экран
- ✅ При первом обращении: запрос к БД
- ✅ При повторных: данные из кэша (быстро)
- ⚠️ FutureBuilder для каждой карточки (пересоздаётся при скролле)
- ⚠️ Кэш очищается при dispose экрана

---

### 2. В деталях смены (work_data_tab.dart)

**Текущее состояние:** ФИО пользователя НЕ ОТОБРАЖАЕТСЯ

```dart
// Строки 53-54
final bool isOwner = currentProfile != null && work.openedBy == currentProfile.id;
```

**Использование:**
- Проверка прав: является ли текущий пользователь владельцем смены
- НЕ отображается имя пользователя, открывшего смену

**История:**
- 10.10.2025: Блок "Общая информация" удалён из work_data_tab.dart
- В блоке было: "Дата", "Объект", **"Открыл: ФИО"**
- Сейчас: информация "Кто открыл" отсутствует в деталях

---

## Проблемы текущего подхода

### ❌ Проблема 1: Дублирование логики
В `works_master_detail_screen.dart` реализован локальный кэш профилей, но он:
- Не переиспользуется в других экранах
- Не доступен глобально
- Очищается при выходе из экрана

### ❌ Проблема 2: Отсутствие единого источника истины
- Список смен: локальный кэш в State
- Детали смены: данных нет вообще
- Нет централизованного кэша профилей

### ❌ Проблема 3: Неэффективность при навигации
Сценарий:
1. Открыли список смен → загрузили профили в локальный кэш
2. Открыли детали смены → кэш недоступен (другой экран)
3. Вернулись в список → кэш очистился при dispose
4. Все профили загружаются заново

### ❌ Проблема 4: Множественные FutureBuilder
При скролле списка смен:
- Каждая видимая карточка создаёт FutureBuilder
- При быстром скролле: множество параллельных запросов
- Хотя кэш и предотвращает запросы к БД, но FutureBuilder пересоздаётся

---

## Оптимальное решение

### ✅ Вариант 1: Глобальный провайдер кэша профилей (рекомендуется)

**Реализация:**

```dart
// lib/presentation/providers/profiles_cache_provider.dart

class ProfilesCacheNotifier extends StateNotifier<Map<String, Profile?>> {
  final ProfileRepository repository;
  
  ProfilesCacheNotifier(this.repository) : super({});
  
  Future<Profile?> getProfile(String userId) async {
    if (state.containsKey(userId)) {
      return state[userId];
    }
    
    try {
      final profile = await repository.getProfile(userId);
      state = {...state, userId: profile};
      return profile;
    } catch (e) {
      state = {...state, userId: null};
      return null;
    }
  }
  
  void clear() => state = {};
}

final profilesCacheProvider = StateNotifierProvider<ProfilesCacheNotifier, Map<String, Profile?>>(
  (ref) => ProfilesCacheNotifier(ref.read(profileRepositoryProvider))
);

// Удобный провайдер для получения профиля по ID
final userProfileProvider = FutureProvider.family<Profile?, String>((ref, userId) async {
  return ref.read(profilesCacheProvider.notifier).getProfile(userId);
});
```

**Использование в списке смен:**

```dart
// Вместо локального кэша и FutureBuilder
Consumer(
  builder: (context, ref, _) {
    final profileAsync = ref.watch(userProfileProvider(work.openedBy));
    
    return profileAsync.when(
      data: (profile) => Text('Открыл: ${profile?.shortName ?? "..."}'),
      loading: () => Text('Загрузка...'),
      error: (_, __) => Text('ID: ${work.openedBy.substring(0, 4)}...'),
    );
  }
)
```

**Преимущества:**
- ✅ Единый кэш для всего приложения
- ✅ Автоматическое кэширование через Riverpod
- ✅ Кэш не очищается при навигации
- ✅ Меньше кода, проще поддержка
- ✅ Riverpod управляет жизненным циклом

---

### ✅ Вариант 2: Денормализация (для будущего)

При реализации плана оптимизации можно добавить в таблицу `works`:

```sql
ALTER TABLE works ADD COLUMN opened_by_name TEXT;
```

С триггером на обновление при изменении профиля пользователя.

**Плюсы:**
- Моментальное отображение без запросов
- Не нужен кэш

**Минусы:**
- Усложнение схемы БД
- Дополнительные триггеры
- Не актуально, если пользователь меняет имя

---

## Рекомендация

**Перед началом реализации плана оптимизации:**

### Шаг 1: Создать глобальный провайдер кэша профилей
- Создать `lib/presentation/providers/profiles_cache_provider.dart`
- Реализовать `ProfilesCacheNotifier` и `userProfileProvider`

### Шаг 2: Рефакторинг works_master_detail_screen.dart
- Удалить локальный `_profileCache` и `_getUserProfile`
- Заменить `FutureBuilder` на `Consumer` + `userProfileProvider(work.openedBy)`

### Шаг 3: Опционально восстановить отображение в деталях
Если нужно показывать "Кто открыл" в деталях смены:
- Добавить Row в `work_data_tab.dart` с иконкой и `userProfileProvider(work.openedBy)`

### Шаг 4: Тестирование
- Открыть список смен → профили загружаются и кэшируются
- Открыть детали → профиль берётся из кэша (мгновенно)
- Вернуться в список → кэш сохранён, повторных запросов нет

---

## Итог

**Текущий подход:** ❌ Неправильный
- Дублирование логики
- Отсутствие переиспользования
- Неэффективность при навигации

**Правильный подход:** ✅ Глобальный Riverpod-провайдер
- Единый источник истины
- Автоматическое кэширование
- Доступен везде в приложении
- Меньше кода, проще поддержка

**Действие:** ✅ РЕАЛИЗОВАНО

---

## Реализация (10.10.2025)

### Созданные файлы:
1. `lib/presentation/providers/profiles_cache_provider.dart`
   - `ProfilesCacheNotifier`: StateNotifier для глобального кэша
   - `profilesCacheProvider`: провайдер кэша Map<String, Profile?>
   - `userProfileProvider`: FutureProvider.family для получения профиля по ID

### Обновлённые файлы:
1. `lib/features/works/presentation/screens/works_master_detail_screen.dart`
   - ❌ Удалён локальный кэш: `final Map<String, Profile?> _profileCache = {}`
   - ❌ Удалена функция: `Future<Profile?> _getUserProfile(String userId)`
   - ✅ Добавлен импорт: `import 'package:projectgt/presentation/providers/profiles_cache_provider.dart'`
   - ✅ Заменён FutureBuilder на Consumer + userProfileProvider
   - ✅ Упрощена логика: profileAsync.when(data, loading, error)

### Результат:
- ✅ Глобальный кэш профилей доступен во всём приложении
- ✅ Автоматическое кэширование через Riverpod
- ✅ Кэш не очищается при навигации между экранами
- ✅ Меньше кода, проще поддержка
- ✅ Riverpod управляет жизненным циклом автоматически

