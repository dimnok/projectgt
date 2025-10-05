import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';

// Новый stateless-контент для формы
/// Виджет формы создания/редактирования объекта недвижимости.
///
/// Используется для ввода и редактирования информации об объекте: наименование, адрес, описание.
/// Поддерживает адаптивный дизайн, валидацию и управление состоянием загрузки.
///
/// Пример использования:
/// ```dart
/// ObjectFormContent(
///   isNew: true,
///   isLoading: false,
///   nameController: nameController,
///   addressController: addressController,
///   descriptionController: descriptionController,
///   formKey: formKey,
///   onSave: _handleSave,
///   onCancel: () => Navigator.pop(context),
/// )
/// ```
class ObjectFormContent extends StatelessWidget {
  /// Флаг: true — форма создания, false — форма редактирования.
  final bool isNew;

  /// Флаг: true — форма/кнопки заблокированы, отображается индикатор загрузки.
  final bool isLoading;

  /// Контроллер для поля "Наименование".
  final TextEditingController nameController;

  /// Контроллер для поля "Адрес".
  final TextEditingController addressController;

  /// Контроллер для поля "Описание".
  final TextEditingController descriptionController;

  /// Ключ формы для валидации.
  final GlobalKey<FormState> formKey;

  /// Колбэк для сохранения (создания/обновления) объекта.
  final VoidCallback onSave;

  /// Колбэк для отмены и закрытия формы.
  final VoidCallback onCancel;

  /// Конструктор [ObjectFormContent].
  ///
  /// Все параметры обязательны для корректной работы формы.
  const ObjectFormContent({
    super.key,
    required this.isNew,
    required this.isLoading,
    required this.nameController,
    required this.addressController,
    required this.descriptionController,
    required this.formKey,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок и кнопка закрытия
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isNew ? 'Новый объект' : 'Редактировать объект',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        style:
                            IconButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: onCancel,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Основная информация
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Информация об объекте',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Наименование
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Наименование *',
                            hintText: 'Введите наименование',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Введите наименование'
                              : null,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        // Адрес
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Адрес *',
                            hintText: 'Введите адрес',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Введите адрес'
                              : null,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        // Описание
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Описание',
                            hintText: 'Введите описание',
                          ),
                          minLines: 2,
                          maxLines: 4,
                          enabled: !isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Кнопки управления
                Row(
                  children: [
                    // Кнопка Отмена
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
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
                    // Кнопка Сохранить
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CupertinoActivityIndicator(),
                              )
                            : Text(isNew ? 'Создать' : 'Сохранить'),
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

/// Экран создания/редактирования объекта недвижимости.
///
/// Использует [ObjectFormContent] для отображения формы и управления состоянием.
/// Поддерживает сценарии создания нового объекта и редактирования существующего.
class ObjectFormScreen extends ConsumerStatefulWidget {
  /// Объект для редактирования. Если null — создаётся новый объект.
  final ObjectEntity? object;

  /// Колбэк, вызываемый после успешного сохранения (для показа уведомления).
  final void Function(bool isNew)? onSuccess;

  /// Конструктор [ObjectFormScreen].
  ///
  /// [object] — объект для редактирования, если null — форма создания.
  /// [onSuccess] — колбэк после успешного сохранения (true — создание, false — редактирование).
  const ObjectFormScreen({super.key, this.object, this.onSuccess});

  @override
  ConsumerState<ObjectFormScreen> createState() => _ObjectFormScreenState();
}

/// Состояние для [ObjectFormScreen].
///
/// Управляет контроллерами, валидацией, загрузкой и обработкой событий формы.
class _ObjectFormScreenState extends ConsumerState<ObjectFormScreen> {
  /// Ключ формы для валидации.
  final _formKey = GlobalKey<FormState>();

  /// Контроллер для поля "Наименование".
  final _nameController = TextEditingController();

  /// Контроллер для поля "Адрес".
  final _addressController = TextEditingController();

  /// Контроллер для поля "Описание".
  final _descriptionController = TextEditingController();

  /// Флаг состояния загрузки (true — кнопки заблокированы, показывается индикатор).
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.object != null) {
      _nameController.text = widget.object!.name;
      _addressController.text = widget.object!.address;
      _descriptionController.text = widget.object!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Обрабатывает нажатие на кнопку "Сохранить".
  ///
  /// Валидирует форму, формирует [ObjectEntity] и вызывает add/update через провайдер.
  /// После успешного сохранения закрывает экран.
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(objectProvider.notifier);
    final isNew = widget.object == null;
    final object = ObjectEntity(
      id: widget.object?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    try {
      if (isNew) {
        await notifier.addObject(object);
      } else {
        await notifier.updateObject(object);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call(isNew);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.object == null;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar:
          AppBarWidget(title: isNew ? 'Новый объект' : 'Редактировать объект'),
      body: ObjectFormContent(
        isNew: isNew,
        isLoading: _isLoading,
        nameController: _nameController,
        addressController: _addressController,
        descriptionController: _descriptionController,
        formKey: _formKey,
        onSave: _handleSave,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
