import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_request_settings.freezed.dart';

/// Режим назначения ответственного за получение.
enum PurchaseRequestReceiverMode {
  /// Инициатор заявки.
  initiator,

  /// Фиксированный пользователь.
  fixedUser,
}

/// Расширения для [PurchaseRequestReceiverMode].
extension PurchaseRequestReceiverModeX on PurchaseRequestReceiverMode {
  /// Значение в БД.
  String get dbValue => switch (this) {
    PurchaseRequestReceiverMode.initiator => 'initiator',
    PurchaseRequestReceiverMode.fixedUser => 'fixed_user',
  };

  /// Парсинг из БД.
  static PurchaseRequestReceiverMode fromDb(String? value) {
    if (value == 'fixed_user') {
      return PurchaseRequestReceiverMode.fixedUser;
    }
    return PurchaseRequestReceiverMode.initiator;
  }
}

/// Настройки маршрута заявок на компанию.
///
/// На каждой роли может быть несколько пользователей. На этапе действует любой
/// из списка (логика совпадает с SQL `purchase_request_internal_user_is_assignee`).
@freezed
abstract class PurchaseRequestSettings with _$PurchaseRequestSettings {
  /// Создаёт настройки.
  const factory PurchaseRequestSettings({
    required String companyId,
    @Default(<String>[]) List<String> firstApproverIds,
    @Default(<String>[]) List<String> invoicePreparerIds,
    @Default(<String>[]) List<String> invoiceApproverIds,
    @Default(<String>[]) List<String> accountantIds,
    @Default(PurchaseRequestReceiverMode.initiator)
    PurchaseRequestReceiverMode receiverMode,
    @Default(<String>[]) List<String> fixedReceiverIds,
  }) = _PurchaseRequestSettings;
}
