# 🔍 Чек-лист аудита модуля «Выгрузка» (Export)

**Дата аудита:** 12.01.2026  
**Статус:** Аудит завершен. Найдено **18 проблем.**

---

## 📊 Краткая сводка

| Категория | Количество |
|-----------|------------|
| 🔴 Нарушения @flutter.mdc (Design System) | 6 |
| 🟠 Deprecated API | 2 |
| 🟡 Архитектурные замечания | 4 |
| 🔵 Дубликаты кода | 3 |
| ⚪ Debug-логирование | 2 |
| 📝 Документация | 1 |

---

## 🔴 Нарушения @flutter.mdc (Design System)

### 1. [НАРУШЕНИЕ] TextField вместо GTTextField
**Файл:** `lib/features/export/presentation/widgets/export_search_action.dart:128`  
**Описание:** Используется стандартный `TextField` вместо кастомного `GTTextField`.  
**Рекомендация:** Заменить на `GTTextField` для соблюдения Design System.

```dart
// Было:
child: TextField(
  controller: ref.watch(_exportSearchControllerProvider),
  // ...

// Должно быть:
child: GTTextField(
  controller: ref.watch(_exportSearchControllerProvider),
  // ...
```

---

### 2. [НАРУШЕНИЕ] TextFormField вместо GTTextField
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart:563`  
**Описание:** Используется стандартный `TextFormField` вместо `GTTextField`.  
**Рекомендация:** Заменить на `GTTextField` для соблюдения Design System.

---

### 3. [НАРУШЕНИЕ] ElevatedButton вместо GTPrimaryButton
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart:625`  
**Описание:** Используется стандартный `ElevatedButton` вместо `GTPrimaryButton`.  
**Рекомендация:** Заменить на `GTPrimaryButton` из `lib/core/widgets/gt_buttons.dart`.

---

### 4. [НАРУШЕНИЕ] OutlinedButton вместо GTSecondaryButton
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart:590,608`  
**Описание:** Используются стандартные `OutlinedButton` и `OutlinedButton.icon`.  
**Рекомендация:** Заменить на `GTSecondaryButton` или `GTTextButton`.

---

### 5. [НАРУШЕНИЕ] FilledButton вместо GTPrimaryButton
**Файл:** `lib/features/export/presentation/widgets/work_search_date_filter.dart:226`  
**Описание:** Используется `FilledButton` вместо `GTPrimaryButton`.  
**Рекомендация:** Заменить на `GTPrimaryButton`.

---

### 6. [НАРУШЕНИЕ] ScaffoldMessenger вместо SnackBarUtils
**Файл:** `lib/features/export/presentation/widgets/work_search_export_action.dart:57,100,119,127`  
**Описание:** Прямое использование `ScaffoldMessenger.of(context).showSnackBar()` вместо `SnackBarUtils`.  
**Рекомендация:** Заменить на:
- `SnackBarUtils.showError(context, message)`
- `SnackBarUtils.showSuccess(context, message)`

---

## 🟠 Deprecated API

### 7. [DEPRECATED] Share.shareXFiles
**Файлы:**
- `lib/features/export/presentation/services/work_search_export_server_service.dart:216`
- `lib/features/export/presentation/widgets/vor_download_action.dart:158`

**Описание:** `Share.shareXFiles` устарел в пакете `share_plus`.  
**Рекомендация:** Заменить на `SharePlus.instance.share()`:

```dart
// Было:
await Share.shareXFiles([XFile(filePath)], text: 'Экспорт: $filename');

// Должно быть:
await SharePlus.instance.share(
  ShareParams(files: [XFile(filePath)], text: 'Экспорт: $filename'),
);
```

---

## 🟡 Архитектурные замечания

### 8. [АРХИТЕКТУРА] DTO в data/datasources
**Файл:** `lib/features/export/data/datasources/work_search_data_source.dart`  
**Описание:** Классы `WorkSearchPaginatedResult` и `WorkSearchFilterValues` объявлены в файле datasource.  
**Рекомендация:** Перенести в `lib/features/export/domain/entities/` или `lib/features/export/data/models/` согласно Clean Architecture.

---

### 9. [АРХИТЕКТУРА] Provider в data слое
**Файл:** `lib/features/export/data/repositories/vor_repository_impl.dart:8`  
**Описание:** `vorRepositoryProvider` объявлен в файле реализации репозитория (data layer).  
**Рекомендация:** Перенести в `lib/features/export/presentation/providers/repositories_providers.dart`.

---

### 10. [АРХИТЕКТУРА] WorkSearchState без Freezed
**Файл:** `lib/features/export/presentation/providers/work_search_provider.dart:7-57`  
**Описание:** Класс `WorkSearchState` реализован вручную с `copyWith`, но не использует `Freezed`.  
**Рекомендация:** Конвертировать в Freezed-класс для гарантии иммутабельности и автогенерации кода:

```dart
@freezed
abstract class WorkSearchState with _$WorkSearchState {
  const factory WorkSearchState({
    required List<WorkSearchResult> results,
    @Default(false) bool isLoading,
    String? error,
    @Default(1) int currentPage,
    @Default(250) int pageSize,
    @Default(0) int totalCount,
  }) = _WorkSearchState;
}
```

---

### 11. [АРХИТЕКТУРА] StateNotifier вместо Notifier
**Файл:** `lib/features/export/presentation/providers/work_search_provider.dart:60`  
**Описание:** Используется устаревший `StateNotifier` / `StateNotifierProvider`.  
**Рекомендация:** Рассмотреть миграцию на `Notifier` / `NotifierProvider` (Riverpod 2.x).

---

## 🔵 Дубликаты кода

### 12. [ДУБЛЬ] Локальный метод _formatDate
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart:656-658`  
**Описание:** Приватный метод `_formatDate` дублирует функцию `formatRuDate` из `lib/core/utils/formatters.dart`.  

```dart
// Было:
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

// Должно быть:
import 'package:projectgt/core/utils/formatters.dart';
// ...
Text('Дата: ${formatRuDate(widget.initialData.workDate)}'),
```

---

### 13. [ДУБЛЬ] Логика сохранения файлов
**Файлы:**
- `lib/features/export/presentation/services/work_search_export_server_service.dart:180-223` (`_saveExcelFile`)
- `lib/features/export/presentation/widgets/vor_download_action.dart:130-162`

**Описание:** Практически идентичная логика сохранения файлов (Web/Desktop/Mobile) в двух местах.  
**Рекомендация:** Вынести в `lib/core/utils/file_save_utils.dart`:

```dart
/// Утилита для кросс-платформенного сохранения файлов.
class FileSaveUtils {
  static Future<String> saveFile({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required MimeType mimeType,
  }) async {
    // Единая логика для Web/Desktop/Mobile
  }
}
```

---

### 14. [ДУБЛЬ] ExportResult локальный класс
**Файл:** `lib/features/export/presentation/services/work_search_export_server_service.dart:227-251`  
**Описание:** Локальный класс `ExportResult` может быть переиспользован в других модулях экспорта.  
**Рекомендация:** Если планируется расширение экспорта — вынести в `lib/core/models/` или `lib/domain/entities/`.

---

## ⚪ Debug-логирование

### 15. [DEBUG] debugPrint в production-коде
**Файл:** `lib/features/export/data/datasources/work_search_data_source_impl.dart`  
**Строки:** 57, 61, 80, 85, 120, 138, 218, 319  
**Описание:** Множественные `debugPrint` с emoji-логами.  
**Рекомендация:** 
- Удалить или заменить на `Logger` из `logger` пакета
- Или использовать `kDebugMode` проверку:

```dart
if (kDebugMode) {
  debugPrint('🔍 [WorkSearch] ...');
}
```

---

### 16. [DEBUG] debugPrint в widget
**Файл:** `lib/features/export/presentation/widgets/export_search_filter_chips.dart:43`  
**Описание:** `debugPrint('Ошибка загрузки фильтров: $e')` в catch-блоке.  
**Рекомендация:** Заменить на полноценное логирование или обработку ошибки через UI.

---

## 📝 Документация

### 17. [ДОКУМЕНТАЦИЯ] Отсутствует документация модуля
**Описание:** Нет файла `docs/export/export_module.md` согласно требованиям `@documentation.mdc`.  
**Рекомендация:** Создать документацию модуля со следующей структурой:
- Описание модуля и его назначение
- Зависимости (таблицы БД, Edge Functions)
- Слой Presentation (экраны, виджеты, провайдеры)
- Слой Domain/Data (сущности, репозитории)
- Дерево файлов
- База данных (если есть специфичные таблицы)
- Бизнес-логика экспорта
- Интеграции с Edge Functions (`generate_vor`, `generate_vor_pdf`, `export-work-search-all`, `export-work-search-pto`)

---

## 🔧 Дополнительные рекомендации

### 18. [ОПТИМИЗАЦИЯ] supabaseClientProvider дублируется
**Файл:** `lib/features/export/presentation/providers/repositories_providers.dart:7-9`  
**Описание:** `supabaseClientProvider` может быть уже объявлен в `lib/core/di/providers.dart`.  
**Рекомендация:** Проверить и использовать единый провайдер из core.

---

## ✅ Положительные аспекты

1. ✅ **Clean Architecture** — модуль имеет чёткое разделение на слои (domain, data, presentation)
2. ✅ **Freezed entity** — `WorkSearchResult` использует Freezed для иммутабельности
3. ✅ **Документированный код** — большинство публичных API имеют doc-комментарии
4. ✅ **Правильное использование `withValues`** — везде используется `Color.withValues(alpha: ...)` вместо устаревшего `withOpacity`
5. ✅ **Нет `print()`** — используется `debugPrint` (хотя и его лучше убрать)
6. ✅ **Кастомные виджеты core** — используются `GTDropdown`, `GTStringDropdown`, `ModalContainerWrapper`, `SnackBarUtils` (частично)

---

## 📋 Приоритет исправлений

### 🔴 Высокий (исправить в первую очередь)
- [ ] #7 — Deprecated `Share.shareXFiles`
- [ ] #6 — Заменить `ScaffoldMessenger` на `SnackBarUtils`
- [ ] #12 — Удалить дубль `_formatDate`

### 🟠 Средний
- [ ] #1-5 — Заменить стандартные виджеты на Design System
- [ ] #8-9 — Исправить нарушения архитектуры
- [ ] #13 — Вынести логику сохранения файлов в core

### 🟡 Низкий
- [ ] #10-11 — Миграция на Freezed/Notifier
- [ ] #15-16 — Удалить/заменить debugPrint
- [ ] #17 — Создать документацию модуля
- [ ] #14, #18 — Оптимизация и рефакторинг

---

## 📌 Команды для актуализации

После внесения изменений выполните:
```bash
dart analyze lib/features/export/
flutter pub run build_runner build --delete-conflicting-outputs
```

---

*Автор: AI Auditor | Правило: @module_audit.mdc*
