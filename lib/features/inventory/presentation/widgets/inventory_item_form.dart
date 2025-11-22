import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Форма для создания/редактирования ТМЦ.
class InventoryItemForm extends ConsumerStatefulWidget {
  /// ТМЦ для редактирования (null для создания нового).
  final InventoryItem? item;

  /// Коллбэк при сохранении.
  final Function(InventoryItem) onSave;

  /// Коллбэк при отмене.
  final VoidCallback onCancel;

  /// Создаёт экземпляр [InventoryItemForm].
  const InventoryItemForm({
    super.key,
    this.item,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<InventoryItemForm> createState() => _InventoryItemFormState();
}

class _InventoryItemFormState extends ConsumerState<InventoryItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _client = Supabase.instance.client;

  // Контроллеры текстовых полей
  late final TextEditingController _nameController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _serviceLifeController;
  late final TextEditingController _notesController;

  // Выбранные значения
  Map<String, dynamic>? _selectedCategory;
  InventoryItemStatus _selectedStatus = InventoryItemStatus.new_;
  InventoryItemCondition _selectedCondition = InventoryItemCondition.new_;
  InventoryLocationType _selectedLocationType = InventoryLocationType.warehouse;
  Map<String, dynamic>? _selectedLocation;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiresDate;

  // Списки для dropdown
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _employees = [];

  // Флаги загрузки
  bool _isLoadingCategories = true;
  bool _isLoadingObjects = true;
  bool _isLoadingEmployees = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeValues();
    _loadData();
  }

  void _initializeControllers() {
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _serialNumberController =
        TextEditingController(text: item?.serialNumber ?? '');
    _unitController = TextEditingController(text: item?.unit ?? 'шт.');
    _quantityController =
        TextEditingController(text: (item?.quantity ?? 1.0).toString());
    _priceController =
        TextEditingController(text: item?.price?.toString() ?? '');
    _serviceLifeController =
        TextEditingController(text: item?.serviceLifeMonths?.toString() ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
  }

  void _initializeValues() {
    final item = widget.item;
    if (item != null) {
      _selectedStatus = item.status;
      _selectedCondition = item.condition;
      _selectedLocationType = item.locationType;
      _purchaseDate = item.purchaseDate;
      _warrantyExpiresDate = item.warrantyExpiresAt;
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadObjects(),
      _loadEmployees(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _client
          .from('inventory_categories')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      if (!mounted) return;
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _isLoadingCategories = false;

        // Устанавливаем выбранную категорию если редактируем
        if (widget.item != null) {
          _selectedCategory = _categories.firstWhere(
            (cat) => cat['id'] == widget.item!.categoryId,
            orElse: () => {},
          );
          if (_selectedCategory!.isEmpty) _selectedCategory = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadObjects() async {
    try {
      final response = await _client
          .from('objects')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      if (!mounted) return;
      setState(() {
        _objects = List<Map<String, dynamic>>.from(response);
        _isLoadingObjects = false;

        // Устанавливаем выбранный объект если редактируем
        if (widget.item != null &&
            widget.item!.locationType == InventoryLocationType.object &&
            widget.item!.locationId != null) {
          _selectedLocation = _objects.firstWhere(
            (obj) => obj['id'] == widget.item!.locationId,
            orElse: () => {},
          );
          if (_selectedLocation!.isEmpty) _selectedLocation = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingObjects = false);
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await _client
          .from('employees')
          .select('id, first_name, last_name, middle_name')
          .eq('status', 'working')
          .order('last_name');

      if (!mounted) return;
      setState(() {
        _employees = List<Map<String, dynamic>>.from(response);
        _isLoadingEmployees = false;

        // Устанавливаем выбранного сотрудника если редактируем
        if (widget.item != null &&
            widget.item!.locationType == InventoryLocationType.employee &&
            widget.item!.locationId != null) {
          _selectedLocation = _employees.firstWhere(
            (emp) => emp['id'] == widget.item!.locationId,
            orElse: () => {},
          );
          if (_selectedLocation!.isEmpty) _selectedLocation = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _serviceLifeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Для новых записей Supabase автоматически генерирует UUID
      // Для существующих используем текущий ID
      final isNewItem = widget.item == null || widget.item!.id.isEmpty;

      final inventoryItem = InventoryItem(
        id: isNewItem ? '' : widget.item!.id,
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!['id'] as String,
        categoryName: _selectedCategory!['name'] as String,
        serialNumber: _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(),
        unit: _unitController.text.trim(),
        quantity: double.tryParse(_quantityController.text) ?? 1.0,
        status: _selectedStatus,
        condition: _selectedCondition,
        locationType: _selectedLocationType,
        locationId: _selectedLocation?['id'] as String?,
        locationName: _getLocationName(),
        price: double.tryParse(_priceController.text),
        purchaseDate: _purchaseDate,
        warrantyExpiresAt: _warrantyExpiresDate,
        serviceLifeMonths: int.tryParse(_serviceLifeController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.item?.createdAt,
        updatedAt: DateTime.now(),
        createdBy: widget.item?.createdBy,
        updatedBy: Supabase.instance.client.auth.currentUser?.id,
      );

      widget.onSave(inventoryItem);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  String? _getLocationName() {
    if (_selectedLocation == null) return null;

    switch (_selectedLocationType) {
      case InventoryLocationType.object:
        return _selectedLocation!['name'] as String?;
      case InventoryLocationType.employee:
        final firstName = _selectedLocation!['first_name'] as String? ?? '';
        final lastName = _selectedLocation!['last_name'] as String? ?? '';
        final middleName = _selectedLocation!['middle_name'] as String? ?? '';
        return '$lastName $firstName${middleName.isNotEmpty ? ' $middleName' : ''}';
      default:
        return 'Склад';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Наименование
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Наименование *',
                hintText: 'Введите наименование ТМЦ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите наименование';
                }
                return null;
              },
              readOnly: _isSaving,
            ),
            const SizedBox(height: 16),

            // Категория
            GTDropdown<Map<String, dynamic>>(
              items: _categories,
              selectedItem: _selectedCategory,
              itemDisplayBuilder: (category) =>
                  category['name'] as String? ?? '',
              onSelectionChanged: (category) {
                if (_isSaving || category == null) return;
                setState(() => _selectedCategory = category);
              },
              labelText: 'Категория *',
              hintText: 'Выберите категорию',
              isLoading: _isLoadingCategories,
              readOnly: _isSaving,
              validator: (value) => value == null ? 'Выберите категорию' : null,
            ),
            const SizedBox(height: 16),

            // Количество и единица измерения
            Row(
              children: [
                // Количество
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Количество *',
                      hintText: '1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,3}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите количество';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Некорректное количество';
                      }
                      return null;
                    },
                    readOnly: _isSaving,
                  ),
                ),
                const SizedBox(width: 16),

                // Единица измерения
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: 'Ед. изм. *',
                      hintText: 'шт.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите ед. изм.';
                      }
                      return null;
                    },
                    readOnly: _isSaving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Серийный номер
            TextFormField(
              controller: _serialNumberController,
              decoration: InputDecoration(
                labelText: 'Серийный номер',
                hintText: 'Введите серийный номер (если есть)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              readOnly: _isSaving,
            ),
            const SizedBox(height: 16),

            // Состояние и статус
            Row(
              children: [
                // Состояние при приходе
                Expanded(
                  child: GTDropdown<InventoryItemCondition>(
                    items: InventoryItemCondition.values,
                    selectedItem: _selectedCondition,
                    itemDisplayBuilder: (condition) =>
                        _getConditionLabel(condition),
                    onSelectionChanged: (condition) {
                      if (_isSaving || condition == null) return;
                      setState(() => _selectedCondition = condition);
                    },
                    labelText: 'Состояние',
                    hintText: 'Выберите состояние',
                    readOnly: _isSaving,
                  ),
                ),
                const SizedBox(width: 16),

                // Статус
                Expanded(
                  child: GTDropdown<InventoryItemStatus>(
                    items: InventoryItemStatus.values,
                    selectedItem: _selectedStatus,
                    itemDisplayBuilder: (status) => _getStatusLabel(status),
                    onSelectionChanged: (status) {
                      if (_isSaving || status == null) return;
                      setState(() => _selectedStatus = status);
                    },
                    labelText: 'Статус',
                    hintText: 'Выберите статус',
                    readOnly: _isSaving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Тип местоположения
            GTDropdown<InventoryLocationType>(
              items: InventoryLocationType.values,
              selectedItem: _selectedLocationType,
              itemDisplayBuilder: (type) => _getLocationTypeLabel(type),
              onSelectionChanged: (type) {
                if (_isSaving || type == null) return;
                setState(() {
                  _selectedLocationType = type;
                  _selectedLocation =
                      null; // Сбрасываем выбранное местоположение
                });
              },
              labelText: 'Тип местоположения',
              hintText: 'Выберите тип',
              readOnly: _isSaving,
            ),
            const SizedBox(height: 16),

            // Конкретное местоположение в зависимости от типа
            if (_selectedLocationType == InventoryLocationType.object)
              GTDropdown<Map<String, dynamic>>(
                items: _objects,
                selectedItem: _selectedLocation,
                itemDisplayBuilder: (obj) => obj['name'] as String? ?? '',
                onSelectionChanged: (obj) {
                  if (_isSaving) return;
                  setState(() => _selectedLocation = obj);
                },
                labelText: 'Объект',
                hintText: 'Выберите объект',
                isLoading: _isLoadingObjects,
                readOnly: _isSaving,
              )
            else if (_selectedLocationType == InventoryLocationType.employee)
              GTDropdown<Map<String, dynamic>>(
                items: _employees,
                selectedItem: _selectedLocation,
                itemDisplayBuilder: (emp) {
                  final firstName = emp['first_name'] as String? ?? '';
                  final lastName = emp['last_name'] as String? ?? '';
                  final middleName = emp['middle_name'] as String? ?? '';
                  return '$lastName $firstName${middleName.isNotEmpty ? ' ${middleName.substring(0, 1)}.' : ''}';
                },
                onSelectionChanged: (emp) {
                  if (_isSaving) return;
                  setState(() => _selectedLocation = emp);
                },
                labelText: 'Сотрудник',
                hintText: 'Выберите сотрудника',
                isLoading: _isLoadingEmployees,
                readOnly: _isSaving,
              ),
            if (_selectedLocationType != InventoryLocationType.warehouse)
              const SizedBox(height: 16),

            // Цена и даты в одной строке
            Row(
              children: [
                // Цена
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Цена',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    readOnly: _isSaving,
                  ),
                ),
                const SizedBox(width: 16),

                // Дата приобретения
                Expanded(
                  child: InkWell(
                    onTap: _isSaving
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _purchaseDate = date);
                            }
                          },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Дата приобретения',
                        hintText: 'Выберите дату',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _purchaseDate != null
                            ? formatRuDate(_purchaseDate!)
                            : '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Гарантия и срок службы
            Row(
              children: [
                // Гарантия до
                Expanded(
                  child: InkWell(
                    onTap: _isSaving
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _warrantyExpiresDate ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _warrantyExpiresDate = date);
                            }
                          },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Гарантия до',
                        hintText: 'Выберите дату',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _warrantyExpiresDate != null
                            ? formatRuDate(_warrantyExpiresDate!)
                            : '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Срок службы (месяцев)
                Expanded(
                  child: TextFormField(
                    controller: _serviceLifeController,
                    decoration: InputDecoration(
                      labelText: 'Срок службы (мес.)',
                      hintText: '12',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    readOnly: _isSaving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Примечания
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Примечания',
                hintText: 'Дополнительная информация',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              readOnly: _isSaving,
            ),
            const SizedBox(height: 32),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : widget.onCancel,
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.item == null ? 'Создать' : 'Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getConditionLabel(InventoryItemCondition condition) {
    switch (condition) {
      case InventoryItemCondition.new_:
        return 'Новый';
      case InventoryItemCondition.used:
        return 'Б/у';
    }
  }

  String _getStatusLabel(InventoryItemStatus status) {
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

  String _getLocationTypeLabel(InventoryLocationType type) {
    switch (type) {
      case InventoryLocationType.warehouse:
        return 'На складе';
      case InventoryLocationType.object:
        return 'На объекте';
      case InventoryLocationType.employee:
        return 'У сотрудника';
    }
  }
}
