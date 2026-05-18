import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/data/models/vor_model.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/domain/entities/vor.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/ks2/data/repositories/ks2_repository_impl.dart';
import 'package:projectgt/features/ks2/domain/repositories/ks2_repository.dart';

part 'contract_ks2_providers.g.dart';

/// Репозиторий актов КС-2 в контексте модуля «Договоры» (без UI модуля «Сметы»).
final contractKs2RepositoryProvider = Provider<Ks2Repository>((ref) {
  final client = Supabase.instance.client;
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return Ks2RepositoryImpl(client, activeCompanyId ?? '');
});

/// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
///
/// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
@riverpod
Future<List<Vor>> contractKs2ApprovedVors(
  Ref ref,
  String contractId,
) async {
  final client = ref.watch(supabaseClientProvider);
  final companyId = ref.watch(activeCompanyIdProvider);
  if (companyId == null || companyId.isEmpty) {
    return [];
  }
  final rows = await client
      .from('vors')
      .select(
        'id, company_id, contract_id, number, start_date, end_date, status, '
        'excel_url, excel_combined_url, pdf_url, created_at, created_by, include_combined_sheet',
      )
      .eq('contract_id', contractId)
      .eq('company_id', companyId)
      .eq('status', 'approved')
      .order('start_date');

  return (rows as List<dynamic>)
      .map(
        (e) => VorModel.fromJson(
          Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
        ).toDomain(),
      )
      .toList();
}

/// Список актов КС-2 по договору (модуль «Договоры»).
@riverpod
class ContractKs2Acts extends _$ContractKs2Acts {
  @override
  Future<List<Ks2Act>> build(String contractId) async {
    final repository = ref.watch(contractKs2RepositoryProvider);
    return repository.getActs(contractId);
  }

  /// Удаление акта с обновлением списка.
  Future<void> deleteAct(String actId) async {
    final repository = ref.read(contractKs2RepositoryProvider);
    await repository.deleteAct(actId);
    ref.invalidateSelf();
    ref.invalidate(contractKs2ApprovedVorsProvider(contractId));
  }
}

/// Состояние формы создания акта КС-2 по ВОР (модуль «Договоры»).
@riverpod
class ContractKs2Creation extends _$ContractKs2Creation {
  @override
  FutureOr<Ks2PreviewData?> build() => null;

  /// Предпросмотр состава акта по выбранной ВОР.
  Future<void> loadPreview({
    required String contractId,
    required String vorId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(contractKs2RepositoryProvider);
      final data = await repository.previewAct(
        contractId: contractId,
        vorId: vorId,
      );
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Создание акта КС-2.
  Future<void> createAct({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime date,
  }) async {
    final repository = ref.read(contractKs2RepositoryProvider);
    await repository.createAct(
      contractId: contractId,
      vorId: vorId,
      number: number,
      date: date,
    );
    state = const AsyncValue.data(null);
  }
}
