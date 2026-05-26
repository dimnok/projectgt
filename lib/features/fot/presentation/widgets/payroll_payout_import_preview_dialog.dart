import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/fot/domain/entities/payroll_payout_import.dart';
import 'package:projectgt/features/fot/presentation/utils/payroll_payout_batch_save.dart';

/// Предпросмотр импорта выплат из Excel с отчётом по расхождениям ФИО.
class PayrollPayoutImportPreviewDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог предпросмотра.
  const PayrollPayoutImportPreviewDialog({
    super.key,
    required this.parseResult,
    required this.batchParams,
  });

  /// Результат разбора файла.
  final PayrollPayoutImportParseResult parseResult;

  /// Параметры выплаты (дата, способ, тип, комментарий).
  final PayrollPayoutBatchParams batchParams;

  @override
  ConsumerState<PayrollPayoutImportPreviewDialog> createState() =>
      _PayrollPayoutImportPreviewDialogState();
}

class _PayrollPayoutImportPreviewDialogState
    extends ConsumerState<PayrollPayoutImportPreviewDialog> {
  bool _saving = false;

  PayrollPayoutImportParseResult get _result => widget.parseResult;

  Future<void> _onImportPressed() async {
    final matched = _result.matchedRows;
    if (matched.isEmpty) {
      SnackBarUtils.showWarning(
        context,
        'Нет строк для импорта — сопоставьте ФИО в справочнике',
      );
      return;
    }

    if (_result.hasIssues) {
      final confirmed = await _confirmPartialImport();
      if (!confirmed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final entries = matched
          .map(
            (r) => (
              employeeId: r.matchedEmployee!.id,
              amount: r.amount,
            ),
          )
          .toList();

      final count = await savePayrollPayoutBatch(
        ref: ref,
        params: widget.batchParams,
        entries: entries,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      SnackBarUtils.showSuccess(context, 'Создано выплат: $count');
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка импорта: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmPartialImport() async {
    final notFound = _result.notFoundRows.length;
    final ambiguous = _result.ambiguousRows.length;
    final matched = _result.matchedRows.length;

    final message = StringBuffer(
      'Не все строки из файла сопоставлены с сотрудниками:\n',
    );
    if (notFound > 0) {
      message.writeln('• не найдено в справочнике: $notFound');
    }
    if (ambiguous > 0) {
      message.writeln('• неоднозначное ФИО: $ambiguous');
    }
    message.writeln('\nИмпортировать только найденных ($matched)?');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Есть расхождения по ФИО'),
        content: Text(message.toString()),
        actions: [
          GTTextButton(
            text: 'Отмена',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          GTPrimaryButton(
            text: 'Импортировать найденных',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    const title = 'Предпросмотр импорта';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummary(theme),
        if (_result.hasIssues) ...[
          const SizedBox(height: 12),
          _buildWarningBanner(theme),
        ],
        const SizedBox(height: 16),
        Expanded(child: _buildTable(theme)),
      ],
    );

    final matchedCount = _result.matchedRows.length;
    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GTTextButton(
          text: 'Отмена',
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        GTPrimaryButton(
          text: _result.hasIssues
              ? 'Импортировать найденных ($matchedCount)'
              : 'Создать выплаты ($matchedCount)',
          isLoading: _saving,
          onPressed: _saving || matchedCount == 0 ? null : _onImportPressed,
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesktopDialogContent(
          title: title,
          footer: footer,
          width: 900,
          height: 640,
          scrollable: false,
          child: content,
        ),
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: content,
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final total = _result.rows.fold<double>(0, (s, r) => s + r.amount);
    final matchedTotal = _result.matchedRows.fold<double>(
      0,
      (s, r) => s + r.amount,
    );

    return Text(
      'Строк в файле: ${_result.rows.length} · '
      'к импорту: ${_result.matchedRows.length} · '
      'сумма к импорту: ${formatCurrency(matchedTotal)} · '
      'всего в файле: ${formatCurrency(total)}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _buildWarningBanner(ThemeData theme) {
    final parts = <String>[];
    if (_result.notFoundRows.isNotEmpty) {
      parts.add('не найдено: ${_result.notFoundRows.length}');
    }
    if (_result.ambiguousRows.isNotEmpty) {
      parts.add('неоднозначно: ${_result.ambiguousRows.length}');
    }

    return Material(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Расхождения по ФИО (${parts.join(', ')}). '
                'Строки без сопоставления не будут импортированы.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _colRowWidth = 44;
  static const double _colStatusWidth = 92;
  static const double _colAmountWidth = 118;
  static const double _rowHeight = 32;
  static const double _horizontalPadding = 12;

  Widget _buildTable(ThemeData theme) {
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final dataStyle = theme.textTheme.bodySmall;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            _buildTableHeader(theme, headerStyle, dividerColor),
            Expanded(
              child: ListView.separated(
                itemCount: _result.rows.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, thickness: 1, color: dividerColor),
                itemBuilder: (context, index) {
                  return _buildTableDataRow(
                    _result.rows[index],
                    theme,
                    dataStyle,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    ThemeData theme,
    TextStyle? headerStyle,
    Color dividerColor,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: SizedBox(
        height: _rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              SizedBox(
                width: _colRowWidth,
                child: Text('Стр.', style: headerStyle),
              ),
              SizedBox(
                width: _colStatusWidth,
                child: Text('Статус', style: headerStyle),
              ),
              Expanded(
                child: Text('ФИО из файла', style: headerStyle),
              ),
              SizedBox(
                width: _colAmountWidth,
                child: Text(
                  'Сумма',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableDataRow(
    PayrollPayoutImportRow row,
    ThemeData theme,
    TextStyle? dataStyle,
  ) {
    final (statusLabel, statusColor) = switch (row.status) {
      PayrollPayoutImportMatchStatus.matched => (
        'Найден',
        Colors.green.shade700,
      ),
      PayrollPayoutImportMatchStatus.notFound => (
        'Не найден',
        theme.colorScheme.error,
      ),
      PayrollPayoutImportMatchStatus.ambiguous => (
        'Неоднозначно',
        theme.colorScheme.tertiary,
      ),
    };

    return SizedBox(
      height: _rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: [
            SizedBox(
              width: _colRowWidth,
              child: Text('${row.excelRowNumber}', style: dataStyle),
            ),
            SizedBox(
              width: _colStatusWidth,
              child: Text(
                statusLabel,
                style: dataStyle?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                row.fioFromFile,
                style: dataStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: _colAmountWidth,
              child: Text(
                formatCurrency(row.amount),
                style: dataStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
