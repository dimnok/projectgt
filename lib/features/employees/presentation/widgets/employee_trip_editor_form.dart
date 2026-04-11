import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_atmosphere.dart';
import 'package:uuid/uuid.dart';

/// Где показывается форма суточных.
enum EmployeeTripEditorSurface {
  /// Центрированный диалог ([DesktopDialogContent]).
  desktopDialog,

  /// Нижняя панель ([MobileBottomSheetContent]) как в мобильном модуле сотрудников.
  mobileBottomSheet,
}

/// Форма для добавления/редактирования суточных выплат сотрудника.
///
/// Позволяет настроить ставку суточных для конкретного сотрудника
/// с указанием объекта, суммы и минимального количества часов.
class EmployeeTripEditorForm extends ConsumerStatefulWidget {
  /// Сотрудник, для которого настраиваются суточные.
  final Employee employee;

  /// Существующая ставка для редактирования (опционально).
  final BusinessTripRate? existingRate;

  /// Callback при успешном сохранении.
  final VoidCallback? onSaved;

  /// Поверхность отображения.
  final EmployeeTripEditorSurface surface;

  /// Конструктор [EmployeeTripEditorForm].
  const EmployeeTripEditorForm({
    super.key,
    required this.employee,
    this.existingRate,
    this.onSaved,
    this.surface = EmployeeTripEditorSurface.desktopDialog,
  });

  /// Показывает форму: на десктопе — диалог, иначе — bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required Employee employee,
    BusinessTripRate? existingRate,
    VoidCallback? onSaved,
  }) {
    if (EmployeesLayoutUtils.useEmployeesDesktopModal(context)) {
      return DesktopDialogContent.show<bool>(
        context,
        title: existingRate != null ? 'Изменение суточных' : 'Добавление суточных',
        width: 500,
        child: EmployeeTripEditorForm(
          employee: employee,
          existingRate: existingRate,
          onSaved: onSaved,
          surface: EmployeeTripEditorSurface.desktopDialog,
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
      builder: (context) => EmployeeTripEditorForm(
        employee: employee,
        existingRate: existingRate,
        onSaved: onSaved,
        surface: EmployeeTripEditorSurface.mobileBottomSheet,
      ),
    );
  }

  @override
  ConsumerState<EmployeeTripEditorForm> createState() =>
      EmployeeTripEditorFormState();
}

/// Состояние [EmployeeTripEditorForm] (форма суточных).
class EmployeeTripEditorFormState extends ConsumerState<EmployeeTripEditorForm> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей формы
  final _rateController = TextEditingController();
  final _minimumHoursController = TextEditingController();

  // Выбранные значения
  ObjectEntity? _selectedObject;
  DateTime _validFrom = DateTime.now();
  DateTime? _validTo;

  // Состояние загрузки
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _minimumHoursController.dispose();
    super.dispose();
  }

  /// Инициализация формы с существующими данными.
  void _initializeForm() {
    if (widget.existingRate != null) {
      final rate = widget.existingRate!;
      _rateController.text = rate.rate.toString();
      _minimumHoursController.text = rate.minimumHours.toString();
      _validFrom = rate.validFrom;
      _validTo = rate.validTo;
      // Для объекта потребуется загрузка из провайдера
    }
  }

  /// Обработка сохранения формы.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedObject == null) {
      SnackBarUtils.showError(context, 'Выберите объект');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rate = BusinessTripRate(
        id: widget.existingRate?.id ?? const Uuid().v4(),
        objectId: _selectedObject!.id,
        employeeId: widget.employee.id,
        rate: parseAmount(_rateController.text) ?? 0.0,
        minimumHours: parseAmount(_minimumHoursController.text) ?? 0.0,
        validFrom: _validFrom,
        validTo: _validTo,
      );

      if (widget.existingRate != null) {
        final updateUseCase = ref.read(updateBusinessTripRateUseCaseProvider);
        await updateUseCase(rate);
      } else {
        final createUseCase = ref.read(createBusinessTripRateUseCaseProvider);
        await createUseCase(rate);
      }

      if (mounted) {
        // Сбрасываем кэш и дожидаемся новых данных до закрытия — иначе UI может
        // остаться на предыдущем [AsyncData] до следующего кадра/перезапуска.
        ref.invalidate(employeeBusinessTripRatesProvider(widget.employee.id));
        try {
          await ref.read(
            employeeBusinessTripRatesProvider(widget.employee.id).future,
          );
        } catch (_) {
          // Запись в БД уже успешна; при сбое перечитывания всё равно закрываем форму.
        }
        if (!mounted) return;
        SnackBarUtils.showSuccess(context, 'Суточные сохранены');
        widget.onSaved?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка сохранения: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _sheetTitle => widget.existingRate != null
      ? 'Изменение суточных'
      : 'Добавление суточных';

  void _tripEditorUnfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Строка выбора даты в стиле мобильных форм сотрудников ([MobileBottomSheetContent]).
  Widget _tripDateRow(
    ThemeData theme, {
    required String label,
    required String valueText,
    required Future<void> Function() onPick,
    Widget? trailing,
  }) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await onPick();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
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
                        valueText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
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
      ),
    );
  }

  Widget _buildFieldsColumn(ThemeData theme) {
    final objectsState = ref.watch(objectProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GTDropdown<ObjectEntity>(
          items: objectsState.objects,
          itemDisplayBuilder: (object) => object.name,
          selectedItem: _selectedObject,
          onSelectionChanged: (value) {
            setState(() {
              _selectedObject = value;
            });
          },
          labelText: 'Объект работы',
          hintText: 'Выберите объект',
          allowClear: false,
          borderRadius: 12,
          validator: (value) => value == null || value.isEmpty
              ? 'Выберите объект'
              : null,
        ),
        const SizedBox(height: 24),
        Text(
          'Настройки выплат',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GTTextField(
          controller: _rateController,
          labelText: 'Сумма суточных (₽/смена)',
          hintText: 'Введите сумму',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          borderRadius: 12,
          textInputAction: TextInputAction.next,
          onEditingComplete: _tripEditorUnfocus,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите сумму';
            }
            final number = parseAmount(value);
            if (number == null || number < 0) {
              return 'Введите корректную сумму';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        GTTextField(
          controller: _minimumHoursController,
          labelText: 'Минимум часов для начисления',
          hintText: 'Например: 5',
          helperText:
              'Суточные будут начислены только если сотрудник отработал не менее указанного количества часов',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          borderRadius: 12,
          textInputAction: TextInputAction.done,
          onEditingComplete: _tripEditorUnfocus,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите минимальное количество часов';
            }
            final number = parseAmount(value);
            if (number == null || number < 0) {
              return 'Введите корректное значение';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Период действия',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _tripDateRow(
          theme,
          label: 'Действует с',
          valueText: formatRuDate(_validFrom),
          onPick: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _validFrom,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null && mounted) {
              setState(() => _validFrom = date);
            }
          },
        ),
        _tripDateRow(
          theme,
          label: 'Действует до',
          valueText:
              _validTo != null ? formatRuDate(_validTo!) : 'Бессрочно',
          trailing: _validTo != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Сбросить дату окончания',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    setState(() => _validTo = null);
                  },
                )
              : null,
          onPick: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _validTo ?? _validFrom.add(const Duration(days: 365)),
              firstDate: _validFrom,
              lastDate: DateTime(2030),
            );
            if (date != null && mounted) {
              setState(() => _validTo = date);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Закрыть',
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GTPrimaryButton(
            text: 'Сохранить',
            onPressed: _isLoading ? null : _handleSave,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objectsState = ref.watch(objectProvider);

    if (widget.existingRate != null && _selectedObject == null) {
      final existingObjId = widget.existingRate!.objectId;
      final match =
          objectsState.objects.where((o) => o.id == existingObjId).firstOrNull;
      if (match != null) {
        Future.microtask(() {
          if (mounted && _selectedObject == null) {
            setState(() {
              _selectedObject = match;
            });
          }
        });
      }
    }

    switch (widget.surface) {
      case EmployeeTripEditorSurface.desktopDialog:
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFieldsColumn(theme),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GTSecondaryButton(
                    text: 'Отмена',
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  GTPrimaryButton(
                    text: 'Сохранить',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ],
          ),
        );
      case EmployeeTripEditorSurface.mobileBottomSheet:
        return MobileBottomSheetContent(
          title: _sheetTitle,
          scrollable: true,
          sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
          footer: _buildFooterActions(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.employee.fullName,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: _buildFieldsColumn(theme),
              ),
            ],
          ),
        );
    }
  }
}
