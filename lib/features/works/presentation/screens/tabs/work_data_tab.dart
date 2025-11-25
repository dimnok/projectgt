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
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/features/works/presentation/widgets/work_data_skeleton.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for internal skeleton

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

        final items = itemsAsync.valueOrNull;
        final hours = hoursAsync.valueOrNull;

        // Проверяем, есть ли данные для отображения статистики
        // Либо они есть в самом объекте Work, либо загрузились списки
        final hasStatsData = (work.itemsCount != null &&
                work.employeesCount != null &&
                work.totalAmount != null) ||
            (items != null && hours != null);

        // Если данных нет совсем - показываем полный скелетон
        if (!hasStatsData) {
          return const WorkDataSkeleton();
        }

        // Рассчитываем статистику (приоритет у полей Work, если null - считаем из списков)
        final worksCount = work.itemsCount ?? items?.length ?? 0;
        final uniqueEmployees = work.employeesCount ??
            hours?.map((h) => h.employeeId).toSet().length ??
            0;
        final totalAmount = work.totalAmount ??
            items?.fold<double>(0, (sum, item) => sum + (item.total ?? 0)) ??
            0.0;
        final productivityPerEmployee =
            uniqueEmployees > 0 ? totalAmount / uniqueEmployees : 0.0;
        final formatter = NumberFormat('#,##0.00', 'ru_RU');

        final isWorkClosed = work.status.toLowerCase() == 'closed';
        final currentProfile = ref.watch(currentUserProfileProvider).profile;

        // Проверка на супер-админа
        final rolesState = ref.watch(rolesNotifierProvider);
        final isSuperAdmin = rolesState.valueOrNull?.any((r) =>
                r.id == currentProfile?.roleId &&
                r.isSystem &&
                r.name == 'Супер-админ') ??
            false;

        final bool isOwner =
            currentProfile != null && work.openedBy == currentProfile.id;
        final bool canModify = (isOwner && !isWorkClosed) || isSuperAdmin;

        if (!isMobile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Блок закрытия смены / валидации
                if (!isWorkClosed)
                  _buildValidationOrLoading(
                    context,
                    theme,
                    work,
                    items,
                    hours,
                    canModify,
                  ),

                // Карточка показателей
                _buildStatsCard(
                  context,
                  theme,
                  worksCount,
                  uniqueEmployees,
                  totalAmount,
                  productivityPerEmployee,
                  formatter,
                ),

                if (items != null && items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  WorkDistributionCard(items: items),
                ] else if (items == null) ...[
                  const SizedBox(height: 16),
                  _buildDistributionSkeleton(context),
                ],
                const SizedBox(height: 16),
                WorkPhotoView(work: work),
                const SizedBox(height: 32),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Блок закрытия смены / валидации
                  if (!isWorkClosed)
                    _buildValidationOrLoading(
                      context,
                      theme,
                      work,
                      items,
                      hours,
                      canModify,
                    ),

                  // Карточка показателей
                  _buildStatsCard(
                    context,
                    theme,
                    worksCount,
                    uniqueEmployees,
                    totalAmount,
                    productivityPerEmployee,
                    formatter,
                  ),

                  if (items != null && items.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    WorkDistributionCard(items: items),
                  ] else if (items == null) ...[
                    const SizedBox(height: 16),
                    _buildDistributionSkeleton(context),
                  ],
                  const SizedBox(height: 16),
                  WorkPhotoView(work: work),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildValidationOrLoading(
    BuildContext context,
    ThemeData theme,
    Work work,
    List<WorkItem>? items,
    List<WorkHour>? hours,
    bool canModify,
  ) {
    // Если списки еще грузятся, мы не можем проверить валидацию
    if (items == null || hours == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CupertinoActivityIndicator()),
        ),
      );
    }

    final (canClose, message) = _canCloseWork(work, items, hours);

    if (canClose) {
      if (canModify) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton.icon(
            onPressed: () => _showCloseWorkConfirmation(work),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Закрыть смену'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Для закрытия смены:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCheckItem('Добавить работы', items.isNotEmpty),
            _buildCheckItem('Добавить сотрудников', hours.isNotEmpty),
            _buildCheckItem('Заполнить кол-во у работ',
                items.isNotEmpty && !items.any((item) => item.quantity <= 0)),
            _buildCheckItem('Заполнить часы сотрудников',
                hours.isNotEmpty && !hours.any((hour) => hour.hours <= 0)),
            _buildCheckItem(
                'Загрузить вечернее фото',
                work.eveningPhotoUrl != null &&
                    work.eveningPhotoUrl!.isNotEmpty),
            if (work.eveningPhotoUrl == null ||
                work.eveningPhotoUrl!.isEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      canModify ? () => _showEveningPhotoOptions(work) : null,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Добавить фото'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildStatsCard(
    BuildContext context,
    ThemeData theme,
    int worksCount,
    int uniqueEmployees,
    double totalAmount,
    double productivityPerEmployee,
    NumberFormat formatter,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Сотрудников',
                    uniqueEmployees.toString(),
                    Icons.people_outline,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Работ',
                    worksCount.toString(),
                    Icons.handyman_outlined,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _buildStatRow(
              context,
              'Общая сумма',
              '${formatter.format(totalAmount)} ₽',
              isMain: true,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              'Выработка на чел.',
              '${formatter.format(productivityPerEmployee)} ₽',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1000.ms,
          color: highlightColor,
          angle: -0.3,
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

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child:
              Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value, {
    bool isMain = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: isMain
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
        ),
      ],
    );
  }

  (bool, String?) _canCloseWork(
      Work work, List<WorkItem> workItems, List<WorkHour> workHours) {
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
