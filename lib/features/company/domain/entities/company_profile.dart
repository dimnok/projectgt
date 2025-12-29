import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_profile.freezed.dart';
part 'company_profile.g.dart';

/// Представляет профиль компании со всеми реквизитами и контактными данными.
@freezed
abstract class CompanyProfile with _$CompanyProfile {
  /// Создает экземпляр [CompanyProfile].
  const factory CompanyProfile({
    required String id,
    @JsonKey(name: 'name_full') required String nameFull,
    @JsonKey(name: 'name_short') required String nameShort,
    @JsonKey(name: 'logo_url') String? logoUrl,
    String? website,
    String? email,
    String? phone,
    @JsonKey(name: 'activity_description') String? activityDescription,
    String? inn,
    String? kpp,
    String? ogrn,
    String? okpo,
    @JsonKey(name: 'legal_address') String? legalAddress,
    @JsonKey(name: 'actual_address') String? actualAddress,
    @JsonKey(name: 'director_name') String? directorName,
    @JsonKey(name: 'director_position') String? directorPosition,
    @JsonKey(name: 'director_basis') String? directorBasis,
    @JsonKey(name: 'director_phone') String? directorPhone,
    @JsonKey(name: 'chief_accountant_name') String? chiefAccountantName,
    @JsonKey(name: 'chief_accountant_phone') String? chiefAccountantPhone,
    @JsonKey(name: 'contact_person') String? contactPerson,
    @JsonKey(name: 'taxation_system') String? taxationSystem,
    @JsonKey(name: 'is_vat_payer') @Default(false) bool isVatPayer,
    @JsonKey(name: 'vat_rate') @Default(0) double vatRate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CompanyProfile;

  /// Создает экземпляр [CompanyProfile] из JSON.
  factory CompanyProfile.fromJson(Map<String, dynamic> json) =>
      _$CompanyProfileFromJson(json);
}
