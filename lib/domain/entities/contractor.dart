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
    /// URL логотипа подрядчика.
    String? logoUrl,
    /// Полное наименование.
    required String fullName,
    /// Краткое наименование.
    required String shortName,
    /// ИНН организации.
    required String inn,
    /// ФИО директора.
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
    /// Дата создания записи.
    DateTime? createdAt,
    /// Дата последнего обновления записи.
    DateTime? updatedAt,
  }) = _Contractor;

  /// Приватный конструктор для расширения функциональности через методы.
  const Contractor._();
} 