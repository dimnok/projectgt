import 'package:freezed_annotation/freezed_annotation.dart';

part 'estimate.freezed.dart';

/// Доменная сущность сметы.
///
/// Описывает позицию сметы с деталями по системе, подсистеме, материалу, количеству и стоимости.
@freezed
abstract class Estimate with _$Estimate {
  /// Создаёт экземпляр [Estimate].
  ///
  /// [id] — идентификатор записи.
  /// [system] — система.
  /// [subsystem] — подсистема.
  /// [number] — порядковый номер.
  /// [name] — наименование.
  /// [article] — артикул.
  /// [manufacturer] — производитель.
  /// [unit] — единица измерения.
  /// [quantity] — количество.
  /// [price] — цена за единицу.
  /// [total] — итоговая сумма.
  /// [objectId] — идентификатор объекта.
  /// [contractId] — идентификатор договора.
  /// [contractNumber] — номер договора.
  /// [estimateTitle] — название сметы.
  const factory Estimate({
    required String id,
    required String system,
    required String subsystem,
    required String number,
    required String name,
    required String article,
    required String manufacturer,
    required String unit,
    required double quantity,
    required double price,
    required double total,
    String? objectId,
    String? contractId,
    String? contractNumber,
    String? estimateTitle,
  }) = _Estimate;

  /// Приватный конструктор для поддержки методов расширения
  const Estimate._();
}
