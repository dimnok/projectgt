import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Визуальные параметры карточки сотрудника в мобильном списке.
///
/// Соответствует градиенту, обводке и теням экрана списка.
@immutable
class EmployeesMobileEmployeeCardStyle {
  /// Создаёт набор стилей карточки.
  const EmployeesMobileEmployeeCardStyle({
    required this.scheme,
    required this.cardTop,
    required this.cardBottom,
    required this.cardBorder,
    required this.cardHighlight,
    required this.cardShadows,
  });

  /// Цветовая схема темы (текст, иконки).
  final ColorScheme scheme;

  /// Верхний цвет градиента заливки карточки.
  final Color cardTop;

  /// Нижний цвет градиента заливки карточки.
  final Color cardBottom;

  /// Цвет рамки карточки и рамки квадратного аватара.
  final Color cardBorder;

  /// Цвет верхней «подсветки» (1 px).
  final Color cardHighlight;

  /// Тени под карточкой.
  final List<BoxShadow> cardShadows;
}

/// Карточка строки сотрудника: градиент, аватар, индикатор статуса (точка), ФИО, должность, объекты.
class EmployeesMobileEmployeeCard extends StatelessWidget {
  /// Создаёт карточку сотрудника для мобильного списка.
  const EmployeesMobileEmployeeCard({
    super.key,
    required this.style,
    required this.photoUrl,
    required this.displayName,
    required this.positionLine,
    required this.objectsLine,
    required this.statusSemanticsLabel,
    required this.statusColor,
  });

  /// Стили карточки и темы.
  final EmployeesMobileEmployeeCardStyle style;

  /// URL фото; при `null` показываются инициалы из [displayName].
  final String? photoUrl;

  /// Полное имя (для подписи при отсутствии фото — инициалы).
  final String displayName;

  /// Строка должности или заглушка.
  final String positionLine;

  /// Названия объектов через запятую или заглушка.
  final String objectsLine;

  /// Текст статуса для доступности ([Semantics]); на экране показывается только цветная точка.
  final String statusSemanticsLabel;

  /// Цвет индикатора статуса (круглая точка).
  final Color statusColor;

  /// Радиус скругления внешней рамки карточки и аватара ([BoxDecoration.borderRadius]).
  static const double _cardDecorationRadius = 16;

  /// Радиус скругления клипа карточки ([ClipRRect]): на 1 меньше внешнего из‑за обводки.
  static const double _cardClipRadius = 15;

  /// Сторона квадратного аватара (крупнее при вертикальных отступах 10, как слева).
  static const double _avatarSide = 68;

  /// Внутренние отступы контента карточки; слева/справа/сверху/снизу одинаковые (как отступ аватара слева).
  static const EdgeInsets _cardContentPadding = EdgeInsets.all(10);

  /// Диаметр точки статуса.
  static const double _statusDotDiameter = 10;

  static String _initialsFromFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${_firstGraphemeUpper(parts[0])}${_firstGraphemeUpper(parts[1])}';
    }
    if (parts.length == 1) {
      return _firstGraphemeUpper(parts[0]);
    }
    return '?';
  }

  static String _firstGraphemeUpper(String s) {
    if (s.isEmpty) return '';
    final first = String.fromCharCode(s.runes.first);
    return first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = style.scheme;
    final hi = style.cardHighlight;
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final initials = _initialsFromFullName(displayName);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardDecorationRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.cardTop, style.cardBottom],
        ),
        border: Border.all(width: 1, color: style.cardBorder),
        boxShadow: style.cardShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardClipRadius),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      hi.withValues(alpha: 0.0),
                      hi,
                      hi.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: _cardContentPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: _avatarSide,
                    height: _avatarSide,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _cardDecorationRadius,
                      ),
                      border: Border.all(color: style.cardBorder, width: 1),
                      color: hasPhoto ? null : scheme.surfaceContainerHighest,
                    ),
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: photoUrl!.trim(),
                            width: _avatarSide,
                            height: _avatarSide,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                              ),
                              child: Semantics(
                                label: 'Статус: $statusSemanticsLabel',
                                child: Container(
                                  width: _statusDotDiameter,
                                  height: _statusDotDiameter,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.22,
                                  letterSpacing: -0.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          positionLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.28,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          objectsLine,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.outline,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            letterSpacing: 0.12,
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
    );
  }
}
