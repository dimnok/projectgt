import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// removed: intl direct import, use formatters
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/domain/entities/employee.dart' as domain_employee;
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_content.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_block_state.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_selection_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Модальное окно для создания/редактирования плана работ.
///
/// Управляет состоянием формы, контроллерами и логикой сохранения.
/// Использует [WorkPlanFormContent] для отображения формы.
class WorkPlanFormModal extends ConsumerStatefulWidget {
  /// План работ для редактирования. Если null — создается новый план.
  final WorkPlan? workPlan;

  /// Колбэк, вызываемый после успешного сохранения плана работ.
  /// [isNew] — true, если создан новый план, false — если редактирование.
  final void Function(bool isNew) onSuccess;

  /// Конструктор [WorkPlanFormModal].
  const WorkPlanFormModal({
    super.key,
    this.workPlan,
    required this.onSuccess,
  });

  @override
  ConsumerState<WorkPlanFormModal> createState() => _WorkPlanFormModalState();
}

/// Состояние модального окна формы плана работ.
class _WorkPlanFormModalState extends ConsumerState<WorkPlanFormModal> {
  /// Флаг состояния загрузки.
  bool _isLoading = false;

  /// Контроллер для поля "Дата".
  late final TextEditingController _dateController;

  /// Выбранная дата.
  DateTime? _selectedDate;

  /// Выбранный объект.
  ObjectEntity? _selectedObject;

  /// Список состояний блоков работ.
  List<WorkBlockState> _workBlocks = [];

  /// Список сотрудников, которые могут быть ответственными для выбранного объекта.
  List<domain_employee.Employee> _availableResponsibles = [];

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.workPlan?.date ?? DateTime.now().add(const Duration(days: 1));
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));

    // Загружаем данные после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEstimates();
      _loadEmployees();
      _initializeWorkPlan();
    });
  }

  /// Загружает estimates для фильтрации систем и работ.
  void _loadEstimates() {
    ref.read(estimateNotifierProvider.notifier).loadEstimates();
  }

  /// Загружает список сотрудников.
  void _loadEmployees() {
    // Employees загружаются через provider автоматически
  }

  /// Инициализирует план работ из переданных данных.
  void _initializeWorkPlan() {
    if (widget.workPlan != null) {
      final workPlan = widget.workPlan!;

      // Устанавливаем объект (падение недопустимо — создаём фолбэк из данных плана)
      final objectState = ref.read(objectProvider);
      final found = objectState.objects
          .where((obj) => obj.id == workPlan.objectId)
          .firstOrNull;
      _selectedObject = found ??
          ObjectEntity(
            id: workPlan.objectId,
            name: workPlan.objectName ?? 'Объект',
            address: workPlan.objectAddress ?? '',
          );

      // Инициализируем блоки работ
      _workBlocks = workPlan.workBlocks.map((block) {
        final blockState = WorkBlockState();

        // Загружаем системы для объекта
        _loadSystemsForBlock(blockState, workPlan.objectId);
        _loadSectionsForBlock(blockState, workPlan.objectId);

        // Устанавливаем значения блока
        blockState.selectedSystem = block.system;
        blockState.selectedSection = block.section;
        blockState.selectedFloor = block.floor;

        // Загружаем сотрудников для блока (если они были назначены)
        final employeeState = ref.read(employeeProvider);
        if (block.responsibleId != null) {
          blockState.selectedResponsible = employeeState.employees
              .where((emp) => emp.id == block.responsibleId)
              .firstOrNull;
        }

        if (block.workerIds.isNotEmpty) {
          blockState.selectedWorkers = employeeState.employees
              .where((emp) => block.workerIds.contains(emp.id))
              .toList();
        }

        // Загружаем этажи если участок выбран
        _loadFloorsForBlock(blockState, workPlan.objectId);

        // Загружаем работы для системы
        if (block.system.isNotEmpty) {
          _loadWorksForBlock(blockState, workPlan.objectId, block.system);
        }

        // Преобразуем WorkPlanItem в SelectedWork
        blockState.selectedWorks =
            block.selectedWorks.map<SelectedWork>((item) {
          final estimate = Estimate(
            id: item.estimateId,
            system: block.system,
            subsystem: '',
            number: '',
            name: item.name,
            article: '',
            manufacturer: '',
            unit: item.unit,
            quantity: item.plannedQuantity,
            price: item.price,
            total: item.plannedQuantity * item.price,
            objectId: workPlan.objectId,
          );
          return SelectedWork(
            estimate: estimate,
            quantity: item.plannedQuantity,
          );
        }).toList();

        return blockState;
      }).toList();
    } else {
      // Для нового плана создаем один пустой блок
      _workBlocks = [];
    }

    setState(() {});
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  /// Обрабатывает сохранение формы.
  void _handleSave() async {
    // Валидация

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату плана работ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedObject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите объект'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canSave()) return;

    setState(() => _isLoading = true);

    try {
      // Получаем текущего пользователя
      final auth = Supabase.instance.client.auth;
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Создаем блоки работ
      final workBlocks = _workBlocks.map((blockState) {
        final selectedWorksItems = blockState.selectedWorks
            .map((selectedWork) => WorkPlanItem(
                  estimateId: selectedWork.estimate.id,
                  name: selectedWork.estimate.name,
                  unit: selectedWork.estimate.unit,
                  price: selectedWork.estimate.price,
                  plannedQuantity: selectedWork.quantity,
                  actualQuantity: 0.0,
                ))
            .toList();

        return WorkBlock(
          id: null, // Генерируется автоматически
          responsibleId: blockState.selectedResponsible?.id,
          workerIds:
              blockState.selectedWorkers.map((worker) => worker.id).toList(),
          section: blockState.selectedSection,
          floor: blockState.selectedFloor,
          system: blockState.selectedSystem!,
          selectedWorks: selectedWorksItems,
        );
      }).toList();

      // Создаем план работ
      final workPlan = WorkPlan(
        id: widget.workPlan?.id,
        createdAt: widget.workPlan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.id,
        date: _selectedDate!,
        objectId: _selectedObject!.id,
        workBlocks: workBlocks,
      );

      // Используем Riverpod для вызова use case
      final container = ProviderScope.containerOf(context, listen: false);
      final createWorkPlanUseCase =
          container.read(createWorkPlanUseCaseProvider);
      final updateWorkPlanUseCase =
          container.read(updateWorkPlanUseCaseProvider);

      if (workPlan.id == null) {
        // Создание нового плана работ
        await createWorkPlanUseCase.call(workPlan);
      } else {
        // Обновление существующего плана работ
        await updateWorkPlanUseCase.call(workPlan);
      }

      final isNew = workPlan.id == null;

      if (!mounted) return;
      final navigator = Navigator.of(context);

      setState(() => _isLoading = false);

      navigator.pop();
      widget.onSuccess(isNew);

      // Показываем сообщение об успехе
      if (mounted) {
        if (isNew) {
          SnackBarUtils.showSuccess(context, 'План работ успешно создан');
        } else {
          SnackBarUtils.showInfo(context, 'Изменения успешно сохранены');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Обрабатывает отмену формы.
  void _handleCancel() {
    Navigator.of(context).pop();
  }

  /// Обрабатывает изменение даты.
  void _handleDateChanged(DateTime? date) {
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = _formatDate(date);
      });
    }
  }

  /// Обрабатывает изменение выбранного объекта.
  void _handleObjectChanged(ObjectEntity? object) {
    setState(() {
      _selectedObject = object;
      // Сбрасываем все блоки при изменении объекта
      _workBlocks = [];

      if (object != null) {
        // Создаем первый блок если объект выбран
        _addNewBlock();
        _loadResponsibles(object.id);
      }
    });
  }

  /// Добавляет новый блок работ.
  void _addNewBlock() {
    if (_selectedObject == null) return;

    setState(() {
      final newBlock = WorkBlockState();

      // Загружаем данные для нового блока
      _loadSystemsForBlock(newBlock, _selectedObject!.id);
      _loadSectionsForBlock(newBlock, _selectedObject!.id);
      _loadResponsibles(_selectedObject!.id);

      _workBlocks.add(newBlock);
    });
  }

  /// Загружает сотрудников, которые могут быть ответственными, для объекта.
  Future<void> _loadResponsibles(String objectId) async {
    try {
      final ds = ref.read(employeeDataSourceProvider);
      final models = await ds.getResponsibleEmployees(objectId);
      setState(() {
        _availableResponsibles = models.map((m) => m.toDomain()).toList()
          ..sort((a, b) => a.lastName.compareTo(b.lastName));
      });
    } catch (_) {
      setState(() {
        _availableResponsibles = [];
      });
    }
  }

  /// Удаляет блок работ.
  void _deleteBlock(int blockIndex) {
    if (_workBlocks.length <= 1) return;

    setState(() {
      _workBlocks.removeAt(blockIndex);
    });
  }

  /// Загружает системы для выбранного объекта в блоке.
  void _loadSystemsForBlock(WorkBlockState blockState, String objectId) {
    final estimates = ref.read(estimateNotifierProvider).estimates;

    blockState.availableSystems = estimates
        .where((estimate) =>
            estimate.objectId == objectId && estimate.system.isNotEmpty)
        .map((estimate) => estimate.system)
        .toSet()
        .toList()
      ..sort();
  }

  /// Загружает работы для выбранного объекта и системы в блоке.
  void _loadWorksForBlock(
      WorkBlockState blockState, String objectId, String system) {
    final estimates = ref.read(estimateNotifierProvider).estimates;

    blockState.availableWorks = estimates
        .where((estimate) =>
            estimate.objectId == objectId && estimate.system == system)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Загружает участки для выбранного объекта в блоке.
  void _loadSectionsForBlock(WorkBlockState blockState, String objectId) async {
    try {
      final supa = Supabase.instance.client;
      final resp = await supa
          .from('work_plans')
          .select('work_plan_blocks(section)')
          .eq('object_id', objectId);

      final sections = <String>{};
      for (final row in resp as List<dynamic>) {
        final blocks = row['work_plan_blocks'] as List<dynamic>?;
        if (blocks == null) continue;
        for (final b in blocks) {
          final section = (b as Map)['section'] as String?;
          if (section != null && section.trim().isNotEmpty) {
            sections.add(section.trim());
          }
        }
      }

      setState(() {
        blockState.availableSections = sections.toList()..sort();
      });
    } catch (_) {
      // В случае ошибки оставляем список пустым
      setState(() {
        blockState.availableSections = [];
      });
    }
  }

  /// Загружает этажи для выбранного участка в блоке.
  void _loadFloorsForBlock(WorkBlockState blockState, String objectId) async {
    try {
      final supa = Supabase.instance.client;
      final resp = await supa
          .from('work_plans')
          .select('work_plan_blocks(floor)')
          .eq('object_id', objectId);

      final floors = <String>{};
      for (final row in resp as List<dynamic>) {
        final blocks = row['work_plan_blocks'] as List<dynamic>?;
        if (blocks == null) continue;
        for (final b in blocks) {
          final bm = b as Map;
          final fl = bm['floor'] as String?;
          if (fl != null && fl.trim().isNotEmpty) {
            floors.add(fl.trim());
          }
        }
      }

      setState(() {
        blockState.availableFloors = floors.toList()..sort();
      });
    } catch (_) {
      setState(() {
        blockState.availableFloors = [];
      });
    }
  }

  /// Обрабатывает изменение ответственного в блоке.
  void _handleBlockResponsibleChanged(
      int blockIndex, domain_employee.Employee? responsible) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      _workBlocks[blockIndex].selectedResponsible = responsible;
    });
  }

  /// Обрабатывает изменение работников в блоке.
  void _handleBlockWorkersChanged(
      int blockIndex, List<domain_employee.Employee> workers) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      _workBlocks[blockIndex].selectedWorkers = workers;
    });
  }

  /// Обрабатывает изменение участка в блоке.
  void _handleBlockSectionChanged(int blockIndex, String? section) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      final block = _workBlocks[blockIndex];
      block.selectedSection = section;
      // Этажи теперь не зависят от участка — подгружаем все доступные для объекта
      if (_selectedObject != null) {
        _loadFloorsForBlock(block, _selectedObject!.id);
      }
    });
  }

  /// Обрабатывает изменение этажа в блоке.
  void _handleBlockFloorChanged(int blockIndex, String? floor) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      _workBlocks[blockIndex].selectedFloor = floor;
    });
  }

  /// Обрабатывает изменение системы в блоке.
  void _handleBlockSystemChanged(int blockIndex, String? system) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      final block = _workBlocks[blockIndex];
      block.selectedSystem = system;
      block.selectedWorks = [];

      if (system != null && _selectedObject != null) {
        _loadWorksForBlock(block, _selectedObject!.id, system);
      } else {
        block.availableWorks = [];
      }
    });
  }

  /// Обрабатывает изменение работ в блоке.
  void _handleBlockWorksChanged(int blockIndex, List<SelectedWork> works) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      _workBlocks[blockIndex].selectedWorks = works;
    });
  }

  /// Обрабатывает изменение состояния сворачивания блока.
  void _handleToggleCollapsed(int blockIndex, bool isCollapsed) {
    if (blockIndex >= _workBlocks.length) return;

    setState(() {
      _workBlocks[blockIndex].isCollapsed = isCollapsed;
    });
  }

  /// Проверяет, можно ли сохранить план работ.
  bool _canSave() {
    if (_selectedDate == null || _selectedObject == null) return false;
    if (_workBlocks.isEmpty) return false;

    // Проверяем каждый блок
    for (final block in _workBlocks) {
      if (block.selectedSystem == null) return false;
      if (block.selectedWorks.isEmpty) return false;

      // Проверяем что у всех работ указано количество > 0
      for (final work in block.selectedWorks) {
        if (work.quantity <= 0) return false;
      }
    }

    return true;
  }

  /// Форматирует дату для отображения.
  String _formatDate(DateTime date) => formatRuDate(date);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Получаем список доступных объектов
        final objectState = ref.watch(objectProvider);
        final allObjects = objectState.objects;

        // Фильтруем объекты по правам пользователя
        final profileState = ref.watch(currentUserProfileProvider);
        final allowedObjectIds =
            profileState.profile?.objectIds ?? const <String>[];
        
        // Если пользователю назначены конкретные объекты, ограничиваем выбор ими.
        // Иначе показываем все доступные (прошедшие через RLS).
        final availableObjects = allowedObjectIds.isNotEmpty
            ? allObjects.where((o) => allowedObjectIds.contains(o.id)).toList()
            : allObjects;

        // Получаем список доступных сотрудников
        final employeeState = ref.watch(employeeProvider);

        // Загружаем сотрудников, если они еще не загружены
        if (employeeState.employees.isEmpty &&
            employeeState.status != EmployeeStatus.loading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(employeeProvider.notifier).getEmployees();
          });
        }

        final availableEmployees = _selectedObject != null
            ? (employeeState.employees
                .where((employee) =>
                    employee.objectIds.contains(_selectedObject!.id) &&
                    employee.status == domain_employee.EmployeeStatus.working)
                .toList()
              ..sort((a, b) => a.lastName.compareTo(b.lastName)))
            : <domain_employee.Employee>[];

        // Получаем список уже выбранных работников во всех блоках (для исключения дублей)
        final alreadySelectedWorkerIds = <String>{};
        for (final block in _workBlocks) {
          for (final worker in block.selectedWorkers) {
            alreadySelectedWorkerIds.add(worker.id);
          }
        }

        return WorkPlanFormContent(
          isNew: widget.workPlan == null,
          isLoading: _isLoading,
          dateController: _dateController,
          selectedDate: _selectedDate,
          onDateChanged: _handleDateChanged,
          availableObjects: availableObjects,
          selectedObject: _selectedObject,
          onObjectChanged: _handleObjectChanged,
          availableEmployees: availableEmployees,
          availableResponsibles: _availableResponsibles,
          alreadySelectedWorkerIds: alreadySelectedWorkerIds,
          workBlocks: _workBlocks,
          onBlockResponsibleChanged: _handleBlockResponsibleChanged,
          onBlockWorkersChanged: _handleBlockWorkersChanged,
          onBlockSectionChanged: _handleBlockSectionChanged,
          onBlockFloorChanged: _handleBlockFloorChanged,
          onBlockSystemChanged: _handleBlockSystemChanged,
          onBlockWorksChanged: _handleBlockWorksChanged,
          onAddBlock: _addNewBlock,
          onDeleteBlock: _deleteBlock,
          onToggleCollapsed: _handleToggleCollapsed,
          onSave: _handleSave,
          onCancel: _handleCancel,
        );
      },
    );
  }
}
