import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../data/repositories/estimate_repository_impl.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/estimate_completion_history.dart';
import '../../../../domain/entities/ks6a_period.dart' as entity;
import '../../../../domain/repositories/estimate_repository.dart';
import '../../../company/presentation/providers/company_providers.dart';

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

/// Модель данных для периода в КС-6а.
class Ks6aPeriodData {
  /// Месяц и год периода.
  final DateTime month;
  
  /// Данные по сметам: estimateId -> {quantity, amount}.
  final Map<String, ({double quantity, double amount})> values;

  const Ks6aPeriodData({required this.month, required this.values});
}

/// Провайдер истории выполнения по всему договору, сгруппированный по периодам.
final contractCompletionByPeriodsProvider = FutureProvider.autoDispose
    .family<List<Ks6aPeriodData>, String>((ref, contractId) async {
  final repository = ref.watch(estimateRepositoryProvider);
  final estimates = await repository.getEstimatesByContract(contractId);
  final history = await repository.getContractCompletionHistory(contractId);
  
  if (history.isEmpty) return [];

  final Map<String, double> priceMap = {
    for (final e in estimates) e.id: e.price
  };

  // Группируем по месяцам
  final Map<DateTime, Map<String, ({double quantity, double amount})>> grouped = {};
  
  for (final row in history) {
    final estimateId = row['estimate_id'] as String;
    final quantity = (row['quantity'] as num).toDouble();
    final date = DateTime.parse(row['works']['date'] as String);
    final monthKey = DateTime(date.year, date.month, 1);
    final price = priceMap[estimateId] ?? 0.0;
    
    grouped.putIfAbsent(monthKey, () => {});
    final periodValues = grouped[monthKey]!;
    
    final current = periodValues[estimateId] ?? (quantity: 0.0, amount: 0.0);
    periodValues[estimateId] = (
      quantity: current.quantity + quantity,
      amount: current.amount + (quantity * price),
    );
  }

  // Сортируем месяцы
  final sortedMonths = grouped.keys.toList()..sort();
  
  // Берем последние 8 месяцев (или сколько есть)
  final lastMonths = sortedMonths.length > 8 
      ? sortedMonths.sublist(sortedMonths.length - 8) 
      : sortedMonths;

  return lastMonths.map((m) => Ks6aPeriodData(
    month: m,
    values: grouped[m]!,
  )).toList();
});

/// Провайдер всех сметных позиций по договору.
/// Используется для левой части таблицы (базовые данные сметы).
final contractEstimatesProvider = FutureProvider.autoDispose
    .family<List<Estimate>, String>((ref, contractId) async {
  final repository = ref.watch(estimateRepositoryProvider);
  return repository.getEstimatesByContract(contractId);
});

/// Провайдер данных Журнала КС-6а (периоды и их выполнение).
/// Возвращает агрегированный объект с периодами и детальными строками.
final ks6aDataProvider = FutureProvider.autoDispose
    .family<entity.Ks6aContractData, String>((ref, contractId) async {
  final repository = ref.watch(estimateRepositoryProvider);
  return repository.getKs6aContractData(contractId);
});

/// Провайдер действий для работы с журналом КС-6а.
/// Позволяет создавать, обновлять и согласовывать периоды.
final ks6aActionsProvider = Provider.autoDispose((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);

  return Ks6aActions(ref, repository, activeCompanyId);
});

/// Класс, инкапсулирующий логику действий над периодами КС-6а.
class Ks6aActions {
  /// Контекст провайдеров для инвалидации кэша.
  final Ref ref;

  /// Репозиторий для выполнения операций в БД.
  final EstimateRepository repository;

  /// Идентификатор активной компании.
  final String? activeCompanyId;

  Ks6aActions(this.ref, this.repository, this.activeCompanyId);

  /// Инициирует создание нового черновика периода за указанный диапазон дат.
  /// 
  /// [contractId] — идентификатор договора.
  /// [startDate], [endDate] — диапазон дат.
  /// [title] — опциональное название периода.
  Future<String> createPeriod({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  }) async {
    if (activeCompanyId == null) throw Exception('Компания не выбрана');
    final id = await repository.createKs6aPeriod(
      contractId: contractId,
      startDate: startDate,
      endDate: endDate,
      title: title,
    );
    ref.invalidate(ks6aDataProvider(contractId));
    return id;
  }

  /// Обновляет данные черновика периода на основе актуальных отчетов о выполнении.
  /// 
  /// [contractId] — для обновления UI.
  /// [periodId] — идентификатор периода для синхронизации.
  Future<void> refreshPeriod(String contractId, String periodId) async {
    await repository.refreshKs6aPeriod(periodId);
    ref.invalidate(ks6aDataProvider(contractId));
  }

  /// Фиксирует (согласовывает) период, делая его неизменяемым.
  /// 
  /// [contractId] — для обновления UI.
  /// [periodId] — идентификатор периода для утверждения.
  Future<void> approvePeriod(String contractId, String periodId) async {
    await repository.approveKs6aPeriod(periodId);
    ref.invalidate(ks6aDataProvider(contractId));
  }
}
