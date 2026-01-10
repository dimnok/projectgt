import 'dart:io';
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
  /// Принимает [contractId] договора, сам [file] и его [fileName].
  /// Возвращает объект [ContractFile] с данными о загруженном файле.
  Future<ContractFile> uploadFile({
    required String contractId,
    required File file,
    required String fileName,
  });

  /// Удаляет запись о файле из базы данных и сам файл из физического хранилища.
  ///
  /// Требует [fileId] (ID записи в БД) и [filePath] (путь к файлу в хранилище).
  Future<void> deleteFile(String fileId, String filePath);

  /// Генерирует временную публичную ссылку для скачивания файла.
  ///
  /// Принимает [filePath] в хранилище и [originalName] для подстановки в заголовок ответа.
  Future<String> getDownloadUrl(String filePath, String originalName);

  /// Скачивает содержимое файла в виде списка байтов.
  ///
  /// Используется для прямого доступа к данным файла по его [filePath].
  Future<List<int>> downloadFile(String filePath);
}
