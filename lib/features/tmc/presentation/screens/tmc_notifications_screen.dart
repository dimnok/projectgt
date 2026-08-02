import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_notification.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Провайдер in-app уведомлений ТМЦ.
final tmcNotificationsProvider =
    FutureProvider.autoDispose<List<TmcNotification>>((ref) async {
  final repo = ref.watch(tmcRepositoryProvider);
  return repo.listNotifications();
});

/// Экран уведомлений модуля ТМЦ.
class TmcNotificationsScreen extends ConsumerWidget {
  /// Создаёт экран.
  const TmcNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tmcNotificationsProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Уведомления ТМЦ',
        leading: BackButton(onPressed: () => context.go(AppRoutes.tmc)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Нет уведомлений'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = items[index];
              return ListTile(
                leading: Icon(
                  n.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  [
                    if (n.body != null && n.body!.isNotEmpty) n.body!,
                    if (n.createdAt != null) formatRuDateTime(n.createdAt!),
                  ].join('\n'),
                ),
                isThreeLine: n.body != null && n.body!.isNotEmpty,
                onTap: () async {
                  if (!n.isRead) {
                    await ref
                        .read(tmcRepositoryProvider)
                        .markNotificationRead(n.id);
                    ref.invalidate(tmcNotificationsProvider);
                  }
                  if (!context.mounted) return;
                  AppSnackBar.show(
                    context: context,
                    message: n.title,
                    kind: AppSnackBarKind.info,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
