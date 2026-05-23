import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/data/models/vor_model.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_ks2_preview.dart';
import 'package:projectgt/domain/entities/vor.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';

part 'contract_act_ks2_providers.g.dart';

/// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
@riverpod
Future<List<Vor>> contractActApprovedVors(
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

  final vors = (rows as List<dynamic>)
      .map(
        (e) => VorModel.fromJson(
          Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
        ).toDomain(),
      )
      .toList();

  final acts = await ref.watch(contractActsProvider(contractId).future);
  final usedVorIds = acts
      .where((a) => a.isKs2 && a.vorId != null)
      .map((a) => a.vorId!)
      .toSet();

  return vors.where((v) => !usedVorIds.contains(v.id)).toList();
}

/// Предпросмотр состава КС-2 по выбранной ВОР.
@riverpod
class ContractActKs2PreviewNotifier extends _$ContractActKs2PreviewNotifier {
  @override
  FutureOr<ContractActKs2Preview?> build() => null;

  /// Загружает превью по [contractId] и [vorId].
  Future<void> loadPreview({
    required String contractId,
    required String vorId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(contractActRepositoryProvider);
      return repository.previewKs2(contractId: contractId, vorId: vorId);
    });
  }

  /// Сбрасывает состояние превью.
  void reset() {
    state = const AsyncValue.data(null);
  }
}
