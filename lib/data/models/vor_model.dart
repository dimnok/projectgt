import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/vor.dart';

part 'vor_model.freezed.dart';
part 'vor_model.g.dart';

/// Модель заголовка ведомости ВОР.
@freezed
abstract class VorModel with _$VorModel {
  /// Создает экземпляр [VorModel].
  const factory VorModel({
    /// Идентификатор ведомости.
    required String id,

    /// Идентификатор компании.
    @JsonKey(name: 'company_id') required String companyId,

    /// Идентификатор договора.
    @JsonKey(name: 'contract_id') required String contractId,

    /// Порядковый номер ведомости.
    required String number,

    /// Дата начала периода работ.
    @JsonKey(name: 'start_date') required DateTime startDate,

    /// Дата окончания периода работ.
    @JsonKey(name: 'end_date') required DateTime endDate,

    /// Текущий статус ведомости.
    required VorStatus status,

    /// Путь к Excel файлу.
    @JsonKey(name: 'excel_url') String? excelUrl,

    /// Путь к PDF файлу.
    @JsonKey(name: 'pdf_url') String? pdfUrl,

    /// Дата создания.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Кто создал (ID пользователя).
    @JsonKey(name: 'created_by') String? createdBy,

    /// ФИО создателя (опционально, подтягивается через join).
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? createdByName,

    /// Список выбранных систем.
    @Default([]) List<String> systems,

    /// История изменений статусов.
    @Default([]) List<VorStatusHistoryModel> statusHistory,
  }) = _VorModel;

  /// Создает экземпляр [VorModel] из JSON.
  factory VorModel.fromJson(Map<String, dynamic> json) =>
      _$VorModelFromJson(json);

  /// Конвертирует модель в доменную сущность.
  const VorModel._();

  /// Преобразует [VorModel] в доменную сущность [Vor].
  Vor toDomain() => Vor(
    id: id,
    contractId: contractId,
    number: number,
    startDate: startDate,
    endDate: endDate,
    status: status,
    excelUrl: excelUrl,
    pdfUrl: pdfUrl,
    createdAt: createdAt,
    createdBy: createdBy,
    createdByName: createdByName,
    systems: systems,
    statusHistory: statusHistory.map((h) => h.toDomain()).toList(),
  );
}

/// Модель позиции ведомости ВОР.
@freezed
abstract class VorItemModel with _$VorItemModel {
  /// Создает экземпляр [VorItemModel].
  const factory VorItemModel({
    /// Идентификатор позиции.
    required String id,

    /// Идентификатор ведомости.
    @JsonKey(name: 'vor_id') required String vorId,

    /// Идентификатор сметной позиции (если есть).
    @JsonKey(name: 'estimate_item_id') String? estimateItemId,

    /// Наименование работы (для новых позиций).
    String? name,

    /// Единица измерения.
    String? unit,

    /// Количество.
    required double quantity,

    /// Флаг превышения или новой позиции.
    @JsonKey(name: 'is_extra') @Default(false) bool isExtra,

    /// Порядок сортировки.
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _VorItemModel;

  /// Создает экземпляр [VorItemModel] из JSON.
  factory VorItemModel.fromJson(Map<String, dynamic> json) =>
      _$VorItemModelFromJson(json);
}

/// Модель истории статусов ВОР.
@freezed
abstract class VorStatusHistoryModel with _$VorStatusHistoryModel {
  /// Создает экземпляр [VorStatusHistoryModel].
  const factory VorStatusHistoryModel({
    /// Идентификатор записи.
    required String id,

    /// Статус, на который перешли.
    required VorStatus status,

    /// Кто совершил действие (ID пользователя).
    @JsonKey(name: 'user_id') String? userId,

    /// ФИО пользователя (опционально).
    @JsonKey(includeFromJson: false, includeToJson: false) String? userName,

    /// Причина изменения.
    String? comment,

    /// Дата изменения.
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _VorStatusHistoryModel;

  /// Создает экземпляр [VorStatusHistoryModel] из JSON.
  factory VorStatusHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$VorStatusHistoryModelFromJson(json);

  /// Конвертирует модель в доменную сущность.
  const VorStatusHistoryModel._();

  /// Преобразует [VorStatusHistoryModel] в доменную сущность [VorHistoryItem].
  VorHistoryItem toDomain() => VorHistoryItem(
    id: id,
    status: status,
    userId: userId,
    userName: userName,
    comment: comment,
    createdAt: createdAt,
  );
}
