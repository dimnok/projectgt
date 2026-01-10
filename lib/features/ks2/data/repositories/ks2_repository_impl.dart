import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/ks2/domain/repositories/ks2_repository.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/data/models/ks2_act_model.dart';

/// Реализация репозитория для работы с актами КС-2 через Supabase.
class Ks2RepositoryImpl implements Ks2Repository {
  final SupabaseClient _supabase;
  final String _activeCompanyId;

  /// Создает экземпляр репозитория.
  Ks2RepositoryImpl(this._supabase, this._activeCompanyId);

  @override
  Future<List<Ks2Act>> getActs(String contractId) async {
    final response = await _supabase
        .from('ks2_acts')
        .select()
        .eq('contract_id', contractId)
        .eq('company_id', _activeCompanyId)
        .order('date', ascending: false); // Свежие сверху

    return (response as List)
        .map((json) => Ks2ActModel.fromJson(json).toDomain())
        .toList();
  }

  @override
  Future<Ks2PreviewData> previewAct({
    required String contractId,
    required DateTime periodTo,
  }) async {
    final response = await _supabase.functions.invoke(
      'ks2_operations',
      body: {
        'action': 'preview',
        'contractId': contractId,
        'companyId': _activeCompanyId,
        'periodTo': periodTo.toIso8601String(),
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to preview KS-2: ${response.data}');
    }

    return Ks2PreviewData.fromJson(response.data);
  }

  @override
  Future<void> createAct({
    required String contractId,
    required DateTime periodTo,
    required String number,
    required DateTime date,
  }) async {
    final response = await _supabase.functions.invoke(
      'ks2_operations',
      body: {
        'action': 'create',
        'contractId': contractId,
        'companyId': _activeCompanyId,
        'periodTo': periodTo.toIso8601String(),
        'actNumber': number,
        'actDate': date.toIso8601String(),
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to create KS-2: ${response.data}');
    }
  }

  @override
  Future<void> deleteAct(String actId) async {
    // 1. Сначала отвязываем работы (возвращаем их в пул доступных)
    await _supabase
        .from('work_items')
        .update({'ks2_id': null})
        .eq('ks2_id', actId)
        .eq('company_id', _activeCompanyId);

    // 2. Затем удаляем сам акт
    await _supabase
        .from('ks2_acts')
        .delete()
        .eq('id', actId)
        .eq('company_id', _activeCompanyId);
  }
}
