import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_atmosphere.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:uuid/uuid.dart';

/// Где отображается форма быстрого добавления сотрудника.
///
/// Задаётся при открытии из [AddEmployeeSimpleDialog.show], чтобы не опираться
/// на [MediaQuery] внутри узкого [Dialog] (иначе можно ошибочно выбрать мобильную вёрстку).
enum AddEmployeeSimpleSurface {
  /// Центрированный диалог ([DesktopDialogContent]).
  desktopDialog,

  /// Модальная панель снизу на ширину экрана ([showModalBottomSheet]).
  mobileBottomSheet,
}

/// Простое модальное окно для быстрого добавления сотрудника.
///
/// Запрашивает только самые необходимые данные: ФИО, телефон и объекты.
class AddEmployeeSimpleDialog extends ConsumerStatefulWidget {
  /// Поверхность отображения (диалог или bottom sheet).
  final AddEmployeeSimpleSurface surface;

  /// Создаёт содержимое модалки быстрого добавления сотрудника.
  const AddEmployeeSimpleDialog({super.key, required this.surface});

  /// Показывает форму добавления: на десктопе — диалог, иначе — bottom sheet на всю ширину.
  static Future<bool?> show(BuildContext context) {
    final useDesktopDialog =
        EmployeesLayoutUtils.useEmployeesDesktopModal(context);
    if (useDesktopDialog) {
      return showDialog<bool>(
        context: context,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: AddEmployeeSimpleDialog(
            surface: AddEmployeeSimpleSurface.desktopDialog,
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddEmployeeSimpleDialog(
        surface: AddEmployeeSimpleSurface.mobileBottomSheet,
      ),
    );
  }

  @override
  ConsumerState<AddEmployeeSimpleDialog> createState() =>
      _AddEmployeeSimpleDialogState();
}

class _AddEmployeeSimpleDialogState
    extends ConsumerState<AddEmployeeSimpleDialog> {
  final _formKey = GlobalKey<FormState>();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<String> _selectedObjectIds = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final lastName = _lastNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      final rawMiddleName = _middleNameController.text.trim();
      final middleName = rawMiddleName.isEmpty ? null : rawMiddleName;

      final companyId = ref.read(activeCompanyIdProvider);
      if (companyId == null) {
        throw Exception('Не выбрана компания');
      }

      final now = DateTime.now();

      final newEmployee = Employee(
        id: const Uuid().v4(),
        companyId: companyId,
        lastName: lastName,
        firstName: firstName,
        middleName: middleName,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        objectIds: _selectedObjectIds,
        status: EmployeeStatus.working,
        employmentType: EmploymentType.unofficial,
        employmentDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await ref
          .read(state.employeeProvider.notifier)
          .createEmployee(newEmployee);

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Сотрудник успешно добавлен');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка при добавлении: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildForm() {
    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GTTextField(
            controller: _lastNameController,
            labelText: 'Фамилия *',
            hintText: 'Иванов',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [GtFormatters.nameFormatter()],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите фамилию';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _firstNameController,
            labelText: 'Имя *',
            hintText: 'Иван',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [GtFormatters.nameFormatter()],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите имя';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _middleNameController,
            labelText: 'Отчество',
            hintText: 'Иванович',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [GtFormatters.nameFormatter()],
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _phoneController,
            labelText: 'Контактный телефон',
            hintText: '+7 (999) 000-00-00',
            keyboardType: TextInputType.phone,
            inputFormatters: [GtFormatters.phoneFormatter()],
          ),
          const SizedBox(height: 16),
          GTDropdown<ObjectEntity>(
            items: objects,
            itemDisplayBuilder: (obj) => obj.name,
            labelText: 'Объекты *',
            hintText: 'Выберите объекты',
            allowMultipleSelection: true,
            selectedItems: objects
                .where((o) => _selectedObjectIds.contains(o.id))
                .toList(),
            onMultiSelectionChanged: (selected) {
              setState(() {
                _selectedObjectIds = selected.map((e) => e.id).toList();
              });
            },
            validator: (value) {
              if (_selectedObjectIds.isEmpty) {
                return 'Выберите хотя бы один объект';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: 'Добавить',
            onPressed: _isLoading ? null : _save,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = _buildForm();
    final footer = _buildFooter();

    switch (widget.surface) {
      case AddEmployeeSimpleSurface.desktopDialog:
        return DesktopDialogContent(
          title: 'Добавить сотрудника',
          width: 500,
          footer: footer,
          child: form,
        );
      case AddEmployeeSimpleSurface.mobileBottomSheet:
        return MobileBottomSheetContent(
          title: 'Добавить сотрудника',
          sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
          footer: footer,
          child: form,
        );
    }
  }
}
