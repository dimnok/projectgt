import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract_file.freezed.dart';
part 'contract_file.g.dart';

/// Сущность файла, прикрепленного к договору.
///
/// Содержит метаданные файла: название, путь в хранилище, размер и тип.
@freezed
abstract class ContractFile with _$ContractFile {
  /// Создает экземпляр сущности файла договора.
  const factory ContractFile({
    required String id,
    required String companyId,
    required String contractId,
    required String name,
    required String filePath,
    required int size,
    required String type,
    required DateTime createdAt,
    required String createdBy,
  }) = _ContractFile;

  /// Преобразует JSON-карту в объект [ContractFile].
  factory ContractFile.fromJson(Map<String, dynamic> json) =>
      _$ContractFileFromJson(json);
}
