import 'package:freezed_annotation/freezed_annotation.dart';

part 'estimate_completion_history.freezed.dart';

/// Сущность, представляющая запись в истории выполнения позиции сметы.
@freezed
abstract class EstimateCompletionHistory with _$EstimateCompletionHistory {
  /// Создает экземпляр [EstimateCompletionHistory].
  const factory EstimateCompletionHistory({
    required DateTime date,
    required double quantity,
    required String section,
    required String floor,
  }) = _EstimateCompletionHistory;
}

