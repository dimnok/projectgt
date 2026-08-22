import 'package:projectgt/core/utils/user_display_utils.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Строка реестра заявок (лёгкая модель из RPC `purchase_request_list`).
class PurchaseRequestListItem {
  /// Создаёт элемент списка.
  const PurchaseRequestListItem({
    required this.id,
    required this.number,
    required this.objectId,
    required this.objectName,
    required this.status,
    required this.createdBy,
    this.createdByName,
    required this.totalAmount,
    required this.createdAt,
  });

  /// Идентификатор заявки.
  final String id;

  /// Номер заявки (ЗП-YYYY-NNNNN).
  final String number;

  /// Объект.
  final String objectId;

  /// Название объекта.
  final String objectName;

  /// Текущий статус.
  final PurchaseRequestStatus status;

  /// Инициатор.
  final String createdBy;

  /// ФИО инициатора.
  final String? createdByName;

  /// Сумма счетов.
  final double totalAmount;

  /// Дата создания.
  final DateTime createdAt;

  /// Отображаемое имя инициатора.
  String get initiatorLabel => formatUserDisplayLabel(createdByName);

  /// Маппинг строки RPC.
  factory PurchaseRequestListItem.fromRpcRow(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String?;
    final status = PurchaseRequestStatusX.parseFromDb(
      statusRaw,
      context: 'PurchaseRequestListItem',
    );

    return PurchaseRequestListItem(
      id: json['id'] as String,
      number: json['number'] as String,
      objectId: json['object_id'] as String,
      objectName: json['object_name'] as String? ?? '',
      status: status,
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
