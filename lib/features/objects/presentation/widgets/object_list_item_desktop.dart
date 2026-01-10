import 'package:flutter/material.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'object_list_shared.dart';

/// Виджет элемента списка объектов для десктопной версии.
///
/// Компактная строка списка, подсвечиваемая при выборе.
class ObjectListItemDesktop extends StatelessWidget {
  /// Данные объекта для отображения.
  final ObjectEntity object;

  /// Флаг, указывающий, выбран ли данный элемент в списке.
  final bool isSelected;

  /// Колбэк, вызываемый при нажатии на элемент.
  final VoidCallback onTap;

  /// Создает компактный элемент списка объектов.
  const ObjectListItemDesktop({
    super.key,
    required this.object,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Material(
        color: isSelected
            ? (isDark ? Colors.grey[800] : Colors.grey[200])
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  ObjectHelper.icon,
                  size: 16,
                  color: isSelected ? Colors.blue : theme.iconTheme.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        object.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.blue : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        object.address,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.8)
                              : theme.textTheme.bodySmall?.color?.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

