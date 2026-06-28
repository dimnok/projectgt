import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/features/profile/presentation/screens/pdf_preview_screen.dart';
import 'package:projectgt/features/profile/utils/profile_pdf_generator.dart';
import 'package:projectgt/features/profile/presentation/widgets/application_form_widgets.dart';

/// Форма для подачи заявления об увольнении по собственному желанию.
class ResignationForm extends ConsumerStatefulWidget {
  /// Профиль сотрудника.
  final Profile profile;

  /// Создаёт форму заявления об увольнении.
  const ResignationForm({super.key, required this.profile});

  @override
  ConsumerState<ResignationForm> createState() => _ResignationFormState();
}

class _ResignationFormState extends ConsumerState<ResignationForm> {
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

    if (picked != null && picked != _dismissalDate) {
      setState(() => _dismissalDate = picked);
    }
  }

  void _openPdfPreview() {
    final fullName = widget.profile.fullName ?? 'Сотрудник';
    final dismissalDateStr = formatRuDate(_dismissalDate);

    Navigator.of(context).push(
      MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Дата увольнения',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        ApplicationDateSelector(
          label: 'Последний рабочий день',
          date: _dismissalDate,
          onTap: _selectDismissalDate,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'По ТК РФ уведомление об увольнении подаётся '
                  'не позднее чем за 2 недели.',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
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
            const SizedBox(width: 12),
            Expanded(
              child: GTPrimaryButton(
                text: 'Просмотр',
                icon: CupertinoIcons.doc_text_search,
                onPressed: _openPdfPreview,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
