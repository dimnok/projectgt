import 'package:freezed_annotation/freezed_annotation.dart';

part 'settlement_file.freezed.dart';

/// Файл, прикреплённый к счёту взаиморасчётов.
@freezed
abstract class SettlementFile with _$SettlementFile {
  /// Создаёт [SettlementFile].
  const factory SettlementFile({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Счёт, к которому прикреплён файл.
    required String settlementOperationId,

    /// Отображаемое имя (может содержать кириллицу).
    required String name,

    /// Путь к объекту в Storage.
    required String filePath,

    /// Размер в байтах.
    required int size,

    /// MIME-тип.
    required String type,

    /// Необязательное описание.
    String? description,

    /// Дата загрузки.
    required DateTime createdAt,

    /// Автор загрузки.
    String? createdBy,
  }) = _SettlementFile;
}
