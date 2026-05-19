import 'package:flutter/material.dart';
import '../../widgets/payroll_bonus_table_widget.dart';

/// Таб «Премии» в модуле ФОТ.
class PayrollTabBonuses extends StatelessWidget {
  /// Создаёт вкладку премий.
  const PayrollTabBonuses({super.key});

  @override
  Widget build(BuildContext context) {
    return const PayrollBonusTableWidget();
  }
}
