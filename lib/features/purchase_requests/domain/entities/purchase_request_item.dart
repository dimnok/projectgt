import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_request_item.freezed.dart';

/// Позиция заявки на закупку.
@freezed
abstract class PurchaseRequestItem with _$PurchaseRequestItem {
  /// Создаёт позицию.
  const factory PurchaseRequestItem({
    required String id,
    required String requestId,
    required String name,
    required double quantity,
    @Default('шт') String unit,
    String? article,
    String? comment,
    @Default(0) int sortOrder,
    DateTime? createdAt,
  }) = _PurchaseRequestItem;
}
