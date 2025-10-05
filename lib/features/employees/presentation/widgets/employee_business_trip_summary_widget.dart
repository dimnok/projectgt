import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет для отображения краткой информации о суточных в экране деталей сотрудника.
///
/// Показывает раскрывающуюся строку с информацией о настроенных суточных выплатах.
/// При клике показывает детальную информацию о всех настройках суточных.
/// Включает кнопку для добавления новых настроек суточных.
class EmployeeBusinessTripSummaryWidget extends ConsumerStatefulWidget {
  /// Сотрудник для отображения суточных.
  final Employee employee;

  /// Стиль для меток.
  final TextStyle labelStyle;

  /// Стиль для значений.
  final TextStyle valueStyle;

  /// Тема приложения.
  final ThemeData theme;

  /// Callback для открытия формы добавления суточных.
  final VoidCallback? onAddBusinessTrip;

  /// Конструктор [EmployeeBusinessTripSummaryWidget].
  const EmployeeBusinessTripSummaryWidget({
    super.key,
    required this.employee,
    required this.labelStyle,
    required this.valueStyle,
    required this.theme,
    this.onAddBusinessTrip,
  });

  @override
  ConsumerState<EmployeeBusinessTripSummaryWidget> createState() =>
      _EmployeeBusinessTripSummaryWidgetState();
}

class _EmployeeBusinessTripSummaryWidgetState
    extends ConsumerState<EmployeeBusinessTripSummaryWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BusinessTripRate>>(
      future: ref.read(getBusinessTripRatesByEmployeeUseCaseProvider)(
          widget.employee.id),
      builder: (context, snapshot) {
        final rates = snapshot.data ?? [];
        final summaryText = _getBusinessTripSummaryFromRates(rates);

        return Column(
          children: [
            // Основная строка (кликабельная)
            GestureDetector(
              onTap: rates.isNotEmpty
                  ? () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    }
                  : null,
              child: Container(
                margin: EdgeInsets.only(
                    bottom: ResponsiveUtils.adaptiveValue(
                        context: context, mobile: 12.0, desktop: 16.0)),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.theme.colorScheme.surface,
                  border: Border.all(
                    color: widget.theme.colorScheme.onSurface
                        .withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.colorScheme.shadow
                          .withValues(alpha: 0.03),
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
                        color: widget.theme.colorScheme.primary
                            .withValues(alpha: 0.7),
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
                      child: Text('Суточные',
                          style: widget.labelStyle
                              .copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text(
                        summaryText,
                        style: widget.valueStyle,
                      ),
                    ),
                    // Кнопка добавления суточных (круглая зелёная)
                    if (widget.onAddBusinessTrip != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: widget.onAddBusinessTrip,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    if (rates.isNotEmpty)
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

            // Детальная информация (раскрывающаяся)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isExpanded && rates.isNotEmpty ? null : 0,
              child: _isExpanded && rates.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surface
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.theme.colorScheme.outline
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: _buildBusinessTripDetails(rates),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  /// Строит детальную информацию о суточных.
  Widget _buildBusinessTripDetails(List<BusinessTripRate> rates) {
    final objectState = ref.watch(objectProvider);
    final objects = objectState.objects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Настройки суточных выплат:',
          style: widget.theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        ...rates.map((rate) {
          final objectName = objects
                  .where((obj) => obj.id == rate.objectId)
                  .map((obj) => obj.name)
                  .firstOrNull ??
              'Объект не найден';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.theme.colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        objectName,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rate.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: rate.isActive
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        rate.isActive ? 'Активно' : 'Неактивно',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: rate.isActive ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${rate.rate.toStringAsFixed(0)} ₽/смена',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      'от ${(rate.minimumHours ?? 0.0).toStringAsFixed(1)} часов',
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: widget.theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                if (rate.validTo != null ||
                    rate.validFrom != DateTime.now()) ...[
                  const SizedBox(height: 4),
                  Text(
                    rate.periodDescription,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Получает краткую информацию о суточных из списка ставок.
  String _getBusinessTripSummaryFromRates(List<BusinessTripRate> rates) {
    if (rates.isEmpty) {
      return 'Не настроены';
    }

    final activeRates = rates.where((rate) => rate.isActive).toList();
    if (activeRates.isEmpty) {
      return '${rates.length} настроек (неактивны)';
    }

    if (activeRates.length == 1) {
      final rate = activeRates.first;
      return '${rate.rate.toStringAsFixed(0)} ₽/смена';
    }

    return '${activeRates.length} активных настроек';
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
