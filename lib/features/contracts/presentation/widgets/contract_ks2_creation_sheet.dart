import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/domain/entities/vor.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_ks2_providers.dart';

/// Шторка формирования акта КС-2 по утверждённой ВОР (модуль «Договоры»).
///
/// Использует только [contractKs2ApprovedVorsProvider] и [contractKs2CreationProvider],
/// без провайдеров модуля «Сметы».
class ContractKs2CreationSheet extends ConsumerStatefulWidget {
  /// Создаёт шторку формирования акта.
  const ContractKs2CreationSheet({super.key, required this.contractId});

  /// Идентификатор договора.
  final String contractId;

  @override
  ConsumerState<ContractKs2CreationSheet> createState() =>
      _ContractKs2CreationSheetState();
}

class _ContractKs2CreationSheetState
    extends ConsumerState<ContractKs2CreationSheet> {
  final _numberController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Vor? _selectedVor;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  List<Vor> _eligibleVors(List<Vor> all, List<Ks2Act> acts) {
    final used = acts.map((a) => a.vorId).whereType<String>().toSet();
    return all
        .where((v) =>
            v.status == VorStatus.approved &&
            !used.contains(v.id) &&
            v.contractId == widget.contractId)
        .toList();
  }

  void _onVorChanged(Vor? vor) {
    setState(() => _selectedVor = vor);
    ref.invalidate(contractKs2CreationProvider);
  }

  void _loadPreview() {
    final vor = _selectedVor;
    if (vor == null) return;
    ref.read(contractKs2CreationProvider.notifier).loadPreview(
          contractId: widget.contractId,
          vorId: vor.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vorsAsync =
        ref.watch(contractKs2ApprovedVorsProvider(widget.contractId));
    final actsAsync = ref.watch(contractKs2ActsProvider(widget.contractId));
    final creationState = ref.watch(contractKs2CreationProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Формирование КС-2 по ВОР',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
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
                    Text(
                      'Акт формируется только из утверждённой ведомости объёмов работ. '
                      'Строки с превышением сметы в акт не входят.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Параметры акта',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GTTextField(
                            controller: _numberController,
                            labelText: 'Номер акта',
                            prefixIcon: CupertinoIcons.number,
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
                    Text('Ведомость ВОР',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    vorsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text(
                        'Не удалось загрузить ВОР: $e',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.error),
                      ),
                      data: (vors) {
                        return actsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => Text(
                            'Не удалось загрузить акты: $e',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: scheme.error),
                          ),
                          data: (acts) {
                            final eligible = _eligibleVors(vors, acts);
                            if (eligible.isEmpty) {
                              return Text(
                                'Нет утверждённых ВОР без акта КС-2 по этому договору. '
                                'Утвердите ВОР или дождитесь снятия привязки с существующего акта.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              );
                            }
                            return GTDropdown<Vor>(
                              items: eligible,
                              itemDisplayBuilder: (v) =>
                                  'ВОР №${v.number} (${formatRuDate(v.startDate)} — ${formatRuDate(v.endDate)})',
                              labelText: 'Утверждённая ВОР',
                              hintText: 'Выберите ведомость',
                              selectedItem: _selectedVor,
                              onSelectionChanged: _onVorChanged,
                              prefixIcon: CupertinoIcons.doc_text,
                              allowClear: true,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    GTSecondaryButton(
                      text: 'Показать состав акта',
                      icon: CupertinoIcons.chart_bar,
                      onPressed: _selectedVor == null || creationState.isLoading
                          ? null
                          : _loadPreview,
                      isLoading: creationState.isLoading,
                    ),
                    if (creationState.valueOrNull != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Итоги',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: 'Строк в акте:',
                              value: '${creationState.value!.itemsCount}',
                            ),
                            _SummaryRow(
                              label: 'Исключено (превышение сметы и др.):',
                              value: '${creationState.value!.skippedCount}',
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Сумма акта:',
                              value: formatCurrency(
                                  creationState.value!.totalAmount),
                              isBold: true,
                            ),
                            if (creationState.value!.candidates.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Позиции',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...creationState.value!.candidates.take(12).map(
                                (c) {
                                  final m =
                                      Map<String, dynamic>.from(c as Map);
                                  final name = (m['name'] ?? '—').toString();
                                  final qty = m['quantity'];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '• $name — $qty',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  );
                                },
                              ),
                              if (creationState.value!.candidates.length > 12)
                                Text(
                                  '… и ещё ${creationState.value!.candidates.length - 12}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GTPrimaryButton(
                        text: 'Сформировать акт',
                        onPressed: () async {
                          if (_numberController.text.trim().isEmpty) {
                            AppSnackBar.show(
                              context: context,
                              message: 'Введите номер акта',
                              kind: AppSnackBarKind.warning,
                            );
                            return;
                          }
                          final vor = _selectedVor;
                          if (vor == null) {
                            AppSnackBar.show(
                              context: context,
                              message: 'Выберите ВОР',
                              kind: AppSnackBarKind.warning,
                            );
                            return;
                          }
                          try {
                            await ref
                                .read(contractKs2CreationProvider.notifier)
                                .createAct(
                                  contractId: widget.contractId,
                                  vorId: vor.id,
                                  number: _numberController.text.trim(),
                                  date: _selectedDate,
                                );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ref.invalidate(
                                contractKs2ActsProvider(widget.contractId));
                            ref.invalidate(contractKs2ApprovedVorsProvider(
                                widget.contractId));
                            AppSnackBar.show(
                              context: context,
                              message: 'Акт КС-2 успешно создан',
                              kind: AppSnackBarKind.success,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            AppSnackBar.show(
                              context: context,
                              message: 'Ошибка создания: $e',
                              kind: AppSnackBarKind.error,
                            );
                          }
                        },
                      ),
                    ],
                    if (creationState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Ошибка расчёта: ${creationState.error}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
