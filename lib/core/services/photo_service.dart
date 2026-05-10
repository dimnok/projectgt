import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;

/// Сервис для работы с фотографиями пользователей, сотрудников и контрагентов через Supabase Storage.
///
/// Позволяет выбирать, загружать и удалять фотографии профиля, сотрудников и контрагентов.
/// Использует [image_picker] и [supabase_flutter].
class PhotoService {
  /// Экземпляр клиента Supabase для работы с хранилищем.
  final SupabaseClient _supabase;
  final _picker = ImagePicker();

  /// Создаёт сервис для работы с фотографиями.
  PhotoService(this._supabase);

  /// Открывает диалог выбора изображения.
  ///
  /// [source] — источник изображения (камера или галерея).
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
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
        return input;
      }

      final normalized = img.bakeOrientation(decoded);
      const int maxSide = 1600;
      final needResize = normalized.width > maxSide || normalized.height > maxSide;
      
      final img.Image processed = needResize
          ? img.copyResize(normalized,
              width: normalized.width >= normalized.height ? maxSide : null,
              height: normalized.height > normalized.width ? maxSide : null,
              interpolation: img.Interpolation.cubic)
          : normalized;

      if (processed.hasAlpha) {
        return Uint8List.fromList(img.encodePng(processed));
      }
      return Uint8List.fromList(img.encodeJpg(processed, quality: 85));
    } catch (e) {
      debugPrint('Compression failed: $e');
      return input;
    }
  }

  String _detectExtension(String? mime) {
    if (mime == null) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }

  String _detectMimeFromBytes(Uint8List bytes) {
    return lookupMimeType('', headerBytes: bytes) ?? 'image/jpeg';
  }

  String _datePath(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$d-$m-$y';
  }

  /// Возвращает имя файла для фотографий смены
  String _getWorkFileName(String displayName) {
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    final photoType = displayName.toLowerCase() == 'evening' ? 'evening' : 'morning';
    return '${timestamp}_$photoType.jpg';
  }

  /// Загружает фото в Supabase Storage.
  Future<String?> uploadPhoto({
    required String entity,
    required String id,
    required File file,
    String? displayName, // displayName оставлен опциональным, чтобы не ломать старые вызовы
  }) async {
    try {
      final originalBytes = await file.readAsBytes();
      return uploadPhotoBytes(
        entity: entity,
        id: id,
        bytes: originalBytes,
        displayName: displayName ?? 'photo',
      );
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Загрузка фото из bytes (универсально для Web/Mobile)
  Future<String?> uploadPhotoBytes({
    required String entity,
    required String id,
    required Uint8List bytes,
    String? displayName,
    DateTime? workDate,
  }) async {
    try {
      late String bucket;
      late String folder;
      
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

      // Удаление старых фото
      try {
        final files = await _supabase.storage.from(bucket).list(path: folder);
        late List<String> toDelete;
        
        if (entity == 'shift' || entity == 'work') {
          // Для смен пока оставляем старую логику удаления по префиксу (morning/evening)
          final type = (displayName?.toLowerCase() == 'evening') ? 'evening' : 'morning';
          toDelete = files
              .where((f) => f.name.contains('_$type.jpg'))
              .map((f) => '$folder${f.name}')
              .toList();
        } else {
          // Для аватаров удаляем всё в папке (кроме плейсхолдеров)
          toDelete = files
              .where((f) => !f.name.startsWith('.emptyFolderPlaceholder'))
              .map((f) => '$folder${f.name}')
              .toList();
        }
        
        if (toDelete.isNotEmpty) {
          await _supabase.storage.from(bucket).remove(toDelete);
        }
      } catch (e) {
        debugPrint('Error cleaning old photos: $e');
      }

      final compressedBytes = await _compressBytes(bytes);
      final mime = _detectMimeFromBytes(compressedBytes);
      final ext = _detectExtension(mime);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      late String fileName;
      late String filePath;

      if (entity == 'shift' || entity == 'work') {
        final dateToUse = workDate ?? DateTime.now();
        final datePrefix = _datePath(dateToUse);
        fileName = _getWorkFileName(displayName ?? 'morning');
        filePath = '$folder$datePrefix/$fileName';
      } else {
        // Идеальный стандарт для аватаров: {id}/avatar_{timestamp}.jpg
        fileName = 'avatar_$timestamp.$ext';
        filePath = '$folder$fileName';
      }

      await _supabase.storage.from(bucket).uploadBinary(
        filePath,
        compressedBytes,
        fileOptions: FileOptions(upsert: true, contentType: mime),
      );

      return _supabase.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading photo bytes: $e');
      rethrow;
    }
  }

  /// Удаляет все фото, связанные с сущностью
  Future<void> deletePhoto({
    required String entity,
    required String id,
    String? displayName,
  }) async {
    try {
      late String bucket;
      late String folder;
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
          throw Exception('Unknown entity for photo delete');
      }

      final files = await _supabase.storage.from(bucket).list(path: folder);
      late List<String> toDelete;

      if (entity == 'shift' || entity == 'work') {
        final type = (displayName?.toLowerCase() == 'evening') ? 'evening' : 'morning';
        toDelete = files
            .where((f) => f.name.contains('_$type.jpg') && !f.name.startsWith('.emptyFolderPlaceholder'))
            .map((f) => '$folder${f.name}')
            .toList();
      } else {
        toDelete = files
            .where((f) => !f.name.startsWith('.emptyFolderPlaceholder'))
            .map((f) => '$folder${f.name}')
            .toList();
      }

      if (toDelete.isNotEmpty) {
        await _supabase.storage.from(bucket).remove(toDelete);
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
    }
  }

  /// Удаляет фото по URL (универсально для любых сущностей)
  Future<void> deletePhotoByUrl(String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final publicIndex = pathSegments.indexOf('public');
      
      if (publicIndex == -1 || publicIndex + 1 >= pathSegments.length) return;

      final bucket = pathSegments[publicIndex + 1];
      final filePath = pathSegments.skip(publicIndex + 2).join('/');

      await _supabase.storage.from(bucket).remove([filePath]);
    } catch (e) {
      debugPrint('Error deleting photo by URL: $e');
    }
  }

  /// Удаляет фото смены по URL (оставлено для совместимости)
  Future<void> deleteWorkPhotoByUrl(String photoUrl) async {
    return deletePhotoByUrl(photoUrl);
  }
}
