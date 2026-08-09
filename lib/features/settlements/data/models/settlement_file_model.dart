import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_file.dart';

part 'settlement_file_model.freezed.dart';
part 'settlement_file_model.g.dart';

/// Модель файла счёта для Supabase.
@freezed
abstract class SettlementFileModel with _$SettlementFileModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SettlementFileModel({
    required String id,
    required String companyId,
    required String settlementOperationId,
    required String name,
    required String filePath,
    required int size,
    required String type,
    String? description,
    required DateTime createdAt,
    String? createdBy,
  }) = _SettlementFileModel;

  const SettlementFileModel._();

  /// JSON → модель.
  factory SettlementFileModel.fromJson(Map<String, dynamic> json) =>
      _$SettlementFileModelFromJson(json);

  /// Доменная сущность → модель.
  factory SettlementFileModel.fromDomain(SettlementFile file) =>
      SettlementFileModel(
        id: file.id,
        companyId: file.companyId,
        settlementOperationId: file.settlementOperationId,
        name: file.name,
        filePath: file.filePath,
        size: file.size,
        type: file.type,
        description: file.description,
        createdAt: file.createdAt,
        createdBy: file.createdBy,
      );

  /// Модель → доменная сущность.
  SettlementFile toDomain() => SettlementFile(
        id: id,
        companyId: companyId,
        settlementOperationId: settlementOperationId,
        name: name,
        filePath: filePath,
        size: size,
        type: type,
        description: description,
        createdAt: createdAt,
        createdBy: createdBy,
      );
}
