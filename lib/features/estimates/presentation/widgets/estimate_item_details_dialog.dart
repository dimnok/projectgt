import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../materials/data/models/material_item.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../materials/presentation/providers/materials_providers.dart';
import '../../../company/presentation/widgets/company_info_widgets.dart';

/// Диалоговое окно с детальной информацией о сметной позиции.
///
/// Отображает основную информацию, показатели выполнения и список
/// привязанных материалов из накладных.
class EstimateItemDetailsDialog extends ConsumerWidget {
  /// Сметная позиция.
  final Estimate estimate;

  /// Данные о выполнении позиции (могут отсутствовать).
  final EstimateCompletionModel? completion;

  /// Нужно ли оборачивать в DesktopDialogContent.
  /// По умолчанию true.
  final bool useWrapper;

  /// Создает экземпляр [EstimateItemDetailsDialog].
  const EstimateItemDetailsDialog({
    super.key,
    required this.estimate,
    this.completion,
    this.useWrapper = true,
  });

  /// Показывает диалоговое окно.
  static Future<void> show(
    BuildContext context, {
    required Estimate estimate,
    EstimateCompletionModel? completion,
  }) {
    return DesktopDialogContent.show(
      context,
      title: 'Детали позиции',
      width: 900,
      child: EstimateItemDetailsDialog(
        estimate: estimate,
        completion: completion,
        useWrapper: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final linkedMaterialsAsync = ref.watch(
      linkedMaterialsProvider(estimate.id),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCards(theme)
            .animate()
            .fade(duration: 400.ms)
            .slideY(begin: 0.05, curve: Curves.easeOut),
        const SizedBox(height: 32),
        _buildMaterialsSection(theme, linkedMaterialsAsync)
            .animate()
            .fade(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.05, curve: Curves.easeOut),
      ],
    );

    if (!useWrapper) return content;

    return DesktopDialogContent(
      title: 'Детали позиции',
      width: 900,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildInfoCards(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Левая колонка: Основная информация
        Expanded(
          flex: 3,
          child: CompanyInfoCard(
            title: 'Параметры сметы',
            icon: CupertinoIcons.info_circle,
            children: [
              CompanyInfoRow(label: 'Система', value: estimate.system)
                  .animate()
                  .fade(delay: 100.ms)
                  .slideX(begin: 0.05),
              CompanyInfoRow(label: 'Подсистема', value: estimate.subsystem)
                  .animate()
                  .fade(delay: 150.ms)
                  .slideX(begin: 0.05),
              CompanyInfoRow(
                label: 'Наименование',
                value: '${estimate.number} ${estimate.name}',
              ).animate().fade(delay: 200.ms).slideX(begin: 0.05),
              CompanyInfoRow(
                label: 'Количество по проекту',
                value: '${formatQuantity(estimate.quantity)} ${estimate.unit}',
                isLast: true,
              ).animate().fade(delay: 250.ms).slideX(begin: 0.05),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Правая колонка: Выполнение
        Expanded(
          flex: 2,
          child: CompanyInfoCard(
            title: 'Текущее выполнение',
            icon: CupertinoIcons.chart_bar_fill,
            accentColor: Colors.green,
            children: [
              if (completion != null) ...[
                CompanyInfoRow(
                  label: 'Факт выполнения',
                  value: formatQuantity(completion!.completedQuantity),
                ).animate().fade(delay: 300.ms).slideX(begin: 0.05),
                CompanyInfoRow(
                  label: 'Остаток по проекту',
                  value: formatQuantity(completion!.remainingQuantity),
                ).animate().fade(delay: 350.ms).slideX(begin: 0.05),
                CompanyInfoRow(
                  label: 'Процент выполнения',
                  value: formatPercentage(
                    completion!.percentage,
                    decimalDigits: 1,
                  ),
                ).animate().fade(delay: 400.ms).slideX(begin: 0.05),
                CompanyInfoRow(
                  label: 'Материал получен',
                  value: formatQuantity(completion!.materialReceived),
                  isLast: true,
                ).animate().fade(delay: 450.ms).slideX(begin: 0.05),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Данные о выполнении отсутствуют'),
                ).animate().fade(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsSection(
    ThemeData theme,
    AsyncValue<List<MaterialItem>> linkedMaterialsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.square_list,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'ПРИВЯЗАННЫЕ МАТЕРИАЛЫ ИЗ НАКЛАДНЫХ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        linkedMaterialsAsync.when(
          data: (materials) {
            if (materials.isEmpty) {
              return _buildEmptyState(theme);
            }
            return _buildMaterialsTable(theme, materials);
          },
          loading: () => _buildLoadingState(theme),
          error: (e, _) => _buildErrorState(theme, e),
        ),
      ],
    );
  }

  Widget _buildMaterialsTable(ThemeData theme, List<MaterialItem> materials) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(4), // Название
            1: FixedColumnWidth(80), // Ед.изм
            2: FlexColumnWidth(2), // Накладная
            3: FlexColumnWidth(2), // Дата
            4: FixedColumnWidth(100), // Кол-во
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              children: [
                _headerCell(theme, 'Наименование'),
                _headerCell(theme, 'Ед.изм', align: TextAlign.center),
                _headerCell(theme, '№ Накладной'),
                _headerCell(theme, 'Дата накладной'),
                _headerCell(
                  theme,
                  'Количество',
                  align: TextAlign.right,
                ),
              ],
            ),
            ...materials.map(
              (m) => TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                ),
                children: [
                  _cell(theme, m.name),
                  _cell(theme, m.unit ?? '—', align: TextAlign.center),
                  _cell(theme, m.receiptNumber ?? '—'),
                  _cell(
                    theme,
                    m.receiptDate != null ? formatRuDate(m.receiptDate!) : '—',
                  ),
                  _cell(
                    theme,
                    formatQuantity(m.quantity ?? 0),
                    align: TextAlign.right,
                    isBold: true,
                    suffix: m.estimateIds.length > 1
                        ? const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: Colors.blue,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: index == 0
                  ? null
                  : Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.05),
                      ),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildLoadingPlaceholder(theme, width: 200),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildLoadingPlaceholder(theme, width: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildLoadingPlaceholder(theme, width: 80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildLoadingPlaceholder(theme, width: 80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildLoadingPlaceholder(theme, width: 60),
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                duration: 1200.ms,
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme, {required double width}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: const Center(
        child: Text(
          'Материалы из накладных не привязаны к этой позиции',
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
            const SizedBox(height: 12),
            Text(
              'Ошибка загрузки материалов: $error',
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(
    ThemeData theme,
    String text, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _cell(
    ThemeData theme,
    String text, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : (align == TextAlign.center
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start),
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: align,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : null,
                fontSize: 13,
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}
