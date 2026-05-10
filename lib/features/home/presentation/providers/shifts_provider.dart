import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/shifts_data_source.dart';
import '../../data/datasources/shifts_data_source_impl.dart';
import '../../data/repositories/shifts_repository_impl.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';

/// Провайдер клиента Supabase для календаря.
final shiftsSupabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер источника данных календаря смен.
final shiftsDataSourceProvider = Provider<ShiftsDataSource>((ref) {
  final client = ref.watch(shiftsSupabaseProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return ShiftsDataSourceImpl(
    supabaseClient: client,
    activeCompanyId: activeCompanyId,
  );
});

/// Провайдер репозитория календаря смен.
final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) {
  final dataSource = ref.watch(shiftsDataSourceProvider);
  return ShiftsRepositoryImpl(dataSource: dataSource);
});

/// Провайдер для получения данных календаря за месяц.
///
/// Возвращает список смен, агрегированный по датам текущего месяца.
/// Использует строку месяца (YYYY-MM) как ключ для стабильности.
final shiftsForMonthProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, monthStr) async {
  final parts = monthStr.split('-');
  final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
  final repository = ref.watch(shiftsRepositoryProvider);
  return await repository.getShiftsForMonth(month);
});

/// Провайдер для получения деталей смен за конкретный день.
///
/// Возвращает разбивку по объектам и системам за выбранный день.
/// Использует строку даты (YYYY-MM-DD) как ключ для стабильности.
final shiftsForDateProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, dateStr) async {
  final date = DateTime.parse(dateStr);
  final repository = ref.watch(shiftsRepositoryProvider);
  return await repository.getShiftsForDate(date);
});

/// Провайдер для получения сводки по сменам за конкретный день.
/// Использует строку даты (YYYY-MM-DD) как ключ для стабильности.
final shiftsSummaryForDateProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, dateStr) async {
  final date = DateTime.parse(dateStr);
  final repository = ref.watch(shiftsRepositoryProvider);
  return await repository.getShiftsSummaryForDate(date);
});
