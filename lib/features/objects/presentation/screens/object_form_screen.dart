import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_form_content.dart';

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
    final activeCompanyId = ref.read(activeCompanyIdProvider);

    if (activeCompanyId == null) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Активная компания не выбрана');
        setState(() => _isLoading = false);
      }
      return;
    }

    final object = ObjectEntity(
      id: widget.object?.id ?? const Uuid().v4(),
      companyId: activeCompanyId,
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

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSuccess?.call(isNew);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.object == null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: isNew ? 'Новый объект' : 'Редактировать объект',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        showThemeSwitch: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ObjectFormContent(
                  isNew: isNew,
                  isLoading: _isLoading,
                  nameController: _nameController,
                  addressController: _addressController,
                  descriptionController: _descriptionController,
                  formKey: _formKey,
                  onCancel: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GTSecondaryButton(
                        text: 'Отмена',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GTPrimaryButton(
                        text: isNew ? 'Создать' : 'Сохранить',
                        onPressed: _handleSave,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
