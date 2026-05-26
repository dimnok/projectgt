import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_excel_download_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_excel_persist.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_ui_labels.dart';
import 'package:projectgt/features/ks2/presentation/services/ks2_form_header_export_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Параметры шапки акта для генерации Excel (из формы КС-2).
class ContractActKs2HeaderExportInput {
  /// Создаёт DTO.
  const ContractActKs2HeaderExportInput({
    this.actNumber,
    this.actDocDate,
    this.reportingPeriodFrom,
    this.reportingPeriodTo,
    this.addenda = const [],
    this.vorId,
  });

  /// Номер акта.
  final String? actNumber;

  /// Дата составления.
  final DateTime? actDocDate;

  /// Начало отчётного периода.
  final DateTime? reportingPeriodFrom;

  /// Конец отчётного периода.
  final DateTime? reportingPeriodTo;

  /// Доп. соглашения для шапки Excel.
  final List<Ks2HeaderAddendumInput> addenda;

  /// ВОР (для черновика до сохранения акта).
  final String? vorId;
}

/// Вкладка «Статус»: согласование, оплата и документы акта КС-2.
class ContractActKs2StatusDocumentsSection extends ConsumerStatefulWidget {
  /// Создаёт секцию.
  const ContractActKs2StatusDocumentsSection({
    super.key,
    required this.contract,
    this.act,
    this.collectHeaderExportInput,
  });

  /// Договор.
  final Contract contract;

  /// Сохранённый акт; `null` — режим создания (секция недоступна).
  final ContractAct? act;

  /// Текущие поля шапки из формы (номер, даты, доп. соглашения).
  final ContractActKs2HeaderExportInput Function()? collectHeaderExportInput;

  @override
  ConsumerState<ContractActKs2StatusDocumentsSection> createState() =>
      ContractActKs2StatusDocumentsSectionState();
}

/// Состояние вкладки «Статус» (сохранение статусов с нижней кнопки формы).
class ContractActKs2StatusDocumentsSectionState
    extends ConsumerState<ContractActKs2StatusDocumentsSection> {
  ContractActWorkflowStatus? _workflow;
  ContractActPaymentStatus? _payment;
  bool _savingStatus = false;
  bool _generatingExcel = false;

  @override
  void initState() {
    super.initState();
    _applyAct(widget.act);
  }

  @override
  void didUpdateWidget(covariant ContractActKs2StatusDocumentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.act?.id != widget.act?.id ||
        oldWidget.act?.workflowStatus != widget.act?.workflowStatus ||
        oldWidget.act?.paymentStatus != widget.act?.paymentStatus ||
        oldWidget.act?.excelPath != widget.act?.excelPath) {
      _applyAct(widget.act);
    }
  }

  void _applyAct(ContractAct? act) {
    if (act == null) return;
    _workflow = act.workflowStatus;
    _payment = act.paymentStatus;
  }

  ContractAct? _resolveAct(List<ContractAct> acts) {
    final id = widget.act?.id;
    if (id == null) return null;
    return acts.where((a) => a.id == id).firstOrNull ?? widget.act;
  }

  /// Текущие выбранные статусы (для сохранения удержаний без перезаписи).
  ({ContractActWorkflowStatus workflow, ContractActPaymentStatus payment})?
      get pendingStatuses {
    if (_workflow == null || _payment == null) return null;
    return (workflow: _workflow!, payment: _payment!);
  }

  ContractAct? _currentActFromProvider() {
    final acts = ref.read(contractActsProvider(widget.contract.id)).valueOrNull;
    if (acts == null) return widget.act;
    return _resolveAct(acts);
  }

  /// Сохраняет статусы, если они отличаются от сохранённых в акте.
  ///
  /// Возвращает `true`, если запись в БД выполнена.
  Future<bool> saveStatusesIfDirty() async {
    if (_workflow == null || _payment == null) return false;
    final act = _currentActFromProvider();
    if (act == null) return false;
    if (_workflow == act.workflowStatus && _payment == act.paymentStatus) {
      return false;
    }
    await _saveStatuses(act);
    return true;
  }

  Future<void> _saveStatuses(ContractAct act) async {
    if (_workflow == null || _payment == null) return;

    setState(() => _savingStatus = true);
    try {
      final repository = ref.read(contractActRepositoryProvider);
      await repository.updateStatuses(
        id: act.id,
        companyId: act.companyId,
        contractId: act.contractId,
        workflowStatus: _workflow!,
        paymentStatus: _payment!,
      );

      ref.invalidate(contractActsProvider(widget.contract.id));

      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Статусы акта сохранены',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить статусы: $e',
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  Future<void> _generateExcel(ContractAct act) async {
    final header = widget.collectHeaderExportInput?.call();
    final vorId = act.vorId?.trim().isNotEmpty == true
        ? act.vorId!.trim()
        : header?.vorId?.trim();

    if (vorId == null || vorId.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'У акта нет привязанной ВОР — Excel сформировать нельзя',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    setState(() => _generatingExcel = true);
    try {
      await persistContractActExcel(
        ref: ref,
        companyId: act.companyId,
        contractId: act.contractId,
        actId: act.id,
        vorId: vorId,
        actNumber: header?.actNumber ?? act.number,
        actDocDate: header?.actDocDate ?? act.actDate,
        reportingPeriodFrom: header?.reportingPeriodFrom ?? act.periodFrom,
        reportingPeriodTo: header?.reportingPeriodTo ?? act.periodTo,
        addenda: header?.addenda ?? const [],
      );

      ref.invalidate(contractActsProvider(widget.contract.id));

      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: act.hasExcel
            ? 'Файл КС-2 пересобран и сохранён в акте'
            : 'Файл КС-2 сформирован и сохранён в акте',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сформировать Excel: $e',
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _generatingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.act == null) {
      return const _PlaceholderCard(
        icon: CupertinoIcons.flag,
        message:
            'Статусы и документы будут доступны после сохранения акта на вкладке «Позиции».',
      );
    }

    final actsAsync = ref.watch(contractActsProvider(widget.contract.id));

    return actsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _PlaceholderCard(
        icon: CupertinoIcons.exclamationmark_triangle,
        message: 'Не удалось загрузить акт: $e',
      ),
      data: (acts) {
        final act = _resolveAct(acts);
        if (act == null) {
          return const _PlaceholderCard(
            icon: CupertinoIcons.doc_text,
            message: 'Акт не найден в списке',
          );
        }

        if (_workflow == null || _payment == null) {
          _applyAct(act);
        }

        final workflow = _workflow!;
        final payment = _payment!;
        final statusDirty = workflow != act.workflowStatus ||
            payment != act.paymentStatus;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'СТАТУСЫ',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatusChip(
                            label: contractActWorkflowStatusLabel(workflow),
                            color: contractActWorkflowStatusColor(
                              theme,
                              workflow,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatusChip(
                            label: contractActPaymentStatusLabel(payment),
                            color: contractActPaymentStatusColor(
                              theme,
                              payment,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GTEnumDropdown<ContractActWorkflowStatus>(
                      values: ContractActWorkflowStatus.values,
                      selectedValue: workflow,
                      allowClear: false,
                      labelText: 'Статус согласования',
                      hintText: 'Выберите статус',
                      enumToString: contractActWorkflowStatusLabel,
                      onChanged: (v) {
                        if (v != null) setState(() => _workflow = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    GTEnumDropdown<ContractActPaymentStatus>(
                      values: ContractActPaymentStatus.values,
                      selectedValue: payment,
                      allowClear: false,
                      labelText: 'Статус оплаты',
                      hintText: 'Выберите статус',
                      enumToString: contractActPaymentStatusLabel,
                      onChanged: (v) {
                        if (v != null) setState(() => _payment = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    PermissionGuard(
                      module: 'contracts',
                      permission: 'update',
                      child: GTPrimaryButton(
                        text: 'Сохранить статусы',
                        isLoading: _savingStatus,
                        onPressed: _savingStatus || !statusDirty
                            ? null
                            : () => _saveStatuses(act),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'ДОКУМЕНТЫ',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DocumentTile(
                      act: act,
                      onDownload: act.hasExcel
                          ? () => downloadContractActExcelForUser(
                                context: context,
                                ref: ref,
                                act: act,
                              )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    PermissionGuard(
                      module: 'contracts',
                      permission: 'update',
                      child: Row(
                        children: [
                          Expanded(
                            child: GTSecondaryButton(
                              text: act.hasExcel
                                  ? 'Пересобрать Excel'
                                  : 'Сформировать Excel',
                              icon: CupertinoIcons.doc_text,
                              isLoading: _generatingExcel,
                              onPressed: _generatingExcel
                                  ? null
                                  : () => _generateExcel(act),
                            ),
                          ),
                          if (act.hasExcel) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: GTSecondaryButton(
                                text: 'Скачать',
                                icon: CupertinoIcons.arrow_down_doc,
                                onPressed: () =>
                                    downloadContractActExcelForUser(
                                      context: context,
                                      ref: ref,
                                      act: act,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Excel сохраняется в карточке акта. После правки позиций на вкладке «Позиции» файл нужно пересобрать.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.45 : 0.7,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.85,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
                color: scheme.primary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.act,
    this.onDownload,
  });

  final ContractAct act;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasFile = act.hasExcel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile
              ? scheme.primary.withValues(alpha: 0.25)
              : scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF217346).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.doc_text_fill,
                  size: 20,
                  color: Color(0xFF217346),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile
                        ? 'КС-2_№${act.number}_${formatRuDate(act.actDate)}.xlsx'
                        : 'Файл Excel не сформирован',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile
                        ? 'Сохранён в акте'
                        : 'Нажмите «Сформировать Excel»',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (onDownload != null)
              IconButton(
                tooltip: 'Скачать',
                onPressed: onDownload,
                icon: Icon(
                  CupertinoIcons.arrow_down_circle,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
