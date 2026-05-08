import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/estimate_revision.dart';

/// Ключ [FutureProvider.family] для загрузки истории позиции по ДС.
@immutable
class EstimatePositionHistoryRequest {
  /// Создаёт ключ запроса истории.
  const EstimatePositionHistoryRequest({
    required this.contractId,
    required this.estimateTitle,
    required this.estimateRowId,
  });

  /// Идентификатор договора.
  final String contractId;

  /// Заголовок сметы.
  final String estimateTitle;

  /// Идентификатор строки в [estimates].
  final String estimateRowId;

  @override
  bool operator ==(Object other) {
    return other is EstimatePositionHistoryRequest &&
        other.contractId == contractId &&
        other.estimateTitle == estimateTitle &&
        other.estimateRowId == estimateRowId;
  }

  @override
  int get hashCode => Object.hash(contractId, estimateTitle, estimateRowId);
}

/// История позиции по снимкам ревизий (read-only).
final estimatePositionAddendumHistoryProvider = FutureProvider.autoDispose
    .family<List<EstimatePositionAddendumHistoryEntry>, EstimatePositionHistoryRequest>(
      (ref, req) async {
        final repo = ref.watch(estimateRepositoryProvider);
        return repo.getEstimatePositionAddendumHistory(
          contractId: req.contractId,
          estimateTitle: req.estimateTitle,
          estimateRowId: req.estimateRowId,
        );
      },
    );
