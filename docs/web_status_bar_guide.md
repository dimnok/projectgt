# 📱 Руководство по настройке статус бара для веб

Этот документ описывает, как использовать новые возможности управления статус баром в веб-версии приложения ProjectGT.

## 🎯 Что было реализовано

### 1. **Единый цвет статус бара с фоном приложения**
- Автоматическая синхронизация цвета статус бара с темой приложения
- Поддержка светлой и темной темы
- Плавные переходы при смене темы

### 2. **Edge-to-edge режим**
- Контент отображается над статус баром
- Создается единое визуальное полотно
- Поддержка safe area для корректного отображения контента

### 3. **Веб-оптимизация**
- Специальные настройки для PWA режима
- Поддержка iOS Safari и Chrome
- Автоматическое управление мета-тегами

## 🚀 Как использовать

### Базовое использование
Все настройки применяются автоматически, никаких дополнительных действий не требуется.

### Кастомный Scaffold с edge-to-edge
```dart
import 'package:projectgt/core/widgets/edge_to_edge_scaffold.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EdgeToEdgeScaffold(
      appBar: AppBar(
        title: Text('Мой экран'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Ваш контент здесь
          Text('Контент под статус баром'),
        ],
      ),
    );
  }
}
```

### Использование EdgeToEdgeHelper
```dart
import 'package:projectgt/core/widgets/edge_to_edge_scaffold.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EdgeToEdgeHelper.scaffold(
      appBar: AppBar(title: Text('Заголовок')),
      body: MyContent(),
      extendBody: true, // Для полного edge-to-edge эффекта
    );
  }
}
```

### Виджет с отступом от статус бара
```dart
Widget build(BuildContext context) {
  return EdgeToEdgeHelper.withStatusBarPadding(
    child: Text('Текст с отступом от статус бара'),
    backgroundColor: Theme.of(context).colorScheme.surface,
  );
}
```

## 🎨 Настройка цветов

### Автоматическая синхронизация
Статус бар автоматически синхронизируется с `ColorScheme.surface` текущей темы:

```dart
// Светлая тема: белый статус бар
ColorScheme.light(surface: Colors.white)

// Темная тема: темный статус бар  
ColorScheme.dark(surface: Colors.grey[900])
```

### Ручная настройка (только для веб)
```dart
import 'package:projectgt/core/utils/web_status_bar.dart';

// Установить кастомный цвет
WebStatusBar.setColor(Colors.blue, isDark: false);

// Синхронизировать с темой
WebStatusBar.syncWithTheme(Theme.of(context));
```

## 📱 PWA оптимизация

### Meta-теги (автоматически настроены)
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
<meta name="theme-color" content="#ffffff">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
```

### CSS переменные
Приложение автоматически устанавливает CSS переменные:
- `--app-surface-color` - цвет поверхности приложения
- `--app-status-bar-color` - цвет статус бара

## 🔧 Технические детали

### Поддерживаемые платформы
- ✅ **Web (Chrome, Safari, Firefox)**
- ✅ **iOS Safari (PWA режим)**
- ✅ **Android Chrome (PWA режим)**
- ✅ **Desktop веб-браузеры**

### Системные требования
- Flutter 3.0+
- Dart 3.0+
- Современные веб-браузеры с поддержкой CSS custom properties

### Автоматические функции
1. **Определение яркости цвета** - автоматический выбор светлых/темных иконок
2. **Safe area поддержка** - корректные отступы для notch устройств
3. **Responsive дизайн** - адаптация под разные размеры экранов
4. **Анимации переходов** - плавная смена цветов при переключении темы

## 🐛 Решение проблем

### Статус бар не меняет цвет
1. Проверьте, что приложение запущено в веб-браузере
2. Убедитесь, что JavaScript включен
3. Откройте Developer Tools и проверьте консоль на ошибки

### Контент перекрывается статус баром
Используйте `EdgeToEdgeScaffold` или добавьте `SafeArea`:
```dart
SafeArea(
  top: true,
  child: YourContent(),
)
```

### PWA не устанавливается
1. Проверьте корректность `manifest.json`
2. Убедитесь, что сайт работает по HTTPS
3. Проверьте наличие service worker

## 📝 Примеры кода

### Экран с полноэкранным изображением
```dart
class FullScreenImagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EdgeToEdgeScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Image.network(
        'https://example.com/image.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
```

### Экран с градиентным фоном
```dart
class GradientPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EdgeToEdgeScaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: EdgeToEdgeHelper.withStatusBarPadding(
          child: Column(
            children: [
              Text('Контент с отступом от статус бара'),
              // Остальной контент
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🔄 Обновления

### v1.0.0 (текущая версия)
- ✅ Базовая поддержка edge-to-edge
- ✅ Автоматическая синхронизация с темой
- ✅ PWA оптимизация
- ✅ Поддержка всех основных браузеров

### Планируемые улучшения
- 🔄 Анимации переходов статус бара
- 🔄 Дополнительные настройки для разработчиков
- 🔄 Поддержка кастомных цветовых схем