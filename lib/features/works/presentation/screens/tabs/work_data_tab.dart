import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/domain/entities/work_item.dart';
import 'package:projectgt/features/works/domain/entities/work_hour.dart';
import 'package:projectgt/features/works/presentation/providers/work_items_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_hours_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_provider.dart';
import 'package:projectgt/features/works/presentation/widgets/work_photo_view.dart';
import 'package:projectgt/features/works/presentation/widgets/photo_loading_dialog.dart';
import 'package:projectgt/features/works/presentation/utils/photo_upload_helper.dart';
import 'package:projectgt/core/notifications/notification_service.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/works/presentation/widgets/work_distribution_card.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/core/utils/telegram_helper.dart';
import 'package:projectgt/features/works/presentation/providers/repositories_providers.dart';

/// Вкладка "Данные" со сводной информацией по смене
class WorkDataTab extends ConsumerStatefulWidget {
  /// Модель смены, для которой отображаются сводные данные.
  final Work work;

  /// Отображаемое название объекта (человекочитаемое).
  final String objectDisplay;

  /// Конструктор вкладки «Данные».
  const WorkDataTab(
      {super.key, required this.work, required this.objectDisplay});

  @override
  ConsumerState<WorkDataTab> createState() => _WorkDataTabState();
}

class _WorkDataTabState extends ConsumerState<WorkDataTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = !ResponsiveUtils.isDesktop(context);
    final work = widget.work;

    return Consumer(
      builder: (context, ref, _) {
        final itemsAsync = ref.watch(workItemsProvider(work.id!));
        final hoursAsync = ref.watch(workHoursProvider(work.id!));

        final isWorkClosed = work.status.toLowerCase() == 'closed';
        final currentProfile = ref.watch(currentUserProfileProvider).profile;
        final bool isOwner =
            currentProfile != null && work.openedBy == currentProfile.id;
        final bool canModify = isOwner && !isWorkClosed;

        return itemsAsync.when(
          data: (items) {
            return hoursAsync.when(
              data: (hours) {
                final canCloseWorkFuture = _canCloseWork(work, items, hours);

                // Используем агрегатные данные из БД (рассчитываются триггерами)
                final worksCount = work.itemsCount ?? items.length;
                final uniqueEmployees = work.employeesCount ??
                    hours.map((h) => h.employeeId).toSet().length;
                final totalAmount = work.totalAmount ??
                    items.fold<double>(
                        0, (sum, item) => sum + (item.total ?? 0));
                final productivityPerEmployee =
                    uniqueEmployees > 0 ? totalAmount / uniqueEmployees : 0.0;
                final formatter = NumberFormat('#,##0.00', 'ru_RU');

                if (!isMobile) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Сводная информация',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FutureBuilder<(bool, String?)>(
                          future: canCloseWorkFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CupertinoActivityIndicator());
                            }
                            final (canClose, message) = snapshot.data!;

                            if (isWorkClosed) {
                              return const SizedBox.shrink();
                            }
                            if (canClose) {
                              return ElevatedButton.icon(
                                onPressed: () =>
                                    _showCloseWorkConfirmation(work),
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Закрыть смену'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: theme.colorScheme.error,
                                            size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Невозможно закрыть смену',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                        'Для закрытия смены требуется выполнить следующие условия:',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    _buildCheckItem(
                                        'Наличие хотя бы одной работы',
                                        items.isNotEmpty),
                                    _buildCheckItem(
                                        'Наличие хотя бы одного сотрудника',
                                        hours.isNotEmpty),
                                    _buildCheckItem(
                                        'У всех работ указано количество',
                                        items.isNotEmpty &&
                                            !items.any(
                                                (item) => item.quantity <= 0)),
                                    _buildCheckItem(
                                        'У всех сотрудников проставлены часы',
                                        hours.isNotEmpty &&
                                            !hours.any(
                                                (hour) => hour.hours <= 0)),
                                    _buildCheckItem(
                                        'Добавлено вечернее фото',
                                        work.eveningPhotoUrl != null &&
                                            work.eveningPhotoUrl!.isNotEmpty),
                                    if (work.eveningPhotoUrl == null ||
                                        work.eveningPhotoUrl!.isEmpty) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: canModify
                                            ? () =>
                                                _showEveningPhotoOptions(work)
                                            : null,
                                        icon: const Icon(Icons.photo_camera),
                                        label: const Text(
                                            'Добавить вечернее фото'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          foregroundColor:
                                              theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                    if (message != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        message,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Производственные показатели',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    )),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                          icon: Icons.work,
                                          label: 'Работ',
                                          value: worksCount.toString(),
                                          iconColor:
                                              theme.colorScheme.tertiary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildMetricCard(
                                          icon: Icons.paid,
                                          label: 'Общая сумма',
                                          value:
                                              '${formatter.format(totalAmount)} ₽',
                                          iconColor: theme.colorScheme.primary,
                                          isLarge: true),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                          icon: Icons.groups,
                                          label: 'Сотрудников',
                                          value: uniqueEmployees.toString(),
                                          iconColor:
                                              theme.colorScheme.secondary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildMetricCard(
                                          icon: Icons.trending_up,
                                          label: 'Выработка на сотрудника',
                                          value:
                                              '${formatter.format(productivityPerEmployee)} ₽/чел.',
                                          iconColor:
                                              theme.colorScheme.tertiary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (items.isNotEmpty)
                          WorkDistributionCard(items: items),
                        const SizedBox(height: 24),
                        WorkPhotoView(work: work),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сводная информация',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          FutureBuilder<(bool, String?)>(
                            future: canCloseWorkFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CupertinoActivityIndicator());
                              }
                              final (canClose, message) = snapshot.data!;
                              if (isWorkClosed) {
                                return const SizedBox.shrink();
                              }
                              if (canClose && canModify) {
                                return ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCloseWorkConfirmation(work),
                                  icon: const Icon(Icons.lock_outline),
                                  label: const Text('Закрыть смену'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: theme.colorScheme.error
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded,
                                              color: theme.colorScheme.error,
                                              size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                                'Невозможно закрыть смену',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      theme.colorScheme.error,
                                                )),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                          'Для закрытия смены требуется выполнить следующие условия:',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      _buildCheckItem(
                                          'Наличие хотя бы одной работы',
                                          items.isNotEmpty),
                                      _buildCheckItem(
                                          'Наличие хотя бы одного сотрудника',
                                          hours.isNotEmpty),
                                      _buildCheckItem(
                                          'У всех работ указано количество',
                                          items.isNotEmpty &&
                                              !items.any((item) =>
                                                  item.quantity <= 0)),
                                      _buildCheckItem(
                                          'У всех сотрудников проставлены часы',
                                          hours.isNotEmpty &&
                                              !hours.any(
                                                  (hour) => hour.hours <= 0)),
                                      _buildCheckItem(
                                          'Добавлено вечернее фото',
                                          work.eveningPhotoUrl != null &&
                                              work.eveningPhotoUrl!.isNotEmpty),
                                      if (work.eveningPhotoUrl == null ||
                                          work.eveningPhotoUrl!.isEmpty) ...[
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _showEveningPhotoOptions(work),
                                          icon: const Icon(Icons.photo_camera),
                                          label: const Text(
                                              'Добавить вечернее фото'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor:
                                                theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                      if (message != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          message,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.error,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.2),
                                  width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Производственные показатели',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      )),
                                  const SizedBox(height: 16),
                                  _buildDataRow(
                                      icon: Icons.groups,
                                      label: 'Сотрудников:',
                                      value: '$uniqueEmployees чел.',
                                      iconColor: theme.colorScheme.primary),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                      icon: Icons.work,
                                      label: 'Работ:',
                                      value: '$worksCount шт.',
                                      iconColor: theme.colorScheme.primary),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.paid,
                                    label: 'Общая сумма:',
                                    value: '${formatter.format(totalAmount)} ₽',
                                    textColor: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.trending_up,
                                    label: 'Выработка на сотрудника:',
                                    value:
                                        '${formatter.format(productivityPerEmployee)} ₽/чел.',
                                    iconColor: theme.colorScheme.tertiary,
                                    textColor: theme.colorScheme.tertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            WorkDistributionCard(items: items),
                          ],
                          const SizedBox(height: 32),
                          WorkPhotoView(work: work),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, st) =>
                  Center(child: Text('Ошибка загрузки сотрудников: $e')),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, st) => Center(child: Text('Ошибка загрузки работ: $e')),
        );
      },
    );
  }

  Widget _buildCheckItem(String text, bool isCompleted) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isCompleted ? Icons.check_circle : Icons.cancel,
              color: isCompleted ? Colors.green : theme.colorScheme.error,
              size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCompleted ? null : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required dynamic value,
    Color? iconColor,
    Color? textColor,
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 16,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              if (value is Widget)
                value
              else
                Text(value.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: fontWeight,
                      fontSize: fontSize,
                      color: textColor,
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool isLarge = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: iconColor ?? theme.colorScheme.primary,
                size: isLarge ? 28 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isLarge ? 22 : 18,
                      color: isLarge ? theme.colorScheme.primary : null,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<(bool, String?)> _canCloseWork(
      Work work, List<WorkItem> workItems, List<WorkHour> workHours) async {
    if (work.status.toLowerCase() == 'closed') {
      return (false, 'Смена уже закрыта');
    }
    if (workItems.isEmpty) return (false, 'Невозможно закрыть смену без работ');
    if (workHours.isEmpty) {
      return (false, 'Невозможно закрыть смену без сотрудников');
    }
    final invalidWorkItems =
        workItems.where((item) => item.quantity <= 0).toList();
    if (invalidWorkItems.isNotEmpty) {
      return (
        false,
        'У некоторых работ не указано количество. Необходимо заполнить все поля количества перед закрытием смены.'
      );
    }
    final invalidWorkHours =
        workHours.where((hour) => hour.hours <= 0).toList();
    if (invalidWorkHours.isNotEmpty) {
      return (
        false,
        'У некоторых сотрудников не указаны часы. Необходимо заполнить все поля часов перед закрытием смены.'
      );
    }
    if (work.eveningPhotoUrl == null || work.eveningPhotoUrl!.isEmpty) {
      return (
        false,
        'Необходимо добавить вечернее фото перед закрытием смены.'
      );
    }
    return (true, null);
  }

  Future<void> _closeWork(Work work) async {
    final workNotifier = ref.read(worksProvider.notifier);
    final updatedWork =
        work.copyWith(status: 'closed', updatedAt: DateTime.now());
    try {
      await workNotifier.updateWork(updatedWork);
      if (work.id != null) {
        await ref
            .read(notificationServiceProvider)
            .cancelShiftReminders(work.id!);
      }
      try {
        if (updatedWork.id != null) {
          final token =
              Supabase.instance.client.auth.currentSession?.accessToken;
          if (token != null) {
            await Supabase.instance.client.functions.invoke(
              'send_admin_work_event',
              body: {'action': 'close', 'work_id': updatedWork.id!},
              headers: {'Authorization': 'Bearer $token'},
            );
          }
        }
      } catch (_) {}

      // Отправляем отчет в Telegram
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Смена успешно закрыта');
        // Даём время на обновление UI
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        // Перезагружаем свежие данные смены из БД чтобы получить telegram_message_id
        final workRepository = ref.read(workRepositoryProvider);
        final freshWork = await workRepository.getWork(work.id!);
        if (!mounted) return;
        if (freshWork != null) {
          // Обновляем смену в группе месяца без инвалидации провайдера
          ref.read(monthGroupsProvider.notifier).updateWorkInGroup(freshWork);
          await _sendTelegramReport(freshWork);
        } else {
          SnackBarUtils.showError(context, 'Не удалось загрузить данные смены');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка при закрытии смены: $e');
      }
    }
  }

  void _showCloseWorkConfirmation(Work work) {
    CupertinoDialogs.showConfirmDialog<bool>(
      context: context,
      title: 'Подтверждение закрытия смены',
      message: '''После закрытия смены будет невозможно:
• Добавлять/удалять работы и сотрудников
• Изменять количество работ и часы
• Редактировать фотографии

Вы уверены, что хотите закрыть смену?''',
      confirmButtonText: 'Закрыть смену',
      isDestructiveAction: true,
      onConfirm: () async => await _closeWork(work),
    );
  }

  void _showEveningPhotoOptions(Work work) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context, rootNavigator: true);

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Вечернее фото',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (work.eveningPhotoUrl != null &&
                      work.eveningPhotoUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        work.eveningPhotoUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              final photoService =
                                  ref.read(photoServiceProvider);
                              await photoService.deleteWorkPhotoByUrl(
                                work.eveningPhotoUrl!,
                              );
                              final updatedWork = work.copyWith(
                                eveningPhotoUrl: null,
                                updatedAt: DateTime.now(),
                              );
                              await ref
                                  .read(worksProvider.notifier)
                                  .updateWork(updatedWork);

                              if (mounted) {
                                navigator.pop();
                                _updateWorkInMonthGroups(updatedWork);
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () => SnackBarUtils.showSuccessByMessenger(
                                    messenger,
                                    'Вечернее фото удалено',
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                SnackBarUtils.showErrorByMessenger(
                                  messenger,
                                  'Ошибка при удалении фото: $e',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Удалить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PhotoOptionButton(
                        icon: Icons.camera_alt,
                        label: 'Камера',
                        onTap: () => _pickEveningPhoto(
                          ImageSource.camera,
                          work,
                        ),
                      ),
                      _PhotoOptionButton(
                        icon: Icons.image,
                        label: 'Галерея',
                        onTap: () => _pickEveningPhoto(
                          ImageSource.gallery,
                          work,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => navigator.pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickEveningPhoto(
    ImageSource source,
    Work work,
  ) async {
    try {
      // ✅ Закрываем Modal Bottom Sheet сразу
      Navigator.pop(context);

      final photoService = ref.read(photoServiceProvider);
      final bytes = await photoService.pickImageBytes(source);

      if (bytes == null) return;
      if (!mounted) return;

      // ✅ Загружаем фото через helper
      final uploadedUrl = await PhotoUploadHelper(
        context: context,
        ref: ref,
      ).uploadPhoto(
        photoType: PhotoType.evening,
        entity: 'work',
        entityId: work.objectId,
        displayName: 'evening',
        photoBytes: bytes,
        workDate: work.date,
        // ✅ Обновляем Work ВО ВРЕМЯ диалога загрузки
        onLoadingComplete: (String photoUrl) async {
          try {
            final updatedWork = work.copyWith(
              eveningPhotoUrl: photoUrl,
              updatedAt: DateTime.now(),
            );
            await ref.read(worksProvider.notifier).updateWork(updatedWork);
            _updateWorkInMonthGroups(updatedWork);
          } catch (e) {
            if (mounted) {
              SnackBarUtils.showError(
                  context, 'Ошибка при сохранении фото: $e');
            }
          }
        },
      );

      if (uploadedUrl == null) return;

      if (!mounted) return;

      // ✅ После нажатия "Готово" просто закрываем галерею
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка при загрузке фото: $e');
    }
  }

  // 🔴 Извлеченный метод для обновления работы в monthGroupsProvider
  void _updateWorkInMonthGroups(Work updatedWork) {
    Future.microtask(() {
      try {
        ref.read(monthGroupsProvider.notifier).updateWorkInGroup(updatedWork);
      } catch (e) {
        // Ignore errors
      }
    });
  }

  Future<void> _sendTelegramReport(Work work) async {
    if (work.id == null) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'ID смены не найден');
      return;
    }

    // Обновляем утреннее сообщение с часами работы
    if (work.telegramMessageId != null) {
      final updateResult = await TelegramHelper.updateWorkOpeningReport(
        work.id!,
        work.telegramMessageId!,
      );
      if (!mounted) return;
      if (updateResult != null && updateResult['success'] == true) {
        SnackBarUtils.showSuccess(context, 'Утреннее сообщение обновлено');
      }
    }

    // Отправляем вечерний отчет как ответ на утреннее сообщение
    final eveningResult = await TelegramHelper.sendWorkReport(work.id!);
    if (!mounted) return;

    if (eveningResult != null && eveningResult['success'] == true) {
      SnackBarUtils.showSuccess(context,
          'Вечерний отчет отправлен!\nРабот: ${eveningResult['items_count']}');
    } else {
      final error = eveningResult?['error'] ?? 'Неизвестная ошибка';
      SnackBarUtils.showError(context, 'Ошибка отправки: $error');
    }
  }
}

class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
