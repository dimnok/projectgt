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
@freezed
abstract class PurchaseRequestSettings with _$PurchaseRequestSettings {
  /// Создаёт настройки.
  const factory PurchaseRequestSettings({
    required String companyId,
    String? firstApproverId,
    String? invoicePreparerId,
    String? invoiceApproverId,
    String? accountantId,
    @Default(PurchaseRequestReceiverMode.initiator)
    PurchaseRequestReceiverMode receiverMode,
    String? fixedReceiverId,
  }) = _PurchaseRequestSettings;
}
