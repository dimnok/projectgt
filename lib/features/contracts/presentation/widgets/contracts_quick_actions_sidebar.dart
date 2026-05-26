import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_detail_navigation_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_addendum_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_with_addenda_export_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_with_execution_export_flow.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_document_upload_flow.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_form_dialog_flow.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/screens/import_estimate_form_modal.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Боковая панель «Быстрые действия» на экране списка договоров (десктоп).
///
/// По [contextContract] ниже действий показывается компактное резюме открытого договора;
/// если детали не открыты — блок подсказок по работе со списком.
///
/// Часть сценариев по-прежнему заглушки ([AppSnackBar]); реализованы: импорт сметы,
/// доп. соглашение (LC/ДС), выгрузка сметы с колонками ДС, блок действий вкладки «Документы»
/// (загрузка, упорядочивание с сохранением из «Готово», примечания), сводка сумм по актам
/// на вкладке «Акты» — единая форма акта (ручной ввод или КС-2 по ВОР).
class ContractsQuickActionsSidebar extends ConsumerWidget {
  /// Горизонтальный зазор между списком и панелью — [ContractListScreenDesktopChrome.gridGutter].
  static const double preferredWidth = 295;

  /// Договор, выбранный во встроенных деталях (`null`, если таблица).
  final Contract? contextContract;

  /// Выбранный подраздел навигации встроенной карточки (для действия «Импорт сметы»).
  final ContractDetailNavigationSection sidebarDetailSection;

  /// Создаёт панель быстрых действий для модуля договоров.
  const ContractsQuickActionsSidebar({
    super.key,
    this.contextContract,
    this.sidebarDetailSection = ContractDetailNavigationSection.general,
  });

  void _stub(BuildContext context, String title) {
    AppSnackBar.show(
      context: context,
      message: '$title — скоро',
      kind: AppSnackBarKind.neutral,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reorderActive =
        contextContract != null &&
        ref.watch(contractDocumentsReorderModeProvider(contextContract!.id));
    final contractFilesLoadingForDocumentsTab =
        contextContract != null &&
                sidebarDetailSection ==
                    ContractDetailNavigationSection.documents
            ? ref.watch(contractFilesProvider(contextContract!.id)).isLoading
            : false;

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      letterSpacing: 1.0,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface.withValues(alpha: 0.55),
      fontSize: 10,
    );

    Widget actionTile({
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GTSecondaryButton(icon: icon, text: label, onPressed: onPressed),
      );
    }

    Widget? documentNotesVisibilityTile;
    if (contextContract != null &&
        sidebarDetailSection == ContractDetailNavigationSection.documents) {
      final cid = contextContract!.id;
      final filesState = ref.watch(contractFilesProvider(cid));
      final anyNotes = filesState.files.any(
        (f) => f.description != null && f.description!.trim().isNotEmpty,
      );
      if (anyNotes) {
        final descriptionsOn = ref.watch(
          contractDocumentDescriptionsVisibleProvider(cid),
        );
        documentNotesVisibilityTile = PermissionGuard(
          module: 'contracts',
          permission: 'read',
          child: actionTile(
            icon: Icons.subject_outlined,
            label: descriptionsOn ? 'Скрыть примечания' : 'Показать примечания',
            onPressed: reorderActive
                ? null
                : () {
                    ref
                            .read(
                              contractDocumentDescriptionsVisibleProvider(
                                cid,
                              ).notifier,
                            )
                            .state =
                        !descriptionsOn;
                  },
          ),
        );
      }
    }

    return SizedBox(
      width: preferredWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surface,
          border: Border.all(
            color: scheme.outline.withValues(alpha: isDark ? 0.18 : 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: isDark ? 0.45 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            ContractListScreenDesktopChrome.gridGutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: scheme.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'БЫСТРЫЕ ДЕЙСТВИЯ',
                      style: titleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (sidebarDetailSection ==
                  ContractDetailNavigationSection.documents) ...[
                if (contextContract != null) ...[
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: reorderActive
                          ? const GTSecondaryButton(
                              icon: Icons.upload_file_rounded,
                              text: 'Загрузить документ',
                              onPressed: null,
                            )
                          : GTPrimaryButton(
                              icon: Icons.upload_file_rounded,
                              text: 'Загрузить документ',
                              onPressed: () => openContractDocumentUploadFlow(
                                context: context,
                                ref: ref,
                                contract: contextContract!,
                              ),
                            ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: reorderActive
                          ? GTPrimaryButton(
                              icon: Icons.check_rounded,
                              text: 'Готово',
                              isLoading: contractFilesLoadingForDocumentsTab,
                              onPressed: () {
                                final id = contextContract!.id;
                                ref
                                        .read(
                                          contractDocumentsReorderSaveRequestProvider(
                                            id,
                                          ).notifier,
                                        )
                                        .state =
                                    ref.read(
                                          contractDocumentsReorderSaveRequestProvider(
                                            id,
                                          ),
                                        ) +
                                        1;
                              },
                            )
                          : GTSecondaryButton(
                              icon: Icons.swap_vert_rounded,
                              text: 'Упорядочить',
                              onPressed: () {
                                final id = contextContract!.id;
                                ref
                                        .read(
                                          contractDocumentsReorderModeProvider(
                                            id,
                                          ).notifier,
                                        )
                                        .state =
                                    true;
                              },
                            ),
                    ),
                  ),
                  if (documentNotesVisibilityTile != null)
                    documentNotesVisibilityTile,
                ],
              ] else ...[
                if (contextContract != null &&
                    sidebarDetailSection ==
                        ContractDetailNavigationSection.acts) ...[
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: actionTile(
                      icon: Icons.fact_check_outlined,
                      label: 'Создать акт',
                      onPressed: () => openContractActFormDialog(
                        context: context,
                        ref: ref,
                        contract: contextContract!,
                      ),
                    ),
                  ),
                ],
                if (sidebarDetailSection !=
                    ContractDetailNavigationSection.acts) ...[
                  if (contextContract != null)
                    PermissionGuard(
                      module: 'estimates',
                      permission: 'import',
                      child: actionTile(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Доп. соглашение',
                        onPressed: () => openContractEstimateAddendumFlow(
                          context: context,
                          ref: ref,
                          contract: contextContract!,
                        ),
                      ),
                    )
                  else
                    actionTile(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Доп. соглашение',
                      onPressed: () => AppSnackBar.show(
                        context: context,
                        message:
                            'Откройте договор из списка, чтобы оформить доп. соглашение',
                        kind: AppSnackBarKind.info,
                      ),
                    ),
                ],
                if (contextContract != null &&
                    sidebarDetailSection ==
                        ContractDetailNavigationSection.estimates) ...[
                  PermissionGuard(
                    module: 'estimates',
                    permission: 'read',
                    child: actionTile(
                      icon: Icons.download_rounded,
                      label: 'Скачать смету',
                      onPressed: () =>
                          openContractEstimateWithAddendaExportFlow(
                            context: context,
                            ref: ref,
                            contract: contextContract!,
                          ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'estimates',
                    permission: 'read',
                    child: actionTile(
                      icon: Icons.fact_check_outlined,
                      label: 'Скачать смету с выполнением',
                      onPressed: () =>
                          openContractEstimateWithExecutionExportFlow(
                            context: context,
                            ref: ref,
                            contract: contextContract!,
                          ),
                    ),
                  ),
                ],
                if (contextContract != null &&
                    sidebarDetailSection ==
                        ContractDetailNavigationSection.estimates)
                  PermissionGuard(
                    module: 'estimates',
                    permission: 'import',
                    child: actionTile(
                      icon: Icons.publish_rounded,
                      label: 'Импорт',
                      onPressed: () {
                        final c = contextContract!;
                        ImportEstimateFormModal.show(
                          context,
                          ref,
                          prefilledContractId: c.id,
                          prefilledObjectId: c.objectId,
                          onSuccess: () {
                            ref.invalidate(contractEstimateFilesProvider(c.id));
                            ref.invalidate(contractEstimatesProvider(c.id));
                            ref.invalidate(estimateGroupsProvider);
                          },
                        );
                      },
                    ),
                  ),
                if (sidebarDetailSection !=
                    ContractDetailNavigationSection.acts) ...[
                  actionTile(
                    icon: Icons.upload_file_rounded,
                    label: 'Импорт договоров',
                    onPressed: () => _stub(context, 'Импорт договоров'),
                  ),
                  actionTile(
                    icon: Icons.description_outlined,
                    label: 'Шаблон договора',
                    onPressed: () => _stub(context, 'Шаблон договора'),
                  ),
                ],
              ],
              if (contextContract != null &&
                  sidebarDetailSection ==
                      ContractDetailNavigationSection.acts) ...[
                const SizedBox(height: 12),
                _ContractActsSidebarSummary(contractId: contextContract!.id),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: contextContract != null
                      ? _ContractSidebarBriefPanel(contract: contextContract!)
                      : _SidebarListHints(theme: theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Сводка по актам договора для боковой панели (вкладка «Акты»).
class _ContractActsSidebarSummary extends ConsumerWidget {
  const _ContractActsSidebarSummary({required this.contractId});

  /// Идентификатор договора.
  final String contractId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final actsAsync = ref.watch(contractActsProvider(contractId));

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 8.5,
      letterSpacing: 0.65,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface.withValues(alpha: 0.42),
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.22,
      fontSize: 12,
    );

    Widget moneyRow(String title, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: labelStyle),
            const SizedBox(height: 2),
            SelectableText(value, style: valueStyle),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: actsAsync.when(
          loading: () => const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            'Сводка недоступна: $e',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.error,
              height: 1.3,
            ),
          ),
          data: (acts) {
            var sumAmount = 0.0;
            var sumVat = 0.0;
            var sumAdvance = 0.0;
            var sumWarranty = 0.0;
            var sumOther = 0.0;
            var sumToPay = 0.0;
            for (final a in acts) {
              sumAmount += a.amount;
              sumVat += a.vatAmount;
              sumAdvance += a.advanceRetention;
              sumWarranty += a.warrantyRetention;
              sumOther += a.otherRetentions;
              sumToPay += a.totalToPay;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ИТОГО ПО АКТАМ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.05,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                moneyRow('Сумма актов', formatCurrency(sumAmount)),
                moneyRow('НДС', formatCurrency(sumVat)),
                moneyRow(
                  'Авансовые удержания',
                  formatCurrency(sumAdvance),
                ),
                moneyRow(
                  'Гарантийные удержания',
                  formatCurrency(sumWarranty),
                ),
                moneyRow('Прочие удержания', formatCurrency(sumOther)),
                moneyRow('К оплате', formatCurrency(sumToPay)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContractSidebarBriefPanel extends StatelessWidget {
  const _ContractSidebarBriefPanel({required this.contract});

  final Contract contract;

  static String _shortId(String id) {
    final t = id.trim();
    if (t.length <= 13) return t;
    return '${t.substring(0, 8)}…${t.substring(t.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sub = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.55),
      height: 1.35,
      fontSize: 11,
    );

    Widget row(String title, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8.5,
                letterSpacing: 0.65,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.22,
              ),
            ),
          ],
        ),
      );
    }

    final stamp = contract.updatedAt ?? contract.createdAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ВЫБРАН ДОГОВОР',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.05,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              color: scheme.primary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          row('Номер', contract.number),
          row('Сумма', formatCurrency(contract.amount)),
          row('Контрагент', contract.contractorName ?? '—'),
          row('Объект', contract.objectName ?? '—'),
          if (stamp != null)
            row('Последнее изменение', formatRuDateTime(stamp)),
          Text('ID: ${_shortId(contract.id)}', style: sub),
        ],
      ),
    );
  }
}

class _SidebarListHints extends StatelessWidget {
  const _SidebarListHints({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.62);

    Widget tip(String bullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                Icons.adjust_rounded,
                size: 10,
                color: scheme.primary.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bullet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  height: 1.38,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ПОДСКАЗКИ',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.05,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              color: scheme.primary.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 10),
          tip(
            'Откройте договор из таблицы — здесь появится краткое резюме и связь с действиями.',
          ),
          tip(
            'Переключайте разделы справа сверху: «Общие данные», сметы, акты и т. д.',
          ),
          tip(
            'Комбинируйте фильтры и поиск перед открытием карточки, чтобы держать на экране релевантный список.',
          ),
        ],
      ),
    );
  }
}
