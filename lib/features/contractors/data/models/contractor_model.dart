import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';

part 'contractor_model.freezed.dart';
part 'contractor_model.g.dart';

/// Модель данных подрядчика для работы с API и хранения в базе.
///
/// Используется для сериализации/десериализации, преобразования в доменную сущность [Contractor].
@freezed
abstract class ContractorModel with _$ContractorModel {
  /// Конструктор модели подрядчика.
  ///
  /// [id] — идентификатор, [logoUrl] — логотип, [fullName]/[shortName] — наименование,
  /// [inn] — ИНН, [director] — директор, [legalAddress]/[actualAddress] — адреса,
  /// [phone]/[email] — контакты, [type] — тип, [createdAt]/[updatedAt] — даты создания/обновления.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory ContractorModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'short_name') required String shortName,
    required String inn,
    required String director,
    @JsonKey(name: 'legal_address') required String legalAddress,
    @JsonKey(name: 'actual_address') required String actualAddress,
    required String phone,
    required String email,
    required ContractorType type,
    String? website,
    String? activityDescription,
    String? kpp,
    String? ogrn,
    String? okpo,
    String? directorBasis,
    String? directorPhone,
    String? chiefAccountantName,
    String? chiefAccountantPhone,
    String? contactPerson,
    String? taxationSystem,
    @Default(false) bool isVatPayer,
    @Default(0) double vatRate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ContractorModel;

  /// Приватный конструктор для поддержки методов расширения.
  const ContractorModel._();

  /// Создаёт модель из JSON.
  factory ContractorModel.fromJson(Map<String, dynamic> json) =>
      _$ContractorModelFromJson(json);

  /// Создаёт модель из доменной сущности [Contractor].
  factory ContractorModel.fromDomain(Contractor contractor) => ContractorModel(
        id: contractor.id,
        companyId: contractor.companyId,
        logoUrl: contractor.logoUrl,
        fullName: contractor.fullName,
        shortName: contractor.shortName,
        inn: contractor.inn,
        director: contractor.director,
        legalAddress: contractor.legalAddress,
        actualAddress: contractor.actualAddress,
        phone: contractor.phone,
        email: contractor.email,
        type: contractor.type,
        website: contractor.website,
        activityDescription: contractor.activityDescription,
        kpp: contractor.kpp,
        ogrn: contractor.ogrn,
        okpo: contractor.okpo,
        directorBasis: contractor.directorBasis,
        directorPhone: contractor.directorPhone,
        chiefAccountantName: contractor.chiefAccountantName,
        chiefAccountantPhone: contractor.chiefAccountantPhone,
        contactPerson: contractor.contactPerson,
        taxationSystem: contractor.taxationSystem,
        isVatPayer: contractor.isVatPayer,
        vatRate: contractor.vatRate,
        createdAt: contractor.createdAt,
        updatedAt: contractor.updatedAt,
      );

  /// Преобразует модель в доменную сущность [Contractor].
  Contractor toDomain() => Contractor(
        id: id,
        companyId: companyId,
        logoUrl: logoUrl,
        fullName: fullName,
        shortName: shortName,
        inn: inn,
        director: director,
        legalAddress: legalAddress,
        actualAddress: actualAddress,
        phone: phone,
        email: email,
        type: type,
        website: website,
        activityDescription: activityDescription,
        kpp: kpp,
        ogrn: ogrn,
        okpo: okpo,
        directorBasis: directorBasis,
        directorPhone: directorPhone,
        chiefAccountantName: chiefAccountantName,
        chiefAccountantPhone: chiefAccountantPhone,
        contactPerson: contactPerson,
        taxationSystem: taxationSystem,
        isVatPayer: isVatPayer,
        vatRate: vatRate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
