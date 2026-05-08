import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Идентификатор выбранного договора в разделе «Подрядчики».
///
/// `null` — договор не выбран, таблица смет не показывается. Сбрасывается
/// при смене выбранного объекта.
final subcontractorsSelectedContractIdProvider = StateProvider<String?>(
  (ref) => null,
);
