import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';
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
    String? description,
    @JsonKey(name: 'display_order') required int displayOrder,
    @JsonKey(name: 'document_status')
    @Default(ContractDocumentStatus.draft)
    ContractDocumentStatus documentStatus,
    @JsonKey(name: 'document_version') @Default(1) int documentVersion,
    @JsonKey(name: 'is_amendment') @Default(false) bool isAmendment,
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
        description: entity.description,
        displayOrder: entity.displayOrder,
        documentStatus: entity.documentStatus,
        documentVersion: entity.documentVersion,
        isAmendment: entity.isAmendment,
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
    description: description,
    displayOrder: displayOrder,
    documentStatus: documentStatus,
    documentVersion: documentVersion,
    isAmendment: isAmendment,
    createdAt: createdAt,
    createdBy: createdBy,
  );
}
