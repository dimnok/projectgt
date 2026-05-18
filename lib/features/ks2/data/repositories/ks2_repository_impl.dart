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
        .select('*, vors(number)')
        .eq('contract_id', contractId)
        .eq('company_id', _activeCompanyId)
        .order('date', ascending: false);

    return (response as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map<String, dynamic>);
      final nested = row.remove('vors');
      String? vorNumber;
      if (nested is Map<String, dynamic> && nested['number'] != null) {
        vorNumber = nested['number'].toString();
      }
      final model = Ks2ActModel.fromJson(row);
      return model.toDomain().copyWith(vorNumber: vorNumber);
    }).toList();
  }

  @override
  Future<Ks2PreviewData> previewAct({
    required String contractId,
    required String vorId,
  }) async {
    final response = await _supabase.functions.invoke(
      'ks2_operations',
      body: {
        'action': 'preview',
        'contractId': contractId,
        'companyId': _activeCompanyId,
        'vorId': vorId,
      },
    );

    if (response.status != 200) {
      final d = response.data;
      if (d is Map && d['error'] != null) {
        throw Exception(d['error'].toString());
      }
      throw Exception('Не удалось получить превью КС-2: ${response.data}');
    }

    return Ks2PreviewData.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> createAct({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime date,
  }) async {
    final response = await _supabase.functions.invoke(
      'ks2_operations',
      body: {
        'action': 'create',
        'contractId': contractId,
        'companyId': _activeCompanyId,
        'vorId': vorId,
        'actNumber': number,
        'actDate': date.toIso8601String(),
      },
    );

    if (response.status != 200) {
      final d = response.data;
      if (d is Map && d['error'] != null) {
        throw Exception(d['error'].toString());
      }
      throw Exception('Не удалось создать КС-2: ${response.data}');
    }
  }

  @override
  Future<void> deleteAct(String actId) async {
    await _supabase
        .from('work_items')
        .update({'ks2_id': null})
        .eq('ks2_id', actId)
        .eq('company_id', _activeCompanyId);

    await _supabase
        .from('ks2_acts')
        .delete()
        .eq('id', actId)
        .eq('company_id', _activeCompanyId);
  }
}
