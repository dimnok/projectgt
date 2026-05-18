import 'dart:io';
import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/domain/entities/contract_file.dart';

/// Интерфейс репозитория для управления файлами договоров.
///
/// Определяет методы для получения, загрузки, удаления и скачивания файлов,
/// связанных с конкретными договорами.
abstract class ContractFileRepository {
  /// Возвращает список метаданных всех файлов, прикрепленных к договору с [contractId].
  Future<List<ContractFile>> getFilesByContract(String contractId);

  /// Загружает новый файл в хранилище и создает запись в базе данных.
  ///
  /// Принимает [contractId] договора, сам [file], его [fileName] и [description].
  /// Возвращает объект [ContractFile] с данными о загруженном файле.
  Future<ContractFile> uploadFile({
    required String contractId,
    required File file,
    required String fileName,
    String? description,
  });

  /// Удаляет запись о файле из базы данных и сам файл из физического хранилища.
  ///
  /// Требует [fileId] (ID записи в БД) и [filePath] (путь к файлу в хранилище).
  Future<void> deleteFile(String fileId, String filePath);

  /// Обновляет отображаемое имя и примечание файла (метаданные в БД).
  ///
  /// Путь в хранилище и содержимое файла не меняются. Поле [type] пересчитывается
  /// по расширению в [name] (расширение должно совпадать с исходным файлом).
  /// Не переданные [documentStatus], [documentVersion], [isAmendment] не изменяются.
  Future<ContractFile> updateFileMetadata({
    required String fileId,
    required String name,
    String? description,
    ContractDocumentStatus? documentStatus,
    int? documentVersion,
    bool? isAmendment,
  });

  /// Массово выставляет статус документооборота для выбранных файлов.
  Future<void> updateFilesDocumentStatus({
    required List<String> fileIds,
    required ContractDocumentStatus status,
  });

  /// Скачивает содержимое файла в виде списка байтов.
  ///
  /// Используется для прямого доступа к данным файла по его [filePath].
  Future<List<int>> downloadFile(String filePath);

  /// Сохраняет порядок отображения файлов договора в БД.
  ///
  /// [orderedFileIds] — идентификаторы в порядке сверху вниз в UI.
  Future<void> updateFilesDisplayOrder({
    required String contractId,
    required List<String> orderedFileIds,
  });
}
