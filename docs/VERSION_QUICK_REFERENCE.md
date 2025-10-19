# Система версионирования приложения — Краткая справка

## 📊 Архитектура в одной картинке

```
┌─────────────────────────────────────────────────────────────┐
│                  АРХИТЕКТУРА ВЕРСИОНИРОВАНИЯ                │
└─────────────────────────────────────────────────────────────┘

1️⃣ БД СЛОЙ
┌────────────────────────────────┐
│  Supabase: app_versions       │
│  ├─ id (UUID)                 │
│  ├─ current_version (1.0.3)   │
│  ├─ minimum_version (1.0.2)   │ ← Блокирует старые версии
│  ├─ force_update (true/false) │ ← Принудительная блокировка
│  └─ update_message (TEXT)     │
│                               │
│  RLS: читают ВСЕ              │
│       пишут ТОЛЬКО АДМИНЫ      │
│  Realtime: ✅ АКТИВЕН          │
└────────────────────────────────┘

2️⃣ РЕПОЗИТОРИЙ СЛОЙ
┌────────────────────────────────┐
│  VersionRepository             │
│  ├─ getVersionInfo()           │
│  ├─ watchVersionChanges()      │ ← Realtime Stream
│  └─ updateVersion()            │ ← Только админы
└────────────────────────────────┘

3️⃣ БИЗНЕС-ЛОГИКА СЛОЙ
┌────────────────────────────────┐
│  VersionUtils                  │
│  ├─ compareVersions()          │ ← Сравнивает версии
│  └─ isVersionSupported()       │ ← Проверяет поддержку
└────────────────────────────────┘

4️⃣ UI СЛОЙ
┌─────────────────────┬─────────────────────┐
│  VersionManagement  │  ForceUpdateScreen  │
│  (админ-панель)     │  (блокировка)       │
└─────────────────────┴─────────────────────┘

5️⃣ ГЛАВНОЕ ПРИЛОЖЕНИЕ
┌────────────────────────────────┐
│  main.dart                     │
│  - Слушает watchAppVersion     │
│  - Проверяет версию            │
│  - Редиректит если нужно       │
└────────────────────────────────┘
```

---

## 🎯 Как это работает?

### Сценарий 1: Обновление версии (Админ блокирует старую версию)

```
1. Админ открывает экран управления версией
   ↓
2. Меняет minimum_version с 1.0.1 на 1.0.2
   ↓
3. Нажимает "Сохранить"
   ↓
4. VersionRepository.updateVersion() отправляет UPDATE в БД
   ↓
5. Supabase Realtime публикует событие (~1 сек)
   ↓
6. Все активные приложения получают обновление через Stream
   ↓
7. watchAppVersionProvider уведомляет слушателей в main.dart
   ↓
8. main.dart проверяет: AppConstants.appVersion (1.0.1) < minimum_version (1.0.2)
   ↓
9. Результат: ЗАБЛОКИРОВАН → redirect на /force-update
   ↓
10. Пользователь видит экран обновления
```

### Сценарий 2: Запуск приложения (Версия не поддерживается)

```
1. Пользователь открывает приложение
   ↓
2. main.dart инициализируется
   ↓
3. Запускается watchAppVersionProvider
   ↓
4. Repository делает getVersionInfo() из БД
   ↓
5. Проверка: isVersionSupported(appVersion, minimumVersion)
   ↓
6. Если ПОДДЕРЖИВАЕТСЯ → открыть HomeScreen
   ↓
7. Если НЕ ПОДДЕРЖИВАЕТСЯ → redirect на /force-update (блокировка)
```

---

## 🔑 Ключевые файлы и их роли

| Файл | Строк | Роль | Критично |
|------|-------|------|----------|
| `lib/core/constants/app_constants.dart` | 28 | Константа версии (1.0.2) | 🔴 Да |
| `lib/core/utils/version_utils.dart` | 49 | Сравнение версий | 🔴 Да |
| `lib/data/repositories/version_repository.dart` | 88 | API к БД | 🔴 Да |
| `lib/data/models/app_version_model.dart` | 26 | JSON сериализация | 🟡 Важно |
| `lib/domain/entities/app_version.dart` | 33 | Freezed модель | 🟡 Важно |
| `lib/features/version_control/providers/version_providers.dart` | 59 | Riverpod провайдеры | 🔴 Да |
| `lib/features/version_control/presentation/version_management_screen.dart` | 618 | Админ-панель | 🟡 Важно |
| `lib/features/version_control/presentation/force_update_screen.dart` | 349 | Экран блокировки | 🟡 Важно |
| `lib/main.dart` | (119-155) | Слушание Realtime | 🔴 Да |
| `supabase/migrations/20251005054905_create_app_versions_table.sql` | 47 | Миграция БД | 🔴 Да |

---

## 📋 Таблица БД: Полный справочник

### Колонки и типы данных

```sql
-- Структура таблицы app_versions
CREATE TABLE app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    current_version TEXT NOT NULL,              -- e.g., "1.0.3"
    minimum_version TEXT NOT NULL,              -- e.g., "1.0.2"
    force_update BOOLEAN DEFAULT false,         -- e.g., true/false
    update_message TEXT,                        -- e.g., "Критический баг"
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Текущая запись в БД (16 октября 2025)
id                  = 383c87f5-11b5-4d6f-8074-ca8fda7c1bc6
current_version     = 1.0.3
minimum_version     = 1.0.2
force_update        = true
update_message      = "Пожалуйста, обновите приложение до последней версии"
created_at          = 2025-10-05 18:31:31 UTC
updated_at          = 2025-10-16 08:23:55 UTC
```

### RLS Политики

```sql
-- Политика 1: Чтение (все могут читать)
CREATE POLICY "Все могут читать версию приложения"
  ON app_versions FOR SELECT
  TO authenticated
  USING (true);

-- Политика 2: Запись (только админы)
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

---

## 🧪 Тестирование

### Тест 1: Проверка блокировки версии

```bash
# 1. В БД установить минимальную версию выше текущей
UPDATE app_versions 
SET minimum_version = '2.0.0' 
WHERE id = '383c87f5-11b5-4d6f-8074-ca8fda7c1bc6';

# 2. Перезагрузить приложение
# → Должно перенаправить на /force-update

# 3. Откатить изменения
UPDATE app_versions 
SET minimum_version = '1.0.2' 
WHERE id = '383c87f5-11b5-4d6f-8074-ca8fda7c1bc6';

# 4. Перезагрузить приложение
# → Должно открыться нормально
```

### Тест 2: Realtime синхронизация

```
1. Откройте приложение на двух устройствах
2. На панели администратора измените minimum_version
3. На обоих устройствах должно обновиться за ~1 сек
4. Если minimum_version > текущей версии → редирект на /force-update
```

### Тест 3: Проверка прав администратора

```dart
// Пользователь без role='admin' не может вызвать updateVersion()
// Попытка приведёт к ошибке RLS policy violation

final repository = ref.read(versionRepositoryProvider);
try {
  await repository.updateVersion(
    id: versionId,
    minimumVersion: '2.0.0',
    forceUpdate: true,
  );
  // ❌ RLS Policy violation
} catch (e) {
  print('Ошибка: $e'); // Policy violation
}
```

---

## 💡 Примеры использования в коде

### Пример 1: Проверка версии вручную

```dart
import 'package:projectgt/core/utils/version_utils.dart';
import 'package:projectgt/core/constants/app_constants.dart';

// Сравнение версий
final result = VersionUtils.compareVersions('1.2.3', '1.2.0');
// result = 1 (current > minimum)

// Проверка поддержки
final isSupported = VersionUtils.isVersionSupported('1.0.2', '1.0.2');
// isSupported = true
```

### Пример 2: Получение версии из Realtime

```dart
// В любом ConsumerWidget
final versionAsync = ref.watch(watchAppVersionProvider);

versionAsync.when(
  data: (versionInfo) {
    print('Current: ${versionInfo.currentVersion}');
    print('Minimum: ${versionInfo.minimumVersion}');
  },
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => Text('Ошибка: $err'),
);
```

### Пример 3: Обновление версии (администратор)

```dart
// Только для пользователей с role='admin'
final repository = ref.read(versionRepositoryProvider);

await repository.updateVersion(
  id: versionId,
  minimumVersion: '1.0.3',
  forceUpdate: true,
  updateMessage: 'Критический баг исправлен',
);
```

---

## ❌ Частые ошибки

### ❌ Ошибка 1: Забыли обновить версию в pubspec.yaml

```yaml
# ❌ НЕПРАВИЛЬНО
# pubspec.yaml: version: 1.0.1+1
# app_constants.dart: appVersion = '1.0.2'

# ✅ ПРАВИЛЬНО
# Синхронизировать обе версии
pubspec.yaml: version: 1.0.2+22
app_constants.dart: appVersion = '1.0.2'
```

### ❌ Ошибка 2: Попытка изменить версию без прав админа

```dart
// ❌ Вызовет RLS policy violation
await updateVersion(); // User role != 'admin'

// ✅ Проверить роль перед вызовом
if (userProfile.role == 'admin') {
  await updateVersion();
}
```

### ❌ Ошибка 3: Неправильный формат версии

```dart
// ❌ Неправильно
minimum_version = '1.0' // Без patch
minimum_version = 'v1.0.0' // С префиксом

// ✅ Правильно
minimum_version = '1.0.0' // Формат major.minor.patch
```

---

## 🚀 Чек-лист для продакшна

- [ ] Версия в `pubspec.yaml` синхронизирована с `AppConstants.appVersion`
- [ ] RLS политики включены на таблице `app_versions`
- [ ] Realtime активирован для таблицы `app_versions`
- [ ] main.dart слушает `watchAppVersionProvider`
- [ ] Админ-панель доступна только пользователям с `role='admin'`
- [ ] Экран `/force-update` красиво оформлен и работает на всех платформах
- [ ] Тестировано: редирект при `current < minimum_version`
- [ ] Тестировано: Realtime обновления работают за ~1 сек
- [ ] Документация актуальна и понятна команде

---

**Дата обновления:** 16 октября 2025  
**Версия документации:** 1.0  
**Статус:** ✅ Актуально для продакшна
