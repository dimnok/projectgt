import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';

/// Экран управления ставками командировочных выплат.
///
/// Отображает список всех ставок с возможностью создания, редактирования и удаления.
/// Поддерживает фильтрацию по объектам и периодам действия.
class BusinessTripRatesScreen extends ConsumerStatefulWidget {
  /// Идентификатор объекта для фильтрации (опционально).
  final String? objectId;

  /// Конструктор [BusinessTripRatesScreen].
  ///
  /// [objectId] — если указан, отображаются только ставки для этого объекта.
  const BusinessTripRatesScreen({super.key, this.objectId});

  @override
  ConsumerState<BusinessTripRatesScreen> createState() =>
      _BusinessTripRatesScreenState();
}

class _BusinessTripRatesScreenState
    extends ConsumerState<BusinessTripRatesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Командировочные ставки'),
      body: Column(
        children: [
          // Заголовок и описание
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Управление ставками командировочных',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Настройте ставки командировочных выплат для объектов с указанием периодов действия.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Список ставок
          Expanded(
            child: FutureBuilder<List<BusinessTripRate>>(
              future: _loadRates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки ставок',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                final rates = snapshot.data ?? [];

                if (rates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет ставок командировочных',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Создайте первую ставку командировочных выплат',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createRate,
                          icon: const Icon(Icons.add),
                          label: const Text('Создать ставку'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rates.length,
                  itemBuilder: (context, index) {
                    final rate = rates[index];
                    return _buildRateCard(rate);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRate,
        icon: const Icon(Icons.add),
        label: const Text('Новая ставка'),
      ),
    );
  }

  /// Загружает ставки командировочных.
  Future<List<BusinessTripRate>> _loadRates() async {
    try {
      final useCase = ref.read(getBusinessTripRatesUseCaseProvider);

      if (widget.objectId != null) {
        final objectUseCase =
            ref.read(getBusinessTripRatesByObjectUseCaseProvider);
        return await objectUseCase(widget.objectId!);
      }

      return await useCase();
    } catch (e) {
      throw Exception('Ошибка загрузки ставок: $e');
    }
  }

  /// Создаёт карточку ставки командировочных.
  Widget _buildRateCard(BusinessTripRate rate) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с суммой
            Row(
              children: [
                Expanded(
                  child: Text(
                    rate.formattedRate,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Статус активности
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rate.isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rate.isActive ? 'Активна' : 'Неактивна',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: rate.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Период действия
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  rate.periodDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ID объекта (временно, пока нет названий)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Объект: ${rate.objectId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editRate(rate),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Изменить'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteRate(rate),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Удалить'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Создаёт новую ставку командировочных.
  void _createRate() {
    SnackBarUtils.showInfo(context, 'Функция создания ставки в разработке');
  }

  /// Редактирует ставку командировочных.
  void _editRate(BusinessTripRate rate) {
    SnackBarUtils.showInfo(
        context, 'Функция редактирования ставки в разработке');
  }

  /// Удаляет ставку командировочных.
  void _deleteRate(BusinessTripRate rate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить ставку?'),
        content: Text(
            'Вы уверены, что хотите удалить ставку ${rate.formattedRate} для объекта ${rate.objectId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final useCase = ref.read(deleteBusinessTripRateUseCaseProvider);
                await useCase(rate.id);
                if (mounted) {
                  setState(() {}); // Обновляем список
                  SnackBarUtils.showSuccess(context, 'Ставка удалена');
                }
              } catch (e) {
                if (mounted) {
                  SnackBarUtils.showError(context, 'Ошибка удаления: $e');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
