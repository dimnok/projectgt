import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/estimate.dart';

part 'estimate_model.freezed.dart';
part 'estimate_model.g.dart';

/// Модель данных для работы с таблицей смет в источнике данных.
///
/// Используется для сериализации/десериализации и передачи между слоями data/domain.
@freezed
abstract class EstimateModel with _$EstimateModel {
  /// Создаёт экземпляр [EstimateModel].
  ///
  /// [id] — идентификатор записи (может быть null для новых).
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
  /// [estimateTitle] — название сметы.
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory EstimateModel({
    String? id,
    required String system,
    required String subsystem,
    @JsonKey(fromJson: _numberFromJson) required String number,
    required String name,
    required String article,
    required String manufacturer,
    required String unit,
    required double quantity,
    required double price,
    required double total,
    @JsonKey(name: 'object_id') String? objectId,
    @JsonKey(name: 'contract_id') String? contractId,
    @JsonKey(name: 'estimate_title') String? estimateTitle,
  }) = _EstimateModel;

  /// Приватный конструктор для поддержки методов расширения.
  const EstimateModel._();

  /// Создаёт [EstimateModel] из JSON.
  factory EstimateModel.fromJson(Map<String, dynamic> json) =>
      _$EstimateModelFromJson(json);
}

/// Функция для обработки поля number при десериализации из JSON
String _numberFromJson(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

/// Маппинг EstimateModel → Estimate (domain layer).
extension EstimateModelMapper on EstimateModel {
  /// Преобразует [EstimateModel] в доменную сущность [Estimate].
  Estimate toDomain() => Estimate(
        id: id ?? '',
        system: system,
        subsystem: subsystem,
        number: number,
        name: name,
        article: article,
        manufacturer: manufacturer,
        unit: unit,
        quantity: quantity,
        price: price,
        total: total,
        objectId: objectId,
        contractId: contractId,
        estimateTitle: estimateTitle,
      );
}

/// Маппинг Estimate (domain layer) → EstimateModel (data layer).
extension EstimateDomainMapper on Estimate {
  /// Преобразует доменную сущность [Estimate] в [EstimateModel].
  EstimateModel toModel() => EstimateModel(
        id: id.trim().isEmpty ? null : id,
        system: system,
        subsystem: subsystem,
        number: number,
        name: name,
        article: article,
        manufacturer: manufacturer,
        unit: unit,
        quantity: quantity,
        price: price,
        total: total,
        objectId: objectId,
        contractId: contractId,
        estimateTitle: estimateTitle,
      );
}
