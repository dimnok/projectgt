import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_assignment.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';

/// Вкладка «ТМЦ» в карточке сотрудника.
///
/// Показывает активные выдачи из модуля ТМЦ. Данные загружаются
/// при первом выборе вкладки ([isActive] = true).
class EmployeeTmcSection extends ConsumerStatefulWidget {
  /// Сотрудник, чьи выдачи отображаются.
  final Employee employee;

  /// `true`, когда вкладка «ТМЦ» выбрана (для ленивой загрузки).
  final bool isActive;

  /// Создаёт вкладку ТМЦ сотрудника.
  const EmployeeTmcSection({
    super.key,
    required this.employee,
    this.isActive = true,
  });

  @override
  ConsumerState<EmployeeTmcSection> createState() => _EmployeeTmcSectionState();
}

class _EmployeeTmcSectionState extends ConsumerState<EmployeeTmcSection> {
  bool _wasActivated = false;

  @override
  void initState() {
    super.initState();
    _wasActivated = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant EmployeeTmcSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_wasActivated) {
      _wasActivated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_wasActivated) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canReadTmc = ref.watch(permissionServiceProvider).can('tmc', 'read');
    final assignmentsAsync = ref.watch(
      tmcAssignmentsProvider(widget.employee.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Выданное имущество',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        assignmentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SelectableText.rich(
              TextSpan(
                text: 'Не удалось загрузить ТМЦ.\n$error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          ),
          data: (assignments) {
            final active = assignments.where((a) => a.isActive).toList();
            if (active.isEmpty) {
              return _EmptyTmcList(
                theme: theme,
                canReadTmc: canReadTmc,
              );
            }
            return Column(
              children: [
                for (var i = 0; i < active.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _AssignmentTile(
                    index: i + 1,
                    assignment: active[i],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.index,
    required this.assignment,
  });

  final int index;
  final TmcAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = assignment.itemName?.trim().isNotEmpty == true
        ? assignment.itemName!
        : 'ТМЦ';
    final numberedTitle = '$index. $title';
    final subtitle = _subtitle(assignment);
    final cost = assignment.unitPrice == null
        ? null
        : formatCurrency(assignment.unitPrice! * assignment.quantity);

    return Semantics(
      label: [numberedTitle, subtitle, if (cost != null) cost].join('. '),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    numberedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (cost != null) ...[
              const SizedBox(width: 12),
              Text(
                cost,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(TmcAssignment assignment) {
    final parts = <String>[];
    final inventory = assignment.inventoryNumber?.trim();
    if (inventory != null && inventory.isNotEmpty) {
      parts.add('инв. № $inventory');
    }
    if (assignment.quantity != 1) {
      parts.add(formatQuantity(assignment.quantity));
    }
    parts.add('выдано ${formatRuDate(assignment.issuedAt)}');
    final objectName = assignment.objectName?.trim();
    if (objectName != null && objectName.isNotEmpty) {
      parts.add(objectName);
    }
    return parts.join(' · ');
  }
}

class _EmptyTmcList extends StatelessWidget {
  const _EmptyTmcList({
    required this.theme,
    required this.canReadTmc,
  });

  final ThemeData theme;
  final bool canReadTmc;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        canReadTmc
            ? 'Нет выданного имущества'
            : 'Нет права просмотра ТМЦ',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
