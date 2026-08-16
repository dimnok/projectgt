/// Метаданные файла заявки на закупку (`purchase_request_files`).
class PurchaseRequestFile {
  /// Создаёт файл.
  const PurchaseRequestFile({
    required this.id,
    required this.requestId,
    required this.type,
    required this.storagePath,
    required this.fileName,
    this.invoiceId,
    this.mimeType,
    this.size,
    this.createdAt,
  });

  /// Идентификатор записи.
  final String id;

  /// Заявка.
  final String requestId;

  /// Связанный счёт (для type = invoice).
  final String? invoiceId;

  /// Тип файла в БД.
  final String type;

  /// Путь в Supabase Storage.
  final String storagePath;

  /// Исходное имя файла.
  final String fileName;

  /// MIME-тип.
  final String? mimeType;

  /// Размер в байтах.
  final int? size;

  /// Дата загрузки.
  final DateTime? createdAt;
}
