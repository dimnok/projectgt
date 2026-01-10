import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Утилиты для работы с балансом сотрудников
class BalanceUtils {
  static final _numberFormat =
      NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 2);

  /// Получает цвет для отображения баланса
  ///
  /// Логика:
  /// - Положительный баланс (> 0): компания должна сотруднику → зеленый
  /// - Отрицательный баланс (< 0): переплата сотруднику → красный
  /// - Нулевой баланс (= 0): полный расчет → серый
  static Color getBalanceColor(double balance, ThemeData theme) {
    if (balance > 0) {
      // Компания должна сотруднику - зеленый
      return Colors.green.shade600;
    } else if (balance < 0) {
      // Переплата сотруднику - красный
      return Colors.red.shade600;
    } else {
      // Полный расчет - серый
      return theme.colorScheme.outline;
    }
  }

  /// Получает иконку для отображения баланса
  static IconData getBalanceIcon(double balance) {
    if (balance > 0) {
      // Компания должна сотруднику
      return Icons.arrow_upward;
    } else if (balance < 0) {
      // Переплата сотруднику
      return Icons.arrow_downward;
    } else {
      // Полный расчет
      return Icons.check_circle_outline;
    }
  }

  /// Получает текстовое описание состояния баланса
  static String getBalanceDescription(double balance) {
    if (balance > 0) {
      return 'К доплате';
    } else if (balance < 0) {
      return 'Переплата';
    } else {
      return 'Расчет';
    }
  }

  /// Форматирует сумму баланса для отображения
  static String formatBalance(double balance) {
    return _numberFormat.format(balance.abs());
  }

  /// Создает виджет для отображения баланса с иконкой и цветом
  static Widget buildBalanceWidget(
    double balance,
    ThemeData theme, {
    bool showIcon = true,
    bool showDescription = false,
    TextStyle? textStyle,
  }) {
    final color = getBalanceColor(balance, theme);
    final icon = getBalanceIcon(balance);
    final formattedAmount = formatBalance(balance);
    final description = getBalanceDescription(balance);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedAmount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (textStyle ?? const TextStyle()).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showDescription)
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Создает простой текстовый виджет баланса
  static Widget buildSimpleBalanceText(
    double balance,
    ThemeData theme, {
    TextStyle? textStyle,
  }) {
    final color = getBalanceColor(balance, theme);
    final formattedAmount = formatBalance(balance);

    return Text(
      formattedAmount,
      style: (textStyle ?? const TextStyle()).copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
