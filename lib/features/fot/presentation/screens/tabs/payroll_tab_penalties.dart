import 'package:flutter/material.dart';
import '../../widgets/payroll_penalty_table_widget.dart';
import '../../widgets/payroll_penalty_form_modal.dart';

class PayrollTabPenalties extends StatelessWidget {
  const PayrollTabPenalties({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 51),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              const PayrollPenaltyTableWidget(),
              Positioned(
                right: 8,
                bottom: 8,
                child: FloatingActionButton(
                  heroTag: 'addPayrollPenalty',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                      ),
                      builder: (ctx) => const PayrollPenaltyFormModal(),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 