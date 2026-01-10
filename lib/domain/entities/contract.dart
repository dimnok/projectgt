import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract.freezed.dart';

/// Статус контракта (в работе, приостановлен, завершён).
enum ContractStatus {
  /// Контракт в работе.
  active, // В работе
  /// Контракт приостановлен.
  suspended, // Приостановлен
  /// Контракт завершён.
  completed, // Завершен
}

/// Сущность "Контракт" (доменная модель).
///
/// Описывает договор между подрядчиком и заказчиком, включая сумму, сроки и статус.
@freezed
abstract class Contract with _$Contract {
  /// Основной конструктор [Contract].
  ///
  /// Все параметры соответствуют полям контракта в базе данных.
  const factory Contract({
    /// Уникальный идентификатор контракта.
    required String id,

    /// Идентификатор компании.
    required String companyId,

    /// Номер контракта.
    required String number,

    /// Дата заключения контракта.
    required DateTime date,

    /// Дата окончания действия контракта.
    DateTime? endDate,

    /// Идентификатор подрядчика.
    required String contractorId,

    /// Имя подрядчика.
    String? contractorName,

    /// Сумма контракта.
    required double amount,

    /// Ставка НДС (в процентах).
    @Default(0.0) double vatRate,

    /// Включен ли НДС в стоимость (true - в том числе, false - сверху).
    @Default(true) bool isVatIncluded,

    /// Сумма НДС.
    @Default(0.0) double vatAmount,

    /// Сумма аванса.
    @Default(0.0) double advanceAmount,

    /// Гарантийные удержания (сумма).
    @Default(0.0) double warrantyRetentionAmount,

    /// Процент гарантийных удержаний.
    @Default(0.0) double warrantyRetentionRate,

    /// Срок гарантийных обязательств (в месяцах).
    @Default(0) int warrantyPeriodMonths,

    /// Генподрядные (сумма).
    @Default(0.0) double generalContractorFeeAmount,

    /// Процент генподрядных.
    @Default(0.0) double generalContractorFeeRate,

    /// Идентификатор объекта.
    required String objectId,

    /// Имя объекта.
    String? objectName,

    /// Статус контракта ([ContractStatus]).
    @Default(ContractStatus.active) ContractStatus status,

    /// Название организации подрядчика (для документов).
    String? contractorOrgName,

    /// Должность подписанта подрядчика.
    String? contractorPosition,

    /// ФИО подписанта подрядчика.
    String? contractorSigner,

    /// Название организации заказчика (для документов).
    String? customerOrgName,

    /// Должность подписанта заказчика.
    String? customerPosition,

    /// ФИО подписанта заказчика.
    String? customerSigner,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления записи.
    DateTime? updatedAt,
  }) = _Contract;

  /// Приватный конструктор для расширения функциональности через методы.
  const Contract._();
}
