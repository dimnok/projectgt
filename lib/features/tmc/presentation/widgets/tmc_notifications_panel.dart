import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';

/// Уведомления модуля ТМЦ.
class TmcNotificationsPanel extends ConsumerWidget {
  /// Создаёт панель уведомлений.
  const TmcNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tmcNotificationsProvider);

    return async.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Нет уведомлений'));
        }
        return ListView.separated(
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
    );
  }
}
