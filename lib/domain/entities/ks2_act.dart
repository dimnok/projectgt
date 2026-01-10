import 'package:freezed_annotation/freezed_annotation.dart';

part 'ks2_act.freezed.dart';

/// Статус акта КС-2.
enum Ks2Status {
  /// Черновик.
  draft,

  /// Подписан.
  signed,

  /// Оплачен.
  paid,
}

@freezed
/// Сущность акта КС-2 (доменный слой).
abstract class Ks2Act with _$Ks2Act {
  /// Создает доменную сущность акта КС-2.
  const factory Ks2Act({
    required String id,
    required String companyId,
    required String contractId,
    required String number,
    required DateTime date,
    required DateTime periodFrom,
    required DateTime periodTo,
    @Default(Ks2Status.draft) Ks2Status status,
    @Default(0) double totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _Ks2Act;
}
