import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_excel_download_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_form_dialog_flow.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_row_card.dart';

/// Раздел «Акты»: единый список актов договора (`contract_acts`).
class ContractActsSection extends ConsumerStatefulWidget {
  /// Договор.
  final Contract contract;

  /// Показывать заголовок секции.
  final bool showSectionHeader;

  /// Создаёт виджет секции актов.
  const ContractActsSection({
    super.key,
    required this.contract,
    this.showSectionHeader = true,
  });

  @override
  ConsumerState<ContractActsSection> createState() =>
      _ContractActsSectionState();
}

class _ContractActsSectionState extends ConsumerState<ContractActsSection> {
  Future<void> _handleEdit(BuildContext context, ContractAct act) async {
    if (!act.canEditFull) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await openContractActEditDialog(
        context: context,
        ref: ref,
        contract: widget.contract,
        act: act,
      );
    });
  }

  Future<void> _handleDelete(BuildContext context, ContractAct act) async {
    if (!act.canDelete) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final titleText = act.title.trim().isNotEmpty
          ? act.title.trim()
          : 'Акт № ${act.number}';
      final confirmed = await GTConfirmationDialog.show(
        context: context,
        title: act.isKs2 ? 'Удаление акта КС-2' : 'Удаление акта',
        message: act.isKs2
            ? 'Акт будет удалён без возможности восстановления. Продолжить?'
            : 'Акт будет удалён из реестра без возможности восстановления. Продолжить?',
        emphasisText: titleText,
        detail: '№ ${act.number}',
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        type: GTConfirmationType.danger,
      );

      if (confirmed == true) {
        try {
          final delete = ref.read(deleteContractActUseCaseProvider);
          await delete(
            id: act.id,
            companyId: act.companyId,
            contractId: act.contractId,
          );
          if (!context.mounted) return;
          ref.invalidate(contractActsProvider(widget.contract.id));
          AppSnackBar.show(
            context: context,
            message: 'Акт удалён',
            kind: AppSnackBarKind.success,
          );
        } catch (e) {
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Ошибка при удалении: $e',
            kind: AppSnackBarKind.error,
          );
        }
      }
    });
  }

  Widget _buildRow(BuildContext context, ContractAct act) {
    return ContractActRowCard(
      key: ValueKey('act-${act.id}'),
      act: act,
      onEdit: act.canEditFull ? () => _handleEdit(context, act) : null,
      onDelete: act.canDelete ? () => _handleDelete(context, act) : null,
      onDownload: act.isKs2 && act.hasExcel
          ? () => downloadContractActExcelForUser(
                context: context,
                ref: ref,
                act: act,
              )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractId = widget.contract.id;
    final actsAsync = ref.watch(contractActsProvider(contractId));

    final Widget? header = widget.showSectionHeader
        ? const Align(
            alignment: Alignment.centerLeft,
            child: GTSectionTitle(title: 'Акты'),
          )
        : null;

    final body = actsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Не удалось загрузить акты: $e',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            GTSecondaryButton(
              text: 'Повторить',
              onPressed: () {
                ref.invalidate(contractActsProvider(contractId));
              },
            ),
          ],
        ),
      ),
      data: (acts) {
        if (acts.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: acts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) => _buildRow(context, acts[index]),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          header,
          const SizedBox(height: 20),
        ],
        body,
      ],
    );
  }
}
