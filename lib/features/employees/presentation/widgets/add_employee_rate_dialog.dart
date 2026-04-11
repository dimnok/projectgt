import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_atmosphere.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as employee_state;

/// Где показывается форма изменения ставки.
enum AddEmployeeRateSurface {
  /// Центрированный диалог ([DesktopDialogContent]).
  desktopDialog,

  /// Нижняя панель ([MobileBottomSheetContent]) как в остальном мобильном модуле.
  mobileBottomSheet,
}

/// Диалог добавления новой часовой ставки сотрудника.
class AddEmployeeRateDialog extends ConsumerStatefulWidget {
  /// Сотрудник, которому добавляется ставка.
  final Employee employee;

  /// Поверхность отображения.
  final AddEmployeeRateSurface surface;

  /// Создаёт диалог добавления ставки.
  const AddEmployeeRateDialog({
    super.key,
    required this.employee,
    this.surface = AddEmployeeRateSurface.desktopDialog,
  });

  /// Показывает форму: на десктопе — диалог, иначе — bottom sheet.
  static Future<bool?> show(BuildContext context, Employee employee) {
    if (EmployeesLayoutUtils.useEmployeesDesktopModal(context)) {
      return DesktopDialogContent.show<bool>(
        context,
        title: 'Изменение ставки',
        width: 400,
        child: AddEmployeeRateDialog(
          employee: employee,
          surface: AddEmployeeRateSurface.desktopDialog,
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
      builder: (context) => AddEmployeeRateDialog(
        employee: employee,
        surface: AddEmployeeRateSurface.mobileBottomSheet,
      ),
    );
  }

  @override
  ConsumerState<AddEmployeeRateDialog> createState() =>
      _AddEmployeeRateDialogState();
}

class _AddEmployeeRateDialogState extends ConsumerState<AddEmployeeRateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rateController;
  DateTime _validFrom = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.employee.currentHourlyRate?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final rateText = _rateController.text.trim();
    final newRate = double.tryParse(rateText);

    if (newRate == null || newRate <= 0) {
      SnackBarUtils.showError(context, 'Введите корректную сумму ставки');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final setRateUseCase = ref.read(setEmployeeRateUseCaseProvider);
      await setRateUseCase(widget.employee.id, newRate, _validFrom);

      ref.invalidate(getEmployeeRatesUseCaseProvider);
      await ref
          .read(employee_state.employeeProvider.notifier)
          .getEmployee(widget.employee.id);

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Ставка успешно обновлена');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка при сохранении ставки: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _validFromDateRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Дата начала действия *',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _validFrom,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) {
                setState(() => _validFrom = date);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatRuDate(_validFrom),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Новая ставка закроет предыдущую (если она была) и начнёт действовать с указанной даты.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: _rateController,
          labelText: 'Почасовая ставка (₽/час) *',
          hintText: 'Например, 500',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          borderRadius: 12,
          textInputAction: TextInputAction.done,
          onEditingComplete: _unfocus,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Обязательное поле';
            final val = double.tryParse(v.trim());
            if (val == null || val <= 0) return 'Некорректная сумма';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _validFromDateRow(context),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Закрыть',
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GTPrimaryButton(
            text: 'Сохранить',
            onPressed: _isLoading ? null : _save,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.surface) {
      case AddEmployeeRateSurface.desktopDialog:
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormFields(context),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GTSecondaryButton(
                    text: 'Отмена',
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 12),
                  GTPrimaryButton(
                    text: 'Сохранить',
                    onPressed: _isLoading ? null : _save,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ],
          ),
        );
      case AddEmployeeRateSurface.mobileBottomSheet:
        return MobileBottomSheetContent(
          title: 'Изменение ставки',
          scrollable: true,
          sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
          footer: _buildActionRow(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.employee.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: _buildFormFields(context),
              ),
            ],
          ),
        );
    }
  }
}
