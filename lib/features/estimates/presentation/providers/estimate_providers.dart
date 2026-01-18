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
  /// Заголовок сметы.
  final String estimateTitle;

  /// Идентификатор объекта.
  final String? objectId;

  /// Идентификатор контракта.
  final String? contractId;

  /// Номер контракта.
  final String? contractNumber;

  /// Общая сумма по смете.
  final double total;

  /// Количество позиций в смете.
  final int itemsCount;

  /// Список элементов сметы.
  final List<Estimate> items;

  /// Создает экземпляр [EstimateFile].
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

/// Провайдер групп смет (для списков и Sidebar).
/// Использует SQL функцию get_estimate_groups для быстрой загрузки.
final estimateGroupsProvider = FutureProvider.autoDispose<List<EstimateFile>>((
  ref,
) async {
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

/// Провайдер сгруппированных смет для десктопного Sidebar.
/// Группирует по объекту и по договору.
final groupedEstimateFilesProvider =
    Provider.autoDispose<
      AsyncValue<Map<String, Map<String, List<EstimateFile>>>>
    >((ref) {
      final groupsAsync = ref.watch(estimateGroupsProvider);
      final objects = ref.watch(objectProvider).objects;

      return groupsAsync.whenData((estimateFiles) {
        final Map<String, Map<String, List<EstimateFile>>> grouped = {};

        for (final file in estimateFiles) {
          final object = objects.firstWhereOrNull((o) => o.id == file.objectId);
          final objectName = object?.name ?? 'Без объекта';
          final contractNumber = file.contractNumber ?? 'Без договора';

          grouped.putIfAbsent(objectName, () => {});
          grouped[objectName]!.putIfAbsent(contractNumber, () => []);
          grouped[objectName]![contractNumber]!.add(file);
        }

      return grouped;
    });
  });

/// Провайдер состояния видимости боковой панели (Sidebar) в десктопной версии.
final estimateSidebarVisibleProvider = StateProvider.autoDispose<bool>((ref) => true);

/// Аргументы для загрузки деталей сметы.
class EstimateDetailArgs {
  /// Заголовок сметы.
  final String estimateTitle;

  /// Идентификатор объекта.
  final String? objectId;

  /// Идентификатор контракта.
  final String? contractId;

  /// Создает экземпляр [EstimateDetailArgs].
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

/// Провайдер элементов конкретной сметы (Detail).
/// Загружает только элементы выбранной сметы.
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

/// Обертка для списка ID с корректным сравнением (чтобы избежать лишних ребилдов).
class EstimateIds {
  /// Список идентификаторов смет.
  final List<String> ids;

  /// Создает экземпляр [EstimateIds].
  const EstimateIds(this.ids);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateIds && const ListEquality().equals(ids, other.ids);

  @override
  int get hashCode => const ListEquality().hash(ids);
}

/// Провайдер выполнения для конкретных элементов.
/// Загружает данные о выполнении только для переданных ID.
final estimateCompletionByIdsProvider = FutureProvider.autoDispose
    .family<List<EstimateCompletionModel>, EstimateIds>((ref, args) async {
      final repository = ref.watch(estimateRepositoryProvider);
      if (repository is EstimateRepositoryImpl) {
        return repository.getEstimateCompletionByIds(args.ids);
      }
      return [];
    });

/// Провайдер истории выполнения конкретной позиции.
final estimateCompletionHistoryProvider = FutureProvider.autoDispose
    .family<List<EstimateCompletionHistory>, String>((ref, estimateId) async {
      final repository = ref.watch(estimateRepositoryProvider);
      return repository.getEstimateCompletionHistory(estimateId);
    });

/// Провайдер конкретной сметной позиции.
final estimateProvider = FutureProvider.autoDispose
    .family<Estimate?, String>((ref, id) async {
  final repository = ref.watch(estimateRepositoryProvider);
  return repository.getEstimate(id);
});
