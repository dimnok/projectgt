import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/fot/data/models/payroll_payout_model.dart';
import 'package:projectgt/features/fot/presentation/providers/balance_providers.dart';
import 'package:projectgt/features/fot/presentation/providers/payroll_providers.dart';
import 'package:uuid/uuid.dart';

/// Параметры пакетного создания выплат.
class PayrollPayoutBatchParams {
  /// Создаёт параметры выплаты.
  const PayrollPayoutBatchParams({
    required this.payoutDate,
    required this.method,
    required this.type,
    this.comment,
  });

  /// Дата выплаты.
  final DateTime payoutDate;

  /// Способ выплаты (`card`, `cash`, `bank_transfer`).
  final String method;

  /// Тип (`salary`, `advance`).
  final String type;

  /// Комментарий.
  final String? comment;
}

/// Создаёт выплаты пакетом и обновляет связанные провайдеры.
Future<int> savePayrollPayoutBatch({
  required WidgetRef ref,
  required PayrollPayoutBatchParams params,
  required List<({String employeeId, double amount})> entries,
}) async {
  if (entries.isEmpty) return 0;

  final activeCompanyId = ref.read(activeCompanyIdProvider);
  if (activeCompanyId == null) {
    throw Exception('Компания не выбрана');
  }

  final createUseCase = ref.read(createPayoutUseCaseProvider);
  final comment = params.comment?.trim();
  var created = 0;

  for (final entry in entries) {
    if (entry.amount <= 0) continue;
    final payout = PayrollPayoutModel(
      id: const Uuid().v4(),
      employeeId: entry.employeeId,
      companyId: activeCompanyId,
      amount: entry.amount,
      payoutDate: params.payoutDate,
      method: params.method,
      type: params.type,
      createdAt: DateTime.now(),
      comment: comment == null || comment.isEmpty ? null : comment,
    );
    await createUseCase(payout);
    created++;
  }

  ref.invalidate(filteredPayrollPayoutsProvider);
  ref.invalidate(employeeAggregatedBalanceProvider);
  ref.invalidate(payrollPayoutsByFilterProvider);

  return created;
}
