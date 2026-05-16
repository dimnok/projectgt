import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/home/domain/entities/ai_contract_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Состояние для хранения выбранного ID договора для ИИ-анализа.
/// Если null, анализируется последний активный договор по умолчанию.
final selectedAiContractIdProvider = StateProvider<String?>((ref) => null);

/// Провайдер, вызывающий Edge Function `analyze-contract-plan`.
final aiContractPlanProvider = FutureProvider<AiContractPlan?>((ref) async {
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  final contractId = ref.watch(selectedAiContractIdProvider);

  if (activeCompanyId == null) {
    return null; // Нет активной компании
  }

  final client = Supabase.instance.client;

  try {
    final body = <String, dynamic>{'company_id': activeCompanyId};

    if (contractId != null) {
      body['contract_id'] = contractId;
    }

    final response = await client.functions.invoke(
      'analyze-contract-plan',
      body: body,
    );

    if (response.status != 200) {
      throw Exception('Ошибка вызова функции: ${response.status}');
    }

    final Map<String, dynamic> data = response.data;

    // Если вернулась ошибка внутри JSON (например, нет активных договоров)
    if (data.containsKey('error')) {
      // Можно выбросить ошибку или вернуть null
      return null;
    }

    return AiContractPlan.fromJson(data);
  } catch (e) {
    throw Exception('Не удалось загрузить ИИ план: $e');
  }
});
