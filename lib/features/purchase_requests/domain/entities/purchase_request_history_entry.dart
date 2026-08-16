import 'package:projectgt/core/utils/user_display_utils.dart';
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
  String get userLabel => formatUserDisplayLabel(userName);

  /// Маппинг из PostgREST.
  factory PurchaseRequestHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestHistoryEntry(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      action: json['action'] as String,
      fromStatus: _statusFromHistoryJson(json['from_status']),
      toStatus: _statusFromHistoryJson(json['to_status']),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

PurchaseRequestStatus? _statusFromHistoryJson(Object? value) {
  if (value == null) return null;
  final raw = value as String;
  if (raw.isEmpty) return null;
  return PurchaseRequestStatusX.parseFromDb(raw, context: 'history');
}
