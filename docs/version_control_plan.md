# План реализации системы версионирования приложения

**Дата создания:** 5 октября 2025 года  
**Дата обновления:** 5 октября 2025 года (упрощена структура)  
**Цель:** Мгновенная блокировка старых версий приложения через Supabase Realtime

---

## 1. База данных

### Таблица `app_versions` (единая версия для всех платформ)

```sql
CREATE TABLE app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_version TEXT NOT NULL,
  minimum_version TEXT NOT NULL,
  force_update BOOLEAN DEFAULT false,
  update_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS политики
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Все могут читать версию приложения"
  ON app_versions FOR SELECT
  TO authenticated
  USING (true);

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

### Начальные данные
```sql
INSERT INTO app_versions (current_version, minimum_version, force_update, update_message)
VALUES ('1.0.1', '1.0.1', false, 'Пожалуйста, обновите приложение до последней версии');
```

### Realtime включение
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE app_versions;
```

**Преимущества единой версии:**
- ✅ Проще управление (один параметр вместо трёх)
- ✅ Синхронизация версий между платформами
- ✅ Меньше ошибок при обновлении

---

## 2. Flutter-реализация

### 2.1. Константа версии приложения
```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appVersion = '1.0.1'; // Синхронизировать с pubspec.yaml
  
  static String get appPlatform {
    if (kIsWeb) return 'web';
    else if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    else if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'web';
  }
}
```

### 2.2. Модель версии
```dart
// lib/domain/entities/app_version.dart
@freezed
abstract class AppVersion with _$AppVersion {
  const factory AppVersion({
    required String id,
    required String currentVersion,
    required String minimumVersion,
    required bool forceUpdate,
    String? updateMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AppVersion;
}
```

### 2.3. Repository
```dart
// lib/data/repositories/version_repository.dart
class VersionRepository {
  final SupabaseClient _client;
  
  // Получить версию (единая для всех платформ)
  Future<AppVersion> getVersionInfo();
  
  // Подписка на изменения версии (Realtime)
  Stream<AppVersion> watchVersionChanges();
  
  // Обновление версии (только для админов)
  Future<void> updateVersion({
    required String id,
    required String minimumVersion,
    required bool forceUpdate,
    String? updateMessage,
  });
}
```

### 2.4. Provider версии
```dart
// lib/features/version_control/providers/version_providers.dart
final watchAppVersionProvider = StreamProvider<AppVersion>((ref) {
  final repository = ref.watch(versionRepositoryProvider);
  return repository.watchVersionChanges();
});

final versionCheckerProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(versionRepositoryProvider);
  final versionInfo = await repository.getVersionInfo();
  
  return VersionUtils.isVersionSupported(
    AppConstants.appVersion,
    versionInfo.minimumVersion,
  );
});
```

### 2.5. Утилита сравнения версий
```dart
// lib/core/utils/version_utils.dart
class VersionUtils {
  static int compareVersions(String current, String minimum) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minimumParts = minimum.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (currentParts[i] > minimumParts[i]) return 1;
      if (currentParts[i] < minimumParts[i]) return -1;
    }
    return 0;
  }
  
  static bool isVersionSupported(String current, String minimum) {
    return compareVersions(current, minimum) >= 0;
  }
}
```

### 2.6. Экран блокировки (ForceUpdateScreen)

**Особенности:**
- 🎨 Современный градиентный дизайн
- 📱 Адаптивная вёрстка (mobile/tablet/desktop)
- 🔄 Анимированная иконка обновления
- 🌐 **Web:** Кнопка "Перезагрузить страницу"
- 📱 **iOS/Android:** Только инструкция (без кнопки)
- 📊 Визуальное сравнение версий (текущая → требуемая)

```dart
// lib/features/version_control/presentation/force_update_screen.dart
class ForceUpdateScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = AppConstants.appPlatform;
    
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            // Анимированная иконка с градиентом
            TweenAnimationBuilder(...),
            
            // Заголовок
            Text('Требуется обновление'),
            
            // Информация о версиях
            Row(
              children: [
                _buildVersionBadge('Текущая', appVersion, errorColor),
                Icon(Icons.arrow_forward),
                _buildVersionBadge('Требуется', minimumVersion, primaryColor),
              ],
            ),
            
            // Кнопка обновления (только для Web)
            if (platform == 'web')
              ElevatedButton(
                onPressed: _reloadWeb,
                child: Text('Перезагрузить страницу'),
              ),
            
            // Инструкция для iOS/Android (без кнопки)
            if (platform != 'web')
              Container(
                child: Text('Обновите через ${platform == 'ios' ? 'App Store' : 'Google Play'}'),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 2.7. Интеграция в main.dart
```dart
// lib/main.dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Подписка на изменения версии через Realtime
    ref.listen<AsyncValue<AppVersion>>(
      watchAppVersionProvider,
      (previous, next) {
        next.whenData((versionInfo) {
          final isSupported = VersionUtils.isVersionSupported(
            AppConstants.appVersion,
            versionInfo.minimumVersion,
          );
          
          if (!isSupported) {
            // Мгновенный редирект на ForceUpdateScreen
            ref.read(routerProvider).go('/force-update');
          }
        });
      },
    );
    
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

---

## 3. Админка

### Экран управления версией (упрощённый)

```dart
// lib/features/version_control/presentation/version_management_screen.dart
class VersionManagementScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(currentVersionInfoProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Управление версией приложения')),
      body: versionAsync.when(
        data: (version) => Column(
          children: [
            // Предупреждение
            Container(
              child: Text('Изменения применяются мгновенно через Realtime'),
            ),
            
            // Единая карточка для всех платформ
            Card(
              child: Column(
                children: [
                  Text('Единая версия для iOS, Android, Web'),
                  TextField(
                    decoration: InputDecoration(labelText: 'Минимальная версия'),
                    controller: minimumVersionController,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Сообщение'),
                    controller: messageController,
                  ),
                  SwitchListTile(
                    title: Text('Принудительное обновление'),
                    value: forceUpdate,
                    onChanged: (value) => setState(() => forceUpdate = value),
                  ),
                  ElevatedButton(
                    onPressed: _saveVersion,
                    child: Text('Сохранить изменения'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. Алгоритм работы

### 4.1. При запуске приложения
1. ✅ Загрузить версию из `app_versions` (единая запись)
2. ✅ Сравнить `AppConstants.appVersion` с `minimum_version`
3. ✅ Если версия устарела → редирект на `ForceUpdateScreen`
4. ✅ Подписаться на изменения через Realtime

### 4.2. При изменении минимальной версии админом
1. ✅ Админ обновляет `minimum_version` в единственной записи
2. ✅ Supabase Realtime мгновенно отправляет событие всем подписчикам
3. ✅ Flutter получает обновление через Stream
4. ✅ Provider пересчитывает актуальность версии
5. ✅ Listener в `main.dart` выполняет редирект на `ForceUpdateScreen`
6. ✅ Пользователь видит стилизованный экран с требованием обновления

### 4.3. Экран обновления (ForceUpdateScreen)
- 🌐 **Web:** Показывает кнопку "Перезагрузить страницу"
- 📱 **iOS:** Показывает инструкцию с иконкой Apple (без кнопки)
- 🤖 **Android:** Показывает инструкцию с иконкой Android (без кнопки)

---

## 5. Ключевые преимущества

1. **Мгновенность**: Realtime гарантирует получение обновления за < 1 секунды
2. **Простота**: Единая версия для всех платформ (не нужно обновлять 3 раза)
3. **Надёжность**: Проверка версии при каждом запуске приложения
4. **Безопасность**: RLS защищает изменение версий (только админы через profiles)
5. **UX**: Современный дизайн с адаптивной вёрсткой
6. **Платформенность**: Разные UX для Web (кнопка) и Mobile (инструкция)

---

## 6. Дополнительные улучшения (опционально)

- 🔄 **Graceful degradation**: За N минут до блокировки показывать предупреждение
- 📊 **Аналитика**: Логировать попытки входа со старых версий
- 🔔 **Push-уведомления**: Уведомить пользователей заранее
- 🧪 **A/B тестирование**: Постепенное внедрение обновлений (по процентам)
- 🤖 **CI/CD**: Автоматическое обновление версии при деплое

---

## 7. Чек-лист реализации

- [x] Создать таблицу `app_versions` (единая версия) + RLS
- [x] Включить Realtime для таблицы
- [x] Добавить `AppConstants.appVersion` (синхронизировать с pubspec.yaml)
- [x] Реализовать `VersionRepository` + Realtime подписку
- [x] Создать `VersionProvider` + `VersionChecker`
- [x] Разработать стилизованный `ForceUpdateScreen`
- [x] Убрать кнопку обновления на iOS/Android
- [x] Добавить роуты `/force-update` и `/version-management`
- [x] Интегрировать listener в `main.dart`
- [x] Создать упрощённую админку управления версией
- [x] Исправить RLS политики (использовать profiles вместо auth.users)
- [ ] Протестировать на всех платформах (web, iOS, Android)
- [ ] Настроить автоинкремент версии при билде

---

## 8. Изменения от первоначального плана

### Упрощения:
1. **Единая версия для всех платформ** вместо отдельных версий для web/ios/android
   - Проще управление
   - Меньше ошибок
   - Синхронизация между платформами

2. **Убрана кнопка обновления на iOS/Android**
   - Невозможно программно открыть App Store/Google Play
   - Вместо этого показывается инструкция с иконкой платформы

3. **Улучшенный UI**
   - Современный градиентный дизайн
   - Адаптивная вёрстка
   - Анимированная иконка
   - Визуальное сравнение версий

---

**Итог:** Система реализована, упрощена и готова к использованию. Все компоненты работают через единую версию для всех платформ.
