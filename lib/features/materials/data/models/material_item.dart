import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_item.freezed.dart';
part 'material_item.g.dart';

/// Модель материала из таблицы `public.materials` в Supabase.
///
/// Поля соответствуют колонкам БД.
@freezed
abstract class MaterialItem with _$MaterialItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory MaterialItem({
    /// Идентификатор записи (UUID)
    required String id,

    /// Наименование материала
    required String name,

    /// ID компании (Multi-tenancy)
    required String companyId,

    /// Единица измерения, например: шт, м, т, м³
    String? unit,

    /// Количество
    double? quantity,

    /// Цена за единицу
    double? price,

    /// Итоговая стоимость (computed в БД)
    double? total,

    /// Номер расходной накладной
    String? receiptNumber,

    /// Дата расходной накладной
    DateTime? receiptDate,

    /// Использовано
    double? used,

    /// Остаток
    double? remaining,

    /// URL файла (накладная/скан)
    String? fileUrl,
  }) = _MaterialItem;

  factory MaterialItem.fromJson(Map<String, dynamic> json) =>
      _$MaterialItemFromJson(json);

  /// Создание модели из Map (для совместимости со старым кодом, если нужно, 
  /// но лучше использовать fromJson)
  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem.fromJson(map);
  }
}
