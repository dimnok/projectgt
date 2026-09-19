import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/fot/data/models/payroll_bonus_model.dart';
import 'package:projectgt/features/fot/presentation/providers/bonus_providers.dart';
import 'package:projectgt/features/fot/presentation/providers/payroll_providers.dart';
import 'package:uuid/uuid.dart';

/// Параметры пакетного создания премий.
class PayrollBonusBatchParams {
  /// Создаёт параметры премии.
  const PayrollBonusBatchParams({
    required this.date,
    required this.objectId,
    this.reason,
  });

  /// Дата премии.
  final DateTime date;

  /// Идентификатор объекта.
  final String objectId;

  /// Примечание.
  final String? reason;
}

/// Создаёт премии пакетом и обновляет связанные провайдеры.
Future<int> savePayrollBonusBatch({
  required WidgetRef ref,
  required PayrollBonusBatchParams params,
  required List<({String employeeId, double amount})> entries,
}) async {
  if (entries.isEmpty) return 0;

  final activeCompanyId = ref.read(activeCompanyIdProvider);
  if (activeCompanyId == null) {
    throw Exception('Компания не выбрана');
  }

  final createUseCase = ref.read(createBonusUseCaseProvider);
  final reason = params.reason?.trim();
  var created = 0;

  for (final entry in entries) {
    if (entry.amount <= 0) continue;
    final bonus = PayrollBonusModel(
      id: const Uuid().v4(),
      employeeId: entry.employeeId,
      companyId: activeCompanyId,
      type: 'manual',
      amount: entry.amount,
      reason: reason == null || reason.isEmpty ? null : reason,
      date: params.date,
      createdAt: DateTime.now(),
      objectId: params.objectId,
    );
    await createUseCase(bonus);
    created++;
  }

  ref.invalidate(bonusesByFilterProvider);
  invalidatePayrollFotTableDependents(ref);

  return created;
}
