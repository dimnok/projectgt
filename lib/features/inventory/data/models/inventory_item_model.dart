import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';

part 'inventory_item_model.freezed.dart';
part 'inventory_item_model.g.dart';

/// Модель данных ТМЦ для работы с API и хранения в базе.
///
/// Используется для сериализации/десериализации, преобразования в доменную сущность [InventoryItem].
@freezed
abstract class InventoryItemModel with _$InventoryItemModel {
  /// Конструктор модели ТМЦ.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory InventoryItemModel({
    required String id,
    required String name,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'serial_number') String? serialNumber,
    required String unit,
    @Default(1.0) double quantity,
    @JsonKey(name: 'photo_url') String? photoUrl,
    required String status,
    required String condition,
    @JsonKey(name: 'location_type') required String locationType,
    @JsonKey(name: 'location_id') String? locationId,
    @JsonKey(name: 'responsible_id') String? responsibleId,
    @JsonKey(name: 'receipt_id') String? receiptId,
    @JsonKey(name: 'receipt_item_id') String? receiptItemId,
    double? price,
    @JsonKey(name: 'purchase_date') DateTime? purchaseDate,
    @JsonKey(name: 'warranty_expires_at') DateTime? warrantyExpiresAt,
    @JsonKey(name: 'service_life_months') int? serviceLifeMonths,
    @JsonKey(name: 'issued_at') DateTime? issuedAt,
    String? notes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'updated_by') String? updatedBy,
  }) = _InventoryItemModel;

  const InventoryItemModel._();

  /// Создаёт модель из JSON.
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);

  /// Создаёт модель из доменной сущности [InventoryItem].
  factory InventoryItemModel.fromDomain(InventoryItem item) =>
      InventoryItemModel(
        id: item.id,
        name: item.name,
        categoryId: item.categoryId,
        serialNumber: item.serialNumber,
        unit: item.unit,
        quantity: item.quantity,
        photoUrl: item.photoUrl,
        status: statusToString(item.status),
        condition: _conditionToString(item.condition),
        locationType: _locationTypeToString(item.locationType),
        locationId: item.locationId,
        responsibleId: item.responsibleId,
        receiptId: item.receiptId,
        receiptItemId: item.receiptItemId,
        price: item.price,
        purchaseDate: item.purchaseDate,
        warrantyExpiresAt: item.warrantyExpiresAt,
        serviceLifeMonths: item.serviceLifeMonths,
        issuedAt: item.issuedAt,
        notes: item.notes,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        createdBy: item.createdBy,
        updatedBy: item.updatedBy,
      );

  /// Преобразует модель в доменную сущность [InventoryItem].
  InventoryItem toDomain() => InventoryItem(
        id: id,
        name: name,
        categoryId: categoryId,
        serialNumber: serialNumber,
        unit: unit,
        quantity: quantity,
        photoUrl: photoUrl,
        status: _statusFromString(status),
        condition: _conditionFromString(condition),
        locationType: _locationTypeFromString(locationType),
        locationId: locationId,
        responsibleId: responsibleId,
        receiptId: receiptId,
        receiptItemId: receiptItemId,
        price: price,
        purchaseDate: purchaseDate,
        warrantyExpiresAt: warrantyExpiresAt,
        serviceLifeMonths: serviceLifeMonths,
        issuedAt: issuedAt,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        updatedBy: updatedBy,
      );

  /// Преобразует статус инвентаря из перечисления в строковое значение для API.
  static String statusToString(InventoryItemStatus status) {
    switch (status) {
      case InventoryItemStatus.new_:
        return 'new';
      case InventoryItemStatus.good:
        return 'good';
      case InventoryItemStatus.broken:
        return 'broken';
      case InventoryItemStatus.writtenOff:
        return 'written_off';
      case InventoryItemStatus.repair:
        return 'repair';
      case InventoryItemStatus.critical:
        return 'critical';
    }
  }

  static InventoryItemStatus _statusFromString(String status) {
    switch (status) {
      case 'new':
        return InventoryItemStatus.new_;
      case 'good':
        return InventoryItemStatus.good;
      case 'broken':
        return InventoryItemStatus.broken;
      case 'written_off':
        return InventoryItemStatus.writtenOff;
      case 'repair':
        return InventoryItemStatus.repair;
      case 'critical':
        return InventoryItemStatus.critical;
      default:
        return InventoryItemStatus.new_;
    }
  }

  static String _conditionToString(InventoryItemCondition condition) {
    switch (condition) {
      case InventoryItemCondition.new_:
        return 'new';
      case InventoryItemCondition.used:
        return 'used';
    }
  }

  static InventoryItemCondition _conditionFromString(String condition) {
    switch (condition) {
      case 'new':
        return InventoryItemCondition.new_;
      case 'used':
        return InventoryItemCondition.used;
      default:
        return InventoryItemCondition.new_;
    }
  }

  static String _locationTypeToString(InventoryLocationType locationType) {
    switch (locationType) {
      case InventoryLocationType.warehouse:
        return 'warehouse';
      case InventoryLocationType.object:
        return 'object';
      case InventoryLocationType.employee:
        return 'employee';
    }
  }

  static InventoryLocationType _locationTypeFromString(String locationType) {
    switch (locationType) {
      case 'warehouse':
        return InventoryLocationType.warehouse;
      case 'object':
        return InventoryLocationType.object;
      case 'employee':
        return InventoryLocationType.employee;
      default:
        return InventoryLocationType.warehouse;
    }
  }
}
