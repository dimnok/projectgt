import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/work_plan.dart';

part 'work_plan_model.freezed.dart';
part 'work_plan_model.g.dart';

/// Модель плана работ для слоя data.
///
/// Используется для сериализации/десериализации данных из/в Supabase
/// и преобразования в доменную сущность [WorkPlan].
@freezed
abstract class WorkPlanModel with _$WorkPlanModel {
  /// Конструктор для создания [WorkPlanModel].
  ///
  /// Все параметры соответствуют полям таблицы work_plans в базе данных.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory WorkPlanModel({
    @JsonKey(includeIfNull: false) String? id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String createdBy,
    required DateTime date,
    required String objectId,
    @JsonKey(includeIfNull: false) String? objectName,
    @JsonKey(includeIfNull: false) String? objectAddress,
    @Default([]) List<WorkBlockModel> workBlocks,
  }) = _WorkPlanModel;

  /// Приватный конструктор для поддержки расширения через [freezed].
  const WorkPlanModel._();

  /// Создаёт [WorkPlanModel] из JSON.
  factory WorkPlanModel.fromJson(Map<String, dynamic> json) =>
      _$WorkPlanModelFromJson(json);

  /// Создаёт [WorkPlanModel] из доменной сущности [WorkPlan].
  factory WorkPlanModel.fromDomain(WorkPlan workPlan) => WorkPlanModel(
        id: workPlan.id,
        createdAt: workPlan.createdAt,
        updatedAt: workPlan.updatedAt,
        createdBy: workPlan.createdBy,
        date: workPlan.date,
        objectId: workPlan.objectId,
        objectName: workPlan.objectName,
        objectAddress: workPlan.objectAddress,
        workBlocks: workPlan.workBlocks
            .map((block) => WorkBlockModel.fromDomain(block))
            .toList(),
      );

  /// Преобразует [WorkPlanModel] в доменную сущность [WorkPlan].
  WorkPlan toDomain() => WorkPlan(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        date: date,
        objectId: objectId,
        objectName: objectName,
        objectAddress: objectAddress,
        workBlocks: workBlocks.map((block) => block.toDomain()).toList(),
      );
}

/// Модель элемента плана работ для слоя data.
@freezed
abstract class WorkPlanItemModel with _$WorkPlanItemModel {
  /// Конструктор для создания [WorkPlanItemModel].
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory WorkPlanItemModel({
    required String estimateId,
    required String name,
    required String unit,
    required double price,
    @Default(0) double plannedQuantity,
    @Default(0) double actualQuantity,
  }) = _WorkPlanItemModel;

  /// Приватный конструктор для поддержки расширения через [freezed].
  const WorkPlanItemModel._();

  /// Создаёт [WorkPlanItemModel] из JSON.
  factory WorkPlanItemModel.fromJson(Map<String, dynamic> json) =>
      _$WorkPlanItemModelFromJson(json);

  /// Создаёт [WorkPlanItemModel] из доменной сущности [WorkPlanItem].
  factory WorkPlanItemModel.fromDomain(WorkPlanItem item) => WorkPlanItemModel(
        estimateId: item.estimateId,
        name: item.name,
        unit: item.unit,
        price: item.price,
        plannedQuantity: item.plannedQuantity,
        actualQuantity: item.actualQuantity,
      );

  /// Преобразует [WorkPlanItemModel] в доменную сущность [WorkPlanItem].
  WorkPlanItem toDomain() => WorkPlanItem(
        estimateId: estimateId,
        name: name,
        unit: unit,
        price: price,
        plannedQuantity: plannedQuantity,
        actualQuantity: actualQuantity,
      );
}

/// Модель блока работ для сериализации/десериализации.
@freezed
abstract class WorkBlockModel with _$WorkBlockModel {
  /// Основной конструктор [WorkBlockModel].
  const factory WorkBlockModel({
    /// Уникальный идентификатор блока работ.
    @JsonKey(includeIfNull: false) String? id,

    /// ID ответственного сотрудника за блок.
    @JsonKey(includeIfNull: false) String? responsibleId,

    /// Список ID работников, назначенных на блок.
    @Default([]) List<String> workerIds,

    /// Участок объекта для данного блока.
    @JsonKey(includeIfNull: false) String? section,

    /// Этаж объекта для данного блока.
    @JsonKey(includeIfNull: false) String? floor,

    /// Система работ (обязательное поле).
    required String system,

    /// Список работ в блоке с объемами.
    @Default([]) List<WorkPlanItemModel> selectedWorks,
  }) = _WorkBlockModel;

  /// Создает [WorkBlockModel] из JSON.
  factory WorkBlockModel.fromJson(Map<String, dynamic> json) =>
      _$WorkBlockModelFromJson(json);

  /// Создает [WorkBlockModel] из доменной сущности [WorkBlock].
  factory WorkBlockModel.fromDomain(WorkBlock workBlock) => WorkBlockModel(
        id: workBlock.id,
        responsibleId: workBlock.responsibleId,
        workerIds: workBlock.workerIds,
        section: workBlock.section,
        floor: workBlock.floor,
        system: workBlock.system,
        selectedWorks: workBlock.selectedWorks
            .map((item) => WorkPlanItemModel.fromDomain(item))
            .toList(),
      );
}

/// Расширение для [WorkBlockModel] с дополнительными методами.
extension WorkBlockModelExtension on WorkBlockModel {
  /// Преобразует [WorkBlockModel] в доменную сущность [WorkBlock].
  WorkBlock toDomain() => WorkBlock(
        id: id,
        responsibleId: responsibleId,
        workerIds: workerIds,
        section: section,
        floor: floor,
        system: system,
        selectedWorks: selectedWorks.map((item) => item.toDomain()).toList(),
      );
}
