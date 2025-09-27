import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/balance_utils.dart';

/// Константы для таблицы ФОТ (Фонд оплаты труда).
///
/// Содержит цветовые и размерные параметры, используемые для стилизации ячеек,
/// выделения премий, штрафов, выплат, баланса, а также для адаптивного управления отступами между колонками.
class PayrollTableConstants {
  /// Цвет для выделения премий ("Премия") в таблице ФОТ.
  /// Используется для положительных начислений, связанных с бонусами.
  static const Color bonusColor = Color(0xFF2E7D32);

  /// Цвет для выделения штрафов ("Штраф") в таблице ФОТ.
  /// Используется для отрицательных начислений, связанных с удержаниями.
  static const Color penaltyColor = Color(0xFFC62828);

  /// Цвет для выделения выплат ("Выплата") в таблице ФОТ.
  /// Используется для отображения фактических выплат сотрудникам.
  static const Color payoutColor = Color(0xFF1565C0);

  /// Цвет для выделения баланса ("Баланс") в таблице ФОТ.
  /// Используется для итоговой суммы (начислено минус выплачено).
  static const Color balanceColor = Color(0xFF4527A0);

  /// Минимальный горизонтальный отступ между колонками на мобильных устройствах (в пикселях).
  static const double mobileColumnSpacing = 12;

  /// Горизонтальный отступ между колонками на планшетах (в пикселях).
  static const double tabletColumnSpacing = 16;

  /// Горизонтальный отступ между колонками на десктопах (в пикселях).
  static const double desktopColumnSpacing = 24;
}

/// Утилиты для создания ячеек таблицы ФОТ
class PayrollTableCellBuilder {
  static final NumberFormat _numberFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  /// Создаёт ячейку с информацией о сотруднике
  static DataCell buildEmployeeCell({
    required int index,
    required String employeeName,
    required String position,
    required ThemeData theme,
    required bool isMobile,
  }) {
    return DataCell(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMobile)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  index.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  employeeName.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (position.isNotEmpty && !isMobile)
                  Text(
                    position,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Создаёт ячейку с часами
  static DataCell buildHoursCell(double hours) {
    return DataCell(
      Text(
        hours % 1 == 0 ? hours.toInt().toString() : hours.toStringAsFixed(1),
      ),
    );
  }

  /// Создаёт ячейку с денежной суммой
  static DataCell buildCurrencyCell(double amount,
      {Color? textColor, FontWeight? fontWeight}) {
    return DataCell(
      Text(
        _numberFormat.format(amount),
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  /// Создаёт ячейку с премиями
  static DataCell buildBonusCell(double bonusesTotal, ThemeData theme) {
    return DataCell(
      Text(
        bonusesTotal > 0 ? _numberFormat.format(bonusesTotal) : '—',
        style: bonusesTotal > 0
            ? theme.textTheme.bodyMedium?.copyWith(
                color: PayrollTableConstants.bonusColor,
                fontWeight: FontWeight.w500,
              )
            : null,
      ),
    );
  }

  /// Создаёт ячейку со штрафами
  static DataCell buildPenaltyCell(double penaltiesTotal, ThemeData theme) {
    return DataCell(
      Text(
        penaltiesTotal > 0 ? _numberFormat.format(penaltiesTotal) : '—',
        style: penaltiesTotal > 0
            ? theme.textTheme.bodyMedium?.copyWith(
                color: PayrollTableConstants.penaltyColor,
                fontWeight: FontWeight.w500,
              )
            : null,
      ),
    );
  }

  /// Создаёт ячейку с выплатами
  static DataCell buildPayoutCell(double? payoutAmount, ThemeData theme) {
    final hasPayouts = payoutAmount != null && payoutAmount > 0;
    return DataCell(
      Text(
        hasPayouts ? _numberFormat.format(payoutAmount) : '—',
        style: hasPayouts
            ? theme.textTheme.bodyMedium?.copyWith(
                color: PayrollTableConstants.payoutColor,
                fontWeight: FontWeight.w500,
              )
            : null,
      ),
    );
  }

  /// Создаёт ячейку с балансом с улучшенной индикацией
  static DataCell buildBalanceCell(double balance, ThemeData theme) {
    return DataCell(
      BalanceUtils.buildBalanceWidget(
        balance,
        theme,
        showIcon: true,
        showDescription: false,
        textStyle: theme.textTheme.bodyMedium,
      ),
    );
  }

  /// Создаёт ячейку "К выплате" с выделением
  static DataCell buildNetSalaryCell(double netSalary, ThemeData theme) {
    return DataCell(
      Text(
        _numberFormat.format(netSalary),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Создаёт итоговую ячейку с контейнером
  static DataCell buildTotalCell(double amount, ThemeData theme,
      {Color? backgroundColor}) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          amount > 0 ? _numberFormat.format(amount) : '—',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: backgroundColor != null
                ? PayrollTableConstants.payoutColor
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  /// Создаёт итоговую ячейку баланса с улучшенной индикацией
  static DataCell buildTotalBalanceCell(double balance, ThemeData theme) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: BalanceUtils.getBalanceColor(balance, theme)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: BalanceUtils.buildBalanceWidget(
          balance,
          theme,
          showIcon: true,
          showDescription: false,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
