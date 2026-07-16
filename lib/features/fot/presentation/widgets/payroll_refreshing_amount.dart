import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Компактный индикатор вместо суммы при фоновом пересчёте ФОТ.
class PayrollRefreshingAmount extends StatelessWidget {
  /// Показывать спиннер вместо [child].
  final bool isRefreshing;

  /// Содержимое ячейки при готовых данных.
  final Widget child;

  /// Диаметр спиннера.
  final double size;

  /// Создаёт слот суммы с опциональным индикатором загрузки.
  const PayrollRefreshingAmount({
    super.key,
    required this.isRefreshing,
    required this.child,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRefreshing) return child;

    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.65);
    return SizedBox(
      width: size,
      height: size,
      child: CupertinoActivityIndicator(color: color),
    );
  }
}
