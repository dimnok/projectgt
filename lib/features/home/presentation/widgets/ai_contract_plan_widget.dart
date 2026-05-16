import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/home/presentation/providers/ai_contract_plan_provider.dart';

final _moneyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

/// Виджет для отображения плана по договору, сгенерированного ИИ.
class AiContractPlanWidget extends ConsumerStatefulWidget {
  /// Создает виджет.
  const AiContractPlanWidget({super.key});

  @override
  ConsumerState<AiContractPlanWidget> createState() => _AiContractPlanWidgetState();
}

class _AiContractPlanWidgetState extends ConsumerState<AiContractPlanWidget> {
  
  String _getContractTitle(String? contractId, List<dynamic> contracts) {
    if (contractId == null) return 'Договор';
    final int idx = contracts.indexWhere((c) => c.id == contractId);
    return idx >= 0 ? 'Договор ${contracts[idx].number}' : 'Договор';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiPlanAsync = ref.watch(aiContractPlanProvider);
    final contractsState = ref.watch(contractProvider);
    final contracts = contractsState.contracts;
    final selectedContractId = ref.watch(selectedAiContractIdProvider);

    // Автоматически выбираем первый договор, если ничего не выбрано
    // Выполняем отложенно, чтобы не вызывать rebuild в процессе build
    if (selectedContractId == null && contracts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedAiContractIdProvider.notifier).state = contracts.first.id;
        }
      });
    }

    // В качестве отображаемого ID берем выбранный, либо первый из списка (пока стейт не обновился)
    final String? displayContractId = selectedContractId ?? (contracts.isNotEmpty ? contracts.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок и переключатель договоров
        Row(
          children: [
            Icon(CupertinoIcons.doc_text,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getContractTitle(displayContractId, contracts),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Предыдущий',
              onPressed: (contracts.isEmpty || displayContractId == null)
                  ? null
                  : () {
                      final int idx =
                          contracts.indexWhere((c) => c.id == displayContractId);
                      if (idx > 0) {
                        final nextId = contracts[idx - 1].id;
                        ref.read(selectedAiContractIdProvider.notifier).state = nextId;
                      }
                    },
              icon: const Icon(CupertinoIcons.chevron_left),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Следующий',
              onPressed: (contracts.isEmpty || displayContractId == null)
                  ? null
                  : () {
                      final int idx =
                          contracts.indexWhere((c) => c.id == displayContractId);
                      if (idx >= 0 && idx < contracts.length - 1) {
                        final nextId = contracts[idx + 1].id;
                        ref.read(selectedAiContractIdProvider.notifier).state = nextId;
                      }
                    },
              icon: const Icon(CupertinoIcons.chevron_right),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        aiPlanAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Ошибка загрузки ИИ-плана: $e',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ),
          data: (plan) {
            if (plan == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Нет данных для анализа',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Рекомендация ИИ в стиле "заметки"
                  Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFACC15).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.sparkles,
                        color: Color(0xFFFACC15),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plan.recommendation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Основные метрики: План vs Факт
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetricComparisonCard(
                        title: 'Монтажники',
                        icon: CupertinoIcons.person_3_fill,
                        color: const Color(0xFF3B82F6), // Blue
                        planLabel: 'План на сегодня',
                        planValue: plan.installersPlanToday.toString(),
                        factLabel: 'Ср. факт (за 7 дней)',
                        factValue: plan.averageInstallersFact?.toString() ?? '—',
                        deltaLabel: (plan.averageInstallersFact ?? 0) < plan.installersPlanToday
                            ? 'Не хватает: ${plan.installersPlanToday - (plan.averageInstallersFact ?? 0)}'
                            : 'Избыток: ${(plan.averageInstallersFact ?? 0) - plan.installersPlanToday}',
                        isDeltaPositive: (plan.averageInstallersFact ?? 0) >= plan.installersPlanToday,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricComparisonCard(
                        title: 'Выработка',
                        icon: CupertinoIcons.money_rubl_circle_fill,
                        color: const Color(0xFF10B981), // Green
                        planLabel: 'План на сегодня',
                        planValue: _moneyFormat.format(plan.dailyPlanAmount),
                        factLabel: 'Ср. факт (за 7 дней)',
                        factValue: plan.averageDailyProductionFact != null 
                            ? _moneyFormat.format(plan.averageDailyProductionFact) 
                            : '—',
                        deltaLabel: plan.averageDailyProductionFact != null
                            ? (plan.averageDailyProductionFact! >= plan.dailyPlanAmount
                                ? '+${_moneyFormat.format(plan.averageDailyProductionFact! - plan.dailyPlanAmount)}'
                                : _moneyFormat.format(plan.averageDailyProductionFact! - plan.dailyPlanAmount))
                            : '',
                        isDeltaPositive: plan.averageDailyProductionFact != null && plan.averageDailyProductionFact! >= plan.dailyPlanAmount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Информация о договоре и прогресс
                Builder(
                  builder: (context) {
                    final contractAmount = plan.contractAmount ?? 0;
                    final executedAmount = plan.executedAmount ?? 0;
                    final percent = contractAmount > 0 
                        ? (executedAmount / contractAmount).clamp(0.0, 1.0) 
                        : 0.0;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Выполнено / По договору',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: _moneyFormat.format(executedAmount),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' / ',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          TextSpan(
                                            text: _moneyFormat.format(contractAmount),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(percent * 100).toStringAsFixed(1)}%',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Осталось дней по договору:',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${plan.daysLeft ?? 0}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          );
        },
        ),
      ],
    );
  }
}

class _MetricComparisonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String planLabel;
  final String planValue;
  final String factLabel;
  final String factValue;
  final String deltaLabel;
  final bool isDeltaPositive;

  const _MetricComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.planLabel,
    required this.planValue,
    required this.factLabel,
    required this.factValue,
    required this.deltaLabel,
    required this.isDeltaPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deltaColor = isDeltaPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // План
          Text(
            planLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            planValue,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          
          // Факт и Дельта
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                factLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    factValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (deltaLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        deltaLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: deltaColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
