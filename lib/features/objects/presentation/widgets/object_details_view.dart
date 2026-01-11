import 'package:flutter/material.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'object_list_shared.dart';

/// Виджет для отображения детальной информации об объекте.
/// Используется как на отдельном экране (mobile), так и в боковой панели (desktop).
class ObjectDetailsView extends StatelessWidget {
  /// Объект для отображения.
  final ObjectEntity object;

  /// Создаёт виджет деталей объекта.
  const ObjectDetailsView({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Center(
            child: Column(
              children: [
                ObjectAvatar(object: object, radius: 50, useHero: true),
                const SizedBox(height: 16),
                Text(
                  object.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (object.address.length < 60) ...[
                  const SizedBox(height: 8),
                  Text(
                    object.address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          ObjectDetailsSections(object: object),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
