import 'package:freezed_annotation/freezed_annotation.dart';

part 'estimate_completion_model.freezed.dart';
part 'estimate_completion_model.g.dart';

/// Модель для отчёта о выполнении смет.
@freezed
abstract class EstimateCompletionModel with _$EstimateCompletionModel {
  /// Фабричный конструктор
  const factory EstimateCompletionModel({
    @JsonKey(name: 'estimate_id', fromJson: _parseString)
    @Default('')
    final String estimateId,
    @JsonKey(name: 'object_id', fromJson: _parseString)
    @Default('')
    final String objectId,
    @JsonKey(name: 'contract_id', fromJson: _parseString)
    @Default('')
    final String contractId,
    @Default('') final String system,
    @Default('') final String subsystem,
    @Default('') final String number,
    @Default('') final String name,
    @Default('') final String unit,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) final double quantity,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) final double total,
    @JsonKey(name: 'completed_quantity', fromJson: _parseDouble)
    @Default(0.0)
    final double completedQuantity,
    @JsonKey(name: 'completed_total', fromJson: _parseDouble)
    @Default(0.0)
    final double completedTotal,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) final double percentage,
    @JsonKey(name: 'remaining_quantity', fromJson: _parseDouble)
    @Default(0.0)
    final double remainingQuantity,
  }) = _EstimateCompletionModel;

  /// Создаёт модель из JSON
  factory EstimateCompletionModel.fromJson(Map<String, dynamic> json) =>
      _$EstimateCompletionModelFromJson(json);
}

/// Парсер для UUID/String
String _parseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

/// Парсер для numeric/string→double
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? 0.0;
  }
  return 0.0;
}
