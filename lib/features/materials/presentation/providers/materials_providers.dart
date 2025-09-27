import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/materials_repository.dart';
import '../../data/models/material_item.dart';
import '../../../../core/di/providers.dart';

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
  final contractNumber = ref.watch(selectedContractNumberProvider);
  return repo.fetchAll(contractNumber: contractNumber);
});

/// Провайдер списка номеров договоров (из таблицы materials)
final materialsContractNumbersProvider =
    FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(materialsRepositoryProvider);
  return repo.fetchDistinctContractNumbers();
});
