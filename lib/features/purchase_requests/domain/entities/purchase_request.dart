import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

part 'purchase_request.freezed.dart';

/// Заявка на закупку (карточка).
@freezed
abstract class PurchaseRequest with _$PurchaseRequest {
  /// Создаёт заявку.
  const factory PurchaseRequest({
    required String id,
    required String companyId,
    required String number,
    required String objectId,
    String? objectName,
    required String createdBy,
    String? createdByName,
    String? currentAssigneeId,
    required PurchaseRequestStatus status,
    String? comment,
    @Default(0) double totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? completedAt,
  }) = _PurchaseRequest;

  const PurchaseRequest._();

  /// Отображаемое имя инициатора.
  String get initiatorLabel =>
      (createdByName != null && createdByName!.trim().isNotEmpty)
          ? createdByName!.trim()
          : '—';
}
