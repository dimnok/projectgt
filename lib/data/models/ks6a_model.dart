import 'package:freezed_annotation/freezed_annotation.dart';

part 'ks6a_model.freezed.dart';
part 'ks6a_model.g.dart';

/// Статусы периода КС-6а.
enum Ks6aStatus {
  /// Черновик (редактируемый).
  @JsonValue('draft')
  draft,

  /// Согласовано (только для чтения).
  @JsonValue('approved')
  approved,
}

/// Модель заголовка периода КС-6а.
@freezed
abstract class Ks6aPeriod with _$Ks6aPeriod {
  /// Создает экземпляр [Ks6aPeriod].
  const factory Ks6aPeriod({
    /// Идентификатор периода.
    required String id,

    /// Дата начала периода.
    @JsonKey(name: 'start_date') required DateTime startDate,

    /// Дата окончания периода.
    @JsonKey(name: 'end_date') required DateTime endDate,

    /// Статус периода (черновик/согласовано).
    required Ks6aStatus status,

    /// Название периода.
    String? title,

    /// Итоговая сумма по периоду.
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
  }) = _Ks6aPeriod;

  /// Создает экземпляр [Ks6aPeriod] из JSON.
  factory Ks6aPeriod.fromJson(Map<String, dynamic> json) => _$Ks6aPeriodFromJson(json);
}

/// Модель строки периода КС-6а.
@freezed
abstract class Ks6aPeriodItem with _$Ks6aPeriodItem {
  /// Создает экземпляр [Ks6aPeriodItem].
  const factory Ks6aPeriodItem({
    /// Идентификатор записи.
    required String id,

    /// Идентификатор периода.
    @JsonKey(name: 'period_id') required String periodId,

    /// Идентификатор сметной позиции.
    @JsonKey(name: 'estimate_id') required String estimateId,

    /// Количество за период.
    required double quantity,

    /// Снапшот цены на момент создания периода.
    @JsonKey(name: 'price_snapshot') required double priceSnapshot,

    /// Сумма за период (quantity * price_snapshot).
    required double amount,
  }) = _Ks6aPeriodItem;

  /// Создает экземпляр [Ks6aPeriodItem] из JSON.
  factory Ks6aPeriodItem.fromJson(Map<String, dynamic> json) => _$Ks6aPeriodItemFromJson(json);
}

/// Обертка для всех данных КС-6а по договору.
@freezed
abstract class Ks6aContractData with _$Ks6aContractData {
  /// Создает экземпляр [Ks6aContractData].
  const factory Ks6aContractData({
    /// Список периодов.
    required List<Ks6aPeriod> periods,

    /// Список всех строк всех периодов.
    required List<Ks6aPeriodItem> items,
  }) = _Ks6aContractData;

  /// Создает экземпляр [Ks6aContractData] из JSON.
  factory Ks6aContractData.fromJson(Map<String, dynamic> json) => _$Ks6aContractDataFromJson(json);
}
