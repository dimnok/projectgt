import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/ks2/domain/repositories/ks2_repository.dart';
import 'package:projectgt/features/ks2/data/repositories/ks2_repository_impl.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

part 'ks2_providers.g.dart';

/// Провайдер репозитория КС-2.
final ks2RepositoryProvider = Provider<Ks2Repository>((ref) {
  final client = Supabase.instance.client;
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return Ks2RepositoryImpl(client, activeCompanyId ?? '');
});

/// Провайдер списка актов для конкретного договора.
@riverpod
class Ks2Acts extends _$Ks2Acts {
  @override
  Future<List<Ks2Act>> build(String contractId) async {
    final repository = ref.watch(ks2RepositoryProvider);
    return repository.getActs(contractId);
  }

  /// Удаление акта с обновлением списка.
  Future<void> deleteAct(String actId) async {
    final repository = ref.read(ks2RepositoryProvider);
    await repository.deleteAct(actId);
    // Инвалидируем провайдер, чтобы перезагрузить список
    ref.invalidateSelf();
  }
}

/// Состояние экрана создания КС-2.
@riverpod
class Ks2Creation extends _$Ks2Creation {
  @override
  FutureOr<Ks2PreviewData?> build() {
    return null; // Изначально данных нет
  }

  /// Загрузка предварительных данных (Preview).
  Future<void> loadPreview({
    required String contractId,
    required DateTime periodTo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(ks2RepositoryProvider);
      final data = await repository.previewAct(
        contractId: contractId,
        periodTo: periodTo,
      );
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Создание акта.
  Future<void> createAct({
    required String contractId,
    required DateTime periodTo,
    required String number,
    required DateTime date,
  }) async {
    final repository = ref.read(ks2RepositoryProvider);
    await repository.createAct(
      contractId: contractId,
      periodTo: periodTo,
      number: number,
      date: date,
    );
    // После успешного создания можно сбросить состояние
    state = const AsyncValue.data(null);
  }
}
