import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_estimate_positions_table_panel.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_addendum_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_with_addenda_export_flow.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/screens/import_estimate_form_modal.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Раздел смет на карточке договора: таблица позиций в стиле модуля «Подрядчики».
///
/// Заголовок экрана на десктопе — в [ContractDetailsPanel]; импорт, доп. соглашение
/// и «Скачать смету» — в [ContractsQuickActionsSidebar] при широкой вёрстке; на узком экране
/// эти кнопки остаются в секции. При [stretchTableVertically] без обёртки
/// [ContractAtmosphereCard] — фон и рамку даёт контейнер встроенной детали.
class ContractEstimatesSection extends ConsumerWidget {
  /// Заголовок раздела смет над карточкой (совпадает с подписью в toolbar детали).
  static const String embeddedScreenTitle = 'Сметы по договору';

  /// Договор, к которому относятся сметы.
  final Contract contract;

  /// Таблица занимает оставшуюся высоту родителя (конечные ограничения по высоте).
  final bool stretchTableVertically;

  /// Создаёт секцию таблицы смет по договору [contract].
  const ContractEstimatesSection({
    super.key,
    required this.contract,
    this.stretchTableVertically = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktopLayout = ResponsiveUtils.isDesktop(context);

    final importRow = !isDesktopLayout
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  PermissionGuard(
                    module: 'estimates',
                    permission: 'import',
                    child: GTSecondaryButton(
                      text: 'Импорт',
                      onPressed: () => ImportEstimateFormModal.show(
                        context,
                        ref,
                        prefilledContractId: contract.id,
                        prefilledObjectId: contract.objectId,
                        onSuccess: () {
                          ref.invalidate(
                            contractEstimateFilesProvider(contract.id),
                          );
                          ref.invalidate(
                            contractEstimatesProvider(contract.id),
                          );
                          ref.invalidate(estimateGroupsProvider);
                        },
                      ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'estimates',
                    permission: 'import',
                    child: GTSecondaryButton(
                      text: 'Доп. соглашение',
                      onPressed: () => openContractEstimateAddendumFlow(
                        context: context,
                        ref: ref,
                        contract: contract,
                      ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'estimates',
                    permission: 'read',
                    child: GTSecondaryButton(
                      text: 'Скачать смету',
                      onPressed: () =>
                          openContractEstimateWithAddendaExportFlow(
                        context: context,
                        ref: ref,
                        contract: contract,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;

    final tablePanel = ContractEstimatePositionsTablePanel(
      contract: contract,
      fillAvailableHeight: stretchTableVertically,
    );

    final body = stretchTableVertically
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (importRow != null) importRow,
              Expanded(child: tablePanel),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (importRow != null) importRow,
              tablePanel,
            ],
          );

    final guarded = PermissionGuard(
      module: 'estimates',
      permission: 'read',
      child: body,
    );

    // Во встроенном полноэкранном режиме фон и рамка уже у области деталей — без второй карточки.
    if (stretchTableVertically) {
      return guarded;
    }

    return ContractAtmosphereCard(child: guarded);
  }
}
