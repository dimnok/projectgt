import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';

/// Экран для создания и редактирования сметы.
///
/// Позволяет вводить и изменять данные по позиции сметы.
class EstimateFormScreen extends ConsumerStatefulWidget {
  /// Идентификатор редактируемой сметы (null для создания).
  final String? estimateId;

  /// Создаёт экран формы сметы.
  const EstimateFormScreen({super.key, this.estimateId});

  @override
  ConsumerState<EstimateFormScreen> createState() => _EstimateFormScreenState();
}

/// Состояние для [EstimateFormScreen].
class _EstimateFormScreenState extends ConsumerState<EstimateFormScreen> {
  /// Ключ формы.
  final _formKey = GlobalKey<FormState>();

  /// Контроллеры для полей формы.
  final _systemController = TextEditingController();
  final _subsystemController = TextEditingController();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _articleController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.estimateId != null) {
      Future.microtask(() async {
        await ref
            .read(estimateNotifierProvider.notifier)
            .selectEstimate(widget.estimateId!);
        final estimate = ref.read(estimateNotifierProvider).selectedEstimate;
        if (estimate != null) {
          _titleController.text = estimate.estimateTitle ?? '';
          _systemController.text = estimate.system;
          _subsystemController.text = estimate.subsystem;
          _numberController.text = estimate.number;
          _nameController.text = estimate.name;
          _articleController.text = estimate.article;
          _manufacturerController.text = estimate.manufacturer;
          _unitController.text = estimate.unit;
          _quantityController.text = estimate.quantity.toString();
          _priceController.text = estimate.price.toString();
          _totalController.text = estimate.total.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _systemController.dispose();
    _subsystemController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _articleController.dispose();
    _manufacturerController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(estimateNotifierProvider.notifier);
    final activeCompanyId = ref.read(activeCompanyIdProvider);
    final estimate = Estimate(
      id: widget.estimateId ?? '',
      companyId: activeCompanyId ?? '',
      system: _systemController.text.trim(),
      subsystem: _subsystemController.text.trim(),
      number: _numberController.text.trim(),
      name: _nameController.text.trim(),
      article: _articleController.text.trim(),
      manufacturer: _manufacturerController.text.trim(),
      unit: _unitController.text.trim(),
      quantity: double.tryParse(
              _quantityController.text.trim().replaceAll(',', '.')) ??
          0,
      price:
          double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ??
              0,
      total:
          double.tryParse(_totalController.text.trim().replaceAll(',', '.')) ??
              0,
      estimateTitle: _titleController.text.trim(),
    );
    if (widget.estimateId == null) {
      await notifier.addEstimate(estimate);
    } else {
      await notifier.updateEstimate(estimate);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.estimateId != null;
    final state = ref.watch(estimateNotifierProvider);
    return Scaffold(
      appBar:
          AppBar(title: Text(isEdit ? 'Редактировать смету' : 'Создать смету')),
      body: state.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: 'Название сметы'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Обязательное поле' : null,
                    ),
                    TextFormField(
                      controller: _systemController,
                      decoration: const InputDecoration(labelText: 'Система'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Обязательное поле' : null,
                    ),
                    TextFormField(
                      controller: _subsystemController,
                      decoration:
                          const InputDecoration(labelText: 'Подсистема'),
                    ),
                    TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(labelText: '№'),
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Наименование материалов/работ'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Обязательное поле' : null,
                    ),
                    TextFormField(
                      controller: _articleController,
                      decoration: const InputDecoration(labelText: 'Артикул'),
                    ),
                    TextFormField(
                      controller: _manufacturerController,
                      decoration:
                          const InputDecoration(labelText: 'Производитель'),
                    ),
                    TextFormField(
                      controller: _unitController,
                      decoration:
                          const InputDecoration(labelText: 'Единица измерения'),
                    ),
                    TextFormField(
                      controller: _quantityController,
                      decoration:
                          const InputDecoration(labelText: 'Количество'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Цена'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _totalController,
                      decoration: const InputDecoration(labelText: 'Сумма'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    GTPrimaryButton(
                      text: isEdit ? 'Сохранить' : 'Создать',
                      onPressed: state.isLoading ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
