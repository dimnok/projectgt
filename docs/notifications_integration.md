## Уведомления в ProjectGT (локальные, iOS/Android)

### Обзор
В приложении внедрены локальные уведомления для iOS/Android на основе пакета `flutter_local_notifications`. Используются таймзоны через `timezone` и реальная локальная зона устройства через `flutter_timezone`.

- Пакеты:
  - `flutter_local_notifications`
  - `timezone`
  - `flutter_timezone`

- Ключевые места кода:
  - `lib/core/notifications/notification_service.dart` — сервис уведомлений (инициализация, запрос прав, планирование/отмена)
  - `lib/main.dart` — инициализация сервиса при старте + переход по уведомлению на экран смены (`/works/{shiftId}`)
  - `lib/features/works/presentation/screens/work_form_screen.dart` — планирование напоминаний при открытии смены
  - `lib/features/works/presentation/screens/work_details_panel.dart` — отмена напоминаний при закрытии смены
  - `lib/features/profile/presentation/screens/notifications_settings_screen.dart` — настройки слотов уведомлений и их отключение

### Инициализация
- В `main.dart` выполняется:
  - `tz.initializeTimeZones()`
  - `ref.read(notificationServiceProvider).initialize(onSelect: ...)` — обработка тапа по уведомлению наведёт на экран смены.
- В `NotificationService.initialize()` дополнительно:
  - Установка локальной таймзоны: `FlutterTimezone.getLocalTimezone()` + `tz.setLocalLocation(...)`
  - Запрос прав: 
    - Android 13+: `requestNotificationsPermission()`
    - iOS/macOS: `requestPermissions(alert/badge/sound)`

### Конфигурация платформ
- Android:
  - `android/app/src/main/AndroidManifest.xml`:
    - `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`
  - Каналы создаются автоматически через `AndroidNotificationDetails`.

- iOS:
  - `ios/Runner/AppDelegate.swift`:
    - `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate`
  - Разрешения запрашиваются в рантайме из сервиса.

### Бизнес‑логика напоминаний
- Когда пользователь открывает смену (`work_form_screen.dart`):
  1) Получаем список слотов из профиля пользователя (см. ниже), формат `['HH:MM', 'HH:MM', 'HH:MM']`.
  2) Планируем уведомления только на будущие времена «сегодня».
  3) В payload уведомления кладём `shiftId`.

- Когда смена закрывается (`work_details_panel.dart`):
  - Отменяем запланированные уведомления по `shiftId`.

- Сервис: `NotificationService.scheduleShiftReminders({shiftId, date, slotTimesHHmm})`:
  - На вход: id смены, дата (обычно `DateTime.now()`), список времён в формате `HH:mm`.
  - Если список пуст, используется дефолт: `['13:00','15:00','18:00']`.

### Настройки пользователя (слоты времени)
- Слоты настраиваются в `Профиль → Уведомления` на отдельном экране: главный тумблер включения и три независимых слота времени (шаг 30 минут). Каждый слот можно отключить.
- Данные сохраняются в JSON‑поле профиля `object.slot_times` (массив строк `HH:MM`). При полном отключении уведомлений ключ `slot_times` удаляется.

#### База данных
- Таблица: `public.profiles`
- Поле хранения используется `object.slot_times` (JSONB). При необходимости можно дополнительно денормализовать в отдельную колонку (опционально).

### Обработка клика по уведомлению
- В `main.dart` обработчик `onDidReceiveNotificationResponse` открывает маршрут `'/works/{payload}'`. Убедитесь, что роут существует в `go_router`.

### Проверка
- Быстрый сценарий:
  - Откройте смену до ближайшего слота, сверните приложение, дождитесь баннера.
  - Закройте смену до следующего слота — уведомление не придёт.

- iOS Simulator особенности:
  - После ручной смены времени системные «календарные» триггеры могут вести себя нестабильно. Надёжнее проверять без смены времени или на реальном устройстве.

### Типичные проблемы
- iOS: в форграунде баннеры не показываются по умолчанию — сверните приложение.
- Android OEM (Xiaomi/Huawei и пр.): агрессивное энергосбережение может «душить» фон.
- Все слоты «прошли» на момент открытия смены — уведомлений на сегодня не будет.

### Как адаптировать под себя
- Изменить тексты/канал:
  - В `NotificationService` поправить `AndroidNotificationDetails`/`DarwinNotificationDetails`.
- Добавить больше слотов:
  - Расширьте форму профиля и передавайте массив `slotTimesHHmm` любой длины.

### Короткие примеры
Планирование из произвольного места кода:
```dart
await ref.read(notificationServiceProvider).scheduleShiftReminders(
  shiftId: 'abc123',
  date: DateTime.now(),
  slotTimesHHmm: ['12:30','15:00','18:45'],
);
```

Отмена по `shiftId`:
```dart
await ref.read(notificationServiceProvider).cancelShiftReminders('abc123');
```

### Итог
Локальные уведомления интегрированы с поддержкой настроек слотов времени на пользователя, корректной работой таймзон и навигацией по тапу на экран смены.


