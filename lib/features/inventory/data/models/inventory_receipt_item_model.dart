import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_receipt_item_model.freezed.dart';
part 'inventory_receipt_item_model.g.dart';

/// Модель данных позиции накладной прихода ТМЦ.
@freezed
abstract class InventoryReceiptItemModel with _$InventoryReceiptItemModel {
  /// Конструктор модели позиции накладной.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory InventoryReceiptItemModel({
    required String id,
    @JsonKey(name: 'receipt_id') required String receiptId,
    required String name,
    @JsonKey(name: 'category_id') required String categoryId,
    required String unit,
    required double quantity,
    double? price,
    double? total,
    @JsonKey(name: 'serial_number') String? serialNumber,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? notes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _InventoryReceiptItemModel;

  const InventoryReceiptItemModel._();

  /// Создаёт модель из JSON.
  factory InventoryReceiptItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryReceiptItemModelFromJson(json);
}

