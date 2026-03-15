import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../data/repositories/estimate_repository_impl.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/estimate_completion_history.dart';
import '../../../../domain/entities/vor.dart';
import '../../../../domain/repositories/estimate_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/vor_export_service.dart';
import '../services/vor_cumulative_export_service.dart';

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
final estimateSidebarVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);

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
final estimateProvider = FutureProvider.autoDispose.family<Estimate?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(estimateRepositoryProvider);
  return repository.getEstimate(id);
});

/// Провайдер всех сметных позиций по договору.
/// Используется для левой части таблицы (базовые данные сметы).
final contractEstimatesProvider = FutureProvider.autoDispose
    .family<List<Estimate>, String>((ref, contractId) async {
      final repository = ref.watch(estimateRepositoryProvider);
      return repository.getEstimatesByContract(contractId);
    });

/// Провайдер уникальных названий систем по договору.
final contractSystemsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, contractId) async {
      final estimates = await ref.watch(
        contractEstimatesProvider(contractId).future,
      );
      return estimates
          .map((e) => e.system)
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    });

/// Модель данных для выполнения ВОР по договору.
class ContractVorCompletionData {
  /// Список сметных позиций.
  final List<Estimate> estimates;

  /// Список ведомостей ВОР (периодов).
  final List<Vor> vors;

  /// Мапа выполнения: estimateId -> { vorId -> quantity }.
  final Map<String, Map<String, double>> completionMap;

  /// Создает экземпляр [ContractVorCompletionData].
  const ContractVorCompletionData({
    required this.estimates,
    required this.vors,
    required this.completionMap,
  });
}

/// Провайдер агрегированных данных о выполнении ВОР по договору.
final contractVorCompletionProvider = FutureProvider.autoDispose
    .family<ContractVorCompletionData, String>((ref, contractId) async {
      // Кэшируем данные на 5 минут после того, как все слушатели отпишутся,
      // чтобы избежать повторной загрузки при переключении таба ВОР.
      final link = ref.keepAlive();
      Timer? timer;
      ref.onDispose(() => timer?.cancel());
      ref.onCancel(() {
        timer = Timer(const Duration(minutes: 5), () {
          link.close();
        });
      });
      ref.onResume(() {
        timer?.cancel();
      });

      final repository = ref.watch(estimateRepositoryProvider);
      final client = ref.watch(supabaseClientProvider);

      // 1. Загружаем сметы и ВОРы параллельно
      final results = await Future.wait([
        repository.getEstimatesByContract(contractId),
        repository.getVors(contractId),
      ]);

      final estimates = results[0] as List<Estimate>;
      final vors = results[1] as List<Vor>;

      // Сортируем ВОРы по дате начала (startDate), чтобы они шли последовательно
      vors.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (vors.isEmpty) {
        return ContractVorCompletionData(
          estimates: estimates,
          vors: [],
          completionMap: {},
        );
      }

      // 2. Загружаем все vor_items для этих ВОР
      final vorIds = vors.map((v) => v.id).toList();
      final vorItemsResponse = await client
          .from('vor_items')
          .select('estimate_item_id, vor_id, quantity')
          .filter('vor_id', 'in', vorIds);

      final Map<String, Map<String, double>> completionMap = {};

      for (final item in vorItemsResponse) {
        final estimateId = item['estimate_item_id'] as String;
        final vorId = item['vor_id'] as String;
        final quantity = (item['quantity'] as num).toDouble();

        completionMap.putIfAbsent(estimateId, () => {});
        final currentQty = completionMap[estimateId]![vorId] ?? 0.0;
        completionMap[estimateId]![vorId] = currentQty + quantity;
      }

      return ContractVorCompletionData(
        estimates: estimates,
        vors: vors,
        completionMap: completionMap,
      );
    });

/// Провайдер списка ВОР по договору.
final vorsProvider = FutureProvider.autoDispose.family<List<Vor>, String>((
  ref,
  contractId,
) async {
  final repository = ref.watch(estimateRepositoryProvider);
  return repository.getVors(contractId);
});

/// Провайдер действий для работы с ВОР.
final vorActionsProvider = Provider.autoDispose((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  return VorActions(ref, repository);
});

/// Провайдер сервиса экспорта ВОР.
final vorExportServiceProvider = Provider.autoDispose((ref) {
  final client = Supabase.instance.client;
  return VorExportService(client);
});

/// Провайдер сервиса накопительного экспорта ВОР.
final vorCumulativeExportServiceProvider = Provider.autoDispose((ref) {
  final client = Supabase.instance.client;
  return VorCumulativeExportService(client);
});

/// Класс, инкапсулирующий логику действий над ВОР.
class VorActions {
  /// Контекст провайдеров.
  final Ref ref;

  /// Репозиторий смет.
  final EstimateRepository repository;

  /// Создает экземпляр [VorActions].
  VorActions(this.ref, this.repository);

  /// Создает новую ведомость ВОР.
  Future<String> createVor({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> systems,
  }) async {
    final id = await repository.createVor(
      contractId: contractId,
      startDate: startDate,
      endDate: endDate,
      systems: systems,
    );

    // Сразу наполняем ВОР данными из журналов работ
    await repository.populateVorItems(id);

    ref.invalidate(vorsProvider(contractId));
    ref.invalidate(contractVorCompletionProvider(contractId));
    return id;
  }

  /// Обновляет статус ВОР.
  Future<void> updateStatus(
    String contractId,
    String vorId,
    VorStatus status, {
    String? comment,
  }) async {
    await repository.updateVorStatus(vorId, status, comment: comment);
    ref.invalidate(vorsProvider(contractId));
    ref.invalidate(contractVorCompletionProvider(contractId));
  }

  /// Удаляет ВОР.
  Future<void> deleteVor(String contractId, String vorId) async {
    try {
      // 1. Сначала получаем путь к файлу, чтобы удалить его из Storage
      final vorData = await ref
          .read(supabaseClientProvider)
          .from('vors')
          .select('excel_url, pdf_url')
          .eq('id', vorId)
          .maybeSingle();

      final String? excelUrl = vorData?['excel_url'];
      final String? pdfUrl = vorData?['pdf_url'];

      // 2. Удаляем запись из БД (каскадное удаление должно быть настроено в БД)
      await repository.deleteVor(vorId);

      // 3. Если файлы были в Storage, удаляем их
      final filesToDelete = <String>[
        if (excelUrl != null && excelUrl.isNotEmpty) excelUrl,
        if (pdfUrl != null && pdfUrl.isNotEmpty) pdfUrl,
      ];

      if (filesToDelete.isNotEmpty) {
        debugPrint(
          '🗑️ [VorActions] Удаление файлов ВОР из Storage: $filesToDelete',
        );
        await ref
            .read(supabaseClientProvider)
            .storage
            .from('vor_documents')
            .remove(filesToDelete);
      }

      ref.invalidate(vorsProvider(contractId));
      ref.invalidate(contractVorCompletionProvider(contractId));
    } catch (e) {
      debugPrint('❌ [VorActions] Ошибка при удалении ВОР: $e');
      rethrow;
    }
  }

  /// Загружает подписанный PDF-файл для уже подписанной ведомости ВОР.
  Future<void> uploadPdf({
    required String contractId,
    required String vorId,
    required File file,
    required String fileName,
  }) async {
    await repository.uploadVorPdf(vorId: vorId, file: file, fileName: fileName);

    ref.invalidate(vorsProvider(contractId));
  }

  /// Возвращает временную ссылку для просмотра подписанного PDF-файла ВОР.
  Future<String> getVorPdfViewUrl(String vorId) {
    return repository.getVorPdfViewUrl(vorId);
  }
}
