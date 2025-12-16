import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/features/ks2/presentation/providers/ks2_providers.dart';

/// Виджет карточки акта КС-2.
///
/// Отображает основную информацию об акте: номер, дата, статус, сумма.
class Ks2ActCard extends ConsumerWidget {
  /// Акт КС-2 для отображения.
  final Ks2Act act;

  /// Создает карточку акта КС-2.
  const Ks2ActCard({super.key, required this.act});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor =
        act.status == Ks2Status.draft ? Colors.orange : Colors.green;
    final statusText = act.status == Ks2Status.draft ? 'Черновик' : 'Подписан';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Акт № ${act.number} от ${formatRuDate(act.date)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Период: ${formatRuDate(act.periodFrom)} — ${formatRuDate(act.periodTo)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сумма:'),
                Text(
                  formatCurrency(act.totalAmount),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (act.status == Ks2Status.draft) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Удалить акт?'),
                          content: const Text(
                              'Работы будут возвращены в список доступных для нового акта.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Отмена')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Удалить',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref
                            .read(ks2ActsProvider(act.contractId).notifier)
                            .deleteAct(act.id);
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Удалить',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
