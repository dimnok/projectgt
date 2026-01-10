import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Вспомогательный класс для стилей карточки сотрудника.
///
/// Содержит размеры и стили для разных режимов отображения (компактный/обычный).
class EmployeeCardStyles {
  /// Радиус аватара сотрудника.
  final double avatarRadius;

  /// Размер иконки внутри аватара.
  final double iconSize;

  /// Масштаб текста имени сотрудника.
  final double nameTextScale;

  /// Внешний отступ карточки.
  final EdgeInsets cardMargin;

  /// Внутренний отступ содержимого карточки.
  final EdgeInsets contentPadding;

  /// Создает стили для карточки сотрудника.
  ///
  /// [isCompact] - флаг компактного режима.
  EmployeeCardStyles({required bool isCompact})
      : avatarRadius = isCompact ? 24.0 : 30.0,
        iconSize = isCompact ? 24.0 : 30.0,
        nameTextScale = isCompact ? 1.0 : 1.1,
        cardMargin = isCompact
            ? const EdgeInsets.symmetric(horizontal: 0, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        contentPadding = const EdgeInsets.all(16.0);
}

/// Виджет карточки сотрудника, адаптивный под разные размеры экрана.
///
/// Используется в списке сотрудников и адаптируется под мобильные/десктопные устройства.
class EmployeeCard extends StatelessWidget {
  /// Данные сотрудника.
  final Employee employee;

  /// Флаг, указывающий, выбрана ли эта карточка.
  final bool isSelected;

  /// Обработчик нажатия на карточку.
  final VoidCallback? onTap;

  /// Модификатор размера карточки (compact/normal).
  final bool isCompact;

  /// Список объектов для отображения.
  final List<ObjectEntity> objects;

  /// Создаёт карточку сотрудника.
  ///
  /// [employee] - данные сотрудника.
  /// [isSelected] - выбрана ли эта карточка.
  /// [onTap] - обработчик нажатия на карточку.
  /// [isCompact] - использовать ли компактный вид (по умолчанию определяется автоматически).
  /// [objects] - список объектов для отображения названий объектов, к которым привязан сотрудник.
  const EmployeeCard({
    super.key,
    required this.employee,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
    this.objects = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusText, statusColor) =
        EmployeeUIUtils.getStatusInfo(employee.status);

    // Определяем использовать ли компактный режим
    final bool useCompactLayout =
        isCompact || ResponsiveUtils.isDesktop(context);

    // Определяем тип устройства для адаптивного отображения статуса
    final bool isMobile = ResponsiveUtils.isMobile(context);

    // Создаем стили на основе размера макета
    final styles = EmployeeCardStyles(isCompact: useCompactLayout);

    final cardWidget = Card(
      margin: styles.cardMargin,
      elevation: isMobile ? 8 : 0,
      shadowColor:
          isMobile ? theme.colorScheme.shadow.withValues(alpha: 0.2) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
        side: BorderSide(
          color: isSelected
              ? Colors.green
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
            child: Container(
              decoration: isMobile
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    )
                  : null,
              child: Stack(
                children: [
                  // Бейдж со статусом (только для десктопа)
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: AppBadge(
                          text: statusText,
                          color: statusColor,
                        ),
                      ),
                    ),
                  // Цветная полоска статуса слева (только для мобильных)
                  if (isMobile)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        color: statusColor,
                      ),
                    ),
                  // Основное содержимое
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile
                          ? styles.contentPadding.left + 8
                          : styles.contentPadding.left,
                      styles.contentPadding.top,
                      styles.contentPadding.right,
                      styles.contentPadding.bottom,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Аватар
                        _buildAvatar(context, styles, theme),
                        SizedBox(width: useCompactLayout ? 12 : 16),
                        // Информация
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Имя и фамилия с индикатором статуса для мобильных
                              Row(
                                children: [
                                  // Цветная точка статуса (только для мобильных)
                                  if (isMobile) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // ФИО
                                  Expanded(
                                    child: Text(
                                      _getEmployeeFullName(),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: (theme.textTheme.titleMedium
                                                    ?.fontSize ??
                                                16) *
                                            styles.nameTextScale,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (employee.position != null)
                                Text(
                                  employee.position!,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              // Добавляем отображение объектов
                              if (employee.objectIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: isMobile
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4)
                                        : EdgeInsets.zero,
                                    decoration: isMobile
                                        ? BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.2),
                                              width: 0.5,
                                            ),
                                          )
                                        : null,
                                    child: Text(
                                      _getObjectsText(),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return isMobile
        ? Tooltip(
            message: statusText,
            child: cardWidget,
          )
        : cardWidget;
  }

  /// Получает текстовое представление списка объектов сотрудника.
  ///
  /// Если у сотрудника нет объектов — возвращает "Нет объектов".
  /// Если не найдено ни одного названия — возвращает "Нет информации".
  /// В противном случае возвращает строку с перечислением объектов.
  String _getObjectsText() {
    if (employee.objectIds.isEmpty) {
      return "Нет объектов";
    }

    // Получаем имена объектов по objectIds
    final names = employee.objectIds
        .map((id) => objects
            .firstWhere(
              (o) => o.id == id,
              orElse: () => const ObjectEntity(
                id: '',
                companyId: '',
                name: '—',
                address: '',
              ),
            )
            .name)
        .where((name) => name != '—')
        .toList();

    if (names.isEmpty) {
      return "Нет информации";
    }

    return "Объекты: ${names.join(', ')}";
  }

  /// Строит аватар сотрудника.
  ///
  /// Использует Hero-анимацию для плавного перехода.
  Widget _buildAvatar(
      BuildContext context, EmployeeCardStyles styles, ThemeData theme) {
    return Hero(
      tag: 'employee_avatar_${employee.id}_$hashCode',
      child: CircleAvatar(
        radius: styles.avatarRadius,
        backgroundColor: theme.colorScheme.primary,
        child: _buildAvatarContent(styles, theme),
      ),
    );
  }

  /// Создает содержимое аватара в зависимости от наличия фото.
  ///
  /// Если фото есть — отображает фото, иначе — иконку-заполнитель.
  Widget _buildAvatarContent(EmployeeCardStyles styles, ThemeData theme) {
    // Если есть фото - отображаем фото, иначе - иконку
    return employee.photoUrl != null
        ? _buildAvatarImage(styles, theme)
        : _buildAvatarPlaceholder(styles, theme, isError: false);
  }

  /// Создает изображение аватара сотрудника.
  ///
  /// Использует CachedNetworkImage для загрузки фото по URL.
  Widget _buildAvatarImage(EmployeeCardStyles styles, ThemeData theme) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: employee.photoUrl!,
        width: styles.avatarRadius * 2,
        height: styles.avatarRadius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            _buildImageLoadingPlaceholder(styles, theme),
        errorWidget: (context, url, error) =>
            _buildAvatarPlaceholder(styles, theme, isError: true),
      ),
    );
  }

  /// Создает заполнитель при загрузке изображения аватара.
  ///
  /// Используется, пока фото сотрудника не загружено.
  Widget _buildImageLoadingPlaceholder(
      EmployeeCardStyles styles, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: styles.iconSize,
        color: theme.colorScheme.primary,
      ),
    );
  }

  /// Создает иконку-заполнитель аватара.
  ///
  /// [isError] — если true, отображается иконка ошибки.
  Widget _buildAvatarPlaceholder(EmployeeCardStyles styles, ThemeData theme,
      {required bool isError}) {
    final Color iconColor =
        isError ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimary;

    return Icon(
      Icons.person,
      size: styles.iconSize,
      color: iconColor,
    );
  }

  /// Возвращает полное имя сотрудника.
  ///
  /// Формат: "Фамилия Имя Отчество" (если отчество есть).
  String _getEmployeeFullName() {
    // Всегда возвращаем полное имя, включая отчество (если есть)
    return '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ""}';
  }
}
