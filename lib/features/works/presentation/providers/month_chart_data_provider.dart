import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/light_work.dart';
import 'repositories_providers.dart';

part 'month_chart_data_provider.g.dart';

/// Провайдер для загрузки данных графика за месяц.
///
/// Использует [LightWork] для получения всех смен месяца без пагинации,
/// но с минимальным набором полей (только дата и сумма).
@riverpod
Future<List<LightWork>> monthChartData(
  ref,
  DateTime month,
) async {
  final repository = ref.watch(workRepositoryProvider);
  return repository.getMonthWorksForChart(month);
}
