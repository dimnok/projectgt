import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Модель заявки для Supabase.
class PurchaseRequestModel {
  /// Создаёт модель.
  const PurchaseRequestModel({
    required this.id,
    required this.companyId,
    required this.number,
    required this.objectId,
    this.objectName,
    required this.createdBy,
    this.createdByName,
    this.currentAssigneeId,
    required this.status,
    this.comment,
    this.totalAmount = 0,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.completedAt,
  });

  /// Идентификатор заявки.
  final String id;

  /// Идентификатор компании.
  final String companyId;

  /// Номер заявки.
  final String number;

  /// Идентификатор объекта.
  final String objectId;

  /// Название объекта (из join).
  final String? objectName;

  /// Идентификатор автора.
  final String createdBy;

  /// ФИО инициатора (из join profiles).
  final String? createdByName;

  /// Текущий ответственный.
  final String? currentAssigneeId;

  /// Статус заявки.
  final PurchaseRequestStatus status;

  /// Комментарий.
  final String? comment;

  /// Сумма заявки.
  final double totalAmount;

  /// Дата создания.
  final DateTime? createdAt;

  /// Дата обновления.
  final DateTime? updatedAt;

  /// Дата отправки.
  final DateTime? submittedAt;

  /// Дата завершения.
  final DateTime? completedAt;

  /// Из JSON (PostgREST / RPC).
  factory PurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'draft';
    return PurchaseRequestModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      number: json['number'] as String,
      objectId: json['object_id'] as String,
      objectName: json['objects']?['name'] as String?,
      createdBy: json['created_by'] as String,
      createdByName: _parseCreatedByName(json),
      currentAssigneeId: json['current_assignee_id'] as String?,
      status: PurchaseRequestStatusX.fromDb(statusRaw) ??
          PurchaseRequestStatus.draft,
      comment: json['comment'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      submittedAt: _parseDateTime(json['submitted_at']),
      completedAt: _parseDateTime(json['completed_at']),
    );
  }

  /// В доменную сущность.
  PurchaseRequest toDomain() => PurchaseRequest(
        id: id,
        companyId: companyId,
        number: number,
        objectId: objectId,
        objectName: objectName,
        createdBy: createdBy,
        createdByName: createdByName,
        currentAssigneeId: currentAssigneeId,
        status: status,
        comment: comment,
        totalAmount: totalAmount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        submittedAt: submittedAt,
        completedAt: completedAt,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }

  static String? _parseCreatedByName(Map<String, dynamic> json) {
    final direct = json['created_by_name'] as String?;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final profile = json['profiles'];
    if (profile is! Map) return null;

    for (final key in ['short_name', 'full_name', 'email']) {
      final value = profile[key] as String?;
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

/// Модель позиции заявки.
class PurchaseRequestItemModel {
  /// Создаёт модель позиции.
  const PurchaseRequestItemModel({
    required this.id,
    required this.requestId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.article,
    this.comment,
    this.sortOrder = 0,
    this.createdAt,
  });

  /// Идентификатор позиции.
  final String id;

  /// Идентификатор заявки.
  final String requestId;

  /// Наименование.
  final String name;

  /// Количество.
  final double quantity;

  /// Единица измерения.
  final String unit;

  /// Артикул.
  final String? article;

  /// Комментарий.
  final String? comment;

  /// Порядок сортировки.
  final int sortOrder;

  /// Дата создания.
  final DateTime? createdAt;

  /// Из JSON.
  factory PurchaseRequestItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItemModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'шт',
      article: json['article'] as String?,
      comment: json['comment'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// В доменную сущность.
  PurchaseRequestItem toDomain() => PurchaseRequestItem(
        id: id,
        requestId: requestId,
        name: name,
        quantity: quantity,
        unit: unit,
        article: article,
        comment: comment,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  /// JSON для insert/update.
  Map<String, dynamic> toWriteJson({required String companyId}) => {
        'company_id': companyId,
        'request_id': requestId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'article': article,
        'comment': comment,
        'sort_order': sortOrder,
      };
}

/// Модель настроек модуля.
class PurchaseRequestSettingsModel {
  /// Создаёт модель настроек.
  const PurchaseRequestSettingsModel({
    required this.companyId,
    this.firstApproverId,
    this.invoicePreparerId,
    this.invoiceApproverId,
    this.accountantId,
    this.receiverMode = PurchaseRequestReceiverMode.initiator,
    this.fixedReceiverId,
  });

  /// Идентификатор компании.
  final String companyId;

  /// Первый согласующий.
  final String? firstApproverId;

  /// Подготовка счетов.
  final String? invoicePreparerId;

  /// Согласование счетов.
  final String? invoiceApproverId;

  /// Бухгалтер (оплата).
  final String? accountantId;

  /// Режим получения материала.
  final PurchaseRequestReceiverMode receiverMode;

  /// Фиксированный получатель.
  final String? fixedReceiverId;

  /// Из JSON.
  factory PurchaseRequestSettingsModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestSettingsModel(
      companyId: json['company_id'] as String,
      firstApproverId: json['first_approver_id'] as String?,
      invoicePreparerId: json['invoice_preparer_id'] as String?,
      invoiceApproverId: json['invoice_approver_id'] as String?,
      accountantId: json['accountant_id'] as String?,
      receiverMode: PurchaseRequestReceiverModeX.fromDb(
        json['receiver_mode'] as String?,
      ),
      fixedReceiverId: json['fixed_receiver_id'] as String?,
    );
  }

  /// В доменную сущность.
  PurchaseRequestSettings toDomain() => PurchaseRequestSettings(
        companyId: companyId,
        firstApproverId: firstApproverId,
        invoicePreparerId: invoicePreparerId,
        invoiceApproverId: invoiceApproverId,
        accountantId: accountantId,
        receiverMode: receiverMode,
        fixedReceiverId: fixedReceiverId,
      );
}
