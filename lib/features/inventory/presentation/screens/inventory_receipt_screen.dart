import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/inventory/data/models/inventory_receipt_item_model.dart';
import 'package:projectgt/features/inventory/data/models/inventory_receipt_model.dart';
import 'package:projectgt/features/inventory/data/datasources/inventory_receipt_data_source_impl.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:projectgt/features/inventory/presentation/models/receipt_item_row.dart';
import 'package:projectgt/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:projectgt/features/inventory/presentation/widgets/receipt_item_row_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Экран прихода ТМЦ на склад.
class InventoryReceiptScreen extends ConsumerStatefulWidget {
  /// Создаёт экран прихода ТМЦ.
  ///
  /// [hasReceipt] - начальное состояние переключателя "Есть накладная".
  /// По умолчанию true (с накладной).
  const InventoryReceiptScreen({
    super.key,
    this.hasReceipt = true,
  });

  /// Начальное состояние переключателя "Есть накладная".
  final bool hasReceipt;

  @override
  ConsumerState<InventoryReceiptScreen> createState() =>
      _InventoryReceiptScreenState();
}

class _InventoryReceiptScreenState
    extends ConsumerState<InventoryReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiptNumberController = TextEditingController();
  final _commentController = TextEditingController();

  DateTime? _receiptDate;
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;
  final List<ReceiptItemRow> _items = [];
  bool _isLoading = false;
  bool _isSuppliersLoading = false;
  String? _errorMessage;
  late bool _hasReceipt;
  List<String> _units = [];
  bool _unitsLoading = false;

  @override
  void initState() {
    super.initState();
    _hasReceipt = widget.hasReceipt;
    _loadSuppliers();
    _loadUnits();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isSuppliersLoading = true);
    try {
      final suppliers =
          await ref.read(inventoryRepositoryProvider).getSuppliersForDropdown();
      setState(() {
        _suppliers = suppliers;
        _isSuppliersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSuppliersLoading = false);
    }
  }

  Future<void> _loadUnits() async {
    setState(() => _unitsLoading = true);
    try {
      final units = await ref.read(inventoryRepositoryProvider).getUnits();
      setState(() {
        _units = units;
        _unitsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _unitsLoading = false);
    }
  }

  @override
  void dispose() {
    _receiptNumberController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveReceipt() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final validationError = _validateForm();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final dataSource = SupabaseInventoryReceiptDataSource(client);

      final receiptData = await _prepareReceiptData();
      final itemsData = _prepareReceiptItems();
      await dataSource.createReceipt(
        InventoryReceiptModel(
          id: const Uuid().v4(),
          receiptNumber: receiptData.receiptNumber,
          receiptDate: receiptData.receiptDate,
          supplierId: receiptData.supplierId,
          comment: _hasReceipt
              ? _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim()
              : 'ТМЦ без накладной',
          createdBy: userId,
        ),
        itemsData.receiptItems,
        itemsData.itemStatuses,
        itemsData.itemServiceLives,
      );

      ref.invalidate(inventoryItemsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasReceipt ? 'Накладная успешно создана' : 'ТМЦ успешно добавлено',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isLoading = false;
      });

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(ReceiptItemRow());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  String? _validateForm() {
    if (_items.isEmpty) return 'Добавьте хотя бы одну позицию';

    if (_hasReceipt) {
      if (_receiptDate == null) return 'Выберите дату накладной';
      if (_selectedSupplierId == null) return 'Выберите поставщика';
    } else {
      _receiptDate ??= DateTime.now();
    }

    return null;
  }

  void _toggleReceiptMode() {
    setState(() {
      _hasReceipt = !_hasReceipt;
      _errorMessage = null;
      if (!_hasReceipt) {
        _receiptNumberController.clear();
        _selectedSupplierId = null;
      }
    });
  }

  Future<({String receiptNumber, DateTime receiptDate, String? supplierId})>
      _prepareReceiptData() async {
    final client = Supabase.instance.client;

    if (_hasReceipt) {
      final receiptNumber = _receiptNumberController.text.trim();
      final existingReceipt = await client
          .from('inventory_receipts')
          .select('id')
          .eq('receipt_number', receiptNumber)
          .maybeSingle();

      if (existingReceipt != null) {
        throw Exception(
          'Накладная с номером "$receiptNumber" уже существует. Введите другой номер.',
        );
      }

      return (
        receiptNumber: receiptNumber,
        receiptDate: _receiptDate!,
        supplierId: _selectedSupplierId,
      );
    } else {
      return (
        receiptNumber: 'БЕЗ-НАКЛАДНОЙ-${const Uuid().v4()}',
        receiptDate: _receiptDate ?? DateTime.now(),
        supplierId: null,
      );
    }
  }

  ({
    List<InventoryReceiptItemModel> receiptItems,
    Map<String, InventoryItemStatus> itemStatuses,
    Map<String, int?> itemServiceLives,
  }) _prepareReceiptItems() {
    final receiptItems = <InventoryReceiptItemModel>[];
    final itemStatuses = <String, InventoryItemStatus>{};
    final itemServiceLives = <String, int?>{};

    for (final item in _items) {
      final itemId = const Uuid().v4();
      receiptItems.add(
        InventoryReceiptItemModel(
          id: itemId,
          receiptId: '',
          name: item.name,
          categoryId: item.categoryId,
          unit: item.unit,
          quantity: item.quantity,
          price: item.price,
          total: (item.price ?? 0.0) * item.quantity,
          serialNumber: item.serialNumber,
          notes: item.notes,
        ),
      );
      itemStatuses[itemId] = item.status;
      itemServiceLives[itemId] = item.serviceLifeMonths;
    }

    return (
      receiptItems: receiptItems,
      itemStatuses: itemStatuses,
      itemServiceLives: itemServiceLives,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        appBar: AppBarWidget(
          title: 'Приход ТМЦ',
          leading: BackButton(),
          showThemeSwitch: false,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Приход ТМЦ',
        leading: BackButton(),
        showThemeSwitch: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: InkWell(
                            onTap: _isLoading ? null : _toggleReceiptMode,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Есть накладная',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _hasReceipt
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                        _hasReceipt ? Colors.green : Colors.red,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_hasReceipt)
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Данные накладной',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _isLoading
                                            ? null
                                            : () async {
                                                final picked =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: _receiptDate ??
                                                      DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime.now(),
                                                );
                                                if (picked != null) {
                                                  setState(() {
                                                    _receiptDate = picked;
                                                  });
                                                }
                                              },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Дата *',
                                            border: OutlineInputBorder(),
                                            prefixIcon:
                                                Icon(Icons.calendar_today),
                                          ),
                                          child: Text(
                                            _receiptDate != null
                                                ? formatRuDate(_receiptDate!)
                                                : 'Выберите дату',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _receiptNumberController,
                                        decoration: const InputDecoration(
                                          labelText: 'Номер накладной *',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Введите номер накладной';
                                          }
                                          return null;
                                        },
                                        enabled: !_isLoading,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _suppliers.isEmpty &&
                                              !_isSuppliersLoading
                                          ? Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme.errorContainer
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    color:
                                                        theme.colorScheme.error,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'В системе нет поставщиков. Добавьте поставщика в разделе "Справочники → Контрагенты" с типом "Поставщик".',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: theme
                                                            .colorScheme.error,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : GTDropdown<String>(
                                              items: _suppliers
                                                  .map((s) => s['id'] as String)
                                                  .toList(),
                                              selectedItem: _selectedSupplierId,
                                              itemDisplayBuilder: (id) {
                                                final supplier =
                                                    _suppliers.firstWhere(
                                                  (s) => s['id'] == id,
                                                  orElse: () => {},
                                                );
                                                if (supplier.isEmpty) return '';
                                                final shortName =
                                                    supplier['short_name']
                                                        as String?;
                                                final fullName =
                                                    supplier['full_name']
                                                        as String?;
                                                return (shortName?.isNotEmpty ==
                                                        true)
                                                    ? shortName!
                                                    : fullName ?? '';
                                              },
                                              onSelectionChanged: (supplierId) {
                                                if (_isLoading) return;
                                                setState(() {
                                                  _selectedSupplierId =
                                                      supplierId;
                                                  _errorMessage =
                                                      null; // Очищаем ошибку при выборе
                                                });
                                              },
                                              labelText: 'Поставщик *',
                                              hintText: 'Выберите поставщика',
                                              isLoading: _isSuppliersLoading,
                                              readOnly: _isLoading,
                                              validator: (value) {
                                                if (_selectedSupplierId ==
                                                    null) {
                                                  return 'Выберите поставщика';
                                                }
                                                return null;
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Комментарий',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  enabled: !_isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _hasReceipt ? 'Позиции накладной' : 'Позиции ТМЦ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _addItem,
                            icon: const Icon(Icons.add),
                            label: Text(_hasReceipt
                                ? 'Добавить позицию'
                                : 'Добавить ТМЦ'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Нет позиций',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _hasReceipt
                                        ? 'Добавьте позиции накладной'
                                        : 'Добавьте позиции ТМЦ',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Card(
                            margin: EdgeInsets.only(
                                bottom: index == _items.length - 1 ? 0 : 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: ReceiptItemRowWidget(
                              item: item,
                              index: index,
                              onChanged: (updatedItem) {
                                setState(() {
                                  _items[index] = updatedItem;
                                });
                              },
                              onRemove: () => _removeItem(index),
                              isLoading: _isLoading,
                              units: _units,
                              unitsLoading: _unitsLoading,
                            ),
                          );
                        }),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveReceipt,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _hasReceipt
                                  ? 'Сохранить накладную'
                                  : 'Сохранить ТМЦ',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
