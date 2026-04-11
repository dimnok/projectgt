import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/employees/presentation/providers/employee_avatar_controller.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_business_trip_summary_widget.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_rate_summary_widget.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_trip_editor_form.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_atmosphere.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_employee_edit_blocks.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;

/// Детальная карточка сотрудника для мобильного списка (bottom sheet).
///
/// Показывает основные поля, ставки и суточные.
class EmployeesMobileEmployeeDetailsSheet {
  EmployeesMobileEmployeeDetailsSheet._();

  /// Открывает bottom sheet с данными сотрудника.
  static Future<void> show(
    BuildContext context, {
    required Employee employee,
    required List<ObjectEntity> objects,
  }) async {
    final screenWidth = MediaQuery.sizeOf(context).width;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (_, ref, __) {
            final state = ref.watch(employee_state.employeeProvider);
            final emp =
                state.employees.where((e) => e.id == employee.id).firstOrNull ??
                employee;

            void closeSheet() {
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            }

            void showTripEditor([BusinessTripRate? rate]) {
              EmployeeTripEditorForm.show(
                sheetContext,
                employee: emp,
                existingRate: rate,
                onSaved: () {},
              );
            }

            final theme = Theme.of(sheetContext);
            final scheme = theme.colorScheme;
            final labelStyle =
                theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.35,
                ) ??
                TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.35,
                );
            final valueStyle =
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(fontWeight: FontWeight.w600);

            return MobileBottomSheetContent(
              title: 'Сотрудник',
              scrollable: true,
              sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
              footer: GTSecondaryButton(text: 'Закрыть', onPressed: closeSheet),
              child: _EmployeesMobileEmployeeDetailsBody(
                employee: emp,
                objects: objects,
                theme: theme,
                labelStyle: labelStyle,
                valueStyle: valueStyle,
                onAddBusinessTrip: () => showTripEditor(),
                onEditBusinessTrip: showTripEditor,
              ),
            );
          },
        );
      },
    );
  }
}

/// Содержимое прокрутки: шапка и секции без обёртки sheet.
class _EmployeesMobileEmployeeDetailsBody extends ConsumerWidget {
  const _EmployeesMobileEmployeeDetailsBody({
    required this.employee,
    required this.objects,
    required this.theme,
    required this.labelStyle,
    required this.valueStyle,
    required this.onAddBusinessTrip,
    required this.onEditBusinessTrip,
  });

  final Employee employee;
  final List<ObjectEntity> objects;
  final ThemeData theme;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final VoidCallback onAddBusinessTrip;
  final void Function(BusinessTripRate rate) onEditBusinessTrip;

  static const double _avatarSide = 72;
  static const double _avatarRadius = 12;
  static const double _sectionRadius = 12;
  static const EdgeInsets _sectionPadding = EdgeInsets.fromLTRB(14, 12, 14, 14);

  /// Блок с тонкой рамкой и скруглением (секция или шапка без заголовка).
  ///
  /// [titleTrailing] — компактная кнопка редактирования справа от заголовка.
  static Widget _sectionCard(
    ThemeData theme, {
    String? title,
    Widget? titleTrailing,
    required List<Widget> children,
  }) {
    final scheme = theme.colorScheme;
    final borderColor = scheme.outline.withValues(alpha: 0.22);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: title != null
          ? _sectionPadding
          : const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_sectionRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (titleTrailing != null) titleTrailing,
              ],
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  /// Компактная кнопка «изменить» в заголовке секции карточки.
  static Widget _sectionEditButton(
    BuildContext context, {
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        icon: Icon(Icons.edit_outlined, size: 20, color: scheme.primary),
      ),
    );
  }

  /// Нижний лист с действиями по фото (галерея, камера, сохранить, удалить).
  static Future<void> _openAvatarActionsSheet(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final hasPhoto =
        employee.photoUrl != null && employee.photoUrl!.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetCtx) {
        Widget tile({
          required IconData icon,
          required String title,
          required VoidCallback onTap,
          Color? titleColor,
        }) {
          return ListTile(
            leading: Icon(icon, color: titleColor ?? scheme.onSurface),
            title: Text(
              title,
              style: TextStyle(
                color: titleColor ?? scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onTap,
          );
        }

        void runAfterClose(VoidCallback action) {
          Navigator.pop(sheetCtx);
          Future<void>.microtask(() {
            if (context.mounted) action();
          });
        }

        return MobileBottomSheetContent(
          title: 'Фото',
          scrollable: false,
          sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(
                icon: CupertinoIcons.photo_on_rectangle,
                title: 'Выбрать из галереи',
                onTap: () => runAfterClose(() {
                  ref
                      .read(employeeAvatarControllerProvider.notifier)
                      .uploadAvatar(employee, ImageSource.gallery, context);
                }),
              ),
              tile(
                icon: CupertinoIcons.camera,
                title: 'Сделать фото',
                onTap: () => runAfterClose(() {
                  ref
                      .read(employeeAvatarControllerProvider.notifier)
                      .uploadAvatar(employee, ImageSource.camera, context);
                }),
              ),
              if (hasPhoto) ...[
                const Divider(height: 1),
                tile(
                  icon: CupertinoIcons.cloud_download,
                  title: 'Сохранить фото',
                  onTap: () => runAfterClose(() {
                    final notifier = ref.read(
                      employeeAvatarControllerProvider.notifier,
                    );
                    notifier.downloadAvatar(context, employee);
                  }),
                ),
                tile(
                  icon: CupertinoIcons.delete,
                  title: 'Удалить фото',
                  titleColor: scheme.error,
                  onTap: () => runAfterClose(() {
                    _confirmDeleteAvatar(context, ref, employee);
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Future<void> _confirmDeleteAvatar(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Удалить фото?'),
        content: const Text(
          'Изображение будет удалено из карточки и из хранилища.',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: GTSecondaryButton(
                    text: 'Отмена',
                    onPressed: () => Navigator.pop(dialogCtx, false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GTPrimaryButton(
                    text: 'Удалить',
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(employeeAvatarControllerProvider.notifier)
          .deleteAvatar(employee, context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = theme.colorScheme;
    final (statusText, statusColor) = EmployeeUIUtils.getStatusInfo(
      employee.status,
    );
    final employmentColor = _employmentTypeColor(employee.employmentType);
    final objectNames = _objectNamesLine(employee, objects);
    final hasPhoto =
        employee.photoUrl != null && employee.photoUrl!.trim().isNotEmpty;
    final initials = _initials(employee);
    final avatarAsync = ref.watch(employeeAvatarControllerProvider);
    final isAvatarBusy = avatarAsync is AsyncLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          theme,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  label: 'Фото сотрудника, открыть действия',
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () =>
                          _openAvatarActionsSheet(context, ref, employee),
                      borderRadius: BorderRadius.circular(_avatarRadius),
                      child: SizedBox(
                        width: _avatarSide,
                        height: _avatarSide,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: _avatarSide,
                              height: _avatarSide,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  _avatarRadius,
                                ),
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.25),
                                ),
                                color: scheme.surfaceContainerHighest,
                              ),
                              child: hasPhoto
                                  ? CachedNetworkImage(
                                      imageUrl: employee.photoUrl!.trim(),
                                      width: _avatarSide,
                                      height: _avatarSide,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                            if (isAvatarBusy)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _avatarRadius,
                                  ),
                                  child: ColoredBox(
                                    color: scheme.scrim.withValues(alpha: 0.45),
                                    child: Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Icon(
                                    CupertinoIcons.camera_fill,
                                    size: 14,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              employee.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                          _sectionEditButton(
                            context,
                            tooltip: 'Изменить ФИО, работу и контакты',
                            onPressed: () {
                              EmployeesMobileEmployeeEditBlocks.showProfileEditor(
                                context,
                                employee: employee,
                                objects: objects,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        employee.position?.trim().isNotEmpty == true
                            ? employee.position!.trim()
                            : 'Должность не указана',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: employmentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              EmployeeUIUtils.getEmploymentTypeText(
                                employee.employmentType,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: employmentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv(
              theme,
              'Телефон',
              employee.phone?.trim().isNotEmpty == true
                  ? employee.phone!.trim()
                  : '—',
            ),
            _kv(
              theme,
              'Дата приёма',
              employee.employmentDate != null
                  ? formatRuDate(employee.employmentDate!)
                  : '—',
            ),
            _kv(
              theme,
              'Текущая ставка',
              employee.currentHourlyRate != null
                  ? formatCurrency(employee.currentHourlyRate!)
                  : '—',
            ),
            _kv(theme, 'Объекты', objectNames.isNotEmpty ? objectNames : '—'),
          ],
        ),
        _sectionCard(
          theme,
          title: 'Ставки и суточные',
          children: [
            EmployeeRateSummaryWidget(
              employee: employee,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
              theme: theme,
            ),
            EmployeeBusinessTripSummaryWidget(
              employee: employee,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
              theme: theme,
              onAddBusinessTrip: onAddBusinessTrip,
              onEditBusinessTrip: onEditBusinessTrip,
            ),
          ],
        ),
        _sectionCard(
          theme,
          title: 'Документы',
          titleTrailing: _sectionEditButton(
            context,
            tooltip: 'Изменить документы',
            onPressed: () {
              EmployeesMobileEmployeeEditBlocks.showDocumentsEditor(
                context,
                employee: employee,
              );
            },
          ),
          children: [
            _kv(theme, 'Паспорт', _passportLine(employee)),
            _kv(theme, 'Кем выдан', _dashIfEmpty(employee.passportIssuedBy)),
            _kv(
              theme,
              'Дата выдачи',
              employee.passportIssueDate != null
                  ? formatRuDate(employee.passportIssueDate!)
                  : '—',
            ),
            _kv(
              theme,
              'Код подразделения',
              _dashIfEmpty(employee.passportDepartmentCode),
            ),
            _kv(theme, 'ИНН', _dashIfEmpty(employee.inn)),
            _kv(theme, 'СНИЛС', _dashIfEmpty(employee.snils)),
            _kv(
              theme,
              'Адрес регистрации',
              _dashIfEmpty(employee.registrationAddress),
            ),
          ],
        ),
        _sectionCard(
          theme,
          title: 'Личные данные',
          titleTrailing: _sectionEditButton(
            context,
            tooltip: 'Изменить личные данные',
            onPressed: () {
              EmployeesMobileEmployeeEditBlocks.showPersonalEditor(
                context,
                employee: employee,
              );
            },
          ),
          children: [
            _kv(
              theme,
              'Дата рождения',
              employee.birthDate != null
                  ? formatRuDate(employee.birthDate!)
                  : '—',
            ),
            _kv(theme, 'Место рождения', _dashIfEmpty(employee.birthPlace)),
            _kv(theme, 'Гражданство', _dashIfEmpty(employee.citizenship)),
            _kv(theme, 'Размер одежды', _dashIfEmpty(employee.clothingSize)),
            _kv(theme, 'Размер обуви', _dashIfEmpty(employee.shoeSize)),
            _kv(theme, 'Рост', _dashIfEmpty(employee.height)),
          ],
        ),
      ],
    );
  }

  /// Подпись уменьшена ([TextTheme.labelSmall]); значение без обрезки, переносится целиком.
  static Widget _kv(ThemeData theme, String label, String value) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  static String _dashIfEmpty(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? '—' : t;
  }

  static Color _employmentTypeColor(EmploymentType type) {
    switch (type) {
      case EmploymentType.official:
        return Colors.blue;
      case EmploymentType.unofficial:
        return Colors.orange;
      case EmploymentType.contractor:
        return Colors.purple;
    }
  }

  static String _objectNamesLine(Employee e, List<ObjectEntity> objects) {
    const fallback = ObjectEntity(id: '', companyId: '', name: '', address: '');
    if (e.objectIds.isEmpty) return '';
    return e.objectIds
        .map(
          (id) => objects
              .firstWhere((o) => o.id == id, orElse: () => fallback)
              .name,
        )
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  static String _passportLine(Employee e) {
    final s = e.passportSeries?.trim() ?? '';
    final n = e.passportNumber?.trim() ?? '';
    if (s.isEmpty && n.isEmpty) return '—';
    return '$s $n'.trim();
  }

  static String _initials(Employee e) {
    final l = e.lastName.trim();
    final f = e.firstName.trim();
    String one(String x) =>
        x.isEmpty ? '' : String.fromCharCode(x.runes.first).toUpperCase();
    final a = one(l);
    final b = one(f);
    if (a.isEmpty && b.isEmpty) return '?';
    return '$a$b';
  }
}
