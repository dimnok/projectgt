import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Сервис для работы с фотографиями пользователей, сотрудников и контрагентов через Supabase Storage.
///
/// Позволяет выбирать, кадрировать, загружать и удалять фотографии профиля, сотрудников и контрагентов.
/// Использует [image_picker], [image_cropper] и [supabase_flutter].
///
/// Пример использования:
/// ```dart
/// final service = PhotoService(Supabase.instance.client);
/// final file = await service.pickImage(ImageSource.camera);
/// if (file != null) {
///   final url = await service.uploadPhoto(
///     entity: 'employee',
///     id: employeeId,
///     file: file,
///     displayName: employeeName,
///   );
/// }
/// ```
class PhotoService {
  /// Экземпляр клиента Supabase для работы с хранилищем.
  final SupabaseClient _supabase;
  final _picker = ImagePicker();
  final _cropper = ImageCropper();
  
  /// Создаёт сервис для работы с фотографиями.
  ///
  /// [supabase] — экземпляр клиента Supabase для доступа к Storage.
  PhotoService(this._supabase);
  
  /// Открывает диалог выбора и кадрирования изображения.
  ///
  /// [source] — источник изображения (камера или галерея).
  ///
  /// Возвращает [File] с кадрированным изображением или null, если пользователь отменил выбор.
  /// В случае ошибки возвращает null и пишет ошибку в debugPrint.
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return null;
      
      // Кадрирование изображения
      final CroppedFile? croppedFile = await _cropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Редактировать фото',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Редактировать фото',
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  /// Преобразует строку в безопасный slug для имени файла.
  ///
  /// [input] — исходная строка (например, ФИО или название).
  ///
  /// Возвращает строку, пригодную для использования в имени файла (латиница, цифры, подчёркивания).
  String slugify(String input) {
    final map = {
      'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'e','ж':'zh','з':'z','и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'h','ц':'ts','ч':'ch','ш':'sh','щ':'sch','ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya',
      'А':'A','Б':'B','В':'V','Г':'G','Д':'D','Е':'E','Ё':'E','Ж':'Zh','З':'Z','И':'I','Й':'Y','К':'K','Л':'L','М':'M','Н':'N','О':'O','П':'P','Р':'R','С':'S','Т':'T','У':'U','Ф':'F','Х':'H','Ц':'Ts','Ч':'Ch','Ш':'Sh','Щ':'Sch','Ъ':'','Ы':'Y','Ь':'','Э':'E','Ю':'Yu','Я':'Ya'
    };
    String result = input.split('').map((c) => map[c] ?? c).join();
    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_|_$'), '');
    return result.toLowerCase();
  }
  
  /// Возвращает имя папки для хранения фотографий работы на основе текущей даты
  String _getWorkDateFolder() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}/';
  }

  /// Загружает фото в Supabase Storage для профиля, сотрудника или контрагента.
  ///
  /// [entity] — тип сущности: 'profile', 'employee', 'contractor'.
  /// [id] — идентификатор сущности (userId, employeeId, contractorId).
  /// [file] — локальный файл изображения.
  /// [displayName] — отображаемое имя (используется для генерации имени файла).
  ///
  /// Удаляет старые фото с тем же префиксом, загружает новое с уникальным именем (timestamp).
  ///
  /// Возвращает публичный URL загруженного изображения или null в случае ошибки.
  ///
  /// Возможные ошибки логируются через debugPrint.
  Future<String?> uploadPhoto({
    required String entity, // 'profile', 'employee', 'contractor'
    required String id,
    required File file,
    required String displayName, // ФИО, сокращённое имя, полное имя
  }) async {
    try {
      debugPrint('Начинаем загрузку фото для $entity:$id:$displayName');
      late String bucket;
      late String folder;
      final fileExt = path.extension(file.path);
      String safeName = slugify(displayName);
      switch (entity) {
        case 'profile':
          bucket = 'avatars';
          folder = 'profiles/$id/';
          break;
        case 'employee':
          bucket = 'employees';
          folder = '$id/';
          break;
        case 'contractor':
          bucket = 'contractors';
          folder = '$id/';
          break;
        case 'shift':
        case 'work':
          bucket = 'works';
          // Всегда используем текущую дату для папки, вне зависимости от наличия ID
          folder = _getWorkDateFolder();
          break;
        default:
          throw Exception('Unknown entity for photo upload');
      }
      
      debugPrint('Использую бакет: $bucket, папку: $folder');
      
      // ВАЖНО: Бакет 'works' и другие бакеты уже созданы и не требуют проверки или создания
      // Просто работаем с бакетом напрямую
      
      // Удалить все старые файлы с этим префиксом
      try {
        debugPrint('Получаем список файлов в папке $folder...');
        final files = await _supabase.storage.from(bucket).list(path: folder);
        final toDelete = files
            .where((f) => f.name.startsWith(safeName))
            .map((f) => '$folder${f.name}')
            .toList();
        
        if (toDelete.isNotEmpty) {
          debugPrint('Удаляем ${toDelete.length} старых файлов...');
          await _supabase.storage.from(bucket).remove(toDelete);
        }
      } catch (e) {
        // Игнорируем ошибки при удалении (папка может не существовать)
        debugPrint('Ошибка при получении списка файлов или удалении: $e');
        if (e is StorageException) {
          debugPrint('StorageException код: ${e.statusCode}, сообщение: ${e.message}, ошибка: ${e.error}');
        }
      }
      
      // Загружаем новый файл с уникальным именем
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName;
      
      if (entity == 'shift' || entity == 'work') {
        if (displayName.toLowerCase() == 'evening') {
          fileName = '2.jpg';
        } else {
          fileName = '1.jpg';
        }
      } else {
        fileName = '${safeName}_$timestamp$fileExt';
      }
      
      final filePath = '$folder$fileName';
      debugPrint('Загружаем файл по пути: $filePath');
      
      try {
        await _supabase.storage
            .from(bucket)
            .upload(filePath, file, fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ));
        
        debugPrint('Файл успешно загружен, получаем публичный URL...');
        final imageUrlResponse = _supabase.storage.from(bucket).getPublicUrl(filePath);
        debugPrint('Получен URL: $imageUrlResponse');
        return imageUrlResponse;
      } catch (e) {
        debugPrint('Ошибка при загрузке файла: $e');
        if (e is StorageException) {
          debugPrint('StorageException код: ${e.statusCode}, сообщение: ${e.message}, ошибка: ${e.error}');
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (e is StorageException) {
        debugPrint('StorageException: ${e.message} (код ${e.statusCode}): ${e.error}');
      }
      rethrow;
    }
  }
  
  /// Удаляет все фото, связанные с сущностью (профиль, сотрудник, контрагент) в Supabase Storage.
  ///
  /// [entity] — тип сущности: 'profile', 'employee', 'contractor'.
  /// [id] — идентификатор сущности.
  /// [displayName] — отображаемое имя (используется для поиска файлов по префиксу).
  ///
  /// Удаляет все файлы, имя которых начинается с префикса, сгенерированного из [displayName].
  ///
  /// Возможные ошибки логируются через debugPrint.
  Future<void> deletePhoto({
    required String entity,
    required String id,
    required String displayName,
  }) async {
    try {
      late String bucket;
      late String folder;
      final safeName = slugify(displayName);
      switch (entity) {
        case 'profile':
          bucket = 'avatars';
          folder = 'profiles/$id/';
          break;
        case 'employee':
          bucket = 'employees';
          folder = '$id/';
          break;
        case 'contractor':
          bucket = 'contractors';
          folder = '$id/';
          break;
        case 'shift':
        case 'work':
          bucket = 'works';
          // Всегда используем текущую дату для папки, вне зависимости от наличия ID
          folder = _getWorkDateFolder();
          break;
        default:
          throw Exception('Unknown entity for photo delete');
      }
      
      final files = await _supabase.storage.from(bucket).list(path: folder);
      
      // Изменяем логику определения файлов для удаления
      late List<String> toDelete;
      
      if (entity == 'shift' || entity == 'work') {
        // Для фотографий смены удаляем конкретный файл (1.jpg или 2.jpg)
        String fileName;
        if (displayName.toLowerCase() == 'evening') {
          fileName = '2.jpg'; // Вечернее фото
        } else {
          fileName = '1.jpg'; // Утреннее фото
        }
        
        toDelete = files
            .where((f) => f.name == fileName)
            .map((f) => '$folder${f.name}')
            .toList();
      } else {
        // Для других сущностей используем прежнюю логику с поиском по префиксу
        toDelete = files
            .where((f) => f.name.startsWith(safeName))
            .map((f) => '$folder${f.name}')
            .toList();
      }
      
      if (toDelete.isNotEmpty) {
        await _supabase.storage.from(bucket).remove(toDelete);
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      if (e is StorageException) {
        debugPrint('StorageException: ${e.message} (код ${e.statusCode}): ${e.error}');
      }
    }
  }
} 