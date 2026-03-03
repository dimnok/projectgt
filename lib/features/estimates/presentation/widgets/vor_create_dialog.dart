import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../providers/estimate_providers.dart';

/// Окно создания новой ведомости ВОР (пошаговый мастер).
///
/// Реализует 3 этапа: выбор периода, выбор систем и финальная выгрузка.
class VorCreateDialog extends ConsumerStatefulWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Создает экземпляр [VorCreateDialog].
  const VorCreateDialog({
    super.key,
    required this.contractId,
  });

  /// Отображает диалог создания ВОР с усиленным затемнением фона.
  static Future<void> show(BuildContext context, String contractId) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Создание ВОР',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: DesktopDialogContent(
              title: 'Сформировать новую ВОР',
              width: 600,
              child: VorCreateDialog(contractId: contractId),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        return FadeTransition(
          opacity: animation,
          child: Transform.scale(
            scale: 0.95 + (0.05 * curvedValue),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<VorCreateDialog> createState() => _VorCreateDialogState();
}

class _VorCreateDialogState extends ConsumerState<VorCreateDialog> {
  int _currentStep = 1;
  DateTimeRange? _selectedDateRange;
  final List<String> _selectedSystems = [];
  bool _isGenerating = false;
  String? _createdVorId;

  Future<void> _nextStep() async {
    if (_currentStep == 2) {
      // При переходе со 2 на 3 этап фактически создаем ВОР в БД
      await _createVor();
    } else {
      setState(() {
        if (_currentStep < 3) _currentStep++;
      });
    }
  }

  Future<void> _createVor() async {
    if (_selectedDateRange == null || _selectedSystems.isEmpty) return;

    setState(() => _isGenerating = true);
    try {
      final actions = ref.read(vorActionsProvider);
      final id = await actions.createVor(
        contractId: widget.contractId,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        systems: _selectedSystems,
      );

      // Сразу после создания записи в БД вызываем генерацию файла
      try {
        // Вызываем Edge Function для генерации и сохранения в Storage,
        // но НЕ скачиваем файл на устройство пользователя на этом этапе.
        await ref.read(vorExportServiceProvider).generateAndSaveVor(id);
      } catch (e) {
        debugPrint('⚠️ Ошибка фоновой генерации Excel: $e');
      }

      setState(() {
        _createdVorId = id;
        _isGenerating = false;
        _currentStep = 3;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании ВОР: $e')),
        );
      }
    }
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  Future<void> _selectDateRange() async {
    final theme = Theme.of(context);
    
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      saveText: 'Выбрать',
      helpText: '',
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
            child: Material(
              color: Colors.transparent,
              child: Localizations.override(
                context: context,
                locale: const Locale('ru', 'RU'),
                delegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                child: Builder(
                  builder: (context) {
                    return Theme(
                      data: theme.copyWith(
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: theme.colorScheme.surface,
                          headerBackgroundColor: theme.colorScheme.surface,
                          headerForegroundColor: theme.colorScheme.onSurface,
                          elevation: 0,
                          rangePickerHeaderHeadlineStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          rangePickerHeaderHelpStyle: const TextStyle(
                            fontSize: 0,
                            height: 0,
                          ),
                          dayStyle: const TextStyle(fontSize: 12),
                          rangeSelectionBackgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          rangeSelectionOverlayColor: WidgetStateProperty.all(
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: child!,
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
          ),
        );
      },
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemsAsync = ref.watch(contractSystemsProvider(widget.contractId));

    return systemsAsync.when(
      data: (systems) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepIndicator(currentStep: _currentStep),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(systems),
          ),
          const SizedBox(height: 32),
          _NavigationButtons(
            currentStep: _currentStep,
            isNextEnabled: _isNextEnabled && !_isGenerating,
            isLoading: _isGenerating,
            onPrev: _prevStep,
            onNext: _nextStep,
          ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CupertinoActivityIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Ошибка загрузки систем: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  bool get _isNextEnabled {
    if (_currentStep == 1) return _selectedDateRange != null;
    if (_currentStep == 2) return _selectedSystems.isNotEmpty;
    return true;
  }

  Widget _buildCurrentStep(List<String> systems) {
    switch (_currentStep) {
      case 1:
        return _Step1Selection(
          key: const ValueKey(1),
          selectedRange: _selectedDateRange,
          onSelect: _selectDateRange,
        );
      case 2:
        return _Step2SystemSelection(
          key: const ValueKey(2),
          availableSystems: systems,
          selectedSystems: _selectedSystems,
          onToggle: (val) {
            setState(() {
              if (_selectedSystems.contains(val)) {
                _selectedSystems.remove(val);
              } else {
                _selectedSystems.add(val);
              }
            });
          },
        );
      case 3:
        return _Step3Generation(
          key: const ValueKey(3),
          selectedRange: _selectedDateRange,
          selectedSystems: _selectedSystems,
          onDownloadExcel: () {
            if (_createdVorId != null) {
              ref.read(vorExportServiceProvider).exportVorToExcel(_createdVorId!);
            }
          },
          onDownloadPdf: () {
            // TODO: Реализовать экспорт в PDF
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Виджет индикатора этапов.
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepCircle(step: 1, label: 'Период'),
        _StepDivider(),
        _StepCircle(step: 2, label: 'Система'),
        _StepDivider(),
        _StepCircle(step: 3, label: 'Готово'),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int step;
  final String label;

  const _StepCircle({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    final currentStep = context.findAncestorStateOfType<_VorCreateDialogState>()?._currentStep ?? 1;
    final isActive = currentStep >= step;
    final isCurrent = currentStep == step;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrent 
                  ? Colors.blue 
                  : (isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.grey[200]),
              shape: BoxShape.circle,
              border: isCurrent ? Border.all(color: Colors.blue[100]!, width: 4) : null,
            ),
            child: Center(
              child: step < currentStep
                  ? const Icon(Icons.check, size: 16, color: Colors.blue)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? Colors.blue : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey[200],
    );
  }
}

/// Кнопки навигации мастера.
class _NavigationButtons extends StatelessWidget {
  final int currentStep;
  final bool isNextEnabled;
  final bool isLoading;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavigationButtons({
    required this.currentStep,
    required this.isNextEnabled,
    this.isLoading = false,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentStep > 1 && currentStep < 3)
          GTSecondaryButton(text: 'Назад', onPressed: isLoading ? null : onPrev)
        else
          const SizedBox.shrink(),
        
        if (currentStep < 3)
          GTPrimaryButton(
            text: 'Далее',
            isLoading: isLoading,
            onPressed: isNextEnabled ? onNext : null,
          )
        else
          GTSecondaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }
}

/// Этап 1: Выбор периода.
class _Step1Selection extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final VoidCallback onSelect;

  const _Step1Selection({super.key, this.selectedRange, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(CupertinoIcons.calendar, size: 48, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Выберите период выполнения работ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'В ведомость попадут все работы, выполненные в указанные даты',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.time, size: 20, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  selectedRange != null
                      ? '${formatRuDate(selectedRange!.start)} — ${formatRuDate(selectedRange!.end)}'
                      : 'Нажмите, чтобы выбрать даты',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Этап 2: Выбор системы.
class _Step2SystemSelection extends StatelessWidget {
  final List<String> availableSystems;
  final List<String> selectedSystems;
  final ValueChanged<String> onToggle;

  const _Step2SystemSelection({
    super.key,
    required this.availableSystems,
    required this.selectedSystems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const Text(
          'Выберите систему',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Можно выбрать несколько систем одновременно',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (availableSystems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Системы не найдены'),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: availableSystems.map((s) => _SystemChip(
              label: s,
              isSelected: selectedSystems.contains(s),
              onTap: () => onToggle(s),
            )).toList(),
          ),
      ],
    );
  }
}

class _SystemChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SystemChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(CupertinoIcons.check_mark_circled, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Этап 3: Результат и скачивание.
class _Step3Generation extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final List<String> selectedSystems;
  final VoidCallback onDownloadExcel;
  final VoidCallback onDownloadPdf;

  const _Step3Generation({
    super.key,
    required this.selectedRange,
    required this.selectedSystems,
    required this.onDownloadExcel,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    final periodText = selectedRange != null
        ? '${formatRuDate(selectedRange!.start)} — ${formatRuDate(selectedRange!.end)}'
        : 'Период не выбран';

    return Column(
      children: [
        const Icon(CupertinoIcons.check_mark_circled, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'ВОР успешно сформирована!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _InfoCard(periodText: periodText, systemsText: selectedSystems.join(', ')),
        const SizedBox(height: 16),
        const Text(
          'Excel файл успешно сформирован и доступен для скачивания',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GTPrimaryButton(
                icon: CupertinoIcons.cloud_download,
                text: 'Скачать Excel',
                onPressed: onDownloadExcel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GTSecondaryButton(
                icon: CupertinoIcons.doc_text,
                text: 'Скачать PDF',
                onPressed: onDownloadPdf,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String periodText;
  final String systemsText;

  const _InfoCard({required this.periodText, required this.systemsText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Период:', value: periodText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _InfoRow(label: 'Системы:', value: systemsText),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
