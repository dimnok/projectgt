import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/modal_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../../../../core/widgets/modal_container_wrapper.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../core/di/providers.dart';
import '../../../works/presentation/providers/work_items_provider.dart';
import '../../../../presentation/state/estimate_state.dart';
import '../../domain/entities/work_search_result.dart';
import '../providers/work_search_provider.dart';
import '../providers/work_search_date_provider.dart';
import 'export_search_action.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import '../../../../presentation/state/auth_state.dart';
import '../../../../features/roles/presentation/providers/roles_provider.dart';

/// Модальное окно для редактирования работы из результатов поиска.
class ExportWorkItemEditModal extends ConsumerStatefulWidget {
  /// Начальные данные для редактирования.
  final WorkSearchResult initialData;

  /// Создаёт модальное окно для редактирования работы.
  const ExportWorkItemEditModal({
    super.key,
    required this.initialData,
  });

  @override
  ConsumerState<ExportWorkItemEditModal> createState() =>
      _ExportWorkItemEditModalState();
}

class _ExportWorkItemEditModalState
    extends ConsumerState<ExportWorkItemEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  String? _selectedSection;
  String? _selectedFloor;
  Estimate? _selectedEstimate;

  List<String> _availableSections = [];
  List<String> _availableFloors = [];
  List<Estimate> _filteredEstimates = [];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  /// Инициализирует данные формы.
  Future<void> _initializeData() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем доступные секции и этажи
      final workItemsNotifier = ref.read(workItemsNotifierProvider);
      final allItems = await workItemsNotifier.getAllWorkItems();

      // Фильтруем по объекту
      final objectItems = allItems
          .where((item) =>
              item.workId == widget.initialData.workId &&
              item.id == widget.initialData.workItemId)
          .toList();

      // Если есть запись, используем её данные
      if (objectItems.isNotEmpty) {
        final workItem = objectItems.first;
        _selectedSection = workItem.section;
        _selectedFloor = workItem.floor;
      } else {
        // Иначе используем данные из результата поиска
        _selectedSection = widget.initialData.section;
        _selectedFloor = widget.initialData.floor;
      }

      // Получаем уникальные секции и этажи из всех work_items
      _availableSections = allItems
          .map((e) => e.section)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      _availableFloors = allItems
          .map((e) => e.floor)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Инициализируем количество
      _quantityController.text = widget.initialData.quantity.toString();

      // Убеждаемся, что сметы загружены
      final estimateState = ref.read(estimateNotifierProvider);
      if (estimateState.estimates.isEmpty) {
        await ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }

      // Обновляем фильтрованные сметы
      _updateFilteredEstimates();

      // Находим выбранную смету
      _findSelectedEstimate();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка загрузки данных: $e');
      }
    }
  }

  /// Находит выбранную смету по ID или имени.
  void _findSelectedEstimate() {
    if (widget.initialData.estimateId == null) return;

    final estimates = ref.read(estimateNotifierProvider).estimates;
    if (estimates.isEmpty) return;

    try {
      _selectedEstimate = estimates.firstWhere(
        (e) => e.id == widget.initialData.estimateId,
      );
    } catch (e) {
      try {
        _selectedEstimate = estimates.firstWhere(
          (e) =>
              e.name == widget.initialData.workName &&
              (widget.initialData.objectId == null ||
                  e.objectId == widget.initialData.objectId),
        );
      } catch (e) {
        _selectedEstimate = null;
      }
    }
  }

  /// Обновляет список отфильтрованных смет.
  void _updateFilteredEstimates() {
    final allEstimates = ref.read(estimateNotifierProvider).estimates;

    // Если смет нет вообще, оставляем пустой список
    if (allEstimates.isEmpty) {
      setState(() {
        _filteredEstimates = [];
      });
      return;
    }

    // Фильтруем по объекту (если objectId указан)
    var filtered = allEstimates;
    if (widget.initialData.objectId != null &&
        widget.initialData.objectId!.isNotEmpty) {
      filtered = filtered
          .where((e) => e.objectId == widget.initialData.objectId)
          .toList();
    }

    // Фильтруем по системе (из результата поиска) - только если система не пустая
    if (widget.initialData.system.isNotEmpty) {
      filtered =
          filtered.where((e) => e.system == widget.initialData.system).toList();
    }

    // Фильтруем по подсистеме (из результата поиска) - только если подсистема не пустая
    if (widget.initialData.subsystem.isNotEmpty) {
      filtered = filtered
          .where((e) => e.subsystem == widget.initialData.subsystem)
          .toList();
    }

    // Исключаем уже добавленные материалы для этой комбинации
    if (_selectedSection != null &&
        _selectedFloor != null &&
        widget.initialData.workId != null) {
      final workItemsAsync =
          ref.read(workItemsProvider(widget.initialData.workId!));
      final existingItems = workItemsAsync.valueOrNull ?? [];

      final existingEstimateIds = existingItems
          .where((item) =>
              item.section == _selectedSection &&
              item.floor == _selectedFloor &&
              item.system == widget.initialData.system &&
              item.subsystem == widget.initialData.subsystem &&
              item.id != widget.initialData.workItemId) // Исключаем текущий
          .map((e) => e.estimateId)
          .toSet();

      filtered = filtered.where((estimate) {
        // Если это текущий редактируемый материал - всегда включаем его
        if (widget.initialData.estimateId != null &&
            estimate.id == widget.initialData.estimateId) {
          return true;
        }
        // Иначе исключаем уже добавленные материалы
        return !existingEstimateIds.contains(estimate.id);
      }).toList();
    }

    // Если список пустой, но есть текущий материал - добавляем его
    if (filtered.isEmpty && widget.initialData.estimateId != null) {
      try {
        final currentEstimate = allEstimates.firstWhere(
          (e) => e.id == widget.initialData.estimateId,
        );
        filtered = [currentEstimate];
      } catch (e) {
        // Если не нашли по ID, ищем по имени
        try {
          final currentEstimate = allEstimates.firstWhere(
            (e) =>
                e.name == widget.initialData.workName &&
                (widget.initialData.objectId == null ||
                    e.objectId == widget.initialData.objectId),
          );
          filtered = [currentEstimate];
        } catch (e) {
          // Если не нашли, оставляем пустой список
        }
      }
    }

    setState(() {
      _filteredEstimates = filtered;
    });
  }

  /// Сохраняет изменения.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSection == null ||
        _selectedFloor == null ||
        _selectedEstimate == null) {
      SnackBarUtils.showError(context, 'Заполните все поля');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем роль пользователя
      final user = ref.read(authProvider).user;
      if (user?.roleId == null) {
        throw Exception('Пользователь не авторизован или роль не определена');
      }

      final role = await ref.read(roleByIdProvider(user!.roleId!).future);
      final isAdmin =
          role?.name == 'Администратор' || role?.name == 'Супер-админ';

      // Если не админ, проверяем стандартные ограничения
      if (!isAdmin) {
        // Проверка прав пользователя
        final permissionService = ref.read(permissionServiceProvider);
        if (!permissionService.can('works', 'update')) {
          throw Exception('Нет прав на редактирование');
        }

        // Проверка статуса смены
        if (widget.initialData.workStatus?.toLowerCase() != 'open') {
          throw Exception('Нельзя редактировать закрытую смену');
        }
      }

      // Загружаем текущий WorkItem
      final workItemsAsync =
          ref.read(workItemsProvider(widget.initialData.workId!));
      final workItems = workItemsAsync.valueOrNull ?? [];
      final workItem = workItems.firstWhere(
        (item) => item.id == widget.initialData.workItemId,
      );

      // Парсим количество
      final quantityText = _quantityController.text.replaceAll(',', '.');
      final quantity = double.tryParse(quantityText) ?? 0;

      if (quantity <= 0) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Количество должно быть больше 0');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Обновляем WorkItem
      final price = _selectedEstimate!.price;
      final updatedItem = workItem.copyWith(
        section: _selectedSection!,
        floor: _selectedFloor!,
        estimateId: _selectedEstimate!.id,
        name: _selectedEstimate!.name,
        system: _selectedEstimate!.system,
        subsystem: _selectedEstimate!.subsystem,
        unit: _selectedEstimate!.unit,
        quantity: quantity,
        price: price,
        total: price * quantity,
        updatedAt: DateTime.now(),
      );

      // Сохраняем
      await ref
          .read(workItemsProvider(widget.initialData.workId!).notifier)
          .updateOptimistic(updatedItem);

      // Обновляем результаты поиска с теми же параметрами
      final searchQuery = ref.read(exportSearchQueryProvider);
      final dateRange = ref.read(workSearchDateRangeProvider);
      final selectedObjectId = ref.read(exportSelectedObjectIdProvider);

      if (searchQuery.trim().isNotEmpty || selectedObjectId != null) {
        final filters = ref.read(exportSearchFilterProvider);
        await ref.read(workSearchProvider.notifier).searchMaterials(
              startDate: dateRange?.start,
              endDate: dateRange?.end,
              objectId: selectedObjectId,
              searchQuery: searchQuery.trim().isNotEmpty ? searchQuery : null,
              systemFilters: filters['system']?.toList(),
              sectionFilters: filters['section']?.toList(),
              floorFilters: filters['floor']?.toList(),
            );
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Изменения сохранены');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка сохранения: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Переходит к смене.
  void _navigateToWork() {
    if (widget.initialData.workId == null) return;

    Navigator.pop(context);
    context.goNamed(
      'work_details',
      pathParameters: {'workId': widget.initialData.workId!},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Реактивно отслеживаем загрузку смет
    ref.listen<EstimateState>(
      estimateNotifierProvider,
      (previous, next) {
        if (_isInitialized && !next.isLoading && next.estimates.isNotEmpty) {
          _updateFilteredEstimates();
          if (_selectedEstimate == null) {
            _findSelectedEstimate();
          }
        }
      },
    );

    if (_isLoading && !_isInitialized) {
      return ModalContainerWrapper(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(
                  radius: 15,
                  color: theme.brightness == Brightness.light
                      ? Colors.green
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Загрузка данных...',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ModalContainerWrapper(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок
                  ModalUtils.buildModalHeader(
                    title: 'Редактирование работы',
                    onClose: () => Navigator.pop(context),
                    theme: theme,
                  ),
                  const Divider(),

                  // Информация о смене
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Смена: ${widget.initialData.objectName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Дата: ${formatRuDate(widget.initialData.workDate)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Система: ${widget.initialData.system}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Подсистема: ${widget.initialData.subsystem}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Форма редактирования
                  _buildForm(),
                  const SizedBox(height: 24),

                  // Кнопки
                  _buildButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Строит форму редактирования
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Секция
        GTStringDropdown(
          items: _availableSections,
          selectedItem: _selectedSection,
          labelText: 'Секция',
          hintText: 'Выберите секцию',
          allowClear: false,
          validator: (value) =>
              value == null || value.isEmpty ? 'Выберите секцию' : null,
          onSelectionChanged: (value) {
            setState(() {
              _selectedSection = value;
            });
            _updateFilteredEstimates();
          },
        ),
        const SizedBox(height: 16),

        // Этаж
        GTStringDropdown(
          items: _availableFloors,
          selectedItem: _selectedFloor,
          labelText: 'Этаж',
          hintText: 'Выберите этаж',
          allowClear: false,
          validator: (value) =>
              value == null || value.isEmpty ? 'Выберите этаж' : null,
          onSelectionChanged: (value) {
            setState(() {
              _selectedFloor = value;
            });
            _updateFilteredEstimates();
          },
        ),
        const SizedBox(height: 16),

        // Материал
        GTDropdown<Estimate>(
          items: _filteredEstimates,
          itemDisplayBuilder: (e) => e.name,
          selectedItem: _selectedEstimate,
          labelText: 'Материал',
          hintText: 'Выберите материал',
          allowClear: false,
          validator: (value) => value == null ? 'Выберите материал' : null,
          onSelectionChanged: (estimate) {
            setState(() {
              _selectedEstimate = estimate;
            });
          },
        ),
        const SizedBox(height: 16),

        // Количество
        TextFormField(
          controller: _quantityController,
          decoration: const InputDecoration(
            labelText: 'Количество',
            hintText: 'Введите количество',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // ignore: deprecated_member_use
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите количество';
            }
            final normalized = value.replaceAll(',', '.');
            final parsed = double.tryParse(normalized);
            if (parsed == null || parsed <= 0) {
              return 'Введите корректное количество';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Кнопка перехода к смене
        OutlinedButton.icon(
          onPressed: _navigateToWork,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Перейти к смене'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  /// Кнопки действий
  Widget _buildButtons() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CupertinoActivityIndicator(
                      radius: 12,
                      color: theme.brightness == Brightness.light
                          ? Colors.green
                          : null,
                    ),
                  )
                : const Text('Сохранить'),
          ),
        ),
      ],
    );
  }
}
