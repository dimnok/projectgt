# Руководство по разработке

## Начало работы

1. **Клонирование и установка зависимостей**
   ```bash
   flutter pub get
   ```

2. **Запуск кодогенерации**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Настройка окружения**
   - Создайте копию `.env.example` как `.env`
   - Укажите корректные значения для Supabase
   ```
   SUPABASE_URL=https://ваш-проект.supabase.co
   SUPABASE_ANON_KEY=ваш-анонимный-ключ
   ENV=dev
   ```

4. **Запуск приложения**
   ```bash
   flutter run
   ```

## Рекомендации по коду

### Стиль кода

- Следуйте [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Используйте `const` везде, где это возможно
- Документируйте публичные API методы
- Используйте final для всех полей, которые не меняются после инициализации

### BuildContext после await (избегаем use_build_context_synchronously)

- Никогда не используйте `BuildContext` после `await` без проверки на монтирование.
- Для `State`-виджетов используйте проверку:

```dart
if (!mounted) return; // сразу после await и перед использованием context
```

- В колбэках и диалогах, где используется локальный `context`, проверяйте:

```dart
if (!context.mounted) return; // перед Navigator/Scaffold/Theme и т.п.
```

- Где возможно, кэшируйте зависимости от контекста до `await` и используйте их далее:

```dart
final router = GoRouter.of(context);
final navigator = Navigator.of(context);
final messenger = ScaffoldMessenger.of(context);
// ... await ...
if (!mounted) return; // или !context.mounted, если вы в локальном контексте диалога
router.go('/home');
```

- Для Snackbar/диалогов после async-операций: сначала проверка `mounted`, затем показ.
- Избегайте лишних `await` между валидацией и навигацией — по возможности выполняйте навигацию до длительных операций.

### Именование

- Классы: `PascalCase`
- Методы и переменные: `camelCase`
- Константы: `kCamelCase` или `SCREAMING_SNAKE_CASE`
- Приватные поля: `_camelCase`

### Организация файлов

- Файлы UI виджетов: `snake_case.dart`
- Каждый класс/виджет в отдельном файле
- Группируйте связанные классы в одну директорию

## UI-рекомендации

### Общий стиль

- Строгий черно-белый минимализм
- Акцентный цвет: зеленый
- Поддержка светлой и темной темы

### Виджеты

- Создавайте переиспользуемые виджеты в `presentation/widgets/`
- Используйте `ThemeData` и `MediaQuery` для адаптивности
- Всегда оборачивайте состояния в соответствующие Notifier-ы

### Темы

```dart
// Переключение темы
ref.read(themeNotifierProvider.notifier).toggleTheme();

// Использование цветов из темы
final primaryColor = theme.colorScheme.primary;
```

## Работа с Riverpod

### Доступ к состоянию

```dart
// В ConsumerWidget:
final authState = ref.watch(authProvider);

// Обновление состояния (OTP):
await ref.read(authProvider.notifier).requestEmailOtp(email);
```

### Создание провайдеров

```dart
// StateNotifierProvider
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref);
});

// Provider для простых значений
final textProvider = Provider<String>((ref) {
  return "Hello World";
});
```

## Маршрутизация

### Определение маршрутов

Все маршруты определены в `core/common/app_router.dart`.

### Навигация

```dart
// Простой переход
context.go('/profile');

// Переход с именованным маршрутом
context.goNamed('profile');

// Переход с параметрами
context.goNamed('user_profile', pathParameters: {'userId': profile.id});
```

## Работа с Supabase

### Запросы к базе данных

```dart
// Получение одной записи
final response = await client
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();

// Получение списка с сортировкой
final response = await client
    .from('profiles')
    .select('*')
    .order('full_name');
```

### Аутентификация (OTP)

```dart
// Запрос кода на почту
await client.auth.signInWithOtp(email: email, emailRedirectTo: null);

// Подтверждение кода (если используется verifyOtp на бэкенде/клиенте)
// См. presentation/state/auth_state.dart -> verifyEmailOtp

// Выход
await client.auth.signOut();
```

## Отладка и логирование

- Используйте `logger` для структурированного логирования
- Не оставляйте отладочные print в production-коде
- Группируйте логи по уровням важности (info, warning, error)

## Работа с Freezed моделями

### Структура модели

```dart
@freezed
abstract class MyModel with _$MyModel {
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory MyModel({
    required String id,
    String? optionalField,
    @JsonKey(name: 'custom_name') String? customField,
    @Default('default') String defaultField,
  }) = _MyModel;

  const MyModel._();

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

### Ключевые правила

1. **Обязательные элементы**:
   - Ключевое слово `abstract` для всех Freezed классов
   - Приватный конструктор (`const Model._()`) для возможности добавления методов
   - Аннотация `@JsonSerializable` на уровне фабричного конструктора

2. **Параметры JsonSerializable**:
   - `explicitToJson: true` для корректной сериализации вложенных объектов
   - `fieldRename: FieldRename.snake` для snake_case в JSON

3. **Именование файлов**:
   - Основной файл: `my_model.dart`
   - Генерируемые файлы:
     - `my_model.freezed.dart` - код Freezed
     - `my_model.g.dart` - код сериализации

4. **После изменений**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Управление зависимостями

### Структура pubspec.yaml

```yaml
dependencies:
  # Пакеты, используемые в рантайме
  freezed: ^3.0.6
  freezed_annotation: ^3.0.0
  json_serializable: ^6.9.5
  json_annotation: ^4.9.0

dev_dependencies:
  # Пакеты, используемые только при разработке
  build_runner: ^2.4.8
  flutter_lints: ^3.0.1
```

## Работа с аватарами профиля

### Загрузка и отображение

1. **Выбор изображения:**
```dart
final photoService = ref.read(photoServiceProvider);
final file = await photoService.pickImage(ImageSource.gallery);
```

2. **Загрузка на сервер:**
```dart
if (file != null) {
  final url = await photoService.uploadProfilePhoto(userId, file);
  // Обновление профиля с новым URL
  await ref.read(profileProvider.notifier).updateProfile(
    profile.copyWith(photoUrl: url),
  );
}
```

3. **Отображение в UI:**
```dart
CachedNetworkImage(
  imageUrl: profile.photoUrl ?? '',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
)
```

### Рекомендации по работе с изображениями

1. **Оптимизация:**
   - Используйте `CachedNetworkImage` для кэширования
   - Сжимайте изображения перед загрузкой
   - Указывайте размеры для предотвращения layout shifts

2. **Обработка ошибок:**
   - Всегда предоставляйте fallback изображение
   - Обрабатывайте ошибки загрузки
   - Показывайте состояние загрузки

3. **Безопасность:**
   - Проверяйте размер файла перед загрузкой
   - Используйте правильные RLS политики
   - Валидируйте типы файлов

## Сайдбар меню (AppDrawer)

### Структура

```dart
Drawer(
  child: Column(
    children: [
      DrawerHeader(...),  // Профиль пользователя
      DrawerItemWidget(...),  // Пункты меню
      Divider(),
      DrawerItemWidget(...),  // Выход
    ],
  ),
)
```

### Особенности реализации

1. **Профиль пользователя:**
   - Аватар с индикатором статуса
   - Имя и роль пользователя
   - Email с иконкой

2. **Навигация:**
   - Условный рендеринг пунктов меню на основе роли
   - Подсветка активного раздела
   - Анимации при взаимодействии

3. **Состояния:**
   - Обработка загрузки данных
   - Обработка ошибок
   - Индикация активного состояния

### Рекомендации по расширению

1. **Добавление новых пунктов меню:**
```dart
DrawerItemWidget(
  icon: Icons.custom_icon,
  title: 'Новый раздел',
  isSelected: activeRoute == AppRoute.newSection,
  onTap: () => context.goNamed('new_section'),
)
```

2. **Кастомизация:**
   - Используйте `theme` для согласованности стилей
   - Следуйте установленной структуре компонентов
   - Сохраняйте единообразие анимаций 

## Форма сотрудника (EmployeeFormScreen)

- Форма создания/редактирования сотрудника разбита на логические блоки:
  1. Основная информация
  2. Физические параметры
  3. Информация о трудоустройстве
  4. Паспортные данные
  5. Дополнительные документы
- Каждый блок реализован отдельной карточкой (`Card`) для визуального разделения.
- Порядок блоков строго регламентирован для единообразия UX.
- Все поля снабжены валидацией и подсказками.
- Для загрузки и удаления фото сотрудника используется сервис `PhotoService` (см. раздел "Работа с аватарами профиля").
- Используется адаптивная верстка и поддержка тем оформления. 

### Паттерн для форм и модальных окон (Best Practice)

- **Не вкладывайте Scaffold внутрь showModalBottomSheet** — это приводит к ошибкам constraint'ов.
- Для модальных форм используйте отдельный stateful-виджет (например, `ObjectFormModal`), который управляет состоянием и сохранением через Provider.
- Саму форму реализуйте как stateless-виджет (`ObjectFormContent`), чтобы переиспользовать её и в полноэкранном режиме, и в модальном окне.

**Пример:**
```dart
// Stateless-контент формы
class ObjectFormContent extends StatelessWidget { ... }

// Stateful-обёртка для модального окна
class ObjectFormModal extends ConsumerStatefulWidget { ... }
```

- Такой подход унифицирует UX и предотвращает архитектурные ошибки. 

### Мультивыбор объектов в форме сотрудника
- Для поля выбора объектов используется мультиселект на базе DropDownTextField.multiSelection.
- Выбранные объекты отображаются только внутри поля выбора, без дополнительных стикеров (Chip) над полем.
- Фон выпадающего списка всегда белый, а цвет текста элементов — всегда чёрный (Colors.black), что обеспечивает читаемость в любой теме.
- Для кроссплатформенности реализовано явное приведение типов:
  ```dart
  onChanged: (val) {
    setState(() {
      final list = val is List<DropDownValueModel>
          ? val
          : List<DropDownValueModel>.from(val);
      _selectedObjectIds = list.map((e) => e.value.toString()).toList();
    });
  }
  ```
- Кнопки "Отмена" (красная) и "Сохранить" (жёлтая) стилизованы в соответствии с модулем объектов. 

### Унификация форм и модальных окон
- Для всех форм, открываемых в модальных окнах (сотрудники, объекты, контрагенты), используйте Center > SizedBox (width: 50% экрана, min 400, max 900) для ограничения ширины на десктопе. Контент формы — через Center > SingleChildScrollView > ConstrainedBox(maxWidth: 700). Такой подход обеспечивает единообразие UX и предотвращает ошибки constraint'ов.
- Кнопки "Отмена" и "Сохранить" должны быть стилизованы одинаково во всех формах (OutlinedButton/ElevatedButton, высота 44, скругление 12, жирный шрифт). 