import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/inventory/data/models/inventory_receipt_item_model.dart';

part 'inventory_receipt_model.freezed.dart';
part 'inventory_receipt_model.g.dart';

/// Модель данных накладной прихода ТМЦ.
@freezed
abstract class InventoryReceiptModel with _$InventoryReceiptModel {
  /// Конструктор модели накладной.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory InventoryReceiptModel({
    required String id,
    @JsonKey(name: 'receipt_number') required String receiptNumber,
    @JsonKey(name: 'receipt_date') required DateTime receiptDate,
    @JsonKey(name: 'supplier_id') String? supplierId,
    @JsonKey(name: 'file_url') String? fileUrl,
    String? comment,
    @JsonKey(name: 'total_amount') double? totalAmount,
    @JsonKey(name: 'items_count') @Default(0) int itemsCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<InventoryReceiptItemModel>? items,
  }) = _InventoryReceiptModel;

  const InventoryReceiptModel._();

  /// Создаёт модель из JSON.
  factory InventoryReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryReceiptModelFromJson(json);
}
