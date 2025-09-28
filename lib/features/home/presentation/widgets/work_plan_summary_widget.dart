import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Карточка «План работ» для главного экрана.
///
/// Отображает агрегированную «Сумму плана» и «План на одного специалиста»
/// по ближайшему актуальному плану работ:
/// - выбирается ближайший план с датой >= сегодня, если таких нет — последний по дате
/// - сумма плана считается как WorkPlan.totalPlannedCost
/// - «на специалиста» = сумма плана / число уникальных работников в планах блоков
class WorkPlanSummaryWidget extends ConsumerWidget {
  const WorkPlanSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(workPlanNotifierProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (state.workPlans.isEmpty) {
      return Center(
        child: Text(
          'Нет планов работ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    final WorkPlan selected = _selectRelevantPlan(state.workPlans);
    final double totalPlan = selected.totalPlannedCost;
    final int workers =
        selected.workBlocks.expand((b) => b.workerIds).toSet().length;
    final double perSpecialist = workers > 0 ? (totalPlan / workers) : 0;

    // Прогресс: если есть фактические данные — используем их,
    // иначе — доля заполненных блоков (isComplete) среди всех блоков.
    final double actualBased = selected.completionPercentage.clamp(0, 100);
    final int totalBlocks = selected.workBlocks.length;
    final int completeBlocks =
        selected.workBlocks.where((b) => b.isComplete).length;
    final double setupBased =
        totalBlocks > 0 ? (completeBlocks / totalBlocks * 100.0) : 0.0;
    final double progressPercent =
        (actualBased > 0 ? actualBased : setupBased).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'План работ',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _KpiTile(
          label: 'Сумма плана',
          value: formatCurrency(totalPlan),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        _KpiTile(
          label: 'План на специалиста',
          value: formatCurrency(perSpecialist),
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        // Прогресс выполнения плана
        // Фактическая выработка по сменам на объекте за дату плана
        FutureBuilder<double>(
          future: _fetchActualSum(selected.objectId, selected.date),
          builder: (context, snapshot) {
            final double actualSum = snapshot.data ?? 0.0;
            final double finalPercent = totalPlan > 0
                ? ((actualSum / totalPlan) * 100).clamp(0, 100)
                : progressPercent;
            final String suffix = (actualSum <= 0 && totalBlocks > 0)
                ? ' · ${completeBlocks}/${totalBlocks} блоков'
                : '';
            return _ProgressBar(
              percent: finalPercent,
              label: 'Выполнение: ${finalPercent.toStringAsFixed(0)}%$suffix',
            );
          },
        ),
        const Spacer(),
        Row(
          children: [
            _Chip(label: 'Сотрудники', value: workers.toString()),
            const SizedBox(width: 8),
            _Chip(
                label: 'Блоков', value: selected.workBlocks.length.toString()),
          ],
        ),
      ],
    );
  }

  /// Выбирает ближайший по времени план (>= сегодня), иначе — последний по дате.
  WorkPlan _selectRelevantPlan(List<WorkPlan> plans) {
    if (plans.isEmpty) return plans.first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<WorkPlan> futureOrToday = plans.where((p) {
      final d = DateTime(p.date.year, p.date.month, p.date.day);
      return !d.isBefore(today);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (futureOrToday.isNotEmpty) return futureOrToday.first;

    final List<WorkPlan> sorted = List<WorkPlan>.from(plans)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }
}

/// Загружает фактическую выработку по сменам на объекте за конкретную дату.
Future<double> _fetchActualSum(String objectId, DateTime date) async {
  try {
    final supa = Supabase.instance.client;
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')
        .first; // YYYY-MM-DD

    final resp = await supa
        .from('works')
        .select('work_items(total)')
        .eq('object_id', objectId)
        .eq('date', dateStr);

    double sum = 0.0;
    for (final row in (resp as List<dynamic>)) {
      final items = (row as Map)['work_items'] as List<dynamic>?;
      if (items == null) continue;
      for (final it in items) {
        final m = it as Map;
        final t = m['total'];
        if (t is num) sum += t.toDouble();
      }
    }
    return sum;
  } catch (_) {
    return 0.0;
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent; // 0..100
  final String label;
  const _ProgressBar({required this.percent, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = percent.clamp(0, 100) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 14,
            backgroundColor: Colors.green.withValues(alpha: 0.15),
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
