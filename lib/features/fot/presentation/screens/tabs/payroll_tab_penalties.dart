import 'package:flutter/material.dart';
import '../../widgets/payroll_penalty_table_widget.dart';

/// Таб «Штрафы» в модуле ФОТ.
class PayrollTabPenalties extends StatelessWidget {
  /// Создаёт вкладку штрафов.
  const PayrollTabPenalties({super.key});

  @override
  Widget build(BuildContext context) {
    return const PayrollPenaltyTableWidget();
  }
}
