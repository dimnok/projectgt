import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/ks2/presentation/providers/ks2_providers.dart';

/// Шторка создания акта КС-2.
///
/// Позволяет выбрать параметры (номер, дата, период) и сформировать акт на основе выполненных работ.
class Ks2CreationSheet extends ConsumerStatefulWidget {
  /// ID договора, для которого создается акт.
  final String contractId;

  /// Создает шторку создания акта.
  const Ks2CreationSheet({super.key, required this.contractId});

  @override
  ConsumerState<Ks2CreationSheet> createState() => _Ks2CreationSheetState();
}

class _Ks2CreationSheetState extends ConsumerState<Ks2CreationSheet> {
  final _numberController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _periodTo = DateTime.now();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _loadPreview() {
    ref.read(ks2CreationProvider.notifier).loadPreview(
          contractId: widget.contractId,
          periodTo: _periodTo,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creationState = ref.watch(ks2CreationProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Формирование КС-2',
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
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Настройки акта
                      Text('Параметры акта',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numberController,
                              decoration: const InputDecoration(
                                labelText: 'Номер акта',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Дата акта',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(formatRuDate(_selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Выбор периода для сбора работ
                      Text('Включить работы по дату:',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _periodTo,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _periodTo = picked);
                            // Сброс превью, так как дата изменилась
                            ref.invalidate(ks2CreationProvider);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дата окончания отчетного периода',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(formatRuDate(_periodTo)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Кнопка расчета
                      if (creationState is AsyncLoading)
                        ElevatedButton(
                          onPressed: creationState is AsyncLoading
                              ? null
                              : _loadPreview,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: creationState is AsyncLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Рассчитать выполнение'),
                        ),

                      // Результаты расчета
                      if (creationState.valueOrNull != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Итоги расчета',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _SummaryRow(
                                  label: 'Всего работ:',
                                  value: '${creationState.value!.itemsCount}'),
                              _SummaryRow(
                                  label: 'Пропущено (сверх лимита):',
                                  value:
                                      '${creationState.value!.skippedCount}'),
                              const Divider(),
                              _SummaryRow(
                                label: 'Сумма акта:',
                                value: formatCurrency(
                                    creationState.value!.totalAmount),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_numberController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Введите номер акта')),
                              );
                              return;
                            }

                            try {
                              await ref
                                  .read(ks2CreationProvider.notifier)
                                  .createAct(
                                    contractId: widget.contractId,
                                    periodTo: _periodTo,
                                    number: _numberController.text,
                                    date: _selectedDate,
                                  );

                              if (context.mounted) {
                                Navigator.pop(context); // Закрываем модалку
                                // Обновляем список актов на предыдущем экране
                                ref.invalidate(
                                    ks2ActsProvider(widget.contractId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Акт КС-2 успешно создан')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Ошибка создания: $e'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('СФОРМИРОВАТЬ АКТ'),
                        ),
                      ],

                      if (creationState is AsyncError)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Ошибка расчета: ${creationState.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
