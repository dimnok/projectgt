import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/domain/entities/work_item.dart';
import 'package:projectgt/features/works/domain/entities/work_hour.dart';
import 'package:projectgt/features/works/presentation/utils/works_strings.dart';

/// Виджет блока валидации и закрытия смены.
class WorkValidationBlock extends StatelessWidget {
  /// Модель смены.
  final Work work;

  /// Список работ.
  final List<WorkItem>? items;

  /// Список часов сотрудников.
  final List<WorkHour>? hours;

  /// Можно ли редактировать смену.
  final bool canModify;

  /// Колбэк при нажатии на кнопку закрытия смены.
  final VoidCallback onCloseWork;

  /// Колбэк при нажатии на кнопку добавления фото.
  final VoidCallback onAddPhoto;

  /// Конструктор блока валидации.
  const WorkValidationBlock({
    super.key,
    required this.work,
    required this.items,
    required this.hours,
    required this.canModify,
    required this.onCloseWork,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Если списки еще грузятся, мы не можем проверить валидацию
    if (items == null || hours == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CupertinoActivityIndicator()),
        ),
      );
    }

    final (canClose, message) = _canCloseWork(work, items!, hours!);

    if (canClose) {
      if (canModify) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: GTPrimaryButton(
              onPressed: onCloseWork,
              icon: Icons.lock_outline,
              text: WorksStrings.closeWorkBtn,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    WorksStrings.validationTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCheckItem(context, WorksStrings.checkAddItems, items!.isNotEmpty),
            _buildCheckItem(context, WorksStrings.checkAddEmployees, hours!.isNotEmpty),
            _buildCheckItem(
              context,
              WorksStrings.checkFillQuantities,
              items!.isNotEmpty && !items!.any((item) => item.quantity <= 0),
            ),
            _buildCheckItem(
              context,
              WorksStrings.checkFillHours,
              hours!.isNotEmpty && !hours!.any((hour) => hour.hours <= 0),
            ),
            _buildCheckItem(
              context,
              WorksStrings.checkUploadEveningPhoto,
              work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty,
            ),
            if (work.eveningPhotoUrl == null ||
                work.eveningPhotoUrl!.isEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GTSecondaryButton(
                  onPressed: canModify ? onAddPhoto : null,
                  icon: Icons.camera_alt,
                  text: WorksStrings.addPhotoBtn,
                ),
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildCheckItem(BuildContext context, String text, bool isCompleted) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isCompleted ? Icons.check_circle : Icons.cancel,
              color: isCompleted ? Colors.green : theme.colorScheme.error,
              size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCompleted ? null : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (bool, String?) _canCloseWork(
    Work work,
    List<WorkItem> workItems,
    List<WorkHour> workHours,
  ) {
    if (work.status.toLowerCase() == 'closed') {
      return (false, WorksStrings.errorAlreadyClosed);
    }
    if (workItems.isEmpty) return (false, WorksStrings.errorNoItems);
    if (workHours.isEmpty) {
      return (false, WorksStrings.errorNoEmployees);
    }
    final invalidWorkItems =
        workItems.where((item) => item.quantity <= 0).toList();
    if (invalidWorkItems.isNotEmpty) {
      return (
        false,
        WorksStrings.errorEmptyQuantities
      );
    }
    final invalidWorkHours =
        workHours.where((hour) => hour.hours <= 0).toList();
    if (invalidWorkHours.isNotEmpty) {
      return (
        false,
        WorksStrings.errorEmptyHours
      );
    }
    if (work.eveningPhotoUrl == null || work.eveningPhotoUrl!.isEmpty) {
      return (
        false,
        WorksStrings.errorNoEveningPhoto
      );
    }
    return (true, null);
  }
}
