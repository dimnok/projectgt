import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_document.freezed.dart';
part 'company_document.g.dart';

/// Представляет документ компании (лицензия, сертификат и т.д.).
@freezed
abstract class CompanyDocument with _$CompanyDocument {
  /// Создает экземпляр [CompanyDocument].
  const factory CompanyDocument({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    required String type,
    required String title,
    String? number,
    @JsonKey(name: 'issue_date') DateTime? issueDate,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    @JsonKey(name: 'file_url') String? fileUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CompanyDocument;

  /// Создает экземпляр [CompanyDocument] из JSON.
  factory CompanyDocument.fromJson(Map<String, dynamic> json) =>
      _$CompanyDocumentFromJson(json);
}

