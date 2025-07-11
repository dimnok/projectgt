import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../domain/entities/work.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

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
              if (work.photoUrl != null && work.photoUrl!.isNotEmpty && 
                  work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty)
                const SizedBox(width: 16),
              
              // Вечерняя фотография
              if (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty)
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
              if ((work.photoUrl != null && work.photoUrl!.isNotEmpty && 
                  (work.eveningPhotoUrl == null || work.eveningPhotoUrl!.isEmpty)) ||
                  (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty && 
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
              if (work.photoUrl != null && work.photoUrl!.isNotEmpty && 
                  work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty)
                const SizedBox(height: 16),
              
              // Вечерняя фотография
              if (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty)
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
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
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
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Индикатор того, что можно нажать для просмотра оригинала
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  void _showPhotoFullscreen(BuildContext context, List<String> photoUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenPhotoView(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Виджет для полноэкранного просмотра изображений смены.
class _FullscreenPhotoView extends StatelessWidget {
  /// Список URL фотографий для просмотра.
  final List<String> photoUrls;
  /// Индекс фотографии, с которой начинается просмотр.
  final int initialIndex;

  /// Создаёт виджет полноэкранного просмотра фотографий смены.
  const _FullscreenPhotoView({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      appBar: AppBarWidget(
        title: initialIndex == 0 ? 'Фото на начало смены' : 'Фото на конец смены',
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        itemCount: photoUrls.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(photoUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: photoUrls[index]),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
        onPageChanged: (index) {
          // Можно отслеживать изменение страницы
        },
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 30.0,
            height: 30.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
} 