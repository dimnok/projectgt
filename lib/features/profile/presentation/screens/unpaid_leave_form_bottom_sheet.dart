import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/features/profile/presentation/screens/pdf_preview_screen.dart';
import 'package:projectgt/features/profile/utils/profile_pdf_generator.dart';
import 'package:projectgt/features/profile/presentation/widgets/application_form_widgets.dart';

/// Форма для подачи заявления на отпуск за свой счёт.
class UnpaidLeaveForm extends ConsumerStatefulWidget {
  /// Профиль сотрудника.
  final Profile profile;

  /// Создаёт форму заявления на отпуск за свой счёт.
  const UnpaidLeaveForm({super.key, required this.profile});

  @override
  ConsumerState<UnpaidLeaveForm> createState() => _UnpaidLeaveFormState();
}

class _UnpaidLeaveFormState extends ConsumerState<UnpaidLeaveForm> {
  final _formKey = GlobalKey<FormState>();

  // Начальная дата (по умолчанию — завтра)
  late DateTime _startDate;

  // Конечная дата (по умолчанию — завтра)
  late DateTime _endDate;

  // Количество дней (рассчитывается автоматически)
  int _durationDays = 1;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 1));
    _endDate = _startDate;
    _calculateDuration();
  }

  void _calculateDuration() {
    final difference = _endDate.difference(_startDate).inDays;
    setState(() {
      _durationDays = difference + 1;
    });
  }

  void _updateEndDateFromDuration() {
    setState(() {
      _endDate = _startDate.add(Duration(days: _durationDays - 1));
    });
  }

  // Выбор даты начала
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Если новая дата начала больше конца, сдвигаем конец
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
        _calculateDuration();
      });
    }
  }

  // Выбор даты окончания
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _calculateDuration();
      });
    }
  }

  // Увеличение/уменьшение дней кнопками
  void _incrementDays() {
    setState(() {
      _durationDays++;
      _updateEndDateFromDuration();
    });
  }

  void _decrementDays() {
    if (_durationDays > 1) {
      setState(() {
        _durationDays--;
        _updateEndDateFromDuration();
      });
    }
  }

  void _openPdfPreview() {
    final fullName = widget.profile.fullName ?? 'Сотрудник';
    final startDateStr = formatRuDate(_startDate);

    Navigator.of(context).push(
      MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Выбор дат
          Text(
            'Выберите период',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ApplicationDateSelector(
                  label: 'С какого числа',
                  date: _startDate,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ApplicationDateSelector(
                  label: 'По какое число',
                  date: _endDate,
                  onTap: _selectEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Количество дней
          Text(
            'Количество дней',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _decrementDays,
                  icon: const Icon(CupertinoIcons.minus_circle_fill),
                  color: theme.colorScheme.primary,
                ),
                Text(
                  '$_durationDays',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: _incrementDays,
                  icon: const Icon(CupertinoIcons.add_circled_solid),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Инфо о выходных
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
                    'Отпуск за свой счёт предоставляется по согласованию с руководителем.',
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

          // Кнопки действий
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
      ),
    );
  }
}
