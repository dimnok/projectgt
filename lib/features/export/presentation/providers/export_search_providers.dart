import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Задержка (мс) перед RPC по тексту поиска — таблица и каскадные фильтры.
const kExportSearchDebounceMs = 500;

/// Провайдер запроса поиска для таба поиска (мгновенно, для поля ввода).
final exportSearchQueryProvider = StateProvider<String>((ref) => '');

/// Текст поиска для RPC каскадных фильтров (с debounce).
final exportSearchQueryDebouncedProvider =
    StateNotifierProvider<ExportSearchQueryDebouncedNotifier, String>((ref) {
  final notifier = ExportSearchQueryDebouncedNotifier(
    ref.read(exportSearchQueryProvider),
  );

  ref.listen(exportSearchQueryProvider, (_, next) {
    notifier.onQueryChanged(next);
  });

  ref.onDispose(notifier.dispose);

  return notifier;
});

/// Debounce-обёртка над [exportSearchQueryProvider].
class ExportSearchQueryDebouncedNotifier extends StateNotifier<String> {
  /// Создаёт нотификатор с начальным значением запроса.
  ExportSearchQueryDebouncedNotifier(super.initial);

  Timer? _timer;

  /// Планирует обновление [state] после паузы или сразу при очистке поля.
  void onQueryChanged(String next) {
    _timer?.cancel();
    if (next.trim().isEmpty) {
      state = next;
      return;
    }
    _timer = Timer(const Duration(milliseconds: kExportSearchDebounceMs), () {
      state = next;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Провайдер выбранного объекта для поиска.
final exportSelectedObjectIdProvider = StateProvider<String?>((ref) => null);

/// Видимость поля поиска.
final exportSearchVisibleProvider = StateProvider<bool>((ref) => false);

/// Фильтры для результатов поиска.
final exportSearchFilterProvider =
    StateProvider<Map<String, Set<String>>>((ref) => {
          'system': <String>{},
          'section': <String>{},
          'floor': <String>{},
        });
