import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/employee_rate.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет для отображения краткой информации о текущей ставке в экране деталей сотрудника.
///
/// Показывает раскрывающуюся строку с информацией о текущей ставке сотрудника.
/// При клике показывает детальную информацию об истории всех ставок.
class EmployeeRateSummaryWidget extends ConsumerStatefulWidget {
  /// Сотрудник для отображения ставок.
  final Employee employee;

  /// Стиль для меток.
  final TextStyle labelStyle;

  /// Стиль для значений.
  final TextStyle valueStyle;

  /// Тема приложения.
  final ThemeData theme;

  /// Конструктор [EmployeeRateSummaryWidget].
  const EmployeeRateSummaryWidget({
    super.key,
    required this.employee,
    required this.labelStyle,
    required this.valueStyle,
    required this.theme,
  });

  @override
  ConsumerState<EmployeeRateSummaryWidget> createState() =>
      _EmployeeRateSummaryWidgetState();
}

class _EmployeeRateSummaryWidgetState
    extends ConsumerState<EmployeeRateSummaryWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentRateText = widget.employee.currentHourlyRate != null
        ? '${widget.employee.currentHourlyRate!.toStringAsFixed(0)} ₽/час'
        : 'Не указана';

    return Column(
      children: [
        // Основная строка (кликабельная)
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            margin: EdgeInsets.only(
                bottom: ResponsiveUtils.adaptiveValue(
                    context: context, mobile: 12.0, desktop: 16.0)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: widget.theme.colorScheme.surface,
              border: Border.all(
                color:
                    widget.theme.colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      widget.theme.colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color:
                        widget.theme.colorScheme.primary.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: ResponsiveUtils.adaptiveValue(
                    context: context,
                    mobile: 150 - 12,
                    desktop: 150 * 1.2 - 12,
                  ),
                  child: Text('Текущая ставка',
                      style: widget.labelStyle
                          .copyWith(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text(
                    currentRateText,
                    style: widget.valueStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: widget.theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        // История ставок (раскрывающаяся)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? null : 0,
          child: _isExpanded
              ? Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        widget.theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.theme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: _buildRateHistoryDetails(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Строит детальную информацию об истории ставок.
  Widget _buildRateHistoryDetails() {
    final getRatesUseCase = ref.read(getEmployeeRatesUseCaseProvider);

    return FutureBuilder<List<EmployeeRate>>(
      future: getRatesUseCase(widget.employee.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Text(
            'Ошибка загрузки истории ставок',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
          );
        }

        final rates = snapshot.data!;

        if (rates.isEmpty) {
          return Text(
            'История ставок пуста',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'История изменений ставок:',
              style: widget.theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    widget.theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            ...rates.map((rate) {
              final isCurrent = rate.isCurrent;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? widget.theme.colorScheme.primary.withValues(alpha: 0.1)
                      : widget.theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? widget.theme.colorScheme.primary
                            .withValues(alpha: 0.3)
                        : widget.theme.colorScheme.outline
                            .withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Ставка
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${rate.hourlyRate.toStringAsFixed(0)} ₽/час',
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrent
                              ? widget.theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ),

                    // Период действия
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatRatePeriod(rate),
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),

                    // Иконка для текущей ставки
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Форматирует период действия ставки.
  String _formatRatePeriod(EmployeeRate rate) {
    final start =
        '${rate.validFrom.day.toString().padLeft(2, '0')}.${rate.validFrom.month.toString().padLeft(2, '0')}.${rate.validFrom.year}';
    if (rate.validTo == null) {
      return 'с $start';
    }
    final end =
        '${rate.validTo!.day.toString().padLeft(2, '0')}.${rate.validTo!.month.toString().padLeft(2, '0')}.${rate.validTo!.year}';
    return '$start — $end';
  }
}

/// Расширение для удобного создания цвета с изменёнными компонентами.
extension ColorExtension on Color {
  /// Возвращает новый цвет с изменёнными компонентами (r, g, b, a).
  ///
  /// [red], [green], [blue] — новые значения каналов (0..255), если не указаны — берутся из исходного цвета.
  /// [alpha] — новый альфа-канал (0.0..1.0), если не указан — берётся из исходного цвета.
  Color withValues({
    int? red,
    int? green,
    int? blue,
    double? alpha,
  }) {
    return Color.fromRGBO(
      (red ?? r).toInt(),
      (green ?? g).toInt(),
      (blue ?? b).toInt(),
      (alpha ?? a).toDouble(),
    );
  }
}
