import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_plan.freezed.dart';

/// Сущность "План работ" (доменная модель).
///
/// Описывает план работ с указанием даты, объекта, участка, этажа,
/// системы и списка выбранных работ.
@freezed
abstract class WorkPlan with _$WorkPlan {
  /// Основной конструктор [WorkPlan].
  ///
  /// Все параметры соответствуют полям плана работ в базе данных.
  const factory WorkPlan({
    /// Уникальный идентификатор плана работ.
    String? id,

    /// ID компании.
    required String companyId,

    /// Дата создания плана работ.
    required DateTime createdAt,

    /// Дата последнего обновления плана работ.
    required DateTime updatedAt,

    /// ID пользователя, создавшего план работ.
    required String createdBy,

    /// Дата выполнения плана работ.
    required DateTime date,

    /// ID объекта, для которого создается план работ.
    required String objectId,

    /// Название объекта (для отображения).
    String? objectName,

    /// Адрес объекта (для отображения).
    String? objectAddress,

    /// Список блоков работ.
    @Default([]) List<WorkBlock> workBlocks,
  }) = _WorkPlan;

  /// Приватный конструктор для расширения функциональности через методы.
  const WorkPlan._();

  /// Общая стоимость всех блоков работ по плану.
  double get totalPlannedCost =>
      workBlocks.fold(0.0, (sum, block) => sum + block.totalPlannedCost);

  /// Общая стоимость фактически выполненных работ.
  double get totalActualCost =>
      workBlocks.fold(0.0, (sum, block) => sum + block.totalActualCost);

  /// Процент выполнения всего плана работ.
  double get completionPercentage {
    if (workBlocks.isEmpty) return 0;
    final totalPlanned = workBlocks.fold(
      0.0,
      (sum, block) => sum + block.totalPlannedCost,
    );
    final totalActual = workBlocks.fold(
      0.0,
      (sum, block) => sum + block.totalActualCost,
    );
    return totalPlanned > 0 ? (totalActual / totalPlanned * 100) : 0;
  }

  /// Проверяет, валиден ли план (есть блоки и все блоки валидны).
  bool get isValid =>
      workBlocks.isNotEmpty && workBlocks.every((block) => block.isValid);

  /// Количество блоков работ.
  int get blocksCount => workBlocks.length;

  /// Общее количество работ во всех блоках.
  int get totalWorksCount =>
      workBlocks.fold(0, (sum, block) => sum + block.selectedWorks.length);
}

/// Блок работ в рамках плана работ.
///
/// Каждый блок может иметь своего ответственного, работников, участок, этаж,
/// систему и набор работ. Это позволяет организовать работы по разным системам
/// или участкам в рамках одного плана.
@freezed
abstract class WorkBlock with _$WorkBlock {
  /// Основной конструктор [WorkBlock].
  const factory WorkBlock({
    /// Уникальный идентификатор блока работ.
    String? id,

    /// ID компании.
    required String companyId,

    /// ID ответственного сотрудника за блок.
    String? responsibleId,

    /// Список ID работников, назначенных на блок.
    @Default([]) List<String> workerIds,

    /// Участок объекта для данного блока.
    String? section,

    /// Этаж объекта для данного блока.
    String? floor,

    /// Система работ (обязательное поле).
    required String system,

    /// Список работ в блоке с объемами.
    @Default([]) List<WorkPlanItem> selectedWorks,
  }) = _WorkBlock;

  /// Приватный конструктор для расширения функциональности через методы.
  const WorkBlock._();

  /// Общая стоимость всех работ в блоке по плану.
  double get totalPlannedCost =>
      selectedWorks.fold(0.0, (sum, item) => sum + item.totalPlannedCost);

  /// Общая стоимость фактически выполненных работ в блоке.
  double get totalActualCost =>
      selectedWorks.fold(0.0, (sum, item) => sum + item.totalActualCost);

  /// Процент выполнения блока работ.
  double get completionPercentage {
    if (selectedWorks.isEmpty) return 0;
    final totalPlanned = selectedWorks.fold(
      0.0,
      (sum, item) => sum + item.plannedQuantity,
    );
    final totalActual = selectedWorks.fold(
      0.0,
      (sum, item) => sum + item.actualQuantity,
    );
    return totalPlanned > 0 ? (totalActual / totalPlanned * 100) : 0;
  }

  /// Проверяет, заполнен ли блок (есть система и работы).
  bool get isComplete => system.isNotEmpty && selectedWorks.isNotEmpty;

  /// Проверяет, валидны ли все работы в блоке (объемы > 0).
  bool get isValid => selectedWorks.every((work) => work.plannedQuantity > 0);
}

/// Элемент плана работ (выбранная работа).
@freezed
abstract class WorkPlanItem with _$WorkPlanItem {
  /// Основной конструктор [WorkPlanItem].
  const factory WorkPlanItem({
    /// ID компании.
    required String companyId,

    /// ID работы из таблицы estimates.
    required String estimateId,

    /// Название работы.
    required String name,

    /// Единица измерения.
    required String unit,

    /// Цена за единицу.
    required double price,

    /// Запланированное количество.
    @Default(0) double plannedQuantity,

    /// Фактическое выполненное количество.
    @Default(0) double actualQuantity,
  }) = _WorkPlanItem;

  /// Приватный конструктор для расширения функциональности через методы.
  const WorkPlanItem._();

  /// Полная стоимость по плану.
  double get totalPlannedCost => plannedQuantity * price;

  /// Полная стоимость фактически выполненных работ.
  double get totalActualCost => actualQuantity * price;

  /// Процент выполнения работы.
  double get completionPercentage {
    if (plannedQuantity == 0) return 0;
    return (actualQuantity / plannedQuantity) * 100;
  }
}
