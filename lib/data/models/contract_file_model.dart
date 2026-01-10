import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract_file.dart';

part 'contract_file_model.freezed.dart';
part 'contract_file_model.g.dart';

/// Модель данных файла договора для слоя данных (Data layer).
///
/// Служит для преобразования данных из/в формат JSON (Supabase/PostgreSQL)
/// и взаимодействия с доменной сущностью [ContractFile].
@freezed
abstract class ContractFileModel with _$ContractFileModel {
  const ContractFileModel._();

  /// Создает экземпляр модели файла договора.
  const factory ContractFileModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'contract_id') required String contractId,
    required String name,
    @JsonKey(name: 'file_path') required String filePath,
    required int size,
    required String type,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by') required String createdBy,
  }) = _ContractFileModel;

  /// Преобразует JSON-карту в объект [ContractFileModel].
  factory ContractFileModel.fromJson(Map<String, dynamic> json) =>
      _$ContractFileModelFromJson(json);

  /// Создает модель из доменной сущности [ContractFile].
  factory ContractFileModel.fromEntity(ContractFile entity) =>
      ContractFileModel(
        id: entity.id,
        companyId: entity.companyId,
        contractId: entity.contractId,
        name: entity.name,
        filePath: entity.filePath,
        size: entity.size,
        type: entity.type,
        createdAt: entity.createdAt,
        createdBy: entity.createdBy,
      );

  /// Преобразует текущую модель в доменную сущность [ContractFile].
  ContractFile toEntity() => ContractFile(
    id: id,
    companyId: companyId,
    contractId: contractId,
    name: name,
    filePath: filePath,
    size: size,
    type: type,
    createdAt: createdAt,
    createdBy: createdBy,
  );
}
