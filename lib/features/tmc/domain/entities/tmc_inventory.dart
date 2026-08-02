import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_inventory.freezed.dart';

/// Область инвентаризации.
enum TmcInventoryScopeType {
  /// Вся компания.
  @JsonValue('company')
  company,

  /// Склад.
  @JsonValue('warehouse')
  warehouse,

  /// Объект.
  @JsonValue('object')
  object,

  /// Сотрудник.
  @JsonValue('employee')
  employee,

  /// Категория.
  @JsonValue('category')
  category,

  /// Выбранные позиции.
  @JsonValue('items')
  items,
}

/// Расширения для [TmcInventoryScopeType].
extension TmcInventoryScopeTypeX on TmcInventoryScopeType {
  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcInventoryScopeType.company => 'Вся компания',
        TmcInventoryScopeType.warehouse => 'Склад',
        TmcInventoryScopeType.object => 'Объект',
        TmcInventoryScopeType.employee => 'Сотрудник',
        TmcInventoryScopeType.category => 'Категория',
        TmcInventoryScopeType.items => 'Выбранные позиции',
      };
}

/// Статус инвентаризации.
enum TmcInventoryStatus {
  /// Черновик.
  @JsonValue('draft')
  draft,

  /// В процессе.
  @JsonValue('in_progress')
  inProgress,

  /// Завершена.
  @JsonValue('completed')
  completed,

  /// Отменена.
  @JsonValue('cancelled')
  cancelled,
}

/// Расширения для [TmcInventoryStatus].
extension TmcInventoryStatusX on TmcInventoryStatus {
  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcInventoryStatus.draft => 'Черновик',
        TmcInventoryStatus.inProgress => 'В процессе',
        TmcInventoryStatus.completed => 'Завершена',
        TmcInventoryStatus.cancelled => 'Отменена',
      };
}

/// Строка инвентаризации.
@freezed
abstract class TmcInventoryItem with _$TmcInventoryItem {
  /// Создаёт [TmcInventoryItem].
  const factory TmcInventoryItem({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Инвентаризация.
    required String inventoryId,

    /// Позиция каталога.
    required String itemId,

    /// Единица.
    String? unitId,

    /// Количество по учёту.
    @Default(0) double systemQuantity,

    /// Фактическое количество.
    double? actualQuantity,

    /// Излишек (вычисляемое поле БД).
    double? surplus,

    /// Недостача (вычисляемое поле БД).
    double? shortage,

    /// Состояние.
    String? conditionId,

    /// Комментарий.
    String? comment,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Наименование позиции (join).
    String? itemName,

    /// Инвентарный номер (join).
    String? inventoryNumber,
  }) = _TmcInventoryItem;
}

/// Документ инвентаризации ТМЦ.
@freezed
abstract class TmcInventory with _$TmcInventory {
  /// Создаёт [TmcInventory].
  const factory TmcInventory({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Название.
    required String title,

    /// Область инвентаризации.
    @Default(TmcInventoryScopeType.company) TmcInventoryScopeType scopeType,

    /// Склад (при scope = warehouse).
    String? warehouseId,

    /// Объект (при scope = object).
    String? objectId,

    /// Сотрудник (при scope = employee).
    String? employeeId,

    /// Категория (при scope = category).
    String? categoryId,

    /// Статус.
    @Default(TmcInventoryStatus.draft) TmcInventoryStatus status,

    /// Дата начала.
    required DateTime startedAt,

    /// Дата завершения.
    DateTime? completedAt,

    /// Комментарий.
    String? comment,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Автор создания.
    String? createdBy,

    /// Строки инвентаризации.
    @Default([]) List<TmcInventoryItem> items,
  }) = _TmcInventory;
}
