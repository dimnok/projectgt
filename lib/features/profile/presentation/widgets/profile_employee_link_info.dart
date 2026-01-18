import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_edit_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Виджет, отображающий информацию о привязанном сотруднике.
///
/// Показывает:
/// - ФИО сотрудника
/// - Должность
/// - Кнопку для разрыва связи (если [showUnlinkButton] = true)
/// - Кнопку редактирования связи (если [showEditButton] = true)
class ProfileLinkedEmployeeInfo extends ConsumerWidget {
  /// ID привязанного сотрудника.
  final String employeeId;

  /// Показывать ли кнопку "Отвязать".
  final bool showUnlinkButton;

  /// Показывать ли кнопку "Изменить".
  final bool showEditButton;

  /// Компактный режим отображения.
  final bool compact;

  /// Показывать ли контейнер (фон и рамку).
  final bool showContainer;

  /// Показывать ли заголовок ("Привязанный сотрудник").
  final bool showHeader;

  /// Коллбэк при нажатии "Отвязать".
  final VoidCallback? onUnlink;

  /// Создаёт виджет информации о привязанном сотруднике.
  const ProfileLinkedEmployeeInfo({
    super.key,
    required this.employeeId,
    this.showUnlinkButton = false,
    this.showEditButton = false,
    this.compact = false,
    this.showContainer = true,
    this.showHeader = true,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeByIdProvider(employeeId));
    final theme = Theme.of(context);

    return employeeAsync.when(
      data: (employee) {
        if (employee == null) {
          return Text(
            'Сотрудник не найден',
            style: TextStyle(color: theme.colorScheme.error),
          );
        }

        if (compact) {
          return _buildCompactView(context, employee);
        }

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle_fill_badge_checkmark,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Привязанный сотрудник',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (showEditButton)
                    IconButton(
                      icon: const Icon(CupertinoIcons.pencil, size: 18),
                      onPressed: () => _showLinkEditModal(context, employee),
                      tooltip: 'Изменить привязку',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              employee.fullName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (employee.position != null)
              Text(
                employee.position!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            if (showUnlinkButton) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onUnlink,
                icon: const Icon(CupertinoIcons.link_circle_fill, size: 16),
                label: const Text('Отвязать'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        );

        if (!showContainer) {
          return content;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: content,
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CupertinoActivityIndicator(radius: 8),
      ),
      error: (e, _) => Text('Ошибка загрузки: $e'),
    );
  }

  Widget _buildCompactView(BuildContext context, Employee employee) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.link,
            size: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              employee.fullName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkEditModal(BuildContext context, Employee currentEmployee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MobileBottomSheetContent(
        title: 'Изменить привязку',
        child: Consumer(
          builder: (context, ref, _) {
            return ProfileEmployeeLinkEditField(
              initialEmployeeId: currentEmployee.id,
              onChanged: (newEmployeeId) async {
                if (newEmployeeId != null) {
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
