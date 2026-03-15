# 🔧 Настройка Supabase для ProjectGT (Self-hosted)

**Текущий статус:** Переход на Self-hosted сервер завершен (15.03.2026).
**Project URL:** `https://api.progt.ru`
**Legacy Project ID (Cloud):** `hzcawspbkvkrsmsklyuj` (сохранен для обратной совместимости)

## ⚠️ Важно!
Приложение полностью переведено на собственный сервер (Self-hosted Supabase). Все данные, функции и хранилище (Storage) теперь находятся на VPS.

## 🔑 Конфигурация приложения

Основные настройки находятся в `lib/core/config/app_config.dart` и файле `.env`.

### 1. Файл .env (для нативных платформ)
```env
# SELF-HOSTED Supabase
SUPABASE_URL=https://api.progt.ru
SUPABASE_ANON_KEY=eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9... (ваш ключ)
ENV=dev
```

### 2. Файл lib/core/config/app_config.dart (для Web и Fallback)
```dart
class AppConfig {
  static String get supabaseUrl => 'https://api.progt.ru';
  static String get supabaseAnonKey => 'ваш-анонимный-ключ';
  static bool get useMockData => false;
}
```

## 🗄️ Инфраструктура Self-hosted

### 1. База данных и RLS
- База данных полностью мигрирована из Supabase Cloud.
- Все политики Row Level Security (RLS) активны и настроены для изоляции данных по `company_id`.
- Для управления доступом используется функция `get_my_company_ids()`.

### 2. Edge Functions (26 функций)
- Все функции перенесены на новый сервер.
- Вызов функций происходит через стандартный API Gateway: `https://api.progt.ru/functions/v1/`.
- Настроены секреты для интеграций:
  - **DaData** (поиск по ИНН)
  - **Notisend** (отправка SMS/OTP)
  - **Telegram** (уведомления)
  - **Firebase** (Push-уведомления)

### 3. Storage (Хранилище)
- Используется локальное хранилище на диске VPS.
- Бакеты: `avatars`, `employees`, `contractors`, `works`.
- Доступ к файлам осуществляется через публичные URL: `https://api.progt.ru/storage/v1/object/public/...`.

## 🚀 Разработка и Деплой

### Локальная разработка
Для локального запуска достаточно обновить `.env` файл актуальными данными.

### CI/CD (GitHub Actions)
При деплое через GitHub Actions необходимо обновить секреты репозитория:
- `SUPABASE_URL`: `https://api.progt.ru`
- `SUPABASE_ANON_KEY`: (ваш новый ключ)
- `SUPABASE_SERVICE_ROLE_KEY`: (ключ для административных действий, если требуется)

## ❗ Решение проблем на Self-hosted

### Ошибки 401 Unauthorized
- Проверьте актуальность `SUPABASE_ANON_KEY`.
- Убедитесь, что JWT секрет на сервере совпадает с тем, которым подписан ключ.

### Ошибки 404 Not Found (Edge Functions)
- Проверьте, что функция задеплоена на сервере.
- Убедитесь, что Kong API Gateway корректно пробрасывает запросы на `functions-v1`.

### Проблемы со Storage
- Проверьте права доступа к папке хранения на VPS.
- Убедитесь, что RLS политики бакета позволяют загрузку/чтение.

---

## 💡 Полезные ссылки
- [Документация по архитектуре RBAC](architecture/rbac.md)
- [Стандарт документации модулей](development_guide.md)

---
*Последнее обновление: 15 марта 2026 г.*
