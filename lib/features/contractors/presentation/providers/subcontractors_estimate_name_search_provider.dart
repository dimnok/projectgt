import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Текущий поисковый запрос по наименованию позиции в разделе «Подрядчики».
final subcontractorsEstimateNameSearchProvider = StateProvider<String>(
  (ref) => '',
);
