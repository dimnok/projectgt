import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/ks2/presentation/providers/ks2_providers.dart';
import 'package:projectgt/features/ks2/presentation/widgets/ks2_creation_sheet.dart';
import 'package:projectgt/features/ks2/presentation/widgets/ks2_act_card.dart';

/// Нижняя шторка со списком актов КС-2 по договору.
///
/// Позволяет просматривать список актов и переходить к созданию нового.
class Ks2ActsSheet extends ConsumerWidget {
  /// ID договора.
  final String contractId;

  /// Создает шторку со списком актов.
  const Ks2ActsSheet({super.key, required this.contractId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ks2ActsAsync = ref.watch(ks2ActsProvider(contractId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Акты КС-2',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ks2ActsAsync.when(
              data: (acts) {
                if (acts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 64, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text(
                            'Актов пока нет',
                            style: TextStyle(
                                color: theme.disabledColor, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                  context); // Close sheet to open creation
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) =>
                                    Ks2CreationSheet(contractId: contractId),
                              );
                            },
                            child: const Text('Сформировать первый акт'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: acts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final act = acts[index];
                    return Ks2ActCard(act: act);
                  },
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text('Ошибка: $err')),
              ),
            ),
          ),
          if (ks2ActsAsync.hasValue && ks2ActsAsync.value!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet to open creation
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) =>
                          Ks2CreationSheet(contractId: contractId),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Сформировать новый акт'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
