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

    /// Идентификатор объекта.
    required String objectId,

    /// Имя объекта.
    String? objectName,

    /// Статус контракта ([ContractStatus]).
    @Default(ContractStatus.active) ContractStatus status,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления записи.
    DateTime? updatedAt,
  }) = _Contract;

  /// Приватный конструктор для расширения функциональности через методы.
  const Contract._();
}
