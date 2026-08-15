/// Пользователь компании для выбора в настройках маршрута заявок.
class PurchaseRequestCompanyUser {
  /// Создаёт пользователя.
  const PurchaseRequestCompanyUser({
    required this.id,
    required this.email,
    this.fullName,
    this.shortName,
  });

  /// ID пользователя (auth.users / profiles.id).
  final String id;

  /// Email.
  final String email;

  /// Полное имя.
  final String? fullName;

  /// Короткое имя.
  final String? shortName;

  /// Подпись для выпадающего списка.
  String get displayName {
    if (shortName != null && shortName!.trim().isNotEmpty) {
      return shortName!.trim();
    }
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    return email;
  }

  /// Из строки RPC `purchase_request_company_users`.
  factory PurchaseRequestCompanyUser.fromRpcRow(Map<String, dynamic> json) {
    return PurchaseRequestCompanyUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      shortName: json['short_name'] as String?,
    );
  }
}
