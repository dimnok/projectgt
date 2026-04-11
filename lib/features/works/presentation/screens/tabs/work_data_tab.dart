import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/presentation/providers/work_items_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_hours_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_provider.dart';
import 'package:projectgt/features/works/presentation/widgets/work_photo_view.dart';
import 'package:projectgt/features/works/presentation/widgets/photo_loading_dialog.dart';
import 'package:projectgt/features/works/presentation/utils/photo_upload_helper.dart';
import 'package:projectgt/core/notifications/notification_service.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/error/failure.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/works/presentation/widgets/work_distribution_card.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/core/utils/telegram_helper.dart';
import 'package:projectgt/features/works/presentation/providers/repositories_providers.dart';
import 'package:projectgt/features/works/presentation/widgets/work_data_skeleton.dart';
import 'package:projectgt/features/works/presentation/widgets/work_stats_card.dart';
import 'package:projectgt/features/works/presentation/widgets/work_own_contractor_amounts_card.dart';
import 'package:projectgt/features/works/presentation/widgets/work_validation_block.dart';
import 'package:projectgt/features/works/presentation/utils/works_strings.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final isMobile = !ResponsiveUtils.isDesktop(context);
    final work = widget.work;

    // Слушаем ошибки операций со сменами
    ref.listen<AsyncValue<List<Work>>>(worksProvider, (prev, next) {
      next.whenOrNull(
        error: (e, s) {
          final failure = e is Failure ? e : Failure.fromException(e);
          AppSnackBar.show(
            context: context,
            message: failure.message ?? WorksStrings.operationError,
            kind: AppSnackBarKind.error,
          );
        },
      );
    });

    return Consumer(
      builder: (context, ref, _) {
        final itemsAsync = ref.watch(workItemsProvider(work.id!));
        final hoursAsync = ref.watch(workHoursProvider(work.id!));

        final items = itemsAsync.valueOrNull;
        final hours = hoursAsync.valueOrNull;

        // Проверяем, есть ли данные для отображения статистики
        final hasStatsData = (work.itemsCount != null &&
                work.employeesCount != null &&
                work.totalAmount != null) ||
            (items != null && hours != null);

        // Если данных нет совсем - показываем полный скелетон
        if (!hasStatsData) {
          return const WorkDataSkeleton();
        }

        // Рассчитываем статистику верхней карточки: только собственное выполнение
        // (строки без contractor_id). Пока список позиций не загружен — fallback на
        // агрегаты смены из БД (могут включать подрядчика до прихода items).
        final uniqueEmployees = work.employeesCount ??
            hours?.map((h) => h.employeeId).toSet().length ??
            0;
        final int worksCount;
        final double totalAmount;
        if (items != null) {
          final ownItems = items
              .where(
                (i) => i.contractorId == null || i.contractorId!.isEmpty,
              )
              .toList();
          worksCount = ownItems.length;
          totalAmount = ownItems.fold<double>(
            0,
            (sum, item) => sum + (item.total ?? 0),
          );
        } else {
          worksCount = work.itemsCount ?? 0;
          totalAmount = work.totalAmount ?? 0.0;
        }
        final productivityPerEmployee =
            uniqueEmployees > 0 ? totalAmount / uniqueEmployees : 0.0;

        final isWorkClosed = work.status.toLowerCase() == 'closed';
        final currentProfile = ref.watch(currentUserProfileProvider).profile;
        final isCompanyOwner = currentProfile?.systemRole == 'owner';
        final bool isOwner =
            currentProfile != null && work.openedBy == currentProfile.id;
        final bool canModify = (isOwner && !isWorkClosed) || isCompanyOwner;

        final content = Column(
          crossAxisAlignment:
              isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            // Блок закрытия смены / валидации
            if (!isWorkClosed)
              WorkValidationBlock(
                work: work,
                items: items,
                hours: hours,
                canModify: canModify,
                onCloseWork: () => _showCloseWorkConfirmation(work),
                onAddPhoto: () => _showEveningPhotoOptions(work),
              ),

            // Карточка показателей
            WorkStatsCard(
              worksCount: worksCount,
              uniqueEmployees: uniqueEmployees,
              totalAmount: totalAmount,
              productivityPerEmployee: productivityPerEmployee,
            ),

            if (items != null && items.isNotEmpty) ...[
              const SizedBox(height: 16),
              WorkOwnContractorAmountsCard(items: items),
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
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: content,
                  ),
                )
              : content,
        );
      },
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
        AppSnackBar.show(
          context: context,
          message: WorksStrings.successWorkClosed,
          kind: AppSnackBarKind.success,
        );
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
          AppSnackBar.show(
            context: context,
            message: WorksStrings.loadWorkError,
            kind: AppSnackBarKind.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: WorksStrings.closeWorkError(e),
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  void _showCloseWorkConfirmation(Work work) {
    CupertinoDialogs.showConfirmDialog<bool>(
      context: context,
      title: WorksStrings.confirmCloseTitle,
      message: WorksStrings.confirmCloseMessage,
      confirmButtonText: WorksStrings.closeWorkBtn,
      isDestructiveAction: true,
      onConfirm: () async => await _closeWork(work),
    );
  }

  void _showEveningPhotoOptions(Work work) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setBottomSheetState) {
            final navigator = Navigator.of(sheetContext, rootNavigator: true);

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    WorksStrings.eveningPhotoDialogTitle,
                    style: Theme.of(sheetContext)
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
                        GTTextButton(
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
                                  () {
                                    if (!mounted) return;
                                    AppSnackBar.show(
                                      context: context,
                                      message: WorksStrings.successEveningPhotoDeleted,
                                      kind: AppSnackBarKind.success,
                                    );
                                  },
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                AppSnackBar.show(
                                  context: context,
                                  message: WorksStrings.deletePhotoError(e),
                                  kind: AppSnackBarKind.error,
                                );
                              }
                            }
                          },
                          icon: Icons.delete_outline,
                          text: WorksStrings.deleteBtn,
                          color: theme.colorScheme.error,
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
                        label: WorksStrings.cameraBtn,
                        onTap: () => _pickEveningPhoto(
                          ImageSource.camera,
                          work,
                        ),
                      ),
                      _PhotoOptionButton(
                        icon: Icons.image,
                        label: WorksStrings.galleryBtn,
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
                    child: GTTextButton(
                      onPressed: () => navigator.pop(),
                      text: WorksStrings.cancelBtn,
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
              AppSnackBar.show(
                context: context,
                message: WorksStrings.savePhotoError(e),
                kind: AppSnackBarKind.error,
              );
            }
          }
        },
      );

      if (uploadedUrl == null) return;

      if (!mounted) {
        return;
      }

      // ✅ Вкладка данных не должна закрываться после загрузки фото,
      // так как пользователь должен остаться на экране смены.
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: WorksStrings.uploadPhotoError(e),
        kind: AppSnackBarKind.error,
      );
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
      AppSnackBar.show(
        context: context,
        message: WorksStrings.shiftIdNotFoundError,
        kind: AppSnackBarKind.error,
      );
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
        AppSnackBar.show(
          context: context,
          message: WorksStrings.successMorningReportUpdated,
          kind: AppSnackBarKind.success,
        );
      }
    }

    // Отправляем вечерний отчет как ответ на утреннее сообщение
    final eveningResult = await TelegramHelper.sendWorkReport(work.id!);
    if (!mounted) return;

    if (eveningResult != null && eveningResult['success'] == true) {
      AppSnackBar.show(
        context: context,
        message: WorksStrings.successEveningReportSent(eveningResult['items_count']),
        kind: AppSnackBarKind.success,
      );
    } else {
      final error = eveningResult?['error'] ?? 'Неизвестная ошибка';
      AppSnackBar.show(
        context: context,
        message: WorksStrings.telegramSendError(error),
        kind: AppSnackBarKind.error,
      );
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
