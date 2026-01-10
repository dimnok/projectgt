import 'package:freezed_annotation/freezed_annotation.dart';

part 'contractor.freezed.dart';

/// Тип подрядчика (заказчик, подрядчик, поставщик).
enum ContractorType {
  /// Заказчик.
  customer,

  /// Подрядчик.
  contractor,

  /// Поставщик.
  supplier,
}

/// Сущность "Подрядчик" (доменная модель).
///
/// Описывает юридическое лицо или ИП, участвующее в проектах.
@freezed
abstract class Contractor with _$Contractor {
  /// Основной конструктор [Contractor].
  ///
  /// Все параметры соответствуют полям подрядчика в базе данных.
  const factory Contractor({
    /// Уникальный идентификатор подрядчика.
    required String id,

    /// ID компании, к которой относится контрагент.
    @JsonKey(name: 'company_id') required String companyId,

    /// URL логотипа подрядчика.
    String? logoUrl,

    /// Полное наименование.
    required String fullName,

    /// Краткое наименование.
    required String shortName,

    /// ИНН организации.
    required String inn,

    /// ФИО генерального директора.
    required String director,

    /// Юридический адрес.
    required String legalAddress,

    /// Фактический адрес.
    required String actualAddress,

    /// Телефон.
    required String phone,

    /// Email.
    required String email,

    /// Тип подрядчика ([ContractorType]).
    required ContractorType type,

    /// Веб-сайт.
    String? website,

    /// Описание деятельности.
    String? activityDescription,

    /// КПП.
    String? kpp,

    /// ОГРН.
    String? ogrn,

    /// ОКПО.
    String? okpo,

    /// На основании чего действует директор.
    String? directorBasis,

    /// Телефон директора.
    String? directorPhone,

    /// ФИО главного бухгалтера.
    String? chiefAccountantName,

    /// Телефон главного бухгалтера.
    String? chiefAccountantPhone,

    /// Контактное лицо.
    String? contactPerson,

    /// Система налогообложения.
    String? taxationSystem,

    /// Является ли плательщиком НДС.
    @Default(false) bool isVatPayer,

    /// Ставка НДС.
    @Default(0) double vatRate,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления записи.
    DateTime? updatedAt,
  }) = _Contractor;

  /// Приватный конструктор для расширения функциональности через методы.
  const Contractor._();
}

/// Расширение для работы с типом контрагента.
extension ContractorTypeX on ContractorType {
  /// Возвращает человекочитаемое название типа контрагента.
  String get label {
    switch (this) {
      case ContractorType.customer:
        return 'Заказчик';
      case ContractorType.contractor:
        return 'Подрядчик';
      case ContractorType.supplier:
        return 'Поставщик';
    }
  }
}
