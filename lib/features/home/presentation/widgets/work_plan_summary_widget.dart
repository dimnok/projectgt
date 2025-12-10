import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/work_plan.dart';

/// Данные для отображения карточки плана.
class _WorkPlanSummaryData {
  final WorkPlan plan;
  final double totalPlan;
  final double perSpecialist;
  final int workersCount;
  final int totalBlocks;
  final int completeBlocks;
  final double progressPercent;

  const _WorkPlanSummaryData({
    required this.plan,
    required this.totalPlan,
    required this.perSpecialist,
    required this.workersCount,
    required this.totalBlocks,
    required this.completeBlocks,
    required this.progressPercent,
  });
}

/// Провайдер, вычисляющий актуальный план работ для отображения.
///
/// Возвращает [_WorkPlanSummaryData] или null, если планов нет.
final _relevantWorkPlanProvider =
    Provider.autoDispose<_WorkPlanSummaryData?>((ref) {
  // Используем select для пересчёта только при изменении списка планов
  final plans = ref.watch(workPlanNotifierProvider.select((s) => s.workPlans));

  if (plans.isEmpty) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Ищем ближайший план в будущем (или сегодня)
  final futureOrToday = plans.where((p) {
    final d = DateTime(p.date.year, p.date.month, p.date.day);
    return !d.isBefore(today);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  // Если нет будущих, берем самый свежий из прошедших
  final selected = futureOrToday.isNotEmpty
      ? futureOrToday.first
      : (List<WorkPlan>.from(plans)..sort((a, b) => b.date.compareTo(a.date)))
          .first;

  final totalPlan = selected.totalPlannedCost;
  final workers = selected.workBlocks.expand((b) => b.workerIds).toSet();
  final workersCount = workers.length;
  final perSpecialist = workersCount > 0 ? (totalPlan / workersCount) : 0.0;

  // Расчёт прогресса на основе данных внутри плана
  final actualBased = selected.completionPercentage.clamp(0.0, 100.0);
  final totalBlocks = selected.workBlocks.length;
  final completeBlocks = selected.workBlocks.where((b) => b.isComplete).length;
  final setupBased =
      totalBlocks > 0 ? (completeBlocks / totalBlocks * 100.0) : 0.0;
  final progressPercent =
      (actualBased > 0 ? actualBased : setupBased).clamp(0.0, 100.0);

  return _WorkPlanSummaryData(
    plan: selected,
    totalPlan: totalPlan,
    perSpecialist: perSpecialist,
    workersCount: workersCount,
    totalBlocks: totalBlocks,
    completeBlocks: completeBlocks,
    progressPercent: progressPercent,
  );
});

/// Провайдер для получения фактической суммы выполненных работ.
///
/// Аргументы: кортеж (ID объекта, Дата).
final _actualWorkSumProvider = FutureProvider.autoDispose
    .family<double, ({String objectId, DateTime date})>((ref, args) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final dateStr = DateTime(args.date.year, args.date.month, args.date.day)
        .toIso8601String()
        .split('T')
        .first;

    final resp = await client
        .from('works')
        .select('work_items(total)')
        .eq('object_id', args.objectId)
        .eq('date', dateStr);

    double sum = 0.0;
    // Парсим ответ Supabase (List<Map<String, dynamic>>)
    final list = resp as List<dynamic>;
    for (final row in list) {
      final items = (row as Map)['work_items'] as List<dynamic>?;
      if (items == null) continue;
      for (final item in items) {
        final total = (item as Map)['total'];
        if (total is num) sum += total.toDouble();
      }
    }
    return sum;
  } catch (e) {
    // В случае ошибки возвращаем 0.0, чтобы не ломать UI
    return 0.0;
  }
});

/// Карточка «План работ» для главного экрана.
///
/// Отображает агрегированную информацию по ближайшему плану работ.
class WorkPlanSummaryWidget extends ConsumerWidget {
  const WorkPlanSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryData = ref.watch(_relevantWorkPlanProvider);

    // Если данные ещё загружаются в глобальном провайдере (первый запуск)
    // можно проверить loading состояние основного провайдера, если нужно.
    // Но здесь мы просто смотрим на результат селектора.

    if (summaryData == null) {
      // Проверяем, может просто идёт загрузка
      final isLoading =
          ref.watch(workPlanNotifierProvider.select((s) => s.isLoading));
      if (isLoading) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      return Center(
        child: Text(
          'Нет планов работ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
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
          value: formatCurrency(summaryData.totalPlan),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        _KpiTile(
          label: 'План на специалиста',
          value: formatCurrency(summaryData.perSpecialist),
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        _WorkProgress(summaryData: summaryData),
        const Spacer(),
        Row(
          children: [
            _Chip(
              label: 'Сотрудники',
              value: summaryData.workersCount.toString(),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Блоков',
              value: summaryData.totalBlocks.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Виджет прогресса выполнения (вынесен отдельно для оптимизации перерисовок).
class _WorkProgress extends ConsumerWidget {
  final _WorkPlanSummaryData summaryData;

  const _WorkProgress({required this.summaryData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем фактическую сумму асинхронно
    final actualSumAsync = ref.watch(_actualWorkSumProvider((
      objectId: summaryData.plan.objectId,
      date: summaryData.plan.date,
    )));

    return actualSumAsync.when(
      data: (actualSum) {
        final totalPlan = summaryData.totalPlan;
        final finalPercent = totalPlan > 0
            ? ((actualSum / totalPlan) * 100).clamp(0.0, 100.0)
            : summaryData.progressPercent;

        final suffix = (actualSum <= 0 && summaryData.totalBlocks > 0)
            ? ' · ${summaryData.completeBlocks}/${summaryData.totalBlocks} блоков'
            : '';

        return _ProgressBar(
          percent: finalPercent,
          label: 'Выполнение: ${finalPercent.toStringAsFixed(0)}%$suffix',
        );
      },
      loading: () => _ProgressBar(
        percent: summaryData.progressPercent,
        label: 'Загрузка данных...',
      ),
      error: (_, __) => _ProgressBar(
        percent: summaryData.progressPercent,
        label: 'Ошибка загрузки данных',
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

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
    final p = percent.clamp(0.0, 100.0) / 100.0;
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
