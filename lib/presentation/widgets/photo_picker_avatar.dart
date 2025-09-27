import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectgt/core/di/providers.dart';

/// Универсальный виджет для выбора, загрузки, удаления и отображения фото/аватара.
///
/// Используется для сотрудников, контрагентов и других сущностей.
/// Поддерживает выбор из галереи, камеры, удаление, отображение прогресса и адаптацию под темы.
///
/// Пример использования:
/// ```dart
/// PhotoPickerAvatar(
///   imageUrl: url,
///   localFile: file,
///   label: 'Фото',
///   isLoading: false,
///   onImageChanged: (file) { ... },
///   onImageDeleted: () { ... },
/// )
/// ```
class PhotoPickerAvatar extends ConsumerWidget {
  /// URL изображения (например, из сети/Supabase).
  final String? imageUrl;

  /// Локальный файл изображения (например, только что выбранный).
  final File? localFile;

  /// Подпись под аватаром (например, "Фото сотрудника").
  final String label;

  /// Флаг загрузки (отображает индикатор и блокирует действия).
  final bool isLoading;

  /// Имя сущности (например, 'profile', 'employee', 'contractor').
  final String entity;

  /// Идентификатор сущности (например, ID пользователя).
  final String id;

  /// Имя сущности (например, 'profile', 'employee', 'contractor').
  final String displayName;

  /// Колбэк при выборе/замене изображения.
  ///
  /// Если [file] == null, значит фото было удалено.
  final ValueChanged<String?> onPhotoChanged;

  /// Радиус аватара (по умолчанию 48).
  final double radius;

  /// Иконка-заглушка, если фото отсутствует.
  final IconData placeholderIcon;

  /// Разрешить выбор фото с камеры (по умолчанию true).
  final bool allowCamera;

  /// Разрешить удаление фото (по умолчанию true).
  final bool allowDelete;

  /// Создаёт [PhotoPickerAvatar].
  ///
  /// [imageUrl] — url изображения (может быть null).
  /// [localFile] — локальный файл (может быть null).
  /// [label] — подпись под аватаром.
  /// [isLoading] — флаг загрузки.
  /// [entity] — имя сущности.
  /// [id] — идентификатор сущности.
  /// [displayName] — имя сущности.
  /// [onPhotoChanged] — колбэк при выборе/замене.
  /// [radius] — радиус аватара.
  /// [placeholderIcon] — иконка-заглушка.
  /// [allowCamera] — разрешить камеру.
  /// [allowDelete] — разрешить удаление.
  const PhotoPickerAvatar({
    super.key,
    required this.imageUrl,
    required this.localFile,
    required this.label,
    required this.isLoading,
    required this.entity,
    required this.id,
    required this.displayName,
    required this.onPhotoChanged,
    this.radius = 48,
    this.placeholderIcon = Icons.person,
    this.allowCamera = true,
    this.allowDelete = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isLoading ? null : () => _showPhotoOptions(context, ref),
            child: CircleAvatar(
              radius: radius,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.08),
              backgroundImage: localFile != null
                  ? FileImage(localFile!) as ImageProvider<Object>?
                  : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(imageUrl!)
                          as ImageProvider<Object>?
                      : null,
              child:
                  (localFile == null && (imageUrl == null || imageUrl!.isEmpty))
                      ? Icon(placeholderIcon,
                          size: radius, color: theme.colorScheme.primary)
                      : null,
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  /// Открывает модальное окно с выбором источника фото (камера, галерея, удалить).
  void _showPhotoOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (allowCamera)
                  _PhotoOptionButton(
                    icon: Icons.photo_camera,
                    label: 'Камера',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUpload(context, ref, ImageSource.camera);
                    },
                  ),
                _PhotoOptionButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(context, ref, ImageSource.gallery);
                  },
                ),
                if (allowDelete &&
                    (localFile != null ||
                        (imageUrl != null && imageUrl!.isNotEmpty)))
                  _PhotoOptionButton(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    onTap: () async {
                      Navigator.pop(context);
                      final photoService = ref.read(photoServiceProvider);
                      await photoService.deletePhoto(
                        entity: entity,
                        id: id,
                        displayName: displayName,
                      );
                      onPhotoChanged(null);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  /// Открывает image picker и возвращает выбранное фото через onPhotoChanged.
  Future<void> _pickAndUpload(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final photoService = ref.read(photoServiceProvider);
    if (kIsWeb) {
      final Uint8List? bytes = await photoService.pickImageBytes(source);
      if (bytes != null) {
        final url = await photoService.uploadPhotoBytes(
          entity: entity,
          id: id,
          bytes: bytes,
          displayName: displayName,
        );
        onPhotoChanged(url);
      }
    } else {
      final picked = await photoService.pickImage(source);
      if (picked != null) {
        final url = await photoService.uploadPhoto(
          entity: entity,
          id: id,
          file: picked,
          displayName: displayName,
        );
        onPhotoChanged(url);
      }
    }
  }
}

/// Кнопка выбора опции (камера, галерея, удалить) для модального окна выбора фото.
class _PhotoOptionButton extends StatelessWidget {
  /// Иконка опции.
  final IconData icon;

  /// Подпись опции.
  final String label;

  /// Колбэк при выборе.
  final VoidCallback onTap;
  const _PhotoOptionButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
