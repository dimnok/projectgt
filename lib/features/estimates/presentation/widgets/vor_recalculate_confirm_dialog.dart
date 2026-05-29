import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../domain/entities/vor.dart';
import '../../../../domain/entities/vor_recalc_preview.dart';
import '../providers/estimate_providers.dart';

/// Диалог подтверждения пересчёта черновика ВОР с перечнем изменений.
class VorRecalculateConfirmDialog extends ConsumerStatefulWidget {
  /// Ведомость для пересчёта.
  final Vor vor;

  /// Действия над ВОР.
  final VorActions actions;

  /// Создаёт [VorRecalculateConfirmDialog].
  const VorRecalculateConfirmDialog({
    super.key,
    required this.vor,
    required this.actions,
  });

  /// Открывает диалог; возвращает `true`, если пересчёт выполнен.
  static Future<bool?> show({
    required BuildContext context,
    required Vor vor,
    required VorActions actions,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Пересчёт ВОР',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: DesktopDialogContent(
              title: 'Пересчёт ведомости',
              width: 880,
              child: VorRecalculateConfirmDialog(vor: vor, actions: actions),
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<VorRecalculateConfirmDialog> createState() =>
      _VorRecalculateConfirmDialogState();
}

class _VorRecalculateConfirmDialogState
    extends ConsumerState<VorRecalculateConfirmDialog> {
  VorRecalcPreview? _preview;
  Object? _loadError;
  bool _isRecalculating = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final repository = ref.read(estimateRepositoryProvider);
      final preview = await repository.getVorRecalcChanges(widget.vor.id);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _onConfirm() async {
    setState(() => _isRecalculating = true);
    try {
      await widget.actions.recalculateVor(widget.vor.contractId, widget.vor.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRecalculating = false);
      AppSnackBar.show(
        context: context,
        message: 'Не удалось пересчитать ведомость',
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VorSummaryCard(vor: widget.vor),
        const SizedBox(height: 16),
        if (_loadError != null)
          const _ErrorBlock(message: 'Не удалось загрузить список изменений')
        else if (preview == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (!preview.hasChanges)
          Text(
            'Изменений в работах за период не обнаружено.',
            style: theme.textTheme.bodyMedium,
          )
        else
          _ChangesList(preview: preview),
        const SizedBox(height: 12),
        Text(
          'Обновятся только позиции, по которым в журнале работ изменился объём '
          'или появились новые работы. Уже записанная раскладка «по смете / превышение» '
          'для остальных позиций сохранится. '
          'Если объём не менялся, а отличается только единица или написание строки, '
          'пересчёт синхронизирует ведомость с журналом без изменения количества.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTTextButton(
              text: 'Отмена',
              onPressed: _isRecalculating
                  ? null
                  : () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            GTPrimaryButton(
              text: _isRecalculating ? 'Пересчёт…' : 'Пересчитать',
              onPressed:
                  _isRecalculating || preview == null || _loadError != null
                  ? null
                  : _onConfirm,
            ),
          ],
        ),
      ],
    );
  }
}

class _VorSummaryCard extends StatelessWidget {
  final Vor vor;

  const _VorSummaryCard({required this.vor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Номер', value: vor.number),
          const Divider(height: 16),
          _SummaryRow(
            label: 'Период',
            value:
                '${formatRuDate(vor.startDate)} — ${formatRuDate(vor.endDate)}',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangesList extends StatelessWidget {
  final VorRecalcPreview preview;

  const _ChangesList({required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = preview.groupedDisplayEntries;
    final sections = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Изменения по работам за период',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final section = sections[index];
                final entries = grouped[section]!;
                return _SectionBlock(section: section, entries: entries);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String section;
  final List<VorRecalcListEntry> entries;

  const _SectionBlock({required this.section, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        ...entries.map(
          (entry) => switch (entry) {
            VorRecalcMetadataSyncEntry() => _MetadataSyncRow(entry: entry),
            VorRecalcVolumeEntry(:final change) => _VolumeChangeRow(
              change: change,
            ),
          },
        ),
      ],
    );
  }
}

class _MetadataSyncRow extends StatelessWidget {
  final VorRecalcMetadataSyncEntry entry;

  const _MetadataSyncRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = entry.journalUnit.isNotEmpty
        ? entry.journalUnit
        : entry.vorUnit;
    final unitSuffix = unitLabel.isNotEmpty ? ' $unitLabel' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Tooltip(
        message: entry.tooltipMessage,
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 250),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: entry.rowLabel,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text:
                          ' · ${formatQuantity(entry.quantity)}$unitSuffix · ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: 'требуется синхронизация с журналом',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeChangeRow extends StatelessWidget {
  final VorRecalcChange change;

  const _VolumeChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _changeMeta(change.changeType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meta.icon, size: 14, color: meta.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.rowLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildDetailText(change),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: meta.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildDetailText(VorRecalcChange change) {
    final unitSuffix = change.unit.isNotEmpty ? ' ${change.unit}' : '';
    switch (change.changeType) {
      case VorRecalcChangeType.added:
        return '${_changeMeta(change.changeType).label}: '
            '${formatQuantity(change.newQuantity ?? 0)}$unitSuffix';
      case VorRecalcChangeType.removed:
        return '${_changeMeta(change.changeType).label}: '
            'было ${formatQuantity(change.oldQuantity ?? 0)}$unitSuffix';
      case VorRecalcChangeType.modified:
        return '${_changeMeta(change.changeType).label}: '
            '${formatQuantity(change.oldQuantity ?? 0)} → '
            '${formatQuantity(change.newQuantity ?? 0)}$unitSuffix';
    }
  }
}

class _ChangeMeta {
  final String label;
  final IconData icon;
  final Color color;

  const _ChangeMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

_ChangeMeta _changeMeta(VorRecalcChangeType type) {
  switch (type) {
    case VorRecalcChangeType.added:
      return const _ChangeMeta(
        label: 'Добавлено',
        icon: CupertinoIcons.plus_circle_fill,
        color: Colors.green,
      );
    case VorRecalcChangeType.removed:
      return const _ChangeMeta(
        label: 'Удалено',
        icon: CupertinoIcons.minus_circle_fill,
        color: Colors.red,
      );
    case VorRecalcChangeType.modified:
      return const _ChangeMeta(
        label: 'Изменён объём',
        icon: CupertinoIcons.arrow_right_arrow_left,
        color: Colors.orange,
      );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;

  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SelectableText.rich(
        TextSpan(
          text: message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
