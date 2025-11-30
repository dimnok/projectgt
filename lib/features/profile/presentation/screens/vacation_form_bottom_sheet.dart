import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/features/profile/presentation/screens/pdf_preview_screen.dart';
import 'package:projectgt/features/profile/utils/profile_pdf_generator.dart';
import 'package:projectgt/features/profile/presentation/widgets/application_form_widgets.dart';

/// Форма для подачи заявления на ежегодный оплачиваемый отпуск.
class VacationForm extends ConsumerStatefulWidget {
  /// Профиль сотрудника.
  final Profile profile;

  /// Создаёт форму заявления на отпуск.
  const VacationForm({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<VacationForm> createState() => _VacationFormState();
}

class _VacationFormState extends ConsumerState<VacationForm> {
  final _formKey = GlobalKey<FormState>();

  // Начальная дата (по умолчанию — через 2 недели, по ТК РФ)
  late DateTime _startDate;

  // Количество дней (по умолчанию 14)
  int _durationDays = 14;

  // Конечная дата (рассчитывается автоматически)
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 14));
    _calculateEndDate();
  }

  void _calculateEndDate() {
    // Отпуск в календарных днях
    setState(() {
      _endDate = _startDate.add(Duration(days: _durationDays - 1));
    });
  }

  // Выбор даты начала
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
      helpText: 'НАЧАЛО ОТПУСКА',
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _calculateEndDate();
      });
    }
  }

  // Изменение количества дней
  void _setDuration(int days) {
    setState(() {
      _durationDays = days;
      _calculateEndDate();
    });
  }

  void _incrementDays() {
    setState(() {
      _durationDays++;
      _calculateEndDate();
    });
  }

  void _decrementDays() {
    if (_durationDays > 1) {
      setState(() {
        _durationDays--;
        _calculateEndDate();
      });
    }
  }

  void _openPdfPreview() {
    final fullName = widget.profile.fullName ?? 'Сотрудник';
    final startDateStr = DateFormat('dd.MM.yyyy').format(_startDate);

    Navigator.of(context).push(
      MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Дата начала
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
                  Icon(CupertinoIcons.calendar,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    dateFormat.format(_startDate),
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    'Изменить',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
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

          // Быстрый выбор
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

          // Ручной ввод
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
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

          const SizedBox(height: 24),

          // Итоговая информация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.info_circle,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Итоговый период:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'с ${dateFormat.format(_startDate)} по ${dateFormat.format(_endDate)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'На работу: ${dateFormat.format(_endDate.add(const Duration(days: 1)))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
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
