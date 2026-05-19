import 'package:flutter/material.dart';
import '../../widgets/payroll_payout_table_widget.dart';

/// Таб «Выплаты» в модуле ФОТ.
class PayrollTabPayouts extends StatelessWidget {
  /// Создаёт вкладку выплат.
  const PayrollTabPayouts({super.key});

  @override
  Widget build(BuildContext context) {
    return const PayrollPayoutTableWidget();
  }
}
