import 'package:projectgt/features/tmc/domain/entities/tmc_assignment.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_condition.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_dashboard_stats.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_inventory.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_notification.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_repair.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_stock_balance.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_write_off.dart';

/// Результат пагинированного списка позиций ТМЦ.
typedef TmcItemsListResult = ({List<TmcItem> items, int totalCount});

/// Контракт репозитория модуля ТМЦ.
abstract class TmcRepository {
  /// KPI дашборда компании.
  Future<TmcDashboardStats> getDashboardStats();

  /// Пагинированный реестр позиций каталога.
  Future<TmcItemsListResult> listItems({
    String? search,
    String? categoryId,
    TmcAccountingType? accountingType,
    int limit = 50,
    int offset = 0,
  });

  /// Позиция каталога по id.
  Future<TmcItem?> getItem(String id);

  /// Создать позицию каталога.
  Future<TmcItem> createItem(TmcItem item);

  /// Создать позицию каталога и (опционально) принять на склад одной транзакцией.
  /// Если [receiveQuantity] <= 0 или [warehouseId] пустой — только создаёт позицию.
  /// Возвращает созданную позицию; операция поступления проводится через RPC.
  Future<TmcItem> createItemWithReceipt({
    required TmcItem item,
    double receiveQuantity,
    String? warehouseId,
    double? unitPrice,
    String? conditionId,
  });

  /// Обновить позицию каталога.
  Future<TmcItem> updateItem(TmcItem item);

  /// Архивировать позицию каталога.
  Future<void> archiveItem(String id);

  /// Список единиц. [itemId] и/или [status] — опциональные фильтры.
  Future<List<TmcUnit>> listUnits({String? itemId, String? status});

  /// Единица по id.
  Future<TmcUnit?> getUnit(String id);

  /// Список категорий.
  Future<List<TmcCategory>> listCategories();

  /// Создать категорию.
  Future<TmcCategory> createCategory(TmcCategory category);

  /// Обновить категорию.
  Future<TmcCategory> updateCategory(TmcCategory category);

  /// Архивировать категорию.
  Future<void> archiveCategory(String id);

  /// Список состояний.
  Future<List<TmcCondition>> listConditions();

  /// Список складов.
  Future<List<TmcWarehouse>> listWarehouses();

  /// Остатки на складах (количественные + индивидуальные единицы).
  Future<List<TmcStockBalance>> listStock({
    String? warehouseId,
    String? search,
  });

  /// Создать склад.
  Future<TmcWarehouse> createWarehouse(TmcWarehouse warehouse);

  /// Обновить склад.
  Future<TmcWarehouse> updateWarehouse(TmcWarehouse warehouse);

  /// Список операций.
  Future<List<TmcOperation>> listOperations({
    TmcOperationType? operationType,
    String? itemId,
    int limit = 50,
    int offset = 0,
  });

  /// Операция по id со строками.
  Future<TmcOperation?> getOperation(String id);

  /// Провести операцию через RPC [tmc_post_operation].
  Future<TmcOperation> postOperation(Map<String, dynamic> payload);

  /// Активные и завершённые выдачи; при [employeeId] — только сотрудника.
  Future<List<TmcAssignment>> listAssignments({String? employeeId});

  /// Список ремонтов.
  Future<List<TmcRepair>> listRepairs({int limit = 50, int offset = 0});

  /// Список списаний.
  Future<List<TmcWriteOff>> listWriteOffs({int limit = 50, int offset = 0});

  /// Список инвентаризаций.
  Future<List<TmcInventory>> listInventories({int limit = 50, int offset = 0});

  /// Создать инвентаризацию.
  Future<TmcInventory> createInventory(TmcInventory inventory);

  /// Обновить строку инвентаризации.
  Future<TmcInventoryItem> updateInventoryItem(TmcInventoryItem item);

  /// Завершить инвентаризацию.
  Future<TmcInventory> completeInventory(String inventoryId);

  /// In-app уведомления текущего пользователя.
  Future<List<TmcNotification>> listNotifications({bool unreadOnly = false});

  /// Отметить уведомление прочитанным.
  Future<void> markNotificationRead(String id);

  /// Следующий инвентарный номер через RPC.
  Future<String> nextInventoryNumber();
}
