import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/employee_application.dart';
import 'package:projectgt/features/employees/presentation/providers/employee_applications_provider.dart';
import 'package:projectgt/features/employees/presentation/utils/employee_application_download_flow.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_application_forms.dart';

/// Блок «Заявления» в карточке сотрудника.
///
/// Формирование PDF (образцы из профиля), загрузка подписанных сканов
/// и список сохранённых заявлений с просмотром и скачиванием.
class EmployeeApplicationsSection extends ConsumerWidget {
  /// Сотрудник, для которого отображаются заявления.
  final Employee employee;

  /// Разрешено загружать сканы и удалять записи (`employees.update`).
  final bool canManage;

  /// Создаёт секцию заявлений.
  const EmployeeApplicationsSection({
    super.key,
    required this.employee,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(employeeApplicationsProvider(employee.id));
    final busyIds = ref.watch(
      employeeApplicationBusyIdsProvider(employee.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Сформировать заявление',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (canManage) ...[
          _ApplicationTypeTile(
            icon: CupertinoIcons.sun_max,
            iconColor: CupertinoColors.systemBlue,
            title: 'Отпуск',
            subtitle: 'Ежегодный оплачиваемый отпуск',
            onTap: () => showEmployeeVacationApplicationForm(
              context,
              employee: employee,
              ref: ref,
            ),
          ),
          const SizedBox(height: 8),
          _ApplicationTypeTile(
            icon: CupertinoIcons.calendar_badge_minus,
            iconColor: CupertinoColors.systemPurple,
            title: 'Отпуск без содержания',
            subtitle: 'Без сохранения заработной платы',
            onTap: () => showEmployeeUnpaidLeaveApplicationForm(
              context,
              employee: employee,
              ref: ref,
            ),
          ),
          const SizedBox(height: 8),
          _ApplicationTypeTile(
            icon: CupertinoIcons.person_crop_circle_badge_xmark,
            iconColor: CupertinoColors.systemRed,
            title: 'Увольнение',
            subtitle: 'По собственному желанию',
            onTap: () => showEmployeeResignationApplicationForm(
              context,
              employee: employee,
              ref: ref,
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Формирование и загрузка заявлений доступны при праве '
              'редактирования карточки сотрудника.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Подписанные заявления',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: CupertinoActivityIndicator(radius: 8),
              ),
          ],
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            state.errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 12),
        if (state.applications.isEmpty && !state.isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              'Подписанных заявлений пока нет.\n'
              'Сформируйте документ, распечатайте и загрузите скан.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ...state.applications.map(
          (application) => _ApplicationListTile(
            application: application,
            isBusy: busyIds.contains(application.id),
            canManage: canManage,
            onView: () => viewEmployeeApplicationScan(
              context: context,
              ref: ref,
              employeeId: employee.id,
              application: application,
            ),
            onDownload: () => downloadEmployeeApplicationScan(
              context: context,
              ref: ref,
              employeeId: employee.id,
              application: application,
            ),
            onDelete: () => _confirmDelete(context, ref, application),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EmployeeApplication application,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить заявление?',
      message:
          'Запись и подписанный скан будут удалены без возможности восстановления.',
      emphasisText: application.applicationType.title,
      detail: application.scanName,
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(employeeApplicationsProvider(employee.id).notifier)
          .deleteApplication(application);
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Заявление удалено',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Ошибка удаления: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }
}

class _ApplicationTypeTile extends StatelessWidget {
  const _ApplicationTypeTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationListTile extends StatelessWidget {
  const _ApplicationListTile({
    required this.application,
    required this.isBusy,
    required this.canManage,
    required this.onView,
    required this.onDownload,
    required this.onDelete,
  });

  final EmployeeApplication application;
  final bool isBusy;
  final bool canManage;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = _titleLabel(application);
    final uploadMeta = _uploadMeta(application);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 20,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  uploadMeta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CupertinoActivityIndicator(radius: 8),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Просмотр',
              visualDensity: VisualDensity.compact,
              onPressed: onView,
              icon: Icon(
                CupertinoIcons.eye,
                size: 20,
                color: scheme.onSurface,
              ),
            ),
            IconButton(
              tooltip: 'Скачать',
              visualDensity: VisualDensity.compact,
              onPressed: onDownload,
              icon: Icon(
                CupertinoIcons.cloud_download,
                size: 20,
                color: scheme.onSurface,
              ),
            ),
            if (canManage)
              IconButton(
                tooltip: 'Удалить',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(
                  CupertinoIcons.delete,
                  size: 20,
                  color: scheme.error,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _titleLabel(EmployeeApplication application) {
    final start = formatRuDate(application.startDate);
    if (application.applicationType == EmployeeApplicationType.resignation) {
      return '${application.applicationType.title} с $start';
    }
    final days = application.durationDays;
    final end = formatRuDate(application.endDate ?? application.startDate);
    return '${application.applicationType.title} на $days ${_daysWord(days)} '
        'с $start по $end';
  }

  String _uploadMeta(EmployeeApplication application) {
    final when = formatRuDateTime(application.createdAt);
    final who = application.createdByName;
    if (who != null && who.isNotEmpty) return '$who · $when';
    return when;
  }

  String _daysWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    return switch (mod10) {
      1 => 'день',
      2 || 3 || 4 => 'дня',
      _ => 'дней',
    };
  }
}
