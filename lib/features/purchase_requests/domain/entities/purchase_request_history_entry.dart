import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Запись истории заявки.
class PurchaseRequestHistoryEntry {
  /// Создаёт записи истории.
  const PurchaseRequestHistoryEntry({
    required this.id,
    required this.requestId,
    required this.userId,
    this.userName,
    required this.action,
    this.fromStatus,
    this.toStatus,
    this.comment,
    required this.createdAt,
  });

  /// Идентификатор записи.
  final String id;

  /// Заявка.
  final String requestId;

  /// Пользователь.
  final String userId;

  /// ФИО пользователя.
  final String? userName;

  /// Код действия.
  final String action;

  /// Статус до перехода.
  final PurchaseRequestStatus? fromStatus;

  /// Статус после перехода.
  final PurchaseRequestStatus? toStatus;

  /// Комментарий.
  final String? comment;

  /// Время события.
  final DateTime createdAt;

  /// Отображаемое имя пользователя.
  String get userLabel =>
      (userName != null && userName!.trim().isNotEmpty)
          ? userName!.trim()
          : '—';

  /// Маппинг из PostgREST.
  factory PurchaseRequestHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestHistoryEntry(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      action: json['action'] as String,
      fromStatus: PurchaseRequestStatusX.fromDb(json['from_status'] as String?),
      toStatus: PurchaseRequestStatusX.fromDb(json['to_status'] as String?),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
