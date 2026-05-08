import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Идентификатор выбранного объекта в разделе «Подрядчики» (фильтр смет).
///
/// `null` — объект не выбран, таблица пустая до выбора.
final subcontractorsSelectedObjectIdProvider = StateProvider<String?>(
  (ref) => null,
);
