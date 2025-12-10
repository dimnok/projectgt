import 'package:flutter/material.dart';
import 'package:projectgt/features/procurement/data/models/bot_user_model.dart';

/// Карточка, отображающая этап закупки.
///
/// Используется для настройки пользователей, ответственных за разные этапы.
class ProcurementStageCard extends StatelessWidget {
  /// Заголовок этапа.
  final String title;

  /// Описание этапа.
  final String description;

  /// Идентификатор этапа (статус).
  final String stage;

  /// Иконка этапа.
  final IconData icon;

  /// Список ID выбранных пользователей.
  final List<String> selectedIds;

  /// Список всех доступных пользователей.
  final List<BotUserModel> users;

  /// Коллбек обновления списка ответственных.
  final Function(List<String>) onUpdate;

  /// Коллбек добавления ответственного.
  final VoidCallback onAdd;

  /// Создаёт карточку этапа закупки.
  const ProcurementStageCard({
    super.key,
    required this.title,
    required this.description,
    required this.stage,
    required this.icon,
    required this.selectedIds,
    required this.users,
    required this.onUpdate,
    required this.onAdd,
  });

  String _formatShortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];

    final surname = parts[0];
    final initials =
        parts.skip(1).map((p) => p.isNotEmpty ? '${p[0]}.' : '').join('');
    return '$surname $initials';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                tooltip: 'Изменить список',
              ),
            ],
          ),
          if (selectedIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: selectedIds.map((id) {
                final user = users.firstWhere(
                  (u) => u.id == id,
                  orElse: () => BotUserModel(
                      id: id, telegramChatId: 0, fullName: 'Неизвестный'),
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatShortName(user.fullName),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        final newIds = List<String>.from(selectedIds)
                          ..remove(id);
                        onUpdate(newIds);
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
