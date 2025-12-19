import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../data/repositories/estimate_repository_impl.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/estimate_completion_history.dart';

// --- Модели для UI ---

/// Класс, представляющий сгруппированный файл сметы.
class EstimateFile {
  final String estimateTitle;
  final String? objectId;
  final String? contractId;
  final String? contractNumber;
  final double total;
  final int itemsCount;
  final List<Estimate> items;

  const EstimateFile({
    required this.estimateTitle,
    required this.objectId,
    required this.contractId,
    this.contractNumber,
    this.total = 0.0,
    this.itemsCount = 0,
    this.items = const [],
  });
}

// --- Провайдеры ---

/// 1. Провайдер групп смет (для списков и Sidebar)
/// Использует SQL функцию get_estimate_groups для быстрой загрузки
final estimateGroupsProvider =
    FutureProvider.autoDispose<List<EstimateFile>>((ref) async {
  final repository = ref.watch(estimateRepositoryProvider);
  if (repository is EstimateRepositoryImpl) {
    final rawGroups = await repository.getEstimateGroups();
    return rawGroups.map((g) {
      return EstimateFile(
        estimateTitle: g['estimate_title'] as String,
        objectId: g['object_id'] as String?,
        contractId: g['contract_id'] as String?,
        contractNumber: g['contract_number'] as String?,
        total: (g['total_amount'] as num).toDouble(),
        itemsCount: (g['items_count'] as int?) ?? 0,
        items: [], // Items загружаются отдельно при открытии
      );
    }).toList();
  }
  return [];
});

/// 2. Аргументы для загрузки деталей сметы
class EstimateDetailArgs {
  final String estimateTitle;
  final String? objectId;
  final String? contractId;

  const EstimateDetailArgs({
    required this.estimateTitle,
    this.objectId,
    this.contractId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateDetailArgs &&
          runtimeType == other.runtimeType &&
          estimateTitle == other.estimateTitle &&
          objectId == other.objectId &&
          contractId == other.contractId;

  @override
  int get hashCode =>
      estimateTitle.hashCode ^ objectId.hashCode ^ contractId.hashCode;
}

/// 3. Провайдер элементов конкретной сметы (Detail)
/// Загружает только элементы выбранной сметы
final estimateItemsProvider = FutureProvider.autoDispose
    .family<List<Estimate>, EstimateDetailArgs>((ref, args) async {
  final repository = ref.watch(estimateRepositoryProvider);
  if (repository is EstimateRepositoryImpl) {
    return repository.getEstimatesByFile(
      estimateTitle: args.estimateTitle,
      objectId: args.objectId,
      contractId: args.contractId,
    );
  }
  return [];
});

/// 4. Обертка для списка ID с корректным сравнением (чтобы избежать лишних ребилдов)
class EstimateIds {
  final List<String> ids;
  const EstimateIds(this.ids);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateIds && const ListEquality().equals(ids, other.ids);

  @override
  int get hashCode => const ListEquality().hash(ids);
}

/// 5. Провайдер выполнения для конкретных элементов
/// Загружает данные о выполнении только для переданных ID
final estimateCompletionByIdsProvider = FutureProvider.autoDispose
    .family<List<EstimateCompletionModel>, EstimateIds>((ref, args) async {
  final repository = ref.watch(estimateRepositoryProvider);
  if (repository is EstimateRepositoryImpl) {
    return repository.getEstimateCompletionByIds(args.ids);
  }
  return [];
});

/// 6. Провайдер истории выполнения конкретной позиции
final estimateCompletionHistoryProvider = FutureProvider.autoDispose
    .family<List<EstimateCompletionHistory>, String>((ref, estimateId) async {
  final repository = ref.watch(estimateRepositoryProvider);
  return repository.getEstimateCompletionHistory(estimateId);
});

