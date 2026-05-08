import 'package:flutter/material.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_column_config.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_mode.dart';

/// Общие ячейки таблицы подрядчиков: итоги, свёрнутый заголовок группы, денежный текст.
abstract final class SubcontractorsEstimateTableCells {
  /// Сумма в одну строку (без переноса «₽»); при узкой колонке — уменьшение кегля.
  static Widget singleLineMoney(
    String formatted,
    TextStyle style,
    Alignment cellAlignment,
  ) {
    final boxAlignment = switch (cellAlignment.x) {
      > 0 => Alignment.centerRight,
      < 0 => Alignment.centerLeft,
      _ => Alignment.center,
    };
    final textAlign = switch (cellAlignment.x) {
      > 0 => TextAlign.right,
      < 0 => TextAlign.left,
      _ => TextAlign.center,
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: boxAlignment,
      child: Text(
        formatted,
        textAlign: textAlign,
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: style,
      ),
    );
  }

  /// Ячейки строки заголовка раздела (кроме названия): при свёрнутом разделе — итоги.
  ///
  /// См. [aggregateFooter] — [showExecutionVolumeTotals] задаёт видимость объёмных
  /// метрик в режиме [SubcontractorsEstimateTableMode.execution].
  static Widget groupHeaderSecondary(
    ThemeData theme,
    SubcontractorsEstimateTableMode mode,
    SubcontractorColumnConfig config, {
    required bool isCollapsed,
    required double planSectionSum,
    required double subQuantitySum,
    required double subMoneySum,
    required bool hasSubPrice,
    required double completedQuantitySum,
    required double completedAmountSum,
    required double remainingQuantitySum,
    required double remainingAmountSum,
    required double? completionPercent,
    required TextStyle metricStyle,
    bool showExecutionVolumeTotals = true,
  }) {
    if (!isCollapsed) {
      return const SizedBox.shrink();
    }
    if (config.title == 'Сумма') {
      return singleLineMoney(
        formatCurrency(
          mode == SubcontractorsEstimateTableMode.execution
              ? subMoneySum
              : planSectionSum,
        ),
        metricStyle,
        config.cellAlignment,
      );
    }
    if (config.title == 'Кол-во' &&
        mode == SubcontractorsEstimateTableMode.execution) {
      if (!showExecutionVolumeTotals) {
        return const SizedBox.shrink();
      }
      return Text(formatQuantity(subQuantitySum), style: metricStyle);
    }
    if (config.title == 'Сумма суб') {
      if (!hasSubPrice) {
        return Text(
          '—',
          style: metricStyle.copyWith(color: theme.colorScheme.outline),
        );
      }
      return singleLineMoney(
        formatCurrency(subMoneySum),
        metricStyle.copyWith(color: theme.colorScheme.secondary),
        config.cellAlignment,
      );
    }
    if (config.title == 'Выполнено') {
      if (mode == SubcontractorsEstimateTableMode.execution &&
          !showExecutionVolumeTotals) {
        return const SizedBox.shrink();
      }
      return Text(formatQuantity(completedQuantitySum), style: metricStyle);
    }
    if (config.title == 'Сумма вып.') {
      return singleLineMoney(
        formatCurrency(completedAmountSum),
        metricStyle.copyWith(color: theme.colorScheme.secondary),
        config.cellAlignment,
      );
    }
    if (config.title == '%') {
      return Text(
        completionPercent == null
            ? '—'
            : GtFormatters.formatPercentage(
                completionPercent,
                decimalDigits: 1,
              ),
        style: metricStyle,
      );
    }
    if (config.title == 'Остаток') {
      if (mode == SubcontractorsEstimateTableMode.execution &&
          !showExecutionVolumeTotals) {
        return const SizedBox.shrink();
      }
      return Text(formatQuantity(remainingQuantitySum), style: metricStyle);
    }
    if (config.title == 'Сумма ост.') {
      return singleLineMoney(
        formatCurrency(remainingAmountSum),
        metricStyle.copyWith(color: theme.colorScheme.secondary),
        config.cellAlignment,
      );
    }
    return const SizedBox.shrink();
  }

  /// Общая ячейка для строк «Итого по разделу» и «Итого по договору».
  ///
  /// [showExecutionVolumeTotals]: в режиме [SubcontractorsEstimateTableMode.execution]
  /// задать `false` для строк итогов и свёрнутого заголовка раздела, чтобы не показывать
  /// «Кол-во», «Выполнено», «Остаток» (денежные итоги и процент — без изменений).
  static Widget aggregateFooter(
    ThemeData theme,
    SubcontractorsEstimateTableMode mode,
    SubcontractorColumnConfig config, {
    required String nameColumnLabel,
    required double planSum,
    required double subQuantitySum,
    required double subMoneySum,
    required bool hasSubPrice,
    required double completedQuantitySum,
    required double completedAmountSum,
    required double remainingQuantitySum,
    required double remainingAmountSum,
    required double? completionPercent,
    required TextStyle totalLabelStyle,
    bool showExecutionVolumeTotals = true,
  }) {
    if (config.title == 'Наименование') {
      return Text(
        nameColumnLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: totalLabelStyle,
      );
    }
    if (config.title == 'Сумма') {
      return singleLineMoney(
        formatCurrency(
          mode == SubcontractorsEstimateTableMode.execution
              ? subMoneySum
              : planSum,
        ),
        totalLabelStyle,
        config.cellAlignment,
      );
    }
    if (config.title == 'Кол-во' &&
        mode == SubcontractorsEstimateTableMode.execution) {
      if (!showExecutionVolumeTotals) {
        return const SizedBox.shrink();
      }
      return Text(formatQuantity(subQuantitySum), style: totalLabelStyle);
    }
    if (config.title == 'Сумма суб') {
      if (!hasSubPrice) {
        return Text(
          '—',
          style: totalLabelStyle.copyWith(color: theme.colorScheme.outline),
        );
      }
      return singleLineMoney(
        formatCurrency(subMoneySum),
        totalLabelStyle.copyWith(color: theme.colorScheme.secondary),
        config.cellAlignment,
      );
    }
    if (config.title == 'Выполнено') {
      if (mode == SubcontractorsEstimateTableMode.execution &&
          !showExecutionVolumeTotals) {
        return const SizedBox.shrink();
      }
      return Text(formatQuantity(completedQuantitySum), style: totalLabelStyle);
    }
    if (config.title == 'Сумма вып.') {
      return singleLineMoney(
        formatCurrency(completedAmountSum),
        totalLabelStyle.copyWith(color: theme.colorScheme.secondary),
        config.cellAlignment,
      );
    }
    if (config.title == '%') {
      return Text(
        completionPercent == null
            ? '—'
            : GtFormatters.formatPercentage(
                completionPercent,
                decimalDigits: 1,
              ),
        style: totalLabelStyle,
      );
    }
    if (config.title == 'Остаток') {
      if (mode == SubcontractorsEstimateTableMode.execution &&
          !showExecutionVolumeTotals) {
        return const SizedBox.shrink();
      }
      return Text(formatQuantity(remainingQuantitySum), style: totalLabelStyle);
    }
    if (config.title == 'Сумма ост.') {
      return singleLineMoney(
        formatCurrency(remainingAmountSum),
        totalLabelStyle.copyWith(color: theme.colorScheme.secondary),
        config.cellAlignment,
      );
    }
    return const SizedBox.shrink();
  }
}
