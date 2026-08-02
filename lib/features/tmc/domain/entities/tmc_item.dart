import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';

part 'tmc_item.freezed.dart';

/// Позиция каталога ТМЦ.
@freezed
abstract class TmcItem with _$TmcItem {
  /// Создаёт [TmcItem].
  const factory TmcItem({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Наименование.
    required String name,

    /// Категория.
    String? categoryId,

    /// Подкатегория.
    String? subcategoryId,

    /// Тип учёта.
    @Default(TmcAccountingType.individual) TmcAccountingType accountingType,

    /// Артикул / SKU.
    String? sku,

    /// Производитель.
    String? manufacturer,

    /// Модель.
    String? model,

    /// Единица измерения.
    @Default('шт') String unitOfMeasure,

    /// Описание.
    String? description,

    /// URL фото.
    String? photoUrl,

    /// Статус позиции.
    @Default(TmcItemStatus.active) TmcItemStatus status,

    /// Дата поставки.
    DateTime? deliveryDate,

    /// Дата приёмки.
    DateTime? acceptanceDate,

    /// Поставщик (контрагент).
    String? supplierId,

    /// Номер документа поступления.
    String? documentNumber,

    /// Цена за единицу.
    @Default(0) double unitPrice,

    /// Общее количество (на складе + выдано + на объекте).
    @Default(0) double quantity,

    /// Количество на складе / в офисе.
    @Default(0) double qtyInStock,

    /// Количество у сотрудников.
    @Default(0) double qtyIssued,

    /// Количество на объектах.
    @Default(0) double qtyOnObject,

    /// Краткое описание мест хранения (склады).
    String? locationSummary,

    /// Общая стоимость (вычисляемое поле БД).
    @Default(0) double totalCost,

    /// Сумма НДС.
    @Default(0) double vatAmount,

    /// Гарантия до.
    DateTime? warrantyUntil,

    /// В архиве.
    @Default(false) bool isArchived,

    /// Дата архивации.
    DateTime? archivedAt,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Автор создания.
    String? createdBy,

    /// Название категории (join).
    String? categoryName,

    /// Название подкатегории (join).
    String? subcategoryName,

    /// Название поставщика (join).
    String? supplierName,
  }) = _TmcItem;
}
