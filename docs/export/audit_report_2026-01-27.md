# 🔍 Детальный аудит модуля «Выгрузка» (Export)

**Дата аудита:** 27 января 2026  
**Версия аудита:** 2.1 (Полный повторный аудит + проверка дубликатов)  
**Статус:** Найдено **25 критических замечаний**

---

## 📊 Сводка по категориям

| Категория | Количество | Критичность |
|-----------|------------|-------------|
| 🔴 **ДУБЛИКАТЫ КОДА** | 4 | **Критическая** |
| 🔴 Нарушения Design System (@flutter.mdc) | 6 | Высокая |
| 🔴 Прямое использование ScaffoldMessenger | 4 | Высокая |
| 🟠 Архитектурные нарушения (Clean Architecture) | 5 | Средняя |
| 🟠 Устаревшие паттерны Riverpod | 2 | Средняя |
| 🟡 Debug-логирование в production | 3 | Низкая |
| 🟡 Deprecated API | 1 | Низкая |

---

## 🔴 КРИТИЧЕСКИЕ ДУБЛИКАТЫ КОДА

### 0. Дубликаты провайдеров и функций

#### 0.1. [КРИТИЧЕСКИЙ ДУБЛИКАТ] supabaseClientProvider
**Объявлен в 3 местах:**
- `lib/core/di/providers.dart` (строка 108) — **ОСНОВНОЙ**
- `lib/features/export/presentation/providers/repositories_providers.dart` (строка 8) — **ДУБЛИКАТ**
- `lib/features/version_control/providers/version_providers.dart` (строка 9) — **ДУБЛИКАТ**

**Описание:** Один и тот же провайдер `supabaseClientProvider` создаётся 3 раза в разных местах проекта. Это нарушает принцип DRY и может привести к проблемам при изменении логики.

**Рекомендация:** Удалить дубликаты и использовать единый провайдер из `lib/core/di/providers.dart`.

```dart
// В lib/features/export/presentation/providers/repositories_providers.dart
// УДАЛИТЬ:
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ИСПОЛЬЗОВАТЬ импорт:
import '../../../../core/di/providers.dart';
```

---

#### 0.2. [КРИТИЧЕСКИЙ ДУБЛИКАТ] Логика сохранения файлов
**Файлы:**
- `lib/features/export/presentation/services/work_search_export_server_service.dart` → метод `_saveExcelFile()` (строки 264-309)
- `lib/features/export/presentation/widgets/vor_download_action.dart` → inline код в `_downloadReport()` (строки 166-196)

**Описание:** Практически идентичная логика кросс-платформенного сохранения файлов (Web/Desktop/Mobile) реализована в двух местах.

**Сравнение дублирующегося кода:**

| Аспект | work_search_export_server_service | vor_download_action |
|--------|-----------------------------------|---------------------|
| Web | `FileSaver.instance.saveFile()` | `FileSaver.instance.saveFile()` |
| Desktop | `FilePicker.platform.saveFile()` + `File.writeAsBytes()` | `FilePicker.platform.saveFile()` + `File.writeAsBytes()` |
| Mobile | `SharePlus.instance.share()` | `SharePlus.instance.share()` |

**Рекомендация:** Вынести в утилиту `lib/core/utils/file_save_utils.dart`:

```dart
/// Утилита для кросс-платформенного сохранения файлов.
class FileSaveUtils {
  /// Сохраняет файл с адаптацией под платформу.
  static Future<String?> saveFile({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required MimeType mimeType,
    String? shareText,
  }) async {
    if (kIsWeb) {
      return await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: extension,
        mimeType: mimeType,
      );
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл',
        fileName: '$fileName.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (outputFile == null) return null;
      await File(outputFile).writeAsBytes(bytes);
      return outputFile;
    } else {
      final directory = await path_provider.getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.$extension';
      await File(filePath).writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: shareText),
      );
      return filePath;
    }
  }
}
```

---

#### 0.3. [ДУБЛИКАТ] Класс ExportResult не переиспользуется
**Файл:** `lib/features/export/presentation/services/work_search_export_server_service.dart` (строки 313-337)

**Описание:** Класс `ExportResult` объявлен локально в сервисе, хотя может быть полезен для других модулей экспорта.

**Рекомендация:** Если планируется расширение функций экспорта — вынести в `lib/core/models/export_result.dart`.

---

#### 0.4. [ДУБЛИКАТ] Провайдер vorRepositoryProvider в data-слое
**См. раздел 3.2 — Архитектурные нарушения.**

---

## 🔴 КРИТИЧЕСКИЕ НАРУШЕНИЯ

### 1. Нарушения Design System (@flutter.mdc)

#### 1.1. [КРИТИЧЕСКОЕ] TextField вместо GTTextField
**Файл:** `lib/features/export/presentation/widgets/export_search_action.dart`  
**Строка:** 134  
**Описание:** Используется стандартный `TextField` вместо кастомного `GTTextField` из Design System.

```dart
// Текущий код (НАРУШЕНИЕ):
child: TextField(
  controller: ref.watch(_exportSearchControllerProvider),
  // ...
)

// Требуется (согласно @flutter.mdc):
child: GTTextField(
  controller: ref.watch(_exportSearchControllerProvider),
  // ...
)
```

**Правило:** `GTTextField` (`lib/core/widgets/gt_text_field.dart`) — основной текстовый ввод. Используй вместо `TextField` или `TextFormField`.

---

#### 1.2. [КРИТИЧЕСКОЕ] TextFormField вместо GTTextField
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart`  
**Строка:** 574  
**Описание:** Используется стандартный `TextFormField` для ввода количества.

---

#### 1.3. [КРИТИЧЕСКОЕ] ElevatedButton вместо GTPrimaryButton
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart`  
**Строка:** 635  
**Описание:** Используется `ElevatedButton` вместо `GTPrimaryButton`.

```dart
// Текущий код (НАРУШЕНИЕ):
child: ElevatedButton(
  onPressed: _save,
  child: const Text('Сохранить'),
)

// Требуется:
GTPrimaryButton(
  text: 'Сохранить',
  onPressed: _save,
)
```

---

#### 1.4. [КРИТИЧЕСКОЕ] OutlinedButton вместо GTSecondaryButton
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart`  
**Строка:** 618  
**Описание:** Используется `OutlinedButton` вместо `GTSecondaryButton`.

---

#### 1.5. [КРИТИЧЕСКОЕ] FilledButton вместо GTPrimaryButton
**Файл:** `lib/features/export/presentation/widgets/work_search_date_filter.dart`  
**Строка:** 226  
**Описание:** Используется `FilledButton` в компактном date picker.

---

### 2. Прямое использование ScaffoldMessenger

#### 2.1-2.4. [КРИТИЧЕСКОЕ] ScaffoldMessenger вместо SnackBarUtils/AppSnackBar
**Файл:** `lib/features/export/presentation/widgets/work_search_export_action.dart`  
**Строки:** 57, 100, 119, 127

**Описание:** Прямое использование `ScaffoldMessenger.of(context).showSnackBar()` нарушает правила Design System.

```dart
// Текущий код (НАРУШЕНИЕ):
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Ошибка загрузки данных'))
);

// Требуется (согласно @flutter.mdc):
SnackBarUtils.showError(context, 'Ошибка загрузки данных');
// или
AppSnackBar.show(context, message: '...', kind: AppSnackBarKind.error);
```

**Правило:** `AppSnackBar` (`lib/core/widgets/app_snackbar.dart`) — используй `AppSnackBar.show(...)` вместо стандартных снекбаров. Поддерживает очереди уведомлений.

---

## 🟠 АРХИТЕКТУРНЫЕ НАРУШЕНИЯ

### 3. Нарушения Clean Architecture

#### 3.1. [АРХИТЕКТУРА] DTO-классы в файле DataSource
**Файл:** `lib/features/export/data/datasources/work_search_data_source.dart`  
**Классы:** `WorkSearchPaginatedResult`, `WorkSearchFilterValues`

**Описание:** DTO-классы объявлены в файле абстрактного datasource вместо выделенных файлов.

**Рекомендация:** Перенести в:
- `lib/features/export/domain/entities/work_search_paginated_result.dart`
- `lib/features/export/data/models/work_search_filter_values.dart`

---

#### 3.2. [АРХИТЕКТУРА] Provider в слое Data
**Файл:** `lib/features/export/data/repositories/vor_repository_impl.dart`  
**Строка:** 8

**Описание:** `vorRepositoryProvider` объявлен в файле реализации репозитория (data layer), что нарушает разделение слоёв.

```dart
// Текущее расположение (НАРУШЕНИЕ):
// lib/features/export/data/repositories/vor_repository_impl.dart
final vorRepositoryProvider = Provider<VorRepository>((ref) {
  return VorRepositoryImpl(ref.watch(supabaseClientProvider));
});

// Должно быть в:
// lib/features/export/presentation/providers/repositories_providers.dart
```

---

#### 3.3. [АРХИТЕКТУРА] WorkSearchState без Freezed
**Файл:** `lib/features/export/presentation/providers/work_search_provider.dart`  
**Строки:** 7-57

**Описание:** Класс `WorkSearchState` реализован вручную с методом `copyWith`, но не использует `Freezed`, что противоречит правилу о иммутабельности данных.

**Правило (@flutter.mdc):** Применяй `Freezed` для создания неизменяемых и sealed-классов.

```dart
// Текущий код:
class WorkSearchState {
  final List<WorkSearchResult> results;
  // ... ручной copyWith ...
}

// Требуется:
@freezed
abstract class WorkSearchState with _$WorkSearchState {
  const factory WorkSearchState({
    @Default([]) List<WorkSearchResult> results,
    @Default(false) bool isLoading,
    String? error,
    // ...
  }) = _WorkSearchState;
}
```

---

### 4. Устаревшие паттерны Riverpod

#### 4.1. [RIVERPOD] StateNotifier вместо Notifier
**Файл:** `lib/features/export/presentation/providers/work_search_provider.dart`  
**Строки:** 71-72, 200

**Описание:** Используется устаревший `StateNotifier` / `StateNotifierProvider` вместо современного `Notifier` / `NotifierProvider` (Riverpod 2.x+).

```dart
// Текущий код:
class WorkSearchNotifier extends StateNotifier<WorkSearchState> { ... }
final workSearchProvider = StateNotifierProvider<...>((ref) { ... });

// Рекомендуется (Riverpod 2.x):
@riverpod
class WorkSearchNotifier extends _$WorkSearchNotifier {
  @override
  WorkSearchState build() => WorkSearchState();
  // ...
}
```

---

## 🟡 ЗАМЕЧАНИЯ НИЗКОЙ КРИТИЧНОСТИ

### 5. Debug-логирование в production

#### 5.1-5.2. [DEBUG] debugPrint в DataSource
**Файл:** `lib/features/export/data/datasources/work_search_data_source_impl.dart`  
**Строки:** 143, 212

**Описание:** Используется `debugPrint` с emoji-логами в production-коде.

```dart
// Текущий код:
debugPrint('❌ [WorkSearch] Ошибка поиска работ: $e');

// Рекомендация: использовать kDebugMode
if (kDebugMode) {
  debugPrint('❌ [WorkSearch] Ошибка поиска работ: $e');
}
```

---

#### 5.3. [DEBUG] debugPrint в виджете
**Файл:** `lib/features/export/presentation/widgets/export_search_filter_chips.dart`  
**Строка:** 51

---

### 6. Deprecated API

#### 6.1. [DEPRECATED] FilteringTextInputFormatter
**Файл:** `lib/features/export/presentation/widgets/export_work_item_edit_modal.dart`  
**Строка:** 584

**Описание:** Используется `FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))` — устаревший паттерн.

**Рекомендация:** Использовать `quantityFormatter()` или `amountFormatter()` из `lib/core/utils/formatters.dart`.

---

## ✅ ПОЛОЖИТЕЛЬНЫЕ АСПЕКТЫ (Соответствие правилам)

1. ✅ **Color.withValues(alpha: ...)** — везде используется новый API вместо deprecated `withOpacity()`
2. ✅ **Нет print()** — используется `debugPrint` (хотя и его лучше обернуть в kDebugMode)
3. ✅ **Freezed для Entity** — `WorkSearchResult` корректно использует `@freezed`
4. ✅ **formatters.dart** — в большинстве мест используются глобальные форматтеры (`formatRuDate`, `formatCurrency`)
5. ✅ **SnackBarUtils** — частично используется в некоторых файлах (vor_download_action, export_work_item_edit_modal)
6. ✅ **GTDropdown, GTStringDropdown** — используются корректно
7. ✅ **ModalContainerWrapper** — используется для модальных окон
8. ✅ **RLS включён** — все связанные таблицы (`works`, `work_items`, `estimates`) имеют Row-Level Security

---

## 🔌 Серверные функции (Audit)

### Edge Functions
| Функция | Статус | Использование |
|---------|--------|---------------|
| `generate_vor` | ✅ Активна | `VorRepositoryImpl.downloadVorReport()` |
| `generate_vor_pdf` | ✅ Активна | `VorRepositoryImpl.downloadVorPdfReport()` |
| `export-work-search-all` | ✅ Активна | `WorkSearchExportServerService.loadAllSearchResults()` |
| `export-work-search-pto` | ✅ Активна | `WorkSearchExportServerService.exportToPTO()` |

### PostgreSQL RPC Functions
| Функция | Статус | Использование |
|---------|--------|---------------|
| `search_work_items_paginated` | ✅ Используется | `WorkSearchDataSourceImpl.searchMaterials()` |
| `get_work_items_aggregates` | ✅ Используется | `WorkSearchDataSourceImpl.searchMaterials()` |
| `get_work_items_available_filters` | ✅ Используется | `WorkSearchDataSourceImpl.getFilterValues()` |

**Несоответствий между кодом и серверными функциями не обнаружено.**

---

## 📋 Приоритет исправлений

### 🔴 КРИТИЧЕСКИЙ ПРИОРИТЕТ (исправить немедленно)
- [ ] **#0.1** — Удалить дубликат `supabaseClientProvider` из `repositories_providers.dart`
- [ ] **#0.2** — Вынести логику сохранения файлов в `lib/core/utils/file_save_utils.dart`

### 🔴 ВЫСОКИЙ ПРИОРИТЕТ
- [ ] Заменить `ScaffoldMessenger` на `SnackBarUtils` (4 места в work_search_export_action.dart)
- [ ] Заменить `TextField/TextFormField` на `GTTextField` (2 места)
- [ ] Заменить `ElevatedButton/OutlinedButton/FilledButton` на `GTPrimaryButton/GTSecondaryButton` (3 места)

### 🟠 СРЕДНИЙ ПРИОРИТЕТ
- [ ] Перенести `vorRepositoryProvider` в presentation/providers
- [ ] Вынести DTO-классы в отдельные файлы согласно Clean Architecture
- [ ] Конвертировать `WorkSearchState` в Freezed-класс

### 🟡 НИЗКИЙ ПРИОРИТЕТ
- [ ] Миграция `StateNotifier` → `Notifier` (Riverpod 2.x)
- [ ] Обернуть `debugPrint` в `kDebugMode` или удалить
- [ ] Заменить `FilteringTextInputFormatter` на стандартные форматтеры

---

## 📝 Сравнение с документацией

| Аспект | Документация | Код | Статус |
|--------|--------------|-----|--------|
| Серверная пагинация | ✅ Описана | ✅ Реализована | ✅ Соответствует |
| Каскадный Multi-select | ✅ Описан | ✅ Реализован | ✅ Соответствует |
| Edge Functions | ✅ Описаны | ✅ Используются | ✅ Соответствует |
| Design System виджеты | ✅ Требуется | ⚠️ Частично | ⚠️ Несоответствие |
| Мобильная версия | ❌ Не реализована | ❌ Нет | ✅ Соответствует (в Roadmap) |

---

*Автор: AI Auditor | Правила: @flutter.mdc, @documentation.mdc, @module_audit.mdc*
