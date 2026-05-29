/// Одноразовое приглашение в компанию.
class CompanyInvitation {
  /// Идентификатор приглашения.
  final String id;

  /// Код для ввода сотрудником.
  final String code;

  /// Срок действия.
  final DateTime expiresAt;

  /// Дата создания.
  final DateTime createdAt;

  /// Дата использования (если погашено).
  final DateTime? usedAt;

  /// Дата отзыва (если отменено).
  final DateTime? revokedAt;

  /// Создаёт [CompanyInvitation].
  const CompanyInvitation({
    required this.id,
    required this.code,
    required this.expiresAt,
    required this.createdAt,
    this.usedAt,
    this.revokedAt,
  });

  /// Активно ли приглашение (можно ввести).
  bool get isActive =>
      usedAt == null && revokedAt == null && expiresAt.isAfter(DateTime.now());

  /// Создаёт из JSON ответа Supabase.
  factory CompanyInvitation.fromJson(Map<String, dynamic> json) {
    return CompanyInvitation(
      id: json['id'] as String,
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
    );
  }
}
