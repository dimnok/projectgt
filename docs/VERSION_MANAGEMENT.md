# Модуль управления версиями приложения (Version Management System)

**Дата актуализации:** 16 октября 2025 года (полная реализация с Realtime)  
**Статус:** ✅ Продакшн-готово  
**Платформы:** iOS, Android, Web (единая версия для всех)

---

## 🚀 Быстрая справка для разработчиков

| Что | Где | Как |
|-----|-----|-----|
| **Текущая версия приложения** | `lib/core/constants/app_constants.dart` | `AppConstants.appVersion` |
| **Таблица БД** | Supabase `app_versions` | 1 запись с `current_version`, `minimum_version`, `force_update` |
| **Проверка версии** | `main.dart` строка 139 | `watchAppVersionProvider` (Realtime Stream) |
| **Блокировка по версии** | `/force-update` | Автоматически при `current < minimum_version` |
| **Админ-панель** | `/settings/version-management` | Только для `role='admin'` |
| **Сравнение версий** | `lib/core/utils/version_utils.dart` | `VersionUtils.compareVersions()` |
| **Репозиторий данных** | `lib/data/repositories/version_repository.dart` | `getVersionInfo()`, `watchVersionChanges()`, `updateVersion()` |
| **RLS политики** | Миграция БД | Читают все, пишут только админы |
| **Realtime** | Supabase publication | Активирован для таблицы `app_versions` |

---

## Важное замечание о структуре данных

> **Архитектура:**
> - **Одна таблица `app_versions`** для управления версиями всех платформ одновременно
> - **Realtime синхронизация** — мгновенное обновление во всех активных приложениях
> - **Встроенная защита RLS** — читают все, пишут только админы
> - **Независимая работа** — не зависит от других модулей, используется глобально в `main.dart`

---

## Описание модуля

### Зачем нужен модуль?

Система управления версиями приложения решает **критическую задачу** — блокировка/выпуск старых версий приложения в production:

✅ **Принудительное обновление** — при критических багах админ может заблокировать все старые версии  
✅ **Graceful выпуск** — плавное выведение из строя устаревшей версии  
✅ **Realtime синхронизация** — изменения видны пользователям **за секунду**, не требует перезагрузки  
✅ **Единая версия для всех платформ** — нет путаницы между iOS, Android, Web  
✅ **Безопасность** — изменять может только администратор через RLS политики

### Ключевые функции

| Функция | Описание |
|---------|---------|
| **Проверка версии на старте** | При открытии приложения проверяется, поддерживается ли текущая версия |
| **Блокировка старых версий** | Если текущая версия < `minimum_version` — пользователь перенаправляется на экран обновления |
| **Принудительное обновление** | Админ может включить флаг `force_update` для мгновенной блокировки |
| **Realtime обновления** | Через Supabase Realtime все активные приложения получают изменения за ~1 сек |
| **Админ-панель** | Экран для управления версиями (для пользователей с ролью `admin`) |
| **Переводимые сообщения** — Кастомное сообщение об обновлении (на русском) |

---

## Структура и файлы модуля

### 📂 Иерархия файлов

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart              # Константа версии (1.0.2)
│   └── utils/
│       └── version_utils.dart              # Утилиты для сравнения версий
│
├── data/
│   ├── models/
│   │   └── app_version_model.dart          # Модель для JSON-сериализации
│   └── repositories/
│       └── version_repository.dart         # Репозиторий для работы с API
│
├── domain/
│   └── entities/
│       └── app_version.dart                # Сущность версии (Freezed)
│
└── features/
    └── version_control/
        ├── presentation/
        │   ├── version_management_screen.dart   # Админ-панель управления
        │   └── force_update_screen.dart         # Экран принудительного обновления
        └── providers/
            └── version_providers.dart           # Riverpod провайдеры

supabase/migrations/
└── 20251005054905_create_app_versions_table.sql  # Миграция БД
```

---

## База данных: Таблица `app_versions`

### Структура таблицы

| Колонка | Тип | Nullable | Default | Описание |
|---------|-----|----------|---------|---------|
| **id** | UUID | ❌ | `gen_random_uuid()` | Первичный ключ, уникальный идентификатор записи |
| **current_version** | TEXT | ❌ | — | **Текущая актуальная версия** приложения (e.g. "1.0.3"). Информационная, не блокирует доступ |
| **minimum_version** | TEXT | ❌ | — | **Минимально поддерживаемая версия**. Версии ниже этого будут заблокированы (e.g. "1.0.2") |
| **force_update** | BOOLEAN | ✅ | `false` | **Флаг принудительного обновления**. Если `true` — все старые версии немедленно перенаправляются на экран обновления |
| **update_message** | TEXT | ✅ | NULL | **Кастомное сообщение для пользователя** об обновлении (e.g. "Критический баг исправлен") |
| **created_at** | TIMESTAMPTZ | ✅ | `now()` | Дата создания записи |
| **updated_at** | TIMESTAMPTZ | ✅ | `now()` | Дата последнего обновления |

### Текущие данные (1 запись)

```
id                  | 383c87f5-11b5-4d6f-8074-ca8fda7c1bc6
current_version     | 1.0.3
minimum_version     | 1.0.2
force_update        | true
update_message      | "Пожалуйста, обновите приложение до последней версии"
created_at          | 2025-10-05 18:31:31 UTC
updated_at          | 2025-10-16 08:23:55 UTC
```

**Количество записей:** 1 (всегда одна запись для всех платформ)  
**RLS:** ✅ Включён

### RLS-политики

#### 1️⃣ Политика на SELECT (чтение)
```sql
CREATE POLICY "Все могут читать версию приложения"
  ON app_versions FOR SELECT
  TO authenticated
  USING (true);
```
✅ **Все аутентифицированные пользователи** могут читать информацию о версии

#### 2️⃣ Политика на UPDATE/INSERT/DELETE (запись)
```sql
CREATE POLICY "Только админы могут изменять версию"
  ON app_versions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```
✅ **Только пользователи с ролью `admin`** могут изменять данные версии

**Текущее состояние безопасности:** ✅ Безопасно (RLS активирован, две чёткие политики)

### Realtime включение

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE app_versions;
```

✅ **Realtime активирован** — изменения версии подписываются и получаются в реальном времени

---

## Бизнес-логика и ключевые особенности

### 1️⃣ Формат версии

Используется **семантическое версионирование**: `major.minor.patch`

Примеры:
- `1.0.0` → первый релиз
- `1.2.3` → версия 1, минор 2, патч 3
- `2.0.0` → мажорное обновление (breaking changes)

### 2️⃣ Логика проверки версии

#### На старте приложения (main.dart)

```dart
// main.dart: Слушание Realtime изменений версии
ref.listen<AsyncValue<dynamic>>(
  watchAppVersionProvider,
  (previous, next) {
    next.whenData((versionInfo) {
      // Проверяем: текущая версия >= минимальной?
      final isSupported = VersionUtils.isVersionSupported(
        AppConstants.appVersion,  // 1.0.2
        versionInfo.minimumVersion,  // 1.0.2
      );

      // Если версия не поддерживается → блокировка
      if (!isSupported) {
        final router = ref.read(routerProvider);
        router.go('/force-update');  // Перенаправляем на экран обновления
      }
    });
  },
);
```

#### Функция сравнения версий (VersionUtils)

```dart
static int compareVersions(String current, String minimum) {
  // Пример: compareVersions('1.2.3', '1.2.0') → 1 (current > minimum)
  
  final currentParts = current.split('.').map(int.parse).toList();
  final minimumParts = minimum.split('.').map(int.parse).toList();
  
  // Сравниваем по компонентам: major → minor → patch
  for (int i = 0; i < 3; i++) {
    if (currentParts[i] > minimumParts[i]) return 1;   // current больше
    if (currentParts[i] < minimumParts[i]) return -1;  // current меньше
  }
  return 0;  // Равны
}

static bool isVersionSupported(String current, String minimum) {
  // Возвращает true если current >= minimum
  return compareVersions(current, minimum) >= 0;
}
```

### 3️⃣ Сценарии блокировки

| Сценарий | `minimum_version` | Действие | Результат |
|----------|-------------------|---------|-----------|
| **Критический баг** | Повышаем (e.g. `1.0.2` → `1.0.3`) | Пользователь 1.0.2 заблокирован | Перенаправление на `/force-update` |
| **Плавный выпуск** | Приватный канал (нет изменений) | Старые версии спокойно работают | Работает нормально |
| **Мгновенная блокировка** | Включаем `force_update = true` | Все пользователи мгновенно получат Realtime событие | Перенаправление |
| **Откат блокировки** | `force_update = false` + понизить `minimum_version` | Отменяем блокировку | Пользователи вернут доступ |

### 4️⃣ Realtime синхронизация

**Поток данных:**

```
Админ изменяет версию
    ↓
Supabase БД обновляется
    ↓
Realtime публикует событие (~1 сек)
    ↓
Все активные приложения получают обновление через Stream
    ↓
watchAppVersionProvider уведомляет слушателей
    ↓
main.dart проверяет версию и редиректит если нужно
```

**Пример поллинга версии (периодический):**

```dart
// Периодическая проверка версии каждые 60 сек
Timer.periodic(const Duration(seconds: 60), (_) async {
  final repository = ref.read(versionRepositoryProvider);
  final versionInfo = await repository.getVersionInfo();
  // Проверяем и редиректим если нужно
});
```

### 5️⃣ Управление через админ-панель

**Экран:** `/settings/version-management`  
**Доступ:** Только для пользователей с ролью `admin`

**Функции:**
- 📝 Ввод минимальной версии (с валидацией формата `\d+\.\d+\.\d+`)
- 📨 Кастомное сообщение об обновлении
- 🔒 Переключатель принудительного обновления
- 💾 Кнопка сохранения с уведомлением
- 🕐 Отображение даты последнего обновления

---

## Связи и интеграции

### Диаграмма взаимодействия

```
┌────────────────────────────────────────┐
│         Supabase app_versions          │
│  (1 запись для всех платформ)          │
│  - current_version                     │
│  - minimum_version                     │
│  - force_update (boolean)              │
│  - update_message                      │
└────────────┬───────────────────────────┘
             │
             │ Realtime Stream
             ↓
┌────────────────────────────────────────┐
│      VersionRepository (data layer)    │
│  - getVersionInfo()                    │
│  - watchVersionChanges() → Stream      │
│  - updateVersion() [админ only]        │
└────────────┬───────────────────────────┘
             │
             │ Riverpod провайдеры
             ↓
┌────────────────────────────────────────┐
│     version_providers.dart             │
│  - watchAppVersionProvider (Stream)    │
│  - versionCheckerProvider              │
│  - currentVersionInfoProvider          │
└────────────┬───────────────────────────┘
             │
   ┌─────────┴──────────┬─────────────────┐
   ↓                    ↓                 ↓
main.dart       VersionManagement   ForceUpdateScreen
              (админ-панель)
```

### Интеграция с другими модулями

| Модуль | Использование |
|--------|---------------|
| **auth** | Проверка `profiles.role == 'admin'` через RLS |
| **router** | Редирект на `/force-update` при блокировке |
| **notifications** | (опционально) Push-уведомление об обновлении |

### Технические зависимости

```yaml
dependencies:
  supabase_flutter: ^1.x          # Realtime Stream
  flutter_riverpod: ^2.x          # State management
  freezed_annotation: ^2.x        # Immutable models
  json_serializable: ^6.x         # JSON serialization
```

### Безопасность

✅ **RLS активирован** — недоверенные пользователи не могут изменять версию  
✅ **Проверка роли** — только `admin` может обновлять  
✅ **Валидация формата** — на frontend (`^\d+\.\d+\.\d+$`)  
✅ **Realtime безопасность** — Supabase контролирует доступ к events

---

## Текущие ограничения и планы развития

### ✅ Реализованные функции

- ✅ Проверка версии на старте приложения
- ✅ Блокировка старых версий с Realtime синхронизацией
- ✅ Админ-панель управления версией
- ✅ Экран принудительного обновления
- ✅ Поддержка всех платформ (iOS, Android, Web)
- ✅ RLS защита (только админы могут изменять)
- ✅ Кастомное сообщение об обновлении

### 🟡 Средний приоритет улучшений

- 🟡 Более грандиозная поддержка версий (e.g. отдельные версии для iOS/Android)
- 🟡 История изменений версий (log таблица)
- 🟡 Отложенный выпуск версии (schedule обновление на определённое время)
- 🟡 A/B тестирование новых версий (gradual rollout)

### 🟢 Низкий приоритет

- 🟢 Analytics отслеживание версий (сколько пользователей обновилось)
- 🟢 Уведомления в Web Dashboard об обновлении
- 🟢 Интеграция с store-агентами для автоматического выпуска

---

## Примечания для разработчиков

### Как развернуть миграцию?

```bash
# Автоматически при flutter_launcher запуске
supabase migration up

# Или ручной запуск
supabase db push
```

### Как проверить текущую версию в БД?

```sql
SELECT current_version, minimum_version, force_update, updated_at 
FROM app_versions 
LIMIT 1;
```

### Как переключить версию на клиенте?

Измените `AppConstants.appVersion` в `lib/core/constants/app_constants.dart`:

```dart
static const String appVersion = '1.0.2';  // Изменить здесь
```

**⚠️ ВАЖНО:** Синхронизируйте с `pubspec.yaml`:

```yaml
version: 1.0.11+34  # X.Y.Z+buildNumber
```

### Как вызвать редирект на обновление вручную (тестирование)?

```dart
// В любом месте в коде
ref.read(routerProvider).go('/force-update');
```

### Как протестировать Realtime обновления?

1. Откройте приложение на двух устройствах
2. На панели администратора измените `minimum_version`
3. На обоих устройствах должны произойти обновления за ~1 сек

### Логирование версий

```dart
final versionInfo = await ref.read(versionRepositoryProvider).getVersionInfo();
print('Current: ${versionInfo.currentVersion}');
print('Minimum: ${versionInfo.minimumVersion}');
print('Force update: ${versionInfo.forceUpdate}');
```

---

## Статус и Roadmap

| Статус | Описание | ETA |
|--------|---------|-----|
| ✅ MVP | Базовая блокировка/разблокировка версий | готово |
| ✅ Realtime | Мгновенное обновление во всех приложениях | готово |
| ✅ Admin UI | Панель управления для админов | готово |
| 🟡 Platform-specific | Отдельные версии для iOS/Android | Q4 2025 |
| 🟡 Gradual Rollout | Выпуск версии поэтапно (10% → 50% → 100%) | Q1 2026 |
| 🟢 Analytics Dashboard | Аналитика обновлений в WebApp | Q2 2026 |

---

## Правила использования в коде

### ✅ Правильно

```dart
// Проверка версии
final isSupported = VersionUtils.isVersionSupported(
  AppConstants.appVersion,
  versionInfo.minimumVersion,
);

// Использование провайдеров
final versionAsync = ref.watch(watchAppVersionProvider);
final checker = ref.watch(versionCheckerProvider);
```

### ❌ Неправильно

```dart
// Не парсить версию вручную
final currentVersion = int.parse(version);

// Не кэшировать версию локально (используй Realtime)
// final version = await storage.getVersion();

// Не читать версию без Riverpod
// await supabase.from('app_versions').select();
```

---

**Последняя актуализация:** 16 октября 2025 года  
**Автор документации:** Senior Developer  
**Контакт для вопросов:** По работе системы версионирования обращайтесь в dev-команду
