import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/employee_application.dart';
import 'package:projectgt/features/employees/presentation/utils/employee_application_upload_flow.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/features/profile/presentation/screens/pdf_preview_screen.dart';
import 'package:projectgt/features/profile/presentation/widgets/application_form_widgets.dart';
import 'package:projectgt/features/profile/utils/profile_pdf_generator.dart';

/// Открывает форму заявления на отпуск для [employee].
Future<void> showEmployeeVacationApplicationForm(
  BuildContext context, {
  required Employee employee,
  required WidgetRef ref,
}) {
  return _showEmployeeApplicationFormShell(
    context,
    title: 'Ежегодный отпуск',
    child: _EmployeeVacationApplicationFormBody(
      employee: employee,
      ref: ref,
    ),
  );
}

/// Открывает форму заявления на отпуск без содержания для [employee].
Future<void> showEmployeeUnpaidLeaveApplicationForm(
  BuildContext context, {
  required Employee employee,
  required WidgetRef ref,
}) {
  return _showEmployeeApplicationFormShell(
    context,
    title: 'Отпуск без содержания',
    child: _EmployeeUnpaidLeaveApplicationFormBody(
      employee: employee,
      ref: ref,
    ),
  );
}

/// Открывает форму заявления об увольнении для [employee].
Future<void> showEmployeeResignationApplicationForm(
  BuildContext context, {
  required Employee employee,
  required WidgetRef ref,
}) {
  return _showEmployeeApplicationFormShell(
    context,
    title: 'Увольнение',
    child: _EmployeeResignationApplicationFormBody(
      employee: employee,
      ref: ref,
    ),
  );
}

Future<void> _showEmployeeApplicationFormShell(
  BuildContext context, {
  required String title,
  required Widget child,
}) async {
  final useDesktop = EmployeesLayoutUtils.useEmployeesDesktopModal(context);

  if (useDesktop) {
    await DesktopDialogContent.show<void>(
      context,
      title: title,
      width: 640,
      child: child,
    );
    return;
  }

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
    builder: (ctx) => MobileBottomSheetContent(
      title: title,
      scrollable: true,
      child: child,
    ),
  );
}

class _EmployeeVacationApplicationFormBody extends StatefulWidget {
  const _EmployeeVacationApplicationFormBody({
    required this.employee,
    required this.ref,
  });

  final Employee employee;
  final WidgetRef ref;

  @override
  State<_EmployeeVacationApplicationFormBody> createState() =>
      _EmployeeVacationApplicationFormBodyState();
}

class _EmployeeVacationApplicationFormBodyState
    extends State<_EmployeeVacationApplicationFormBody> {
  late DateTime _startDate;
  int _durationDays = 14;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 14));
    _recalculateEndDate();
  }

  void _recalculateEndDate() {
    _endDate = _startDate.add(Duration(days: _durationDays - 1));
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
      helpText: 'НАЧАЛО ОТПУСКА',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _recalculateEndDate();
      });
    }
  }

  void _setDuration(int days) {
    setState(() {
      _durationDays = days;
      _recalculateEndDate();
    });
  }

  void _openPdfPreview() {
    final fullName = widget.employee.fullName;
    final startDateStr = formatRuDate(_startDate);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfPreviewScreen(
          fileName:
              'Заявление_на_отпуск_${fullName.replaceAll(' ', '_')}_$startDateStr',
          buildPdf: (format) => ProfilePdfGenerator.generateVacationPdf(
            format: format,
            fullName: fullName,
            startDate: _startDate,
            endDate: _endDate,
            durationDays: _durationDays,
            date: DateTime.now(),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadScan() async {
    await uploadEmployeeApplicationSignedScan(
      context: context,
      ref: widget.ref,
      employeeId: widget.employee.id,
      applicationType: EmployeeApplicationType.vacation,
      startDate: _startDate,
      endDate: _endDate,
      durationDays: _durationDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.employee.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Дата начала отпуска',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectStartDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.calendar, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(formatRuDate(_startDate), style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('Изменить', style: TextStyle(color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Количество дней',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ApplicationDurationChip(
                label: '7 дней',
                selected: _durationDays == 7,
                onTap: () => _setDuration(7),
              ),
              const SizedBox(width: 8),
              ApplicationDurationChip(
                label: '14 дней',
                selected: _durationDays == 14,
                onTap: () => _setDuration(14),
              ),
              const SizedBox(width: 8),
              ApplicationDurationChip(
                label: '28 дней',
                selected: _durationDays == 28,
                onTap: () => _setDuration(28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Период: с ${formatRuDate(_startDate)} по ${formatRuDate(_endDate)} '
            '($_durationDays дн.)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GTPrimaryButton(
          text: 'Просмотр и печать',
          icon: CupertinoIcons.doc_text_search,
          onPressed: _openPdfPreview,
        ),
        const SizedBox(height: 10),
        GTSecondaryButton(
          text: 'Загрузить подписанный скан',
          icon: CupertinoIcons.cloud_upload,
          onPressed: _uploadScan,
        ),
      ],
    );
  }
}

class _EmployeeUnpaidLeaveApplicationFormBody extends StatefulWidget {
  const _EmployeeUnpaidLeaveApplicationFormBody({
    required this.employee,
    required this.ref,
  });

  final Employee employee;
  final WidgetRef ref;

  @override
  State<_EmployeeUnpaidLeaveApplicationFormBody> createState() =>
      _EmployeeUnpaidLeaveApplicationFormBodyState();
}

class _EmployeeUnpaidLeaveApplicationFormBodyState
    extends State<_EmployeeUnpaidLeaveApplicationFormBody> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _durationDays = 1;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 1));
    _endDate = _startDate;
    _calculateDuration();
  }

  void _calculateDuration() {
    _durationDays = _endDate.difference(_startDate).inDays + 1;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        _calculateDuration();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculateDuration();
      });
    }
  }

  void _openPdfPreview() {
    final fullName = widget.employee.fullName;
    final startDateStr = formatRuDate(_startDate);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfPreviewScreen(
          fileName:
              'Заявление_на_БС_${fullName.replaceAll(' ', '_')}_$startDateStr',
          buildPdf: (format) => ProfilePdfGenerator.generateUnpaidLeavePdf(
            format: format,
            fullName: fullName,
            startDate: _startDate,
            durationDays: _durationDays,
            date: DateTime.now(),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadScan() async {
    await uploadEmployeeApplicationSignedScan(
      context: context,
      ref: widget.ref,
      employeeId: widget.employee.id,
      applicationType: EmployeeApplicationType.unpaidLeave,
      startDate: _startDate,
      endDate: _endDate,
      durationDays: _durationDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.employee.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ApplicationDateSelector(
                label: 'С какого числа',
                date: _startDate,
                onTap: _selectStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ApplicationDateSelector(
                label: 'По какое число',
                date: _endDate,
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Дней: $_durationDays',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        GTPrimaryButton(
          text: 'Просмотр и печать',
          icon: CupertinoIcons.doc_text_search,
          onPressed: _openPdfPreview,
        ),
        const SizedBox(height: 10),
        GTSecondaryButton(
          text: 'Загрузить подписанный скан',
          icon: CupertinoIcons.cloud_upload,
          onPressed: _uploadScan,
        ),
      ],
    );
  }
}

class _EmployeeResignationApplicationFormBody extends StatefulWidget {
  const _EmployeeResignationApplicationFormBody({
    required this.employee,
    required this.ref,
  });

  final Employee employee;
  final WidgetRef ref;

  @override
  State<_EmployeeResignationApplicationFormBody> createState() =>
      _EmployeeResignationApplicationFormBodyState();
}

class _EmployeeResignationApplicationFormBodyState
    extends State<_EmployeeResignationApplicationFormBody> {
  late DateTime _dismissalDate;

  @override
  void initState() {
    super.initState();
    _dismissalDate = DateTime.now().add(const Duration(days: 14));
  }

  Future<void> _selectDismissalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dismissalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
      helpText: 'ДАТА УВОЛЬНЕНИЯ',
    );
    if (picked != null) {
      setState(() => _dismissalDate = picked);
    }
  }

  void _openPdfPreview() {
    final fullName = widget.employee.fullName;
    final dismissalDateStr = formatRuDate(_dismissalDate);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfPreviewScreen(
          fileName:
              'Заявление_на_увольнение_${fullName.replaceAll(' ', '_')}_$dismissalDateStr',
          buildPdf: (format) => ProfilePdfGenerator.generateResignationPdf(
            format: format,
            fullName: fullName,
            dismissalDate: _dismissalDate,
            date: DateTime.now(),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadScan() async {
    await uploadEmployeeApplicationSignedScan(
      context: context,
      ref: widget.ref,
      employeeId: widget.employee.id,
      applicationType: EmployeeApplicationType.resignation,
      startDate: _dismissalDate,
      durationDays: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.employee.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ApplicationDateSelector(
          label: 'Дата увольнения',
          date: _dismissalDate,
          onTap: _selectDismissalDate,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Последний рабочий день: ${formatRuDate(_dismissalDate)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GTPrimaryButton(
          text: 'Просмотр и печать',
          icon: CupertinoIcons.doc_text_search,
          onPressed: _openPdfPreview,
        ),
        const SizedBox(height: 10),
        GTSecondaryButton(
          text: 'Загрузить подписанный скан',
          icon: CupertinoIcons.cloud_upload,
          onPressed: _uploadScan,
        ),
      ],
    );
  }
}
