import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';

part 'ks2_act_model.freezed.dart';
part 'ks2_act_model.g.dart';

@freezed
/// Модель акта КС-2 для слоя данных.
abstract class Ks2ActModel with _$Ks2ActModel {
  const Ks2ActModel._();

  /// Создает экземпляр модели акта КС-2.
  const factory Ks2ActModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'contract_id') required String contractId,
    required String number,
    required DateTime date,
    @JsonKey(name: 'period_from') required DateTime periodFrom,
    @JsonKey(name: 'period_to') required DateTime periodTo,
    @Default(Ks2Status.draft) Ks2Status status,
    @JsonKey(name: 'total_amount') @Default(0) double totalAmount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'created_by') String? createdBy,
  }) = _Ks2ActModel;

  /// Создает экземпляр из JSON.
  factory Ks2ActModel.fromJson(Map<String, dynamic> json) =>
      _$Ks2ActModelFromJson(json);

  /// Преобразует модель в доменную сущность [Ks2Act].
  Ks2Act toDomain() {
    return Ks2Act(
      id: id,
      companyId: companyId,
      contractId: contractId,
      number: number,
      date: date,
      periodFrom: periodFrom,
      periodTo: periodTo,
      status: status,
      totalAmount: totalAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }

  /// Создает модель из доменной сущности [Ks2Act].
  factory Ks2ActModel.fromDomain(Ks2Act entity) {
    return Ks2ActModel(
      id: entity.id,
      companyId: entity.companyId,
      contractId: entity.contractId,
      number: entity.number,
      date: entity.date,
      periodFrom: entity.periodFrom,
      periodTo: entity.periodTo,
      status: entity.status,
      totalAmount: entity.totalAmount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }
}
