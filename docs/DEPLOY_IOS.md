# 🍎 Деплой iOS приложения ProjectGT

## 🚀 Быстрый старт

```bash
# Development сборка
./deploy_ios.sh dev

# Release сборка  
./deploy_ios.sh release

# Архив для деплоя
./deploy_ios.sh archive

# App Store Connect
./deploy_ios.sh store
```

## 📋 Подробные инструкции

### 1. 🔧 Development сборка
Для тестирования на устройстве разработчика:

```bash
./deploy_ios.sh dev
```

**Результат:** `build/ios/iphoneos/Runner.app`
**Установка:** Через Xcode → Window → Devices and Simulators

---

### 2. 🏭 Release сборка
Оптимизированная сборка для распространения:

```bash
./deploy_ios.sh release
```

**Результат:** `build/ios/iphoneos/Runner.app` (42.0MB)
**Использование:** Основа для архивирования

---

### 3. 📦 Создание архива через Xcode

```bash
./deploy_ios.sh archive
```

**Автоматически:**
1. Создаёт release сборку
2. Открывает Xcode с проектом
3. Показывает пошаговые инструкции

**Ручные шаги в Xcode:**
1. Выберите `Any iOS Device` как цель
2. `Product` → `Archive`
3. В Organizer выберите архив
4. `Distribute App`
5. Выберите метод распространения

---

### 4. 🏪 App Store Connect

#### Автоматический способ:
```bash
./deploy_ios.sh store
```

#### Ручной способ (если есть проблемы с сертификатами):
1. Создайте архив через `./deploy_ios.sh archive`
2. В Xcode Organizer выберите архив
3. `Distribute App` → `App Store Connect`
4. Следуйте инструкциям Xcode

---

## 🔐 Настройка сертификатов

### Для App Store:
1. **Apple Developer Account** ($99/год)
2. **iOS Distribution Certificate**
3. **App Store Provisioning Profile**

### Настройка в Xcode:
1. `Xcode` → `Preferences` → `Accounts`
2. Добавьте Apple ID с Developer аккаунтом
3. `Manage Certificates` → `+` → `iOS Distribution`

---

## 📊 Информация о приложении

| Параметр | Значение |
|----------|----------|
| **Название** | ProjectGT |
| **Bundle ID** | `com.projectgt.stroyka` |
| **Версия** | 1.0.1 |
| **Build** | 19 |
| **Deployment Target** | iOS 12.0+ |
| **Team ID** | 8H2R66ST9T |
| **Размер сборки** | ~42.0MB |

---

## 🔍 Методы распространения

### 📱 App Store
- **Аудитория:** Публичная
- **Требования:** Apple Developer Program
- **Процесс:** App Review (1-7 дней)

### 🧪 TestFlight (Beta Testing)
- **Аудитория:** До 10,000 тестеров
- **Требования:** App Store Connect
- **Процесс:** Beta App Review

### 🎯 Ad Hoc
- **Аудитория:** До 100 устройств
- **Требования:** UDID устройств
- **Процесс:** Прямая установка

### 🏢 Enterprise
- **Аудитория:** Сотрудники организации
- **Требования:** Enterprise Developer Program ($299/год)
- **Процесс:** Внутреннее распространение

---

## 🛠 Требования для разработки

- ✅ **macOS** (для Xcode)
- ✅ **Xcode 15+**
- ✅ **Flutter SDK**
- ✅ **iOS 12.0+** устройство/симулятор
- ⚠️ **Apple Developer Account** (для деплоя на устройство)
- ⚠️ **Paid Developer Program** (для App Store)

---

## ❗ Решение проблем

### "No signing certificate found"
1. Убедитесь, что добавили Apple ID в Xcode
2. Создайте iOS Distribution Certificate
3. Проверьте Provisioning Profile

### "Communication with Apple failed"
1. Проверьте интернет соединение
2. Убедитесь, что Apple ID действителен
3. Попробуйте позже (возможны проблемы на стороне Apple)

### "No profiles found"
1. Создайте App Store Provisioning Profile
2. Убедитесь, что Bundle ID зарегистрирован
3. Скачайте профиль в Xcode

---

## 📝 Следующие шаги

1. **Настройте Apple Developer аккаунт**
2. **Создайте App Store listing**
3. **Подготовьте скриншоты и описание**
4. **Настройте метаданные приложения**
5. **Отправьте на Review**

---

## 🆘 Полезные ссылки

- [Apple Developer Program](https://developer.apple.com/programs/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Flutter iOS Deployment](https://flutter.dev/docs/deployment/ios)

---

## 🌐 Веб-деплой

- Домен: `projectgt.surge.sh`
- Команда деплоя:

```bash
flutter build web --release
npx --yes surge ./build/web projectgt.surge.sh
```

- Превью билда: публикуется Surge временно, затем прод — `projectgt.surge.sh`