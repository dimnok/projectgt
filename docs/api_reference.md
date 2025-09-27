# API Reference

## Core

### Dependency Injection (core/di/providers.dart)

| Провайдер | Тип | Описание |
|-----------|-----|----------|
| `supabaseClientProvider` | `Provider<SupabaseClient>` | Клиент Supabase |
| `authDataSourceProvider` | `Provider<AuthDataSource>` | Источник данных аутентификации |
| `profileDataSourceProvider` | `Provider<ProfileDataSource>` | Источник данных профилей |
| `authRepositoryProvider` | `Provider<AuthRepository>` | Репозиторий аутентификации |
| `profileRepositoryProvider` | `Provider<ProfileRepository>` | Репозиторий профилей |
| `loginUseCaseProvider` | `Provider<LoginUseCase>` | UseCase для входа |
| `requestEmailOtpUseCaseProvider` | `Provider<RequestEmailOtpUseCase>` | Запрос OTP на email |
| `verifyEmailOtpUseCaseProvider` | `Provider<VerifyEmailOtpUseCase>` | Подтверждение OTP кода |
| `logoutUseCaseProvider` | `Provider<LogoutUseCase>` | UseCase для выхода |
| `getCurrentUserUseCaseProvider` | `Provider<GetCurrentUserUseCase>` | UseCase для получения текущего пользователя |
| `getProfileUseCaseProvider` | `Provider<GetProfileUseCase>` | UseCase для получения профиля |
| `getProfilesUseCaseProvider` | `Provider<GetProfilesUseCase>` | UseCase для получения всех профилей |
| `updateProfileUseCaseProvider` | `Provider<UpdateProfileUseCase>` | UseCase для обновления профиля |

### Router (core/common/app_router.dart)

| Константа | Значение | Описание |
|-----------|----------|----------|
| `AppRoutes.login` | `/login` | Маршрут страницы входа |
| `AppRoutes.home` | `/` | Маршрут главной страницы |
| `AppRoutes.profile` | `/profile` | Маршрут профиля пользователя |
| `AppRoutes.users` | `/users` | Маршрут списка пользователей |

## Domain

### Repositories

#### AuthRepository (domain/repositories/auth_repository.dart)

| Метод | Параметры | Возвращаемое значение | Описание |
|-------|-----------|------------------------|----------|
| `requestEmailOtp` | `String email` | `Future<void>` | Отправка OTP-кода на email |
| `verifyEmailOtp` | `String email, String code` | `Future<User>` | Подтверждение OTP и вход |
| `logout` | - | `Future<void>` | Выход пользователя |
| `getCurrentUser` | - | `Future<User?>` | Получение текущего пользователя |

#### ProfileRepository (domain/repositories/profile_repository.dart)

| Метод | Параметры | Возвращаемое значение | Описание |
|-------|-----------|------------------------|----------|
| `getProfile` | `String userId` | `Future<Profile?>` | Получение профиля пользователя |
| `getProfiles` | - | `Future<List<Profile>>` | Получение всех профилей |
| `updateProfile` | `Profile profile` | `Future<Profile>` | Обновление профиля |
| `deleteProfile` | `String userId` | `Future<void>` | Удаление профиля |

## Presentation

### State Management

#### AuthProvider (presentation/state/auth_state.dart)

| Метод | Параметры | Возвращаемое значение | Описание |
|-------|-----------|------------------------|----------|
| `checkAuthStatus` | - | `Future<void>` | Проверка статуса аутентификации |
| `requestEmailOtp` | `String email` | `Future<void>` | Запрос OTP на email |
| `verifyEmailOtp` | `String email, String code` | `Future<void>` | Подтверждение OTP |
| `logout` | - | `Future<void>` | Выход пользователя |

Пример использования (OTP-вход):
```dart
// Получение состояния
final authState = ref.watch(authProvider);
final user = authState.user;

// Запрос кода на почту
await ref.read(authProvider.notifier).requestEmailOtp(email);

// Подтверждение кода из письма
await ref.read(authProvider.notifier).verifyEmailOtp(email, code);
```

#### ProfileProvider (presentation/state/profile_state.dart)

| Метод | Параметры | Возвращаемое значение | Описание |
|-------|-----------|------------------------|----------|
| `getProfile` | `String userId` | `Future<void>` | Загрузка профиля |
| `getProfiles` | - | `Future<void>` | Загрузка списка профилей |
| `updateProfile` | `Profile profile` | `Future<void>` | Обновление профиля |
| `refreshProfile` | `String userId` | `Future<void>` | Принудительное обновление профиля |
| `refreshProfiles` | - | `Future<void>` | Принудительное обновление списка профилей |

Пример использования:
```dart
// Получение состояния
final profileState = ref.watch(profileProvider);
final profile = profileState.profile;
final profiles = profileState.profiles;

// Вызов методов
await ref.read(profileProvider.notifier).getProfiles();
```

### Theme (presentation/theme/theme_provider.dart)

| Метод | Параметры | Возвращаемое значение | Описание |
|-------|-----------|------------------------|----------|
| `toggleTheme` | - | `void` | Переключение между светлой и темной темой |
| `setLightMode` | - | `void` | Установка светлой темы |
| `setDarkMode` | - | `void` | Установка темной темы |

Пример использования:
```dart
// Получение состояния темы
final themeState = ref.watch(themeNotifierProvider);
final isDarkMode = themeState.isDarkMode;

// Переключение темы
ref.read(themeNotifierProvider.notifier).toggleTheme();
```

## UI Widgets

### AppBarWidget (presentation/widgets/app_bar_widget.dart)

```dart
AppBarWidget({
  required String title,
  List<Widget>? actions,
})
```

### AppDrawer (presentation/widgets/app_drawer.dart)

```dart
AppDrawer({
  required AppRoute activeRoute,
})
```

Основной виджет бокового меню с поддержкой:
- Отображения профиля пользователя с аватаром
- Адаптивной навигации
- Ролевого доступа к разделам

| Параметр | Тип | Описание |
|----------|-----|----------|
| `activeRoute` | `AppRoute` | Текущий активный раздел |

**Особенности реализации:**
- Использует `CachedNetworkImage` для эффективной загрузки аватаров
- Поддерживает состояния загрузки и ошибок
- Автоматически обновляется при изменении данных профиля
- Имеет индикатор онлайн-статуса

**Пример использования:**
```dart
AppDrawer(
  activeRoute: AppRoute.home,
)
```

### DrawerItemWidget (presentation/widgets/drawer_item_widget.dart)

```dart
DrawerItemWidget({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  bool isSelected = false,
  bool isDestructive = false,
})
```

### PhotoService (core/services/photo_service.dart)

Сервис для работы с фотографиями профиля:

| Метод | Параметры | Возвращаемое значение | Описание |
|-------|-----------|------------------------|----------|
| `pickImage` | `ImageSource source` | `Future<File?>` | Выбор и обработка изображения |
| `uploadProfilePhoto` | `String userId, File photoFile` | `Future<String?>` | Загрузка фото профиля |
| `deleteProfilePhoto` | `String userId` | `Future<void>` | Удаление фото профиля |

**Структура хранения аватаров в Supabase Storage:**
```
avatars/
  profiles/
    {user_id}/
      avatar.jpg
```

**Политики доступа к аватарам:**
```sql
-- Чтение (публичный доступ)
create policy "Public Access"
on storage.objects for select
to public
using (bucket_id = 'avatars');

-- Загрузка (только свои файлы)
create policy "Upload avatar"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars' 
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);
```

### EmployeeFormScreen (features/employees/presentation/screens/employee_form_screen.dart)

Экран создания и редактирования сотрудника. Реализует пошаговую структуру формы с логическим разделением по блокам:
1. Основная информация
2. Физические параметры
3. Информация о трудоустройстве
4. Паспортные данные
5. Дополнительные документы

- Каждый блок реализован отдельной карточкой (`Card`).
- Все поля снабжены валидацией и подсказками.
- Для загрузки и удаления фото сотрудника используется:
  - `PhotoService.uploadEmployeePhoto(employeeId, file)`
  - `PhotoService.deleteEmployeePhoto(employeeId)` 

- Все бизнес-поля сотрудника реализованы согласно модели.
- Для выбора объектов используется мультиселект с поддержкой множественного выбора (DropDownTextField.multiSelection).
- Выбранные объекты не отображаются отдельными стикерами, только внутри поля выбора.
- Цвет текста в выпадающем списке всегда чёрный для обеспечения читаемости на белом фоне.

### ObjectFormContent (features/objects/presentation/screens/object_form_screen.dart)

Stateless-виджет для отображения формы создания/редактирования объекта. Используется как в полноэкранном режиме, так и внутри модального окна.

```dart
ObjectFormContent({
  required bool isNew,
  required bool isLoading,
  required TextEditingController nameController,
  required TextEditingController addressController,
  required TextEditingController descriptionController,
  required GlobalKey<FormState> formKey,
  required VoidCallback onSave,
  required VoidCallback onCancel,
})
```

### ObjectFormModal (features/objects/presentation/screens/objects_list_screen.dart)

Stateful-виджет для использования внутри showModalBottomSheet. Управляет состоянием формы и сохранением через Provider.

```dart
ObjectFormModal({
  ObjectEntity? object,
})
```

- После успешного сохранения автоматически закрывает модальное окно.
- Использует ObjectFormContent для UI. 

### ContractorFormContent (features/contractors/presentation/screens/contractor_form_screen.dart)

Stateless-форма для создания/редактирования контрагента. Использует Center > SingleChildScrollView > ConstrainedBox(maxWidth: 700) для ограничения ширины. Кнопки и поля стилизованы в едином стиле с сотрудниками и объектами.

### ContractorFormScreen (features/contractors/presentation/screens/contractor_form_screen.dart)

Stateful-обёртка для ContractorFormContent, управляет состоянием, загрузкой и сохранением. Не содержит неиспользуемого кода, архитектурно чиста.

### ContractorsListScreen (features/contractors/presentation/screens/contractors_list_screen.dart)

Экран списка, поиска, добавления и редактирования контрагентов. Модальные окна ограничены по ширине и центрированы на десктопе (Center + SizedBox). Код чистый, без дублирования и неиспользуемых функций. 

### ContractsListScreen (features/contracts/presentation/screens/contracts_list_screen.dart)

ContractsListScreen реализует мастер-детейл паттерн на десктопе (список договоров + панель деталей) и полноэкранный режим на мобильных устройствах. Для поиска используется TextField с debounce, на мобильных устройствах поддерживается pull-to-refresh. Добавление и редактирование договора реализовано через showModalBottomSheet с DraggableScrollableSheet, что обеспечивает корректное позиционирование и отсутствие пустого пространства на десктопе. Контент формы вынесен в отдельный stateless-виджет ContractFormModal.

**AppBadge** используется для отображения статуса договора (например, "Активен", "Архив"). Стикер размещён в правом верхнем углу карточки через Stack+Align:

```dart
Stack(
  children: [
    Card(/* ... */),
    Align(
      alignment: Alignment.topRight,
      child: AppBadge(status: contract.status),
    ),
  ],
)
```

**Вызов модального окна:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.8,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    expand: false,
    builder: (_, controller) => SingleChildScrollView(
      controller: controller,
      child: ContractFormModal(/* ... */),
    ),
  ),
);
```

**Состояние** управляется через Riverpod StateNotifier. Все стили и размеры берутся из ThemeData. Поддерживается строгий минимализм, адаптивность, доступность (Semantics, alt text, фокусировка). 

**Особенности жёсткой логики поиска и обновления:**
- Пока поиск скрыт (`_isSearchVisible == false`), используется только NotificationListener, который ловит overscroll (жест вниз) и открывает поиск. RefreshIndicator не используется — обновление не происходит.
- Как только поиск открыт (`_isSearchVisible == true`), появляется RefreshIndicator, и только теперь pull-to-refresh реально обновляет список.
- Двойное срабатывание полностью исключено на уровне структуры виджетов.
- UX стал предсказуемым и стабильным на всех устройствах, независимо от скорости жеста или особенностей платформы. 