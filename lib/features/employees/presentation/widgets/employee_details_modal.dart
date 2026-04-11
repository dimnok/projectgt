import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_context_menu.dart';
import 'package:projectgt/features/employees/presentation/providers/employee_avatar_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_business_trip_summary_widget.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_trip_editor_form.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_rate_summary_widget.dart';
import 'package:projectgt/features/employees/presentation/widgets/editable_inline_text_row.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_edit_form.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as employee_state;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Модальное окно с детальной информацией о сотруднике.
class EmployeeDetailsModal extends ConsumerStatefulWidget {
  /// Сотрудник, чьи данные отображаются в карточке.
  final Employee employee;

  /// Список объектов компании для отображения привязок сотрудника.
  final List<ObjectEntity> objects;

  /// Связь с заголовком [DesktopDialogContent]: скрыть крестик при `false`.
  ///
  /// Задаётся только при показе через [show]; на экране [EmployeeDetailsScreen] не используется.
  final ValueNotifier<bool>? dialogCloseButtonVisibility;

  /// Создаёт модальное окно с деталями сотрудника.
  const EmployeeDetailsModal({
    super.key,
    required this.employee,
    required this.objects,
    this.dialogCloseButtonVisibility,
  });

  /// Отображает модальное окно с деталями сотрудника.
  static Future<void> show(
    BuildContext context, {
    required Employee employee,
    required List<ObjectEntity> objects,
  }) {
    final closeVisibility = ValueNotifier<bool>(true);
    return DesktopDialogContent.show<void>(
      context,
      title: 'Карточка сотрудника',
      width: 1000,
      barrierDismissible: false,
      closeButtonVisibility: closeVisibility,
      child: EmployeeDetailsModal(
        employee: employee,
        objects: objects,
        dialogCloseButtonVisibility: closeVisibility,
      ),
    ).whenComplete(closeVisibility.dispose);
  }

  @override
  ConsumerState<EmployeeDetailsModal> createState() =>
      _EmployeeDetailsModalState();
}

class _EmployeeDetailsModalState extends ConsumerState<EmployeeDetailsModal> {
  bool _isEditing = false;
  late Employee _employee;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _syncDialogCloseButton();
  }

  /// Скрывает крестик диалога в режиме редактирования (закрытие — через «Отмена» / после сохранения).
  void _syncDialogCloseButton() {
    widget.dialogCloseButtonVisibility?.value = !_isEditing;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Подписываемся на обновления сотрудника из провайдера
    final employeeState = ref.watch(employee_state.employeeProvider);
    final updatedEmployee = employeeState.employees.where((e) => e.id == _employee.id).firstOrNull;
    if (updatedEmployee != null) {
      _employee = updatedEmployee;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              ),
            );
          },
          child: _isEditing
              ? EmployeeEditForm(
                  key: const ValueKey('edit_form'),
                  employee: _employee,
                  objects: widget.objects,
                  onCancel: () {
                    setState(() => _isEditing = false);
                    _syncDialogCloseButton();
                  },
                  onSaved: (updatedEmployee) {
                    setState(() {
                      _employee = updatedEmployee;
                      _isEditing = false;
                    });
                    _syncDialogCloseButton();
                  },
                )
              : Column(
                  key: const ValueKey('view_info'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainInfo(theme),
                    const SizedBox(height: 24),
                    _buildFinancialInfo(theme),
                    const SizedBox(height: 24),
                    _buildAdditionalInfo(theme),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final (statusText, statusColor) = EmployeeUIUtils.getStatusInfo(
      _employee.status,
    );

    final hasPhoto = _employee.photoUrl != null;
    final avatarController = ref.watch(employeeAvatarControllerProvider);
    final isLoadingAvatar = avatarController is AsyncLoading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTapDown: (details) {
            if (!_isEditing && !hasPhoto) return;

            final items = <dynamic>[];

            if (_isEditing) {
              if (hasPhoto) {
                items.add(
                  GTContextMenuItem(
                    icon: CupertinoIcons.camera,
                    label: 'Заменить фото',
                    onTap: () => ref.read(employeeAvatarControllerProvider.notifier).uploadAvatar(_employee, ImageSource.gallery, context),
                  ),
                );
              } else {
                items.add(
                  GTContextMenuItem(
                    icon: CupertinoIcons.photo,
                    label: 'Выбрать из галереи',
                    onTap: () => ref.read(employeeAvatarControllerProvider.notifier).uploadAvatar(_employee, ImageSource.gallery, context),
                  ),
                );
                items.add(
                  GTContextMenuItem(
                    icon: CupertinoIcons.camera,
                    label: 'Сделать фото',
                    onTap: () => ref.read(employeeAvatarControllerProvider.notifier).uploadAvatar(_employee, ImageSource.camera, context),
                  ),
                );
              }
            }

            if (hasPhoto) {
              if (items.isNotEmpty) items.add(const Divider(height: 8));
              items.add(
                GTContextMenuItem(
                  icon: CupertinoIcons.cloud_download,
                  label: 'Скачать',
                  onTap: () {
                    // Сохраняем ссылку на notifier до закрытия контекстного меню
                    final notifier = ref.read(employeeAvatarControllerProvider.notifier);
                    // Вызываем метод асинхронно, чтобы меню успело закрыться
                    Future.microtask(() {
                      if (!mounted) return;
                      notifier.downloadAvatar(context, _employee);
                    });
                  },
                ),
              );
            }

            if (_isEditing && hasPhoto) {
              items.add(const Divider(height: 8));
              items.add(
                GTContextMenuItem(
                  icon: CupertinoIcons.delete,
                  label: 'Удалить',
                  isDestructive: true,
                  onTap: () => ref.read(employeeAvatarControllerProvider.notifier).deleteAvatar(_employee, context),
                ),
              );
            }

            if (items.isNotEmpty) {
              GTContextMenu.show(
                context: context,
                tapPosition: details.globalPosition,
                items: items,
                onDismiss: () {},
              );
            }
          },
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: hasPhoto
                    ? CachedNetworkImageProvider(_employee.photoUrl!)
                    : null,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: isLoadingAvatar
                    ? const CircularProgressIndicator()
                    : (!hasPhoto
                        ? Icon(
                            CupertinoIcons.person,
                            size: 48,
                            color: theme.colorScheme.primary,
                          )
                        : null),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isEditing ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: _isEditing ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                      ),
                      child: Icon(
                        CupertinoIcons.camera_fill,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: !_isEditing
                    ? Text(
                        _employee.fullName,
                        key: const ValueKey('name_text'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        'Редактирование профиля',
                        key: const ValueKey('edit_text'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
                child: !_isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_employee.position != null &&
                              _employee.position!.isNotEmpty) ...[
                            Text(
                              _employee.position!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusText,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEmploymentTypeColor(
                                    _employee.employmentType,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getEmploymentTypeColor(
                                      _employee.employmentType,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  EmployeeUIUtils.getEmploymentTypeText(
                                    _employee.employmentType,
                                  ),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: _getEmploymentTypeColor(
                                      _employee.employmentType,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getEmploymentTypeColor(EmploymentType type) {
    switch (type) {
      case EmploymentType.official:
        return Colors.blue;
      case EmploymentType.unofficial:
        return Colors.orange;
      case EmploymentType.contractor:
        return Colors.purple;
    }
  }

  Widget _buildMainInfo(ThemeData theme) {
    final objectNames = _employee.objectIds
        .map(
          (id) => widget.objects
              .firstWhere(
                (o) => o.id == id,
                orElse: () => const ObjectEntity(
                  id: '',
                  companyId: '',
                  name: '—',
                  address: '',
                ),
              )
              .name,
        )
        .where((name) => name != '—')
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Основная информация',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              _InfoItem(
                icon: CupertinoIcons.calendar,
                label: 'Дата приёма',
                value: _employee.employmentDate != null
                    ? formatRuDate(_employee.employmentDate!)
                    : 'Не указана',
              ),
              _InfoItem(
                icon: CupertinoIcons.money_rubl,
                label: 'Ставка',
                value: _employee.currentHourlyRate != null
                    ? formatCurrency(_employee.currentHourlyRate!)
                    : 'Не указана',
              ),
              _InfoItem(
                icon: CupertinoIcons.phone,
                label: 'Телефон',
                value: _employee.phone?.isNotEmpty == true
                    ? _employee.phone!
                    : 'Не указан',
              ),
              _InfoItem(
                icon: CupertinoIcons.building_2_fill,
                label: 'Объекты',
                value: objectNames.isNotEmpty ? objectNames : 'Нет привязки',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Финансовые условия',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        EmployeeRateSummaryWidget(
          employee: _employee,
          labelStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
          valueStyle:
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(),
          theme: theme,
        ),
        EmployeeBusinessTripSummaryWidget(
          employee: _employee,
          onAddBusinessTrip: _showBusinessTripModal,
          onEditBusinessTrip: _showBusinessTripModal,
          labelStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
          valueStyle:
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Личные данные',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.pencil, size: 20),
              color: theme.colorScheme.primary,
              tooltip: 'Редактировать личные данные',
              onPressed: () {
                setState(() => _isEditing = true);
                _syncDialogCloseButton();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Паспорт',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildPassportSeriesNumberAndCitizenship(),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Выдан',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildPassportIssueDateAndCode(),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'Кем выдан',
                value: _employee.passportIssuedBy?.isNotEmpty == true
                    ? _employee.passportIssuedBy!
                    : '—',
                isEditing: false,
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Дата рождения',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        _formatBirthDateWithAge(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'Место рождения',
                value: _employee.birthPlace?.isNotEmpty == true
                    ? _employee.birthPlace!
                    : '—',
                isEditing: false,
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'Адрес регистрации',
                value: _employee.registrationAddress?.isNotEmpty == true
                    ? _employee.registrationAddress!
                    : '—',
                isEditing: false,
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'ИНН',
                value: _employee.inn?.isNotEmpty == true ? _employee.inn! : '—',
                isEditing: false,
              ),
              _buildDivider(),
              EditableInlineTextRow(
                label: 'СНИЛС',
                value: _employee.snils?.isNotEmpty == true
                    ? _employee.snils!
                    : '—',
                isEditing: false,
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Размеры',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildSizesInfoRow(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassportSeriesNumberAndCitizenship() {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
    const valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    final items = <Widget>[];

    if (_employee.passportSeries?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Серия  ', style: labelStyle),
        TextSpan(text: _employee.passportSeries!, style: valueStyle),
      ])));
    }
    if (_employee.passportNumber?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Номер  ', style: labelStyle),
        TextSpan(text: _employee.passportNumber!, style: valueStyle),
      ])));
    }
    if (_employee.citizenship?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Гражданство  ', style: labelStyle),
        TextSpan(text: _employee.citizenship!, style: valueStyle),
      ])));
    }

    if (items.isEmpty) {
      return const Text('—', style: TextStyle(fontWeight: FontWeight.w500));
    }

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildPassportIssueDateAndCode() {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
    const valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    final items = <Widget>[];

    if (_employee.passportIssueDate != null) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Дата  ', style: labelStyle),
        TextSpan(text: formatRuDate(_employee.passportIssueDate!), style: valueStyle),
      ])));
    }
    if (_employee.passportDepartmentCode?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Код  ', style: labelStyle),
        TextSpan(text: GtFormatters.formatPassportDepartmentCode(_employee.passportDepartmentCode), style: valueStyle),
      ])));
    }

    if (items.isEmpty) {
      return const Text('—', style: TextStyle(fontWeight: FontWeight.w500));
    }

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildSizesInfoRow() {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
    const valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    final items = <Widget>[];

    if (_employee.clothingSize?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Одежда  ', style: labelStyle),
        TextSpan(text: _employee.clothingSize!, style: valueStyle),
      ])));
    }
    if (_employee.shoeSize?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Обувь  ', style: labelStyle),
        TextSpan(text: _employee.shoeSize!, style: valueStyle),
      ])));
    }
    if (_employee.height?.isNotEmpty == true) {
      items.add(Text.rich(TextSpan(children: [
        TextSpan(text: 'Рост  ', style: labelStyle),
        TextSpan(text: _employee.height!, style: valueStyle),
      ])));
    }

    if (items.isEmpty) {
      return const Text('—', style: TextStyle(fontWeight: FontWeight.w500));
    }

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: items,
    );
  }

  String _formatBirthDateWithAge() {
    if (_employee.birthDate == null) return '—';
    
    final now = DateTime.now();
    int age = now.year - _employee.birthDate!.year;
    if (now.month < _employee.birthDate!.month || (now.month == _employee.birthDate!.month && now.day < _employee.birthDate!.day)) {
      age--;
    }
    
    String ageText;
    final lastDigit = age % 10;
    final lastTwoDigits = age % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      ageText = 'лет';
    } else if (lastDigit == 1) {
      ageText = 'год';
    } else if (lastDigit >= 2 && lastDigit <= 4) {
      ageText = 'года';
    } else {
      ageText = 'лет';
    }
    
    return '${formatRuDate(_employee.birthDate!)} ($age $ageText)';
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }

  /// Показывает модальное окно для настройки суточных.
  void _showBusinessTripModal([BusinessTripRate? rate]) {
    EmployeeTripEditorForm.show(
      context,
      employee: _employee,
      existingRate: rate,
      onSaved: () {},
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
