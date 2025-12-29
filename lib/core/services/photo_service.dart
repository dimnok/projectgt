import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;

/// Сервис для работы с фотографиями пользователей, сотрудников и контрагентов через Supabase Storage.
///
/// Позволяет выбирать, загружать и удалять фотографии профиля, сотрудников и контрагентов.
/// Использует [image_picker] и [supabase_flutter].
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

  /// Создаёт сервис для работы с фотографиями.
  ///
  /// [supabase] — экземпляр клиента Supabase для доступа к Storage.
  PhotoService(this._supabase);

  /// Открывает диалог выбора изображения.
  ///
  /// [source] — источник изображения (камера или галерея).
  ///
  /// Возвращает [File] с выбранным изображением или null, если пользователь отменил выбор.
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

      // Возвращаем файл напрямую без кадрирования
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Универсальный выбор изображения: возвращает bytes (поддерживает Web/Mobile)
  Future<Uint8List?> pickImageBytes(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (pickedFile == null) return null;
      return await pickedFile.readAsBytes();
    } catch (e) {
      debugPrint('Error picking image bytes: $e');
      return null;
    }
  }

  /// Компрессия изображения: ресайз до ~1600px по длинной стороне, JPEG/PNG
  Future<Uint8List> _compressBytes(Uint8List input) async {
    try {
      final decoded = img.decodeImage(input);
      if (decoded == null) {
        return input; // не смогли декодировать — вернём как есть
      }

      // Нормализация ориентации (если есть EXIF)
      final normalized = img.bakeOrientation(decoded);

      const int maxSide = 1600;
      final needResize = max(normalized.width, normalized.height) > maxSide;
      final img.Image processed = needResize
          ? img.copyResize(normalized,
              width: normalized.width >= normalized.height ? maxSide : null,
              height: normalized.height > normalized.width ? maxSide : null,
              interpolation: img.Interpolation.cubic)
          : normalized;

      // Если есть альфа — PNG, иначе JPEG
      final bool hasAlpha = processed.hasAlpha;
      if (hasAlpha) {
        return Uint8List.fromList(img.encodePng(processed));
      }
      return Uint8List.fromList(img.encodeJpg(processed, quality: 85));
    } catch (e) {
      debugPrint('Compression failed, return original. Error: $e');
      return input;
    }
  }

  String _detectExtension(String? mime) {
    if (mime == null) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    return 'jpg';
  }

  String _detectMimeFromBytes(Uint8List bytes) {
    return lookupMimeType('', headerBytes: bytes) ?? 'image/jpeg';
  }

  String _uniqueId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$now$rnd';
  }

  String _datePath(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$d-$m-$y';
  }

  /// Преобразует строку в безопасный slug для имени файла.
  ///
  /// [input] — исходная строка (например, ФИО или название).
  ///
  /// Возвращает строку, пригодную для использования в имени файла (латиница, цифры, подчёркивания).
  String slugify(String input) {
    final map = {
      'а': 'a',
      'б': 'b',
      'в': 'v',
      'г': 'g',
      'д': 'd',
      'е': 'e',
      'ё': 'e',
      'ж': 'zh',
      'з': 'z',
      'и': 'i',
      'й': 'y',
      'к': 'k',
      'л': 'l',
      'м': 'm',
      'н': 'n',
      'о': 'o',
      'п': 'p',
      'р': 'r',
      'с': 's',
      'т': 't',
      'у': 'u',
      'ф': 'f',
      'х': 'h',
      'ц': 'ts',
      'ч': 'ch',
      'ш': 'sh',
      'щ': 'sch',
      'ъ': '',
      'ы': 'y',
      'ь': '',
      'э': 'e',
      'ю': 'yu',
      'я': 'ya',
      'А': 'A',
      'Б': 'B',
      'В': 'V',
      'Г': 'G',
      'Д': 'D',
      'Е': 'E',
      'Ё': 'E',
      'Ж': 'Zh',
      'З': 'Z',
      'И': 'I',
      'Й': 'Y',
      'К': 'K',
      'Л': 'L',
      'М': 'M',
      'Н': 'N',
      'О': 'O',
      'П': 'P',
      'Р': 'R',
      'С': 'S',
      'Т': 'T',
      'У': 'U',
      'Ф': 'F',
      'Х': 'H',
      'Ц': 'Ts',
      'Ч': 'Ch',
      'Ш': 'Sh',
      'Щ': 'Sch',
      'Ъ': '',
      'Ы': 'Y',
      'Ь': '',
      'Э': 'E',
      'Ю': 'Yu',
      'Я': 'Ya'
    };
    String result = input.split('').map((c) => map[c] ?? c).join();
    // ignore: deprecated_member_use
    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    // ignore: deprecated_member_use
    result = result.replaceAll(RegExp(r'_+'), '_');
    // ignore: deprecated_member_use
    result = result.replaceAll(RegExp(r'^_|_$'), '');
    return result.toLowerCase();
  }

  /// Возвращает уникальное имя файла для фотографий смены на основе текущей даты и времени
  String _getWorkFileName(String displayName) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';

    // Определяем тип фото
    final photoType =
        displayName.toLowerCase() == 'evening' ? 'evening' : 'morning';

    return '${timestamp}_$photoType.jpg';
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
      // path.extension оставлен ранее, но фактически не используется после перехода на bytes
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
          // Используем objectId для создания папки (id должен содержать objectId)
          folder = '$id/';
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
          debugPrint(
              'StorageException код: ${e.statusCode}, сообщение: ${e.message}, ошибка: ${e.error}');
        }
      }

      // ЧИТАЕМ И СЖИМАЕМ В БАЙТЫ, ЗАГРУЖАЕМ ЧЕРЕЗ uploadBinary
      final originalBytes = await file.readAsBytes();
      final compressedBytes = await _compressBytes(originalBytes);
      final now = DateTime.now();
      final mime = _detectMimeFromBytes(compressedBytes);
      final ext = _detectExtension(mime);
      final unique = _uniqueId();
      final datePrefix = _datePath(now);

      // путь: <folder>/<yyyy/MM/dd>/<slug>_<unique>.<ext>
      final fileName = (entity == 'shift' || entity == 'work')
          ? _getWorkFileName(displayName)
          : '${safeName}_$unique.$ext';
      final filePath = '$folder$datePrefix/$fileName';
      debugPrint('Загружаем файл по пути: $filePath');

      try {
        await _supabase.storage.from(bucket).uploadBinary(
              filePath,
              compressedBytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: mime,
              ),
            );

        final imageUrlResponse =
            _supabase.storage.from(bucket).getPublicUrl(filePath);
        debugPrint('Получен URL: $imageUrlResponse');
        return imageUrlResponse;
      } catch (e) {
        debugPrint('Ошибка при загрузке файла: $e');
        if (e is StorageException) {
          debugPrint(
              'StorageException код: ${e.statusCode}, сообщение: ${e.message}, ошибка: ${e.error}');
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (e is StorageException) {
        debugPrint(
            'StorageException: ${e.message} (код ${e.statusCode}): ${e.error}');
      }
      rethrow;
    }
  }

  /// Загрузка фото из bytes (универсально для Web/Mobile)
  Future<String?> uploadPhotoBytes({
    required String entity,
    required String id,
    required Uint8List bytes,
    required String displayName,
    DateTime? workDate,
  }) async {
    try {
      debugPrint('Начинаем загрузку фото (bytes) для $entity:$id:$displayName');
      late String bucket;
      late String folder;
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
          folder = '$id/';
          break;
        default:
          throw Exception('Unknown entity for photo upload');
      }

      // Очистка старых по префиксу — по возможности оставляем последнюю (опционально)
      try {
        final files = await _supabase.storage.from(bucket).list(path: folder);
        final toDelete = files
            .where((f) => f.name.startsWith(safeName))
            .map((f) => '$folder${f.name}')
            .toList();
        if (toDelete.isNotEmpty) {
          await _supabase.storage.from(bucket).remove(toDelete);
        }
      } catch (_) {}

      final compressedBytes = await _compressBytes(bytes);
      final now = DateTime.now();
      final mime = _detectMimeFromBytes(compressedBytes);
      final ext = _detectExtension(mime);
      final unique = _uniqueId();
      // Используем дату смены если передана, иначе текущую дату
      final dateToUse =
          (entity == 'work' || entity == 'shift') && workDate != null
              ? workDate
              : now;
      final datePrefix = _datePath(dateToUse);

      final fileName = (entity == 'shift' || entity == 'work')
          ? _getWorkFileName(displayName)
          : '${safeName}_$unique.$ext';
      final filePath = '$folder$datePrefix/$fileName';

      await _supabase.storage.from(bucket).uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mime,
            ),
          );

      return _supabase.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading photo (bytes): $e');
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
          // Используем objectId для создания папки (id должен содержать objectId)
          folder = '$id/';
          break;
        default:
          throw Exception('Unknown entity for photo delete');
      }

      final files = await _supabase.storage.from(bucket).list(path: folder);

      // Изменяем логику определения файлов для удаления
      late List<String> toDelete;

      if (entity == 'shift' || entity == 'work') {
        // Для фотографий смены удаляем файлы по типу (morning или evening)
        final photoType =
            displayName.toLowerCase() == 'evening' ? 'evening' : 'morning';

        toDelete = files
            .where((f) => f.name.contains('_$photoType.jpg'))
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
        debugPrint(
            'StorageException: ${e.message} (код ${e.statusCode}): ${e.error}');
      }
    }
  }

  /// Удаляет фото смены по URL.
  ///
  /// [photoUrl] — URL фото смены для удаления.
  ///
  /// Извлекает путь из URL и удаляет файл из storage.
  Future<void> deleteWorkPhotoByUrl(String photoUrl) async {
    try {
      debugPrint('Удаляем фото смены по URL: $photoUrl');

      // Извлекаем путь из URL
      // URL имеет вид: https://xxx.supabase.co/storage/v1/object/public/works/2024/01/15/1.jpg
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Находим индекс 'public' и берем все что после него
      final publicIndex = pathSegments.indexOf('public');
      if (publicIndex == -1 || publicIndex + 1 >= pathSegments.length) {
        debugPrint('Не удалось извлечь путь из URL: $photoUrl');
        return;
      }

      final bucket = pathSegments[publicIndex + 1]; // 'works'
      final filePath =
          pathSegments.skip(publicIndex + 2).join('/'); // '2024/01/15/1.jpg'

      debugPrint('Bucket: $bucket, FilePath: $filePath');

      await _supabase.storage.from(bucket).remove([filePath]);
      debugPrint('Фото смены успешно удалено');
    } catch (e) {
      debugPrint('Error deleting work photo by URL: $e');
      if (e is StorageException) {
        debugPrint(
            'StorageException: ${e.message} (код ${e.statusCode}): ${e.error}');
      }
    }
  }
}
