import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Статусы ведомости ВОР.
enum VorStatus {
  /// Черновик (редактируемый).
  @JsonValue('draft')
  draft,

  /// На подписание (заморожен).
  @JsonValue('pending')
  pending,

  /// Подписан (финальный).
  @JsonValue('approved')
  approved,
}

/// Сущность ведомости объемов работ (ВОР).
class Vor {
  /// Идентификатор ведомости.
  final String id;

  /// Идентификатор договора.
  final String contractId;

  /// Номер ведомости.
  final String number;

  /// Дата начала периода.
  final DateTime startDate;

  /// Дата окончания периода.
  final DateTime endDate;

  /// Текущий статус.
  final VorStatus status;

  /// Ссылка на Excel-файл.
  final String? excelUrl;

  /// Ссылка на PDF-файл.
  final String? pdfUrl;

  /// Дата создания.
  final DateTime createdAt;

  /// Идентификатор создателя.
  final String? createdBy;

  /// Имя создателя.
  final String? createdByName;

  /// Список систем.
  final List<String> systems;

  /// История изменения статусов.
  final List<VorHistoryItem> statusHistory;

  /// Создает экземпляр [Vor].
  const Vor({
    required this.id,
    required this.contractId,
    required this.number,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.excelUrl,
    this.pdfUrl,
    required this.createdAt,
    this.createdBy,
    this.createdByName,
    this.systems = const [],
    this.statusHistory = const [],
  });

  /// Возвращает цвет, соответствующий статусу.
  static Color getStatusColor(VorStatus status) {
    switch (status) {
      case VorStatus.approved:
        return Colors.green;
      case VorStatus.draft:
        return Colors.grey;
      case VorStatus.pending:
        return Colors.orange;
    }
  }

  /// Возвращает текстовое описание статуса.
  static String getStatusText(VorStatus status) {
    switch (status) {
      case VorStatus.approved:
        return 'Подписан';
      case VorStatus.draft:
        return 'Черновик';
      case VorStatus.pending:
        return 'На подписание';
    }
  }
}

/// Сущность элемента истории статусов ВОР.
class VorHistoryItem {
  /// Идентификатор записи.
  final String id;

  /// Статус.
  final VorStatus status;

  /// Идентификатор пользователя.
  final String? userId;

  /// Имя пользователя.
  final String? userName;

  /// Комментарий.
  final String? comment;

  /// Дата создания.
  final DateTime createdAt;

  /// Создает экземпляр [VorHistoryItem].
  const VorHistoryItem({
    required this.id,
    required this.status,
    this.userId,
    this.userName,
    this.comment,
    required this.createdAt,
  });
}
