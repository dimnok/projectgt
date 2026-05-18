import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_files_providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_costs_info.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_files_section.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_detail_navigation_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_estimate_positions_table_panel.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_details_main_information_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_addenda_from_revisions_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_estimates_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_documents_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_acts_section.dart';
import 'contract_list_shared.dart';

/// Плюс к потоку (приход): читаемый на [surface] в тёмной и светлой теме.
Color _cashFlowInflowColor(ThemeData theme) {
  return theme.brightness == Brightness.dark
      ? const Color(0xFF69F0AE)
      : const Color(0xFF1B5E20);
}

/// Минус / расход в таблице Cash Flow — тот же акцент, что и системная ошибка.
Color _cashFlowOutflowColor(ThemeData theme) => theme.colorScheme.error;

/// Панель детальной информации о договоре.
///
/// Отображает все ключевые параметры договора: объект, статус, даты, финансовые условия,
/// а также разделы с файлами, дополнительными соглашениями и актами по договору.
/// Включает визуализацию Cash Flow по договору.
///
/// При [detailSectionFilter] не `null` (встроенный список с навигацией по разделам)
/// под шапкой показывается только выбранный подраздел; в диалоге [show] значение `null` — полная карточка.
class ContractDetailsPanel extends ConsumerWidget {
  /// Сущность договора, данные которой необходимо отобразить.
  final Contract contract;

  /// Функция обратного вызова для перехода к форме редактирования договора.
  final VoidCallback onEdit;

  /// Ограничение контента карточки одним разделом (`null` — все блоки как в диалоге).
  final ContractDetailNavigationSection? detailSectionFilter;

  /// Растянуть блок «Сметы» по вертикали под родителя с конечной высотой (inline-детали).
  ///
  /// В диалоге [show] должен быть `false`: там [Column] без [Expanded].
  final bool expandEstimatesBodyToViewport;

  /// Создает экземпляр панели деталей договора.
  const ContractDetailsPanel({
    super.key,
    required this.contract,
    required this.onEdit,
    this.detailSectionFilter,
    this.expandEstimatesBodyToViewport = false,
  });

  /// Заголовок хрома (inline-панель над карточкой, шапка диалога «Договор № …»).
  static String toolbarTitle(Contract contract) =>
      'Договор № ${contract.number}';

  /// Показывает диалоговое окно с деталями договора.
  ///
  /// Возвращает [Future], завершающийся после закрытия диалога (крестик, барьер,
  /// кнопка «Закрыть», после перехода к редактированию и т.д.).
  static Future<void> show(
    BuildContext context, {
    required Contract contract,
    required VoidCallback onEdit,
  }) {
    final done = Completer<void>();

    void safeComplete() {
      if (!done.isCompleted) done.complete();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        safeComplete();
        return;
      }
      final dialogHeight = MediaQuery.sizeOf(context).height * 0.85;
      try {
        await DesktopDialogContent.show<void>(
          context,
          title: toolbarTitle(contract),
          width: 900,
          // Явная высота: иначе у Flexible/LayoutBuilder внутри DesktopDialogContent
          // остаётся неограниченная высота, и Column+Expanded в панели падают по layout.
          height: dialogHeight,
          scrollable:
              false, // Скролл в DesktopDialogContent; панель — Column без Expanded
          padding: EdgeInsets.zero, // Отступы управляются внутри панели
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GTPrimaryButton(
                text: 'Закрыть',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          child: ContractDetailsPanel(
            contract: contract,
            onEdit: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
        );
      } finally {
        safeComplete();
      }
    });

    return done.future;
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    // Используем addPostFrameCallback для предотвращения MouseTracker error на десктопе
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final confirmed = await GTConfirmationDialog.show(
        context: context,
        title: 'Удалить договор?',
        message: 'Вы уверены, что хотите удалить договор № ${contract.number}?',
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        type: GTConfirmationType.danger,
      );

      if (confirmed == true) {
        try {
          await ref.read(contractProvider.notifier).deleteContract(contract.id);
          if (!context.mounted) return;
          AppSnackBar.show(
            context: context,
            message: 'Договор удален',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = detailSectionFilter;
    final fillEstimatesViewport =
        filter == ContractDetailNavigationSection.estimates &&
        expandEstimatesBodyToViewport;

    // Без Expanded: родитель (DesktopDialogContent при scrollable:false) оборачивает
    // child в SingleChildScrollView — там вертикальный maxHeight бесконечен.
    return Column(
      mainAxisSize: fillEstimatesViewport ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Действия в правом верхнем углу карточки (без дубля названия и контрагента — они в toolbar / диалоге).
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: switch (filter) {
            ContractDetailNavigationSection.estimates => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 28,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ContractEstimatesSection.embeddedScreenTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fade(delay: 140.ms),
                    ),
                  ),
                  Expanded(
                    flex: 44,
                    child: Center(
                      child: ContractEstimateEmbeddedTabStrip(
                        contractId: contract.id,
                      ),
                    ),
                  ),
                  // На вкладке «Сметы» действия по договору (редактирование/удаление)
                  // не показываем — они относятся к карточке договора в других разделах.
                  const Expanded(flex: 28, child: SizedBox.shrink()),
                ],
              ),
              ContractDetailNavigationSection.addenda => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 28,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ContractAddendaFromRevisionsSection.embeddedScreenTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fade(delay: 140.ms),
                    ),
                  ),
                  const Expanded(
                    flex: 44,
                    child: Center(child: SizedBox.shrink()),
                  ),
                  const Expanded(flex: 28, child: SizedBox.shrink()),
                ],
              ),
            _ => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: switch (filter) {
                          ContractDetailNavigationSection.documents => Text(
                              'Документы договора',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ).animate().fade(delay: 140.ms),
                          ContractDetailNavigationSection.acts => Text(
                              'Акты по договору',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ).animate().fade(delay: 140.ms),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ),
                    if (filter == ContractDetailNavigationSection.documents &&
                        !ResponsiveUtils.isDesktop(context))
                      Consumer(
                        builder: (context, ref, _) {
                          final cid = contract.id;
                          final fileState =
                              ref.watch(contractFilesProvider(cid));
                          final reorder = ref.watch(
                            contractDocumentsReorderModeProvider(cid),
                          );
                          final descriptionsOn = ref.watch(
                            contractDocumentDescriptionsVisibleProvider(cid),
                          );
                          final anyNotes = fileState.files.any(
                            (f) =>
                                f.description != null &&
                                f.description!.trim().isNotEmpty,
                          );
                          if (!anyNotes) return const SizedBox.shrink();
                          return PermissionGuard(
                            module: 'contracts',
                            permission: 'read',
                            child: Tooltip(
                              message: descriptionsOn
                                  ? 'Скрыть примечания у всех файлов'
                                  : 'Показать примечания у всех файлов',
                              child: GTTextButton(
                                text: descriptionsOn
                                    ? 'Скрыть'
                                    : 'Описания',
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                onPressed: reorder
                                    ? null
                                    : () {
                                        ref
                                            .read(
                                              contractDocumentDescriptionsVisibleProvider(
                                                cid,
                                              ).notifier,
                                            )
                                            .state = !descriptionsOn;
                                      },
                              ),
                            ),
                          );
                        },
                      ),
                    if (filter != ContractDetailNavigationSection.documents &&
                        filter != ContractDetailNavigationSection.acts) ...[
                      PermissionGuard(
                        module: 'contracts',
                        permission: 'update',
                        child: GTTextButton(
                          text: 'Редактировать',
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          onPressed: onEdit,
                        ),
                      ).animate().fade(delay: 200.ms),
                      const SizedBox(width: 4),
                      PermissionGuard(
                        module: 'contracts',
                        permission: 'delete',
                        child: GTTextButton(
                          text: 'Удалить',
                          fontSize: 12,
                          color: theme.colorScheme.error,
                          onPressed: () => _handleDelete(context, ref),
                        ),
                      ).animate().fade(delay: 250.ms),
                    ],
                  ],
                ),
          },
        ),
        const Divider(height: 1),
        if (filter == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContractAtmosphereCard(child: _buildCashFlowSection(theme))
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
                const SizedBox(height: 32),
                ContractAtmosphereCard(
                      child: ContractDetailsMainInformationSection(
                        contract: contract,
                      ),
                    )
                    .animate()
                    .fade(delay: 500.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
                const SizedBox(height: 32),
                ContractFilesSection(contract: contract)
                    .animate()
                    .fade(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
                const SizedBox(height: 32),
                ContractAtmosphereCard(
                      child: ContractAddendaFromRevisionsSection(
                        contract: contract,
                      ),
                    )
                    .animate()
                    .fade(delay: 700.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
                const SizedBox(height: 32),
                ContractAtmosphereCard(
                      child: ContractActsSection(contract: contract),
                    )
                    .animate()
                    .fade(delay: 800.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
                const SizedBox(height: 32),
                const GTSectionTitle(
                  title: 'Выполнение и остатки',
                ).animate().fade(delay: 900.ms, duration: 500.ms),
                const SizedBox(height: 16),
                ContractCostsInfo(
                      contractId: contract.id,
                      objectId: contract.objectId,
                      contractAmount: contract.amount,
                    )
                    .animate()
                    .fade(delay: 1000.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ],
            ),
          )
        else if (fillEstimatesViewport)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child:
                  ContractEstimatesSection(
                        contract: contract,
                        stretchTableVertically: true,
                      )
                      .animate()
                      .fade(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOut),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(24),
            child: switch (filter) {
              ContractDetailNavigationSection.general =>
                ContractAtmosphereCard(
                      child: ContractDetailsMainInformationSection(
                        contract: contract,
                      ),
                    )
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ContractDetailNavigationSection.estimates =>
                ContractEstimatesSection(contract: contract)
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ContractDetailNavigationSection.addenda =>
                ContractAtmosphereCard(
                      child: ContractAddendaFromRevisionsSection(
                        contract: contract,
                        showSectionHeader: false,
                      ),
                    )
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ContractDetailNavigationSection.documents =>
                ContractDocumentsSection(
                      contract: contract,
                      showSectionHeader: false,
                    )
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ContractDetailNavigationSection.acts =>
                ContractActsSection(
                      contract: contract,
                      showSectionHeader: false,
                    )
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              _ => _filteredSectionPlaceholder(theme, filter),
            },
          ),
      ],
    );
  }

  Widget _filteredSectionPlaceholder(
    ThemeData theme,
    ContractDetailNavigationSection section,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'Раздел «${section.label}»: в разработке',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowSection(ThemeData theme) {
    final months = [
      'Янв 2024',
      'Фев 2024',
      'Мар 2024',
      'Апр 2024',
      'Май 2024',
      'Июн 2024',
      'Июл 2024',
      'Авг 2024',
      'Сен 2024',
      'Окт 2024',
      'Ноя 2024',
      'Дек 2024',
    ];
    final incomes = [
      450000.0,
      0.0,
      800000.0,
      300000.0,
      1200000.0,
      0.0,
      500000.0,
      0.0,
      750000.0,
      400000.0,
      0.0,
      900000.0,
    ];
    final expenses = [
      320000.0,
      150000.0,
      400000.0,
      550000.0,
      200000.0,
      100000.0,
      300000.0,
      250000.0,
      350000.0,
      450000.0,
      120000.0,
      500000.0,
    ];

    final totalIncome = incomes.fold(0.0, (a, b) => a + b);
    final totalExpense = expenses.fold(0.0, (a, b) => a + b);
    final totalBalance = totalIncome - totalExpense;

    const double labelWidth = 100.0;
    const double monthWidth = 120.0;
    const double totalWidth = 130.0;
    const double rowHeight = 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTSectionTitle(title: 'Движение денежных средств (Cash Flow)'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.06 : 0.045,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // 1. Fixed Left Column (Labels)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCell(
                    'Статья',
                    labelWidth,
                    rowHeight,
                    theme,
                    isHeader: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell('Приход', labelWidth, rowHeight, theme),
                  const Divider(height: 1),
                  _buildCell('Расход', labelWidth, rowHeight, theme),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    'Итого',
                    labelWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                  ),
                  const Divider(height: 1),
                ],
              ),
              _buildVerticalDivider(theme, height: (rowHeight + 1) * 4),

              // 2. Scrollable Middle (Months)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < months.length; i++) ...[
                        Column(
                          children: [
                            _buildCell(
                              months[i],
                              monthWidth,
                              rowHeight,
                              theme,
                              isHeader: true,
                            ),
                            const Divider(height: 1, thickness: 1),
                            _buildCell(
                              incomes[i] != 0
                                  ? formatCurrency(incomes[i])
                                  : formatCurrency(0),
                              monthWidth,
                              rowHeight,
                              theme,
                              valueColor: incomes[i] > 0
                                  ? _cashFlowInflowColor(theme)
                                  : null,
                            ),
                            const Divider(height: 1),
                            _buildCell(
                              expenses[i] != 0
                                  ? formatCurrency(expenses[i])
                                  : formatCurrency(0),
                              monthWidth,
                              rowHeight,
                              theme,
                              valueColor: expenses[i] > 0
                                  ? _cashFlowOutflowColor(theme)
                                  : null,
                            ),
                            const Divider(height: 1, thickness: 1),
                            _buildCell(
                              formatCurrency(incomes[i] - expenses[i]),
                              monthWidth,
                              rowHeight,
                              theme,
                              isBold: true,
                              valueColor: (incomes[i] - expenses[i]) >= 0
                                  ? _cashFlowInflowColor(theme)
                                  : _cashFlowOutflowColor(theme),
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                        _buildVerticalDivider(
                          theme,
                          height: (rowHeight + 1) * 4,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Fixed Right Column (Totals)
              Column(
                children: [
                  _buildCell(
                    'ИТОГО',
                    totalWidth,
                    rowHeight,
                    theme,
                    isHeader: true,
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    formatCurrency(totalIncome),
                    totalWidth,
                    rowHeight,
                    theme,
                    valueColor: _cashFlowInflowColor(theme),
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1),
                  _buildCell(
                    formatCurrency(totalExpense),
                    totalWidth,
                    rowHeight,
                    theme,
                    valueColor: _cashFlowOutflowColor(theme),
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    formatCurrency(totalBalance),
                    totalWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                    valueColor: totalBalance >= 0
                        ? _cashFlowInflowColor(theme)
                        : _cashFlowOutflowColor(theme),
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    String text,
    double width,
    double height,
    ThemeData theme, {
    bool isHeader = false,
    bool isBold = false,
    Color? valueColor,
    bool isTotalColumn = false,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isHeader
            ? (isTotalColumn
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.02))
            : (isTotalColumn
                  ? theme.colorScheme.primary.withValues(alpha: 0.02)
                  : null),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: (isHeader || isBold || isTotalColumn)
              ? FontWeight.bold
              : FontWeight.normal,
          color: isHeader
              ? (isTotalColumn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55))
              : (valueColor ?? theme.colorScheme.onSurface),
          fontSize: isHeader ? 12 : 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme, {double? height}) {
    return Container(
      width: 1,
      height: height,
      color: theme.colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}
