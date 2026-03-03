import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/vor.dart';
import '../providers/estimate_providers.dart';
import 'vor_approve_dialog.dart';
import 'vor_card_details.dart';
import 'vor_create_dialog.dart';

/// Окно со списком ведомостей ВОР.
///
/// Отображает реестр сформированных ведомостей объемов работ по договору.
class VorListDialog extends ConsumerStatefulWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Создает экземпляр [VorListDialog].
  const VorListDialog({super.key, required this.contractId});

  /// Отображает диалог со списком ВОР с усиленным затемнением фона.
  static Future<void> show(BuildContext context, String contractId) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Ведомости объемов работ (ВОР)',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: DesktopDialogContent(
              title: 'Ведомости объемов работ (ВОР)',
              width: 1000,
              child: VorListDialog(contractId: contractId),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        return FadeTransition(
          opacity: animation,
          child: Transform.scale(
            scale: 0.95 + (0.05 * curvedValue),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<VorListDialog> createState() => _VorListDialogState();
}

class _VorListDialogState extends ConsumerState<VorListDialog> {
  /// Идентификатор текущей раскрытой карточки.
  String? _expandedVorId;

  @override
  Widget build(BuildContext context) {
    final vorsAsync = ref.watch(vorsProvider(widget.contractId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VorHeaderActions(contractId: widget.contractId),
        const SizedBox(height: 24),
        vorsAsync.when(
          data: (vorList) {
            if (vorList.isEmpty) return const _EmptyState();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vorList.length,
              itemBuilder: (context, index) {
                final vor = vorList[index];
                return _VorCard(
                  key: ValueKey(vor.id),
                  vor: vor,
                  isExpanded: _expandedVorId == vor.id,
                  onToggle: () {
                    setState(() {
                      if (_expandedVorId == vor.id) {
                        _expandedVorId = null;
                      } else {
                        _expandedVorId = vor.id;
                      }
                    });
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CupertinoActivityIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text(
                'Ошибка загрузки: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Заголовок с кнопками действий.
class _VorHeaderActions extends StatelessWidget {
  final String contractId;

  const _VorHeaderActions({required this.contractId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Список сформированных ведомостей по договору',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        GTPrimaryButton(
          icon: CupertinoIcons.add,
          text: 'Сформировать новую ВОР',
          onPressed: () => VorCreateDialog.show(context, contractId),
        ),
      ],
    );
  }
}

/// Состояние пустого списка.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Text('Ведомости еще не формировались'),
      ),
    );
  }
}

/// Вспомогательный виджет для строк последовательности в диалоге.
class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

/// Вспомогательный виджет для строк информации в диалоге.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

/// Виджет карточки ВОР с эффектом парения (Hover).
class _VorCard extends ConsumerWidget {
  final Vor vor;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _VorCard({
    super.key,
    required this.vor,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _VorCardContent(
      vor: vor,
      isExpanded: isExpanded,
      onToggle: onToggle,
    );
  }
}

/// Внутренний виджет контента карточки для управления состоянием Hover.
class _VorCardContent extends ConsumerStatefulWidget {
  final Vor vor;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _VorCardContent({
    required this.vor,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  ConsumerState<_VorCardContent> createState() => _VorCardContentState();
}

class _VorCardContentState extends ConsumerState<_VorCardContent> {
  bool _isHovered = false;
  bool _isPickingStatus = false;

  List<VorStatus> _getNextAvailableStatuses(VorStatus currentStatus) {
    switch (currentStatus) {
      case VorStatus.draft:
        return [VorStatus.pending];
      case VorStatus.pending:
        return [VorStatus.draft, VorStatus.approved];
      case VorStatus.approved:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = Vor.getStatusColor(widget.vor.status);
    final statusText = Vor.getStatusText(widget.vor.status);
    final actions = ref.watch(vorActionsProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TapRegion(
        onTapOutside: (event) {
          if (_isPickingStatus) {
            setState(() => _isPickingStatus = false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 8),
          transform: _isHovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(
                  alpha: _isHovered ? 0.08 : 0.04,
                ),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _isPickingStatus
                    ? () => setState(() => _isPickingStatus = false)
                    : widget.onToggle,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: widget.isExpanded
                        ? const BorderRadius.vertical(top: Radius.circular(12))
                        : BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(
                        alpha: _isHovered ? 0.2 : 0.08,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Акцентная полоска слева
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isHovered ? 6 : 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.doc_text_fill,
                              size: 14,
                              color: theme.colorScheme.primary.withValues(
                                alpha: _isHovered ? 1.0 : 0.7,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.vor.number,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: _isHovered
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${formatRuDate(widget.vor.startDate)} — ${formatRuDate(widget.vor.endDate)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: _isHovered ? 1.0 : 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Область статуса с возможностью выбора
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: child,
                          ),
                        ),
                        child: _isPickingStatus
                            ? Row(
                                key: const ValueKey('picking'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ..._getNextAvailableStatuses(
                                    widget.vor.status,
                                  ).map((s) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _StatusTag(
                                        status: Vor.getStatusText(s),
                                        color: Vor.getStatusColor(s),
                                        onTap: () async {
                                          if (s == VorStatus.approved) {
                                            final confirmed =
                                                await VorApproveDialog.show(
                                                  context,
                                                  widget.vor,
                                                );
                                            if (confirmed != true) return;
                                          }

                                          try {
                                            await actions.updateStatus(
                                              widget.vor.contractId,
                                              widget.vor.id,
                                              s,
                                              comment: s == VorStatus.approved
                                                  ? 'Ведомость подписана'
                                                  : 'Статус изменен пользователем',
                                            );
                                            if (!mounted) {
                                              return;
                                            }
                                            setState(
                                              () => _isPickingStatus = false,
                                            );
                                          } catch (e) {
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Ошибка смены статуса: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.xmark_circle_fill,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _isPickingStatus = false,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ],
                              )
                            : _StatusTag(
                                key: const ValueKey('current'),
                                status: statusText,
                                color: statusColor,
                                onTap: widget.vor.status == VorStatus.approved
                                    ? null
                                    : () => setState(
                                        () => _isPickingStatus = true,
                                      ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      _CardActions(vor: widget.vor, isHovered: _isHovered),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: widget.isExpanded ? 0.5 : 0,
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: VorCardDetails(vor: widget.vor),
                crossFadeState: widget.isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Тег статуса ведомости.
class _StatusTag extends StatelessWidget {
  final String status;
  final Color color;
  final VoidCallback? onTap;

  const _StatusTag({
    super.key,
    required this.status,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Блок действий в карточке.
class _CardActions extends ConsumerWidget {
  final Vor vor;
  final bool isHovered;

  const _CardActions({required this.vor, required this.isHovered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.watch(vorActionsProvider);
    final exportService = ref.watch(vorExportServiceProvider);
    final isDraft = vor.status == VorStatus.draft;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: CupertinoIcons.eye,
          tooltip: 'Просмотр',
          onPressed: () {},
        ),
        _ActionButton(
          icon: CupertinoIcons.doc,
          tooltip: 'Excel файл',
          onPressed: () => exportService.exportVorToExcel(vor.id),
        ),
        if (isDraft)
          _ActionButton(
            icon: CupertinoIcons.pencil,
            tooltip: 'Редактировать',
            onPressed: () {},
          ),
        if (isDraft)
          _ActionButton(
            icon: CupertinoIcons.trash,
            tooltip: 'Удалить',
            color: Colors.red[700],
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(CupertinoIcons.trash, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Удаление ведомости'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Вы собираетесь удалить следующую ведомость:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Номер:', value: vor.number),
                            const Divider(height: 16),
                            _InfoRow(
                              label: 'Период:',
                              value:
                                  '${formatRuDate(vor.startDate)} — ${formatRuDate(vor.endDate)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Последовательность действий:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _StepRow(
                        number: '1',
                        text:
                            'Запись будет безвозвратно удалена из базы данных',
                      ),
                      const _StepRow(
                        number: '2',
                        text:
                            'Связанный Excel-файл будет удален из облачного хранилища',
                      ),
                      const _StepRow(
                        number: '3',
                        text: 'История статусов будет очищена',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Это действие нельзя отменить. Продолжить?',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    GTTextButton(
                      text: 'Отмена',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 8),
                    GTPrimaryButton(
                      text: 'Удалить ведомость',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await actions.deleteVor(vor.contractId, vor.id);
              }
            },
          ),
      ],
    );
  }
}

/// Вспомогательный виджет для кнопок действий в карточке.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 16,
              color:
                  color ??
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
