import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/contract_file_model.dart';

/// Абстрактный интерфейс для работы с файлами договоров.
///
/// Определяет контракт для загрузки, получения, удаления и скачивания
/// файлов, привязанных к договорам.
abstract class ContractFileDataSource {
  /// Получает список всех файлов для указанного договора.
  ///
  /// Возвращает список файлов, отсортированный по дате создания
  /// (от новых к старым).
  ///
  /// [contractId] - идентификатор договора.
  ///
  /// Возвращает список [ContractFileModel] или пустой список, если файлов нет.
  Future<List<ContractFileModel>> getFilesByContract(String contractId);

  /// Загружает файл для указанного договора.
  ///
  /// Выполняет загрузку файла в хранилище и сохранение метаданных
  /// в базе данных.
  ///
  /// [contractId] - идентификатор договора.
  /// [file] - файл для загрузки.
  /// [fileName] - оригинальное имя файла для отображения в UI.
  ///
  /// Возвращает [ContractFileModel] с метаданными загруженного файла.
  ///
  /// Выбрасывает исключение при ошибке загрузки или сохранения.
  Future<ContractFileModel> uploadFile({
    required String contractId,
    required File file,
    required String fileName,
  });

  /// Удаляет файл по его идентификатору.
  ///
  /// Удаляет запись из базы данных и файл из хранилища.
  ///
  /// [fileId] - идентификатор файла в базе данных.
  /// [filePath] - путь к файлу в хранилище.
  ///
  /// Выбрасывает исключение при ошибке удаления.
  Future<void> deleteFile(String fileId, String filePath);

  /// Получает подписанный URL для скачивания файла.
  ///
  /// Создаёт временную ссылку с параметром download для принудительного
  /// скачивания файла с правильным именем.
  ///
  /// [filePath] - путь к файлу в хранилище.
  /// [originalName] - оригинальное имя файла для параметра download.
  ///
  /// Возвращает подписанный URL, действительный в течение 1 часа.
  Future<String> getDownloadUrl(String filePath, String originalName);

  /// Скачивает файл как массив байтов.
  ///
  /// [filePath] - путь к файлу в хранилище.
  ///
  /// Возвращает [List<int>] с содержимым файла.
  ///
  /// Выбрасывает исключение при ошибке скачивания.
  Future<List<int>> downloadFile(String filePath);
}

/// Реализация [ContractFileDataSource] на основе Supabase.
///
/// Использует Supabase Storage для хранения файлов и PostgreSQL
/// для хранения метаданных.
class SupabaseContractFileDataSource implements ContractFileDataSource {
  /// Клиент Supabase для работы с API.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  /// Создаёт экземпляр [SupabaseContractFileDataSource].
  ///
  /// [client] - клиент Supabase для выполнения операций.
  /// [activeCompanyId] - ID активной компании.
  SupabaseContractFileDataSource(this.client, this.activeCompanyId);

  @override
  Future<List<ContractFileModel>> getFilesByContract(String contractId) async {
    final response = await client
        .from('contract_files')
        .select('*')
        .eq('contract_id', contractId)
        .eq('company_id', activeCompanyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ContractFileModel.fromJson(json))
        .toList();
  }

  @override
  Future<ContractFileModel> uploadFile({
    required String contractId,
    required File file,
    required String fileName,
  }) async {
    // 1. Upload to Storage
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Для физического пути в Storage используем безопасное имя:
    // заменяем пробелы на подчеркивания и кодируем спецсимволы (включая кириллицу).
    // Это позволит браузеру корректно отобразить имя из URL, если заголовки не сработают.
    final safeName = Uri.encodeComponent(fileName.replaceAll(' ', '_'));
    final storagePath = '$contractId/${timestamp}_$safeName';

    await client.storage
        .from('contracts')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // 2. Save metadata to DB
    final fileData = {
      'contract_id': contractId,
      'company_id': activeCompanyId,
      'name': fileName, // Здесь оставляем оригинальное имя для отображения в UI
      'file_path': storagePath,
      'size': await file.length(),
      'type': _getContentType(fileName),
    };

    final response = await client
        .from('contract_files')
        .insert(fileData)
        .select()
        .single();

    return ContractFileModel.fromJson(response);
  }

  @override
  Future<void> deleteFile(String fileId, String filePath) async {
    // 1. Delete from DB
    await client
        .from('contract_files')
        .delete()
        .eq('id', fileId)
        .eq('company_id', activeCompanyId);

    // 2. Delete from Storage
    await client.storage.from('contracts').remove([filePath]);
  }

  @override
  Future<String> getDownloadUrl(String filePath, String originalName) async {
    final signedUrl = await client.storage
        .from('contracts')
        .createSignedUrl(filePath, 3600);
    final encodedName = Uri.encodeComponent(originalName);

    // Всегда возвращаем ссылку с параметром download для принудительного скачивания с правильным именем
    return '$signedUrl&download=$encodedName';
  }

  @override
  Future<List<int>> downloadFile(String filePath) async {
    return await client.storage.from('contracts').download(filePath);
  }

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
