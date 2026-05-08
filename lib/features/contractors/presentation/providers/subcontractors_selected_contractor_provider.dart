import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Выбранный подрядчик для просмотра расценок в разделе «Подрядчики».
///
/// Сбрасывается при смене объекта или договора в фильтрах экрана.
final subcontractorsSelectedContractorIdProvider = StateProvider<String?>(
  (ref) => null,
);
