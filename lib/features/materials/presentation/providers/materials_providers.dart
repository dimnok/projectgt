import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/materials_repository.dart';
import '../../data/models/material_item.dart';
import '../../data/models/grouped_material_item.dart';
import '../../data/models/material_binding_model.dart';
import '../../../../core/di/providers.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';

/// Режим отображения материалов: М-15 или Сопоставление.
enum MaterialsViewMode {
  /// Таблица "Материал по М-15"
  m15,

  /// Таблица "Сопоставление материалов"
  mapping
}

/// Провайдер текущего режима отображения в модуле материалов.
final materialsViewModeProvider =
    StateProvider<MaterialsViewMode>((ref) => MaterialsViewMode.m15);

/// Провайдер режима группировки по смете (для режима M15)
final isMaterialsGroupedProvider = StateProvider<bool>((ref) => false);

/// Провайдер репозитория материалов
final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MaterialsRepository(client);
});

/// Выбранный номер договора для фильтрации материалов
final selectedContractNumberProvider = StateProvider<String?>((ref) => null);

/// Провайдер списка материалов с учётом выбранного договора
final materialsListProvider = FutureProvider<List<MaterialItem>>((ref) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  final contractNumber = ref.watch(selectedContractNumberProvider);
  return repo.fetchAll(
    companyId: activeId,
    contractNumber: contractNumber,
  );
});

/// Провайдер сгруппированных материалов
final materialsGroupedListProvider =
    FutureProvider<List<GroupedMaterialItem>>((ref) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  final contractNumber = ref.watch(selectedContractNumberProvider);
  return repo.fetchGrouped(
    companyId: activeId,
    contractNumber: contractNumber,
  );
});

/// Провайдер списка номеров договоров (из таблицы materials)
final materialsContractNumbersProvider =
    FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  return repo.fetchDistinctContractNumbers(companyId: activeId);
});

/// Фильтры по колонкам для таблицы материалов
final materialsColumnFiltersProvider =
    StateProvider<Map<String, String>>((ref) => {});

/// Провайдер уникальных названий материалов из накладных.
final uniqueMaterialNamesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, contractNumber) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  return repo.fetchUniqueMaterialNames(
    companyId: activeId,
    contractNumber: contractNumber,
  );
});

/// Провайдер материалов со статусом привязки.
final materialBindingListProvider = FutureProvider.autoDispose
    .family<List<MaterialBindingModel>, ({String? contractNumber, String estimateId})>(
        (ref, arg) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null || arg.contractNumber == null) return [];

  return repo.fetchMaterialsWithBindingStatus(
    companyId: activeId,
    contractNumber: arg.contractNumber!,
    currentEstimateId: arg.estimateId,
  );
});

/// Провайдер материалов, привязанных к конкретной сметной позиции.
final linkedMaterialsProvider = FutureProvider.autoDispose
    .family<List<MaterialItem>, String>((ref, estimateId) async {
  final repo = ref.watch(materialsRepositoryProvider);
  final activeId = ref.watch(activeCompanyIdProvider);
  if (activeId == null) return [];

  return repo.fetchLinkedMaterials(
    estimateId: estimateId,
    companyId: activeId,
  );
});
