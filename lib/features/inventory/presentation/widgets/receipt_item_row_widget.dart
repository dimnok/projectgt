import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:projectgt/features/inventory/presentation/models/receipt_item_row.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Виджет строки позиции накладной.
class ReceiptItemRowWidget extends ConsumerStatefulWidget {
  /// Позиция накладной для редактирования.
  final ReceiptItemRow item;

  /// Порядковый номер позиции.
  final int index;

  /// Колбэк обновления позиции.
  final Function(ReceiptItemRow) onChanged;

  /// Колбэк удаления позиции.
  final VoidCallback onRemove;

  /// Флаг блокировки элементов интерфейса.
  final bool isLoading;

  /// Список единиц измерения.
  final List<String> units;

  /// Флаг загрузки единиц измерения.
  final bool unitsLoading;

  /// Создаёт виджет строки позиции накладной.
  const ReceiptItemRowWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
    required this.isLoading,
    required this.units,
    required this.unitsLoading,
  });

  @override
  ConsumerState<ReceiptItemRowWidget> createState() =>
      _ReceiptItemRowWidgetState();
}

class _ReceiptItemRowWidgetState extends ConsumerState<ReceiptItemRowWidget> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _serialNumberController;
  late TextEditingController _notesController;
  late TextEditingController _serviceLifeController;

  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = false;
  Map<String, dynamic>? _selectedCategory;
  bool _serialNumberRequired = false;
  bool _serviceLifeRequired = false;
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _priceController =
        TextEditingController(text: widget.item.price?.toString() ?? '');
    _serialNumberController =
        TextEditingController(text: widget.item.serialNumber ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _serviceLifeController = TextEditingController(
      text: widget.item.serviceLifeMonths?.toString() ?? '',
    );
    _selectedUnit = widget.item.unit.isNotEmpty ? widget.item.unit : null;
    _loadCategories();
    if (widget.item.categoryId.isNotEmpty) {
      _selectedCategory = {
        'id': widget.item.categoryId,
        'name': widget.item.categoryName,
      };
      _loadCategoryDetails(widget.item.categoryId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _serialNumberController.dispose();
    _notesController.dispose();
    _serviceLifeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_isLoadingCategories) return;
    setState(() => _isLoadingCategories = true);

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('inventory_categories')
          .select('id, name, serial_number_required, service_life_required')
          .eq('is_active', true)
          .order('name');

      if (!mounted) return;

      final categories = List<Map<String, dynamic>>.from(response);
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        _updateSelectedCategory(categories);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  void _updateSelectedCategory(List<Map<String, dynamic>> categories) {
    if (widget.item.categoryId.isEmpty) return;
    final foundCategory = categories.firstWhere(
      (cat) => cat['id'] == widget.item.categoryId,
      orElse: () => _selectedCategory ?? {},
    );
    if (foundCategory.isNotEmpty) {
      _selectedCategory = foundCategory;
      _updateCategorySettings(foundCategory);
    }
  }

  Future<void> _loadCategoryDetails(String categoryId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('inventory_categories')
          .select(
              'serial_number_required, service_life_required, service_life_months')
          .eq('id', categoryId)
          .single();

      if (!mounted) return;

      setState(() {
        _serialNumberRequired =
            response['serial_number_required'] as bool? ?? false;
        _serviceLifeRequired =
            response['service_life_required'] as bool? ?? false;
        _setDefaultServiceLife(response['service_life_months'] as int?);
      });
    } catch (e) {
      // Игнорируем ошибки загрузки деталей категории
    }
  }

  void _setDefaultServiceLife(int? defaultMonths) {
    if (_serviceLifeRequired &&
        defaultMonths != null &&
        widget.item.serviceLifeMonths == null) {
      widget.item.serviceLifeMonths = defaultMonths;
      _serviceLifeController.text = defaultMonths.toString();
    }
  }

  void _updateCategorySettings(Map<String, dynamic> category) {
    _serialNumberRequired =
        category['serial_number_required'] as bool? ?? false;
    _serviceLifeRequired = category['service_life_required'] as bool? ?? false;
  }

  void _clearFieldsIfNotRequired(
    bool oldSerialRequired,
    bool oldServiceLifeRequired,
  ) {
    if (!_serialNumberRequired && oldSerialRequired) {
      widget.item.serialNumber = null;
      _serialNumberController.clear();
    }
    if (!_serviceLifeRequired && oldServiceLifeRequired) {
      widget.item.serviceLifeMonths = null;
      _serviceLifeController.clear();
    }
  }

  String _statusToString(InventoryItemStatus status) {
    switch (status) {
      case InventoryItemStatus.new_:
        return 'Новый';
      case InventoryItemStatus.good:
        return 'Хорошее';
      case InventoryItemStatus.broken:
        return 'Сломан';
      case InventoryItemStatus.writtenOff:
        return 'Списан';
      case InventoryItemStatus.repair:
        return 'В ремонте';
      case InventoryItemStatus.critical:
        return 'Критическое';
    }
  }

  void _updateItem() {
    widget.item.name = _nameController.text.trim();
    widget.item.unit = _selectedUnit ?? '';
    widget.item.quantity = double.tryParse(_quantityController.text) ?? 1.0;
    widget.item.price = double.tryParse(_priceController.text);
    widget.item.serialNumber = _getTrimmedText(_serialNumberController);
    widget.item.notes = _getTrimmedText(_notesController);
    widget.item.serviceLifeMonths =
        int.tryParse(_serviceLifeController.text.trim());
    widget.onChanged(widget.item);
  }

  String? _getTrimmedText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (widget.item.price ?? 0.0) * widget.item.quantity;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Позиция ${widget.index + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: widget.isLoading ? null : widget.onRemove,
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                tooltip: 'Удалить позицию',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GTDropdown<Map<String, dynamic>>(
                  items: _categories,
                  selectedItem: _selectedCategory,
                  itemDisplayBuilder: (category) =>
                      category['name'] as String? ?? '',
                  onSelectionChanged: (category) {
                    if (widget.isLoading || category == null) return;
                    final oldSerialRequired = _serialNumberRequired;
                    final oldServiceLifeRequired = _serviceLifeRequired;
                    setState(() {
                      _selectedCategory = category;
                      widget.item.categoryId = category['id'] as String;
                      widget.item.categoryName = category['name'] as String;
                      _updateCategorySettings(category);
                      _clearFieldsIfNotRequired(
                        oldSerialRequired,
                        oldServiceLifeRequired,
                      );
                    });
                    _loadCategoryDetails(category['id'] as String);
                    widget.onChanged(widget.item);
                  },
                  labelText: 'Категория *',
                  hintText: 'Выберите категорию',
                  isLoading: _isLoadingCategories,
                  readOnly: widget.isLoading,
                  validator: (value) =>
                      _selectedCategory == null ? 'Выберите категорию' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Наименование *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _updateItem(),
                  enabled: !widget.isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTEnumDropdown<InventoryItemStatus>(
                  values: InventoryItemStatus.values,
                  selectedValue: widget.item.status,
                  onChanged: widget.isLoading
                      ? (_) {}
                      : (value) {
                          if (value != null) {
                            setState(() {
                              widget.item.status = value;
                            });
                            widget.onChanged(widget.item);
                          }
                        },
                  labelText: 'Состояние *',
                  hintText: 'Выберите состояние',
                  enumToString: _statusToString,
                  validator: (_) => null,
                  readOnly: widget.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: widget.unitsLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    : GTStringDropdown(
                        items: widget.units,
                        selectedItem: _selectedUnit,
                        onSelectionChanged: (unit) {
                          setState(() => _selectedUnit = unit);
                          _updateItem();
                        },
                        labelText: 'Ед. изм. *',
                        hintText: 'Выберите единицу измерения',
                        allowCustomInput: true,
                        showAddNewOption: true,
                        readOnly: widget.isLoading,
                        validator: (value) =>
                            (_selectedUnit == null || _selectedUnit!.isEmpty)
                                ? 'Выберите единицу измерения'
                                : null,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Количество *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateItem(),
                  enabled: !widget.isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Цена',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateItem(),
                  enabled: !widget.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Стоимость:', style: theme.textTheme.bodyMedium),
                Text(
                  formatCurrency(total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_serialNumberRequired || _serviceLifeRequired) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (_serialNumberRequired) ...[
                  Expanded(
                    child: TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Серийный номер *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateItem(),
                      enabled: !widget.isLoading,
                      validator: (value) => _serialNumberRequired &&
                              (value == null || value.trim().isEmpty)
                          ? 'Укажите серийный номер'
                          : null,
                    ),
                  ),
                  if (_serviceLifeRequired) const SizedBox(width: 16),
                ],
                if (_serviceLifeRequired)
                  Expanded(
                    child: TextFormField(
                      controller: _serviceLifeController,
                      decoration: const InputDecoration(
                        labelText: 'Срок службы (мес.) *',
                        border: OutlineInputBorder(),
                        hintText: 'Для СИЗ/спецодежды',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateItem(),
                      enabled: !widget.isLoading,
                      validator: (value) {
                        if (_serviceLifeRequired &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Укажите срок службы';
                        }
                        final months = int.tryParse(value ?? '');
                        if (value != null &&
                            value.isNotEmpty &&
                            (months == null || months <= 0)) {
                          return 'Введите положительное число';
                        }
                        return null;
                      },
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Примечание',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => _updateItem(),
            enabled: !widget.isLoading,
          ),
        ],
      ),
    );
  }
}
