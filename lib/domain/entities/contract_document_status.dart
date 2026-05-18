import 'package:json_annotation/json_annotation.dart';

/// Статус документа договора в цикле согласования (документооборот).
///
/// Хранится в БД как snake_case-строка ([JsonValue]).
enum ContractDocumentStatus {
  /// Черновик.
  @JsonValue('draft')
  draft,

  /// На согласовании.
  @JsonValue('pending_approval')
  pendingApproval,

  /// Согласовано.
  @JsonValue('approved')
  approved,

  /// Подписано.
  @JsonValue('signed')
  signed,

  /// Отклонено.
  @JsonValue('rejected')
  rejected,

  /// Устарел.
  @JsonValue('obsolete')
  obsolete,
}

/// Значение колонки `document_status` в PostgreSQL.
extension ContractDocumentStatusDb on ContractDocumentStatus {
  /// Строка для записи в БД / Supabase.
  String get dbValue {
    switch (this) {
      case ContractDocumentStatus.draft:
        return 'draft';
      case ContractDocumentStatus.pendingApproval:
        return 'pending_approval';
      case ContractDocumentStatus.approved:
        return 'approved';
      case ContractDocumentStatus.signed:
        return 'signed';
      case ContractDocumentStatus.rejected:
        return 'rejected';
      case ContractDocumentStatus.obsolete:
        return 'obsolete';
    }
  }
}

/// Человекочитаемые подписи статусов для UI.
extension ContractDocumentStatusLabel on ContractDocumentStatus {
  /// Короткая подпись для chip и списков.
  String get ruLabel {
    switch (this) {
      case ContractDocumentStatus.draft:
        return 'Черновик';
      case ContractDocumentStatus.pendingApproval:
        return 'На согласовании';
      case ContractDocumentStatus.approved:
        return 'Согласовано';
      case ContractDocumentStatus.signed:
        return 'Подписано';
      case ContractDocumentStatus.rejected:
        return 'Отклонено';
      case ContractDocumentStatus.obsolete:
        return 'Устарел';
    }
  }
}
