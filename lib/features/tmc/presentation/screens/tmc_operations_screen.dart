import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Журнал операций ТМЦ.
class TmcOperationsScreen extends ConsumerWidget {
  /// Создаёт экран.
  const TmcOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tmcOperationsProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: TmcUiLabels.operationsJournal,
        leading: BackButton(onPressed: () => context.go(AppRoutes.tmc)),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все'),
                  selected: state.operationType == null,
                  onSelected: (_) => ref
                      .read(tmcOperationsProvider.notifier)
                      .setOperationType(null),
                ),
                ...const [
                  TmcOperationType.receipt,
                  TmcOperationType.issue,
                  TmcOperationType.returnFromEmployee,
                  TmcOperationType.transferToObject,
                  TmcOperationType.moveBetweenWarehouses,
                  TmcOperationType.sendToRepair,
                  TmcOperationType.returnFromRepair,
                  TmcOperationType.writeOff,
                  TmcOperationType.changeCondition,
                  TmcOperationType.correction,
                ].map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(TmcUiLabels.operationType(t)),
                          selected: state.operationType == t,
                          onSelected: (_) => ref
                              .read(tmcOperationsProvider.notifier)
                              .setOperationType(t),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TmcOperationsListState state) {
    if (state.isLoading && state.operations.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.operations.isEmpty) {
      return Center(child: Text(state.error!));
    }
    if (state.operations.isEmpty) {
      return const Center(child: Text(TmcUiLabels.emptyOperations));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.operations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final op = state.operations[index];
        final lines = op.items
            .map((l) => l.itemName ?? l.inventoryNumber ?? l.itemId)
            .join(', ');
        return ListTile(
          title: Text(TmcUiLabels.operationType(op.operationType)),
          subtitle: Text(
            '${formatRuDateTime(op.operatedAt)} · $lines',
          ),
        );
      },
    );
  }
}
