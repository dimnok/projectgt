import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';

part 'contract_file.freezed.dart';
part 'contract_file.g.dart';

/// Сущность файла, прикрепленного к договору.
///
/// Содержит метаданные файла: название, путь в хранилище, размер и тип.
/// Поле [displayOrder] задаёт порядок строки в списке документов (меньше — выше).
/// Поля [documentStatus], [documentVersion] и [isAmendment] поддерживают
/// документооборот и отображение версии в UI.
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
    String? description,
    /// Порядок отображения в UI (0 — первый в списке).
    @JsonKey(name: 'display_order') required int displayOrder,
    /// Статус в цикле согласования.
    @JsonKey(name: 'document_status')
    @Default(ContractDocumentStatus.draft)
    ContractDocumentStatus documentStatus,
    /// Номер версии для отображения (v1, v2, …), не меньше 1.
    @JsonKey(name: 'document_version') @Default(1) int documentVersion,
    /// Признак новой редакции (пометка «изм.» в списке).
    @JsonKey(name: 'is_amendment') @Default(false) bool isAmendment,
    /// Дата и время загрузки файла на сервер.
    required DateTime createdAt,
    required String createdBy,
  }) = _ContractFile;

  /// Преобразует JSON-карту в объект [ContractFile].
  factory ContractFile.fromJson(Map<String, dynamic> json) =>
      _$ContractFileFromJson(json);
}
