import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../domain/entities/work.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/work_provider.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/works/presentation/widgets/photo_loading_dialog.dart';
import 'package:projectgt/features/works/presentation/utils/photo_upload_helper.dart';

/// Извлекает время (HH:mm) из имени файла в URL фото смены.
/// Ожидаемый формат имени: YYYY-MM-DD_HH-mm-ss_morning.jpg / ..._evening.jpg
String? extractPhotoTimeFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    // ignore: deprecated_member_use
    final match = RegExp(r"(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})")
        .firstMatch(last);
    if (match != null) {
      final hour = match.group(4);
      final minute = match.group(5);
      if (hour != null && minute != null) {
        return '${hour.padLeft(2, '0')}:${minute.padLeft(2, '0')}';
      }
    }
  } catch (_) {}
  return null;
}

/// Виджет для отображения фотографий смены.
///
/// Показывает утренние и вечерние фотографии работы с возможностью просмотра в полноэкранном режиме.
/// Адаптируется под десктоп и мобильные устройства.
class WorkPhotoView extends StatelessWidget {
  /// Работа, для которой отображаются фотографии.
  final Work work;

  /// Создаёт виджет для отображения фотографий смены [work].
  const WorkPhotoView({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Проверяем, есть ли фотографии
    final hasPhotos = (work.photoUrl != null && work.photoUrl!.isNotEmpty) ||
        (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty);

    if (!hasPhotos) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Фотографии отсутствуют',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // В десктопном режиме располагаем фотографии рядом
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Утренняя фотография
              if (work.photoUrl != null && work.photoUrl!.isNotEmpty)
                Expanded(
                  child: _buildPhotoCard(
                    context: context,
                    title: 'Фото на начало смены',
                    imageUrl: work.photoUrl!,
                    icon: Icons.wb_sunny,
                    iconColor: Colors.amber,
                    index: 0,
                  ),
                ),

              // Разделитель, если есть обе фотографии
              if (work.photoUrl != null &&
                  work.photoUrl!.isNotEmpty &&
                  work.eveningPhotoUrl != null &&
                  work.eveningPhotoUrl!.isNotEmpty)
                const SizedBox(width: 16),

              // Вечерняя фотография
              if (work.eveningPhotoUrl != null &&
                  work.eveningPhotoUrl!.isNotEmpty)
                Expanded(
                  child: _buildPhotoCard(
                    context: context,
                    title: 'Фото на конец смены',
                    imageUrl: work.eveningPhotoUrl!,
                    icon: Icons.nightlight_round,
                    iconColor: Colors.indigo,
                    index: 1,
                  ),
                ),

              // Если есть только одна фотография, добавляем пустой Expanded для баланса
              if ((work.photoUrl != null &&
                      work.photoUrl!.isNotEmpty &&
                      (work.eveningPhotoUrl == null ||
                          work.eveningPhotoUrl!.isEmpty)) ||
                  (work.eveningPhotoUrl != null &&
                      work.eveningPhotoUrl!.isNotEmpty &&
                      (work.photoUrl == null || work.photoUrl!.isEmpty)))
                Expanded(child: Container()),
            ],
          )
        else
          // В мобильном режиме располагаем фотографии друг под другом
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Утренняя фотография
              if (work.photoUrl != null && work.photoUrl!.isNotEmpty)
                _buildPhotoCard(
                  context: context,
                  title: 'Фото на начало смены',
                  imageUrl: work.photoUrl!,
                  icon: Icons.wb_sunny,
                  iconColor: Colors.amber,
                  index: 0,
                ),

              // Разделитель, если есть обе фотографии
              if (work.photoUrl != null &&
                  work.photoUrl!.isNotEmpty &&
                  work.eveningPhotoUrl != null &&
                  work.eveningPhotoUrl!.isNotEmpty)
                const SizedBox(height: 16),

              // Вечерняя фотография
              if (work.eveningPhotoUrl != null &&
                  work.eveningPhotoUrl!.isNotEmpty)
                _buildPhotoCard(
                  context: context,
                  title: 'Фото на конец смены',
                  imageUrl: work.eveningPhotoUrl!,
                  icon: Icons.nightlight_round,
                  iconColor: Colors.indigo,
                  index: 1,
                ),
            ],
          ),
      ],
    );
  }

  /// Строит карточку с фотографией смены.
  Widget _buildPhotoCard({
    required BuildContext context,
    required String title,
    required String imageUrl,
    required IconData icon,
    Color? iconColor,
    required int index,
  }) {
    final theme = Theme.of(context);
    final uploadedTime = extractPhotoTimeFromUrl(imageUrl);

    // Создаем список фотографий для галереи
    final List<String> photoList = [];
    if (work.photoUrl != null && work.photoUrl!.isNotEmpty) {
      photoList.add(work.photoUrl!);
    }
    if (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty) {
      photoList.add(work.eveningPhotoUrl!);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с иконкой
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (uploadedTime != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      uploadedTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Изображение с возможностью клика для просмотра в полноэкранном режиме
          GestureDetector(
            onTap: () {
              _showPhotoFullscreen(context, photoList, index);
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ошибка загрузки изображения',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: theme.colorScheme.surface.withValues(alpha: 0.7),
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                // Индикатор того, что можно нажать для просмотра оригинала
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Нажмите для просмотра',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Открывает полноэкранный просмотр фотографий.
  void _showPhotoFullscreen(
      BuildContext context, List<String> photoUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenPhotoView(
          work: work,
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Виджет для полноэкранного просмотра изображений смены.
class _FullscreenPhotoView extends ConsumerStatefulWidget {
  /// Список URL фотографий для просмотра.
  final List<String> photoUrls;

  /// Индекс фотографии, с которой начинается просмотр.
  final int initialIndex;

  /// Текущая смена.
  final Work work;

  /// Создаёт виджет полноэкранного просмотра фотографий смены.
  const _FullscreenPhotoView({
    required this.work,
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  ConsumerState<_FullscreenPhotoView> createState() =>
      _FullscreenPhotoViewState();
}

class _FullscreenPhotoViewState extends ConsumerState<_FullscreenPhotoView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canModify {
    final profile = ref.read(currentUserProfileProvider).profile;
    return profile != null &&
        widget.work.openedBy == profile.id &&
        widget.work.status.toLowerCase() == 'open';
  }

  String get _titleBase =>
      _currentIndex == 0 ? 'Фото на начало смены' : 'Фото на конец смены';

  String get _title {
    final url =
        (widget.photoUrls.isNotEmpty && _currentIndex < widget.photoUrls.length)
            ? widget.photoUrls[_currentIndex]
            : null;
    final time = url != null ? extractPhotoTimeFromUrl(url) : null;
    if (time != null) {
      return '$_titleBase • $time';
    }
    return _titleBase;
  }

  Future<void> _replacePhoto() async {
    if (!_canModify) {
      SnackBarUtils.showWarning(
          context, 'Заменять фото может только автор открытой смены');
      return;
    }

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Выбор источника фото',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoRoundButton(
                  icon: Icons.photo_camera,
                  label: 'Камера',
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                _PhotoRoundButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
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

    if (source == null) return;

    try {
      final photoService = ref.read(photoServiceProvider);
      final bytes = await photoService.pickImageBytes(source);
      if (bytes == null) return;

      if (!mounted) return;

      // ✅ Загружаем фото через helper
      final photoType =
          _currentIndex == 0 ? PhotoType.morning : PhotoType.evening;
      final displayName = _currentIndex == 0 ? 'morning' : 'evening';

      final uploadedUrl = await PhotoUploadHelper(
        context: context,
        ref: ref,
      ).uploadPhoto(
        photoType: photoType,
        entity: 'work',
        entityId: widget.work.objectId,
        displayName: displayName,
        photoBytes: bytes,
        // ✅ Обновляем Work ВО ВРЕМЯ диалога загрузки
        onLoadingComplete: (String photoUrl) async {
          try {
            final updated = _currentIndex == 0
                ? widget.work
                    .copyWith(photoUrl: photoUrl, updatedAt: DateTime.now())
                : widget.work.copyWith(
                    eveningPhotoUrl: photoUrl, updatedAt: DateTime.now());

            await ref.read(worksProvider.notifier).updateWork(updated);

            // Обновляем локальный список URLов
            setState(() {
              if (_currentIndex == 0) {
                if (widget.photoUrls.isNotEmpty) {
                  widget.photoUrls[0] = photoUrl;
                }
              } else {
                if (widget.photoUrls.length > 1) {
                  widget.photoUrls[1] = photoUrl;
                } else {
                  widget.photoUrls.add(photoUrl);
                }
              }
            });
          } catch (e) {
            if (mounted) {
              SnackBarUtils.showError(
                  context, 'Ошибка при сохранении фото: $e');
            }
          }
        },
      );

      if (uploadedUrl == null) return;

      if (!mounted) return;

      // ✅ После нажатия "Готово" просто закрываем галерею
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при загрузке фото: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      appBar: AppBarWidget(
        title: _title,
        centerTitle: true,
        showThemeSwitch: false,
        leading: const BackButton(),
        actions: [
          if (_canModify)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _replacePhoto,
              child: const Icon(Icons.edit, color: Colors.amber),
            ),
        ],
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.photoUrls.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(widget.photoUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes:
                PhotoViewHeroAttributes(tag: widget.photoUrls[index]),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        loadingBuilder: (context, event) => const Center(
          child: SizedBox(
            width: 30.0,
            height: 30.0,
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
    );
  }
}

class _PhotoRoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoRoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
