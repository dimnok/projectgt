import 'package:projectgt/domain/entities/employee.dart' as domain_employee;
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_selection_widget.dart';

/// Состояние блока работ для управления данными в UI.
///
/// Содержит все данные, необходимые для отображения и редактирования
/// одного блока работ в форме плана работ.
class WorkBlockState {
  /// Уникальный идентификатор блока (для редактирования существующего).
  String? id;

  /// Выбранный ответственный сотрудник.
  domain_employee.Employee? selectedResponsible;

  /// Список выбранных работников.
  List<domain_employee.Employee> selectedWorkers = [];

  /// Доступные участки для выбранного объекта.
  List<String> availableSections = [];

  /// Выбранный участок.
  String? selectedSection;

  /// Доступные этажи для выбранного участка.
  List<String> availableFloors = [];

  /// Выбранный этаж.
  String? selectedFloor;

  /// Доступные системы для выбранного объекта.
  List<String> availableSystems = [];

  /// Выбранная система.
  String? selectedSystem;

  /// Доступные работы для выбранной системы.
  List<Estimate> availableWorks = [];

  /// Выбранные работы с объемами.
  List<SelectedWork> selectedWorks = [];

  /// Флаг свернутости блока (для экономии места в UI).
  bool isCollapsed = false;

  /// Конструктор по умолчанию.
  WorkBlockState();

  /// Проверяет, заполнены ли обязательные поля блока.
  bool get isComplete {
    return selectedSystem != null &&
        selectedWorks.isNotEmpty &&
        selectedWorks.every((work) => work.quantity > 0);
  }

  /// Проверяет, можно ли добавить новый блок (текущий блок заполнен).
  bool get canAddNewBlock => isComplete;

  /// Общая стоимость всех работ в блоке.
  double get totalCost {
    return selectedWorks.fold(0.0, (sum, work) => sum + work.totalCost);
  }

  /// Количество выбранных работ.
  int get worksCount => selectedWorks.length;

  /// Количество выбранных работников.
  int get workersCount => selectedWorkers.length;

  /// Сбрасывает все данные блока.
  void reset() {
    selectedResponsible = null;
    selectedWorkers.clear();
    selectedSection = null;
    selectedFloor = null;
    selectedSystem = null;
    selectedWorks.clear();
    availableSections.clear();
    availableFloors.clear();
    availableSystems.clear();
    availableWorks.clear();
  }

  /// Сбрасывает зависимые поля при изменении системы.
  void resetWorksData() {
    selectedWorks.clear();
    availableWorks.clear();
  }

  /// Сбрасывает зависимые поля при изменении участка.
  void resetFloorData() {
    selectedFloor = null;
    availableFloors.clear();
  }

  @override
  String toString() {
    return 'WorkBlockState(id: $id, system: $selectedSystem, works: $worksCount, workers: $workersCount, cost: ${totalCost.toStringAsFixed(2)})';
  }
}
