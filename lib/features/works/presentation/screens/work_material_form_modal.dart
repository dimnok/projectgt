import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_material.dart';
import '../providers/work_materials_provider.dart';
import 'package:uuid/uuid.dart';

/// Модальное окно для добавления или редактирования материала в смене.
class WorkMaterialFormModal extends ConsumerStatefulWidget {
  /// Идентификатор смены.
  final String workId;

  /// Начальные данные для редактирования (null для создания новой записи).
  final WorkMaterial? initial;

  /// Создаёт модальное окно для добавления или редактирования материала.
  const WorkMaterialFormModal({super.key, required this.workId, this.initial});

  @override
  ConsumerState<WorkMaterialFormModal> createState() =>
      _WorkMaterialFormModalState();
}

class _WorkMaterialFormModalState extends ConsumerState<WorkMaterialFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController unitController;
  late TextEditingController quantityController;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    nameController = TextEditingController(text: i?.name ?? '');
    unitController = TextEditingController(text: i?.unit ?? '');
    quantityController =
        TextEditingController(text: i?.quantity.toString() ?? '');
    commentController = TextEditingController(text: i?.comment ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    unitController.dispose();
    quantityController.dispose();
    commentController.dispose();
    super.dispose();
  }

  /// Сохраняет или обновляет запись о материале.
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final material = WorkMaterial(
      id: widget.initial?.id ?? const Uuid().v4(),
      workId: widget.workId,
      name: nameController.text.trim(),
      unit: unitController.text.trim(),
      quantity: num.tryParse(quantityController.text) ?? 0,
      comment: commentController.text.trim().isEmpty
          ? null
          : commentController.text.trim(),
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.initial == null) {
      await ref
          .read(workMaterialsProvider(widget.workId).notifier)
          .add(material);
    } else {
      await ref
          .read(workMaterialsProvider(widget.workId).notifier)
          .update(material);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок с кнопкой закрытия
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.initial == null
                              ? 'Добавить материал'
                              : 'Редактировать материал',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        style:
                            IconButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Карточка с основным содержимым
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withAlpha(51),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Информационный заголовок
                          Text('Информация о материале',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),

                          // Наименование
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Наименование',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                              helperText: 'Укажите название материала',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Обязательное поле'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Единица измерения
                          TextFormField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Единица измерения',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.straighten_outlined),
                              helperText: 'Например: шт, м, кг, л',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Обязательное поле'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Количество
                          TextFormField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Количество',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers_outlined),
                              helperText: 'Укажите количество материала',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Обязательное поле';
                              }
                              if (num.tryParse(v) == null) {
                                return 'Введите корректное число';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Комментарий
                          TextFormField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              labelText: 'Комментарий (необязательно)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.comment_outlined),
                              helperText:
                                  'Добавьте дополнительную информацию при необходимости',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Кнопки в стиле окна "Открытие смены"
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
