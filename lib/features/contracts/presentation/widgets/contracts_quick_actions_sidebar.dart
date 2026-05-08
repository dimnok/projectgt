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
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/screens/import_estimate_form_modal.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Боковая панель «Быстрые действия» на экране списка договоров (десктоп).
///
/// По [contextContract] ниже действий показывается компактное резюме открытого договора;
/// если детали не открыты — блок подсказок по работе со списком.
///
/// Сценарии кнопок по-прежнему заглушки ([AppSnackBar]), кроме импорта сметы,
/// доп. соглашения (LC/ДС) и выгрузки сметы с колонками ДС.
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

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      letterSpacing: 1.0,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface.withValues(alpha: 0.55),
      fontSize: 10,
    );

    Widget actionTile({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GTSecondaryButton(icon: icon, text: label, onPressed: onPressed),
      );
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
              actionTile(
                icon: Icons.fact_check_outlined,
                label: 'Добавить акт',
                onPressed: () => _stub(context, 'Добавить акт'),
              ),
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
              if (contextContract != null &&
                  sidebarDetailSection ==
                      ContractDetailNavigationSection.estimates)
                PermissionGuard(
                  module: 'estimates',
                  permission: 'read',
                  child: actionTile(
                    icon: Icons.download_rounded,
                    label: 'Скачать смету',
                    onPressed: () => openContractEstimateWithAddendaExportFlow(
                      context: context,
                      ref: ref,
                      contract: contextContract!,
                    ),
                  ),
                ),
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
                          ref.invalidate(
                            contractEstimateFilesProvider(c.id),
                          );
                          ref.invalidate(
                            contractEstimatesProvider(c.id),
                          );
                          ref.invalidate(estimateGroupsProvider);
                        },
                      );
                    },
                  ),
                ),
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
              const SizedBox(height: 10),
              Text(
                'Сценарии кнопок подключаются в следующих итерациях.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                  height: 1.35,
                ),
              ),
            ],
          ),
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
