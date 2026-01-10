import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_form_content.dart';
import 'package:uuid/uuid.dart';

/// Модальное окно для создания или редактирования объекта.
class ObjectFormModal extends ConsumerStatefulWidget {
  /// Объект для редактирования. Если null, создается новый.
  final ObjectEntity? object;

  /// Колбэк при успешном сохранении.
  final Function(bool isNew) onSuccess;

  /// Создаёт модальное окно формы объекта.
  const ObjectFormModal({super.key, this.object, required this.onSuccess});

  /// Статический метод для отображения формы.
  static Future<void> show(
    BuildContext context, {
    ObjectEntity? object,
    required Function(bool) onSuccess,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ObjectFormModal(object: object, onSuccess: onSuccess),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (context) =>
            ObjectFormModal(object: object, onSuccess: onSuccess),
      );
    }
  }

  @override
  ConsumerState<ObjectFormModal> createState() => _ObjectFormModalState();
}

class _ObjectFormModalState extends ConsumerState<ObjectFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.object?.name ?? '');
    _addressController = TextEditingController(
      text: widget.object?.address ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.object?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // #region agent log
    debugPrint('AGENT_LOG: {"location": "object_form_modal.dart:_handleSave", "message": "Entering _handleSave", "hypothesisId": "A"}');
    // #endregion

    setState(() => _isLoading = true);

    final activeCompanyId = ref.read(activeCompanyIdProvider);
    // #region agent log
    debugPrint('AGENT_LOG: {"location": "object_form_modal.dart:_handleSave", "message": "activeCompanyId check", "data": {"activeCompanyId": "$activeCompanyId"}, "hypothesisId": "A"}');
    // #endregion
    if (activeCompanyId == null) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Активная компания не выбрана');
        setState(() => _isLoading = false);
      }
      return;
    }

    final isNew = widget.object == null;
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
      final notifier = ref.read(objectProvider.notifier);
      if (isNew) {
        await notifier.addObject(object);
      } else {
        await notifier.updateObject(object);
      }

      // Проверяем статус после операции
      final finalState = ref.read(objectProvider);
      if (finalState.status == ObjectStatus.error) {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            finalState.errorMessage ?? 'Ошибка при сохранении объекта',
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      if (mounted) {
        // Вызываем колбэк успеха ДО закрытия окна, чтобы родительский виджет
        // мог подготовиться (например, показать Snackbar)
        widget.onSuccess(isNew);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isNew = widget.object == null;
    final title = isNew ? 'Новый объект' : 'Редактировать объект';

    final footer = Row(
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
    );

    final content = ObjectFormContent(
      isNew: isNew,
      isLoading: _isLoading,
      nameController: _nameController,
      addressController: _addressController,
      descriptionController: _descriptionController,
      formKey: _formKey,
      onCancel: () => Navigator.pop(context),
    );

    if (isDesktop) {
      return DesktopDialogContent(title: title, footer: footer, child: content);
    } else {
      return MobileBottomSheetContent(
        title: title,
        footer: footer,
        child: content,
      );
    }
  }
}
