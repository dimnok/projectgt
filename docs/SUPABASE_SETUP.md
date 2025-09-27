# 🔧 Настройка Supabase для ProjectGT

## ⚠️ Важно!
Приложение сейчас работает в **демо-режиме** без подключения к реальной базе данных. Для полноценной работы необходимо настроить Supabase проект.

## 🆕 Создание нового Supabase проекта

### 1. Регистрация в Supabase
1. Перейдите на [supabase.com](https://supabase.com)
2. Нажмите **"Start your project"**
3. Войдите через GitHub, Google или создайте аккаунт

### 2. Создание проекта
1. В dashboard нажмите **"New project"**
2. Выберите организацию (или создайте новую)
3. Заполните данные проекта:
   - **Name**: `ProjectGT`
   - **Database Password**: создайте надёжный пароль
   - **Region**: выберите ближайший регион
   - **Pricing Plan**: Free tier (для начала)
4. Нажмите **"Create new project"**

### 3. Получение настроек проекта
После создания проекта (2-3 минуты):

1. Перейдите в **Settings** → **API**
2. Скопируйте:
   - **Project URL** (например: `https://abcdefgh.supabase.co`)
   - **anon public** ключ (длинная строка)

## 🔑 Обновление конфигурации

Отредактируйте файл `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  /// URL Supabase проекта
  static const String supabaseUrl = 'https://ваш-проект-id.supabase.co';
  
  /// Анонимный ключ Supabase
  static const String supabaseAnonKey = 'ваш-анонимный-ключ';
  
  /// Режим отладки
  static const bool debugMode = true; // false для продакшн
  
  /// Показывать ли заглушку вместо реального Supabase
  static const bool useMockData = false; // ВАЖНО: установить false
}
```

## 🗄️ Настройка базы данных

### 1. Создание таблиц

В Supabase Dashboard перейдите в **SQL Editor** и выполните миграции:

```sql
-- Выполните миграции из папки data/migrations/
-- В следующем порядке:
```

1. `profiles_migration.sql` ← **ОБЯЗАТЕЛЬНО ПЕРВАЯ!**
2. `employees_migration.sql`
3. `contractors_migration.sql`
4. `storage_policy_migration.sql`
5. Другие миграции из папки `data/migrations/`

### 2. Настройка Row Level Security (RLS)

RLS уже настроена в миграциях для защиты данных.

### 3. Настройка Storage (для фото)

1. Перейдите в **Storage**
2. Создайте bucket `employees` для фотографий сотрудников
3. Bucket должен быть **public** для просмотра изображений

## 🔐 Настройка аутентификации

1. Перейдите в **Authentication** → **Settings**
2. Настройте провайдеры входа:
   - **Email** (включён по умолчанию)
   - **Google** (опционально)
   - **Apple** (опционально)

## 🚀 Деплой обновлённой версии

После настройки Supabase:

### Веб-версия:
```bash
./deploy.sh
```

### iOS:
```bash
./deploy.sh ios
```

## 🧪 Проверка подключения

1. Запустите приложение
2. В логах должно появиться: `"Supabase initialized successfully"`
3. Попробуйте зарегистрироваться/войти
4. Создайте тестового сотрудника

## 📊 Мониторинг

В Supabase Dashboard доступны:
- **Logs** - логи запросов
- **Metrics** - статистика использования  
- **Database** - просмотр данных
- **Auth** - управление пользователями

## ❗ Решение проблем

### "Failed host lookup"
- Проверьте правильность URL проекта
- Убедитесь, что проект активен в Supabase

### "Invalid API key"
- Проверьте правильность anon ключа
- Убедитесь, что скопировали именно **anon public** ключ

### "Connection refused"
- Проверьте интернет соединение
- Убедитесь, что проект не заморожен (Free tier ограничения)

### "Row Level Security"
- Если данные не отображаются, проверьте RLS политики
- Убедитесь, что пользователь аутентифицирован

## 💡 Полезные ссылки

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Client](https://supabase.com/docs/reference/dart/installing)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage Guide](https://supabase.com/docs/guides/storage)

## 🆘 Поддержка

Если возникли проблемы:
1. Проверьте логи в консоли приложения
2. Проверьте Supabase Dashboard → Logs
3. Убедитесь, что все миграции выполнены
4. Проверьте настройки RLS

---

*После настройки Supabase приложение получит полную функциональность с сохранением данных в облаке!*