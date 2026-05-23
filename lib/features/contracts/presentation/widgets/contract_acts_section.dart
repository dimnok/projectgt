import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_ks2_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_dialog_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_ks2_act_download_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_ks2_act_row_mapper.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_row_card.dart';

/// Раздел «Акты»: единый список реестра и актов КС-2 по договору.
///
/// Строки — [ContractActRowCard] (как у реестра). Редактирование и удаление
/// реестра — по строке; удаление черновика КС-2 — только для [Ks2Status.draft].
class ContractActsSection extends ConsumerStatefulWidget {
  /// Договор.
  final Contract contract;

  /// Показывать заголовок секции (в полной карточке — да; во вкладке — по желанию).
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

class _ActListEntry {
  _ActListEntry.registry(this.act)
      : ks2Act = null,
        sortDate = act.actDate;

  _ActListEntry.ks2(Ks2Act ks2)
      : act = ks2ActToRegistryRowModel(ks2),
        ks2Act = ks2,
        sortDate = ks2.date;

  final ContractAct act;
  final Ks2Act? ks2Act;
  final DateTime sortDate;
}

class _ContractActsSectionState extends ConsumerState<ContractActsSection> {
  Future<void> _handleEdit(BuildContext context, ContractAct act) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await openContractActEditDialog(
        context: context,
        contract: widget.contract,
        act: act,
      );
    });
  }

  Future<void> _handleRegistryDelete(
    BuildContext context,
    ContractAct act,
  ) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final titleText = act.title.trim().isNotEmpty
          ? act.title.trim()
          : 'Акт № ${act.number}';
      final confirmed = await GTConfirmationDialog.show(
        context: context,
        title: 'Удаление акта',
        message:
            'Акт будет удалён из реестра без возможности восстановления. Продолжить?',
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

  Future<void> _handleKs2Delete(BuildContext context, Ks2Act act) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final confirmed = await GTConfirmationDialog.show(
        context: context,
        title: 'Удаление акта КС-2',
        message: act.vorId != null
            ? 'Акт сформирован по ВОР. Записи журнала работ не привязаны к этому акту напрямую.'
            : 'Работы, привязанные к акту через журнал, будут снова доступны для включения в новый акт.',
        emphasisText: 'КС-2 № ${act.number}',
        detail: formatRuDate(act.date),
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        type: GTConfirmationType.danger,
      );

      if (confirmed == true) {
        try {
          await ref
              .read(contractKs2ActsProvider(act.contractId).notifier)
              .deleteAct(act.id);
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Акт КС-2 удалён',
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

  List<_ActListEntry> _mergeEntries(
    List<ContractAct> registry,
    List<Ks2Act> ks2,
  ) {
    final entries = <_ActListEntry>[
      ...registry.map(_ActListEntry.registry),
      ...ks2.map(_ActListEntry.ks2),
    ];
    entries.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return entries;
  }

  Widget _buildRow(BuildContext context, _ActListEntry entry) {
    final theme = Theme.of(context);
    final ks2 = entry.ks2Act;
    if (ks2 != null) {
      return ContractActRowCard(
        key: ValueKey('ks2-${ks2.id}'),
        act: entry.act,
        workflowStatusLabel: ks2ActWorkflowStatusLabel(ks2.status),
        workflowStatusColor: ks2ActWorkflowStatusColor(theme, ks2.status),
        onDownload: ks2.excelPath != null && ks2.excelPath!.isNotEmpty
            ? () => downloadContractKs2ActExcelForUser(
                  context: context,
                  ref: ref,
                  act: ks2,
                )
            : null,
        onDelete: ks2.status == Ks2Status.draft
            ? () => _handleKs2Delete(context, ks2)
            : null,
      );
    }
    final act = entry.act;
    return ContractActRowCard(
      key: ValueKey('registry-${act.id}'),
      act: act,
      onEdit: () => _handleEdit(context, act),
      onDelete: () => _handleRegistryDelete(context, act),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractId = widget.contract.id;
    final registryAsync = ref.watch(contractActsProvider(contractId));
    final ks2Async = ref.watch(contractKs2ActsProvider(contractId));

    final Widget? header = widget.showSectionHeader
        ? const Align(
            alignment: Alignment.centerLeft,
            child: GTSectionTitle(title: 'Акты'),
          )
        : null;

    final body = _buildCombinedBody(
      context,
      theme,
      registryAsync,
      ks2Async,
      contractId,
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

  Widget _buildCombinedBody(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<ContractAct>> registryAsync,
    AsyncValue<List<Ks2Act>> ks2Async,
    String contractId,
  ) {
    final registryLoading = registryAsync.isLoading;
    final ks2Loading = ks2Async.isLoading;
    if (registryLoading && ks2Loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final registryError = registryAsync.hasError;
    final ks2Error = ks2Async.hasError;
    if (registryError &&
        ks2Error &&
        !registryAsync.hasValue &&
        !ks2Async.hasValue) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Не удалось загрузить акты: ${registryAsync.error}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            GTSecondaryButton(
              text: 'Повторить',
              onPressed: () {
                ref.invalidate(contractActsProvider(contractId));
                ref.invalidate(contractKs2ActsProvider(contractId));
              },
            ),
          ],
        ),
      );
    }

    final registry = registryAsync.valueOrNull ?? [];
    final ks2 = ks2Async.valueOrNull ?? [];
    final entries = _mergeEntries(registry, ks2);

    if (entries.isEmpty) {
      if (registryLoading || ks2Loading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _buildRow(context, entries[index]),
    );
  }
}
