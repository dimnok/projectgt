import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/shifts_data_source.dart';
import '../../data/datasources/shifts_data_source_impl.dart';
import '../../data/repositories/shifts_repository_impl.dart';
import '../../domain/repositories/shifts_repository.dart';

/// Провайдер клиента Supabase для календаря.
final shiftsSupabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер источника данных календаря смен.
final shiftsDataSourceProvider = Provider<ShiftsDataSource>((ref) {
  final client = ref.watch(shiftsSupabaseProvider);
  return ShiftsDataSourceImpl(supabaseClient: client);
});

/// Провайдер репозитория календаря смен.
final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) {
  final dataSource = ref.watch(shiftsDataSourceProvider);
  return ShiftsRepositoryImpl(dataSource: dataSource);
});

/// Провайдер для получения данных календаря за месяц.
///
/// Возвращает список смен, агрегированный по датам текущего месяца.
final shiftsForMonthProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>(
        (ref, month) async {
  final repository = ref.watch(shiftsRepositoryProvider);
  return await repository.getShiftsForMonth(month);
});

/// Провайдер для получения деталей смен за конкретный день.
///
/// Возвращает разбивку по объектам и системам за выбранный день.
final shiftsForDateProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final repository = ref.watch(shiftsRepositoryProvider);
  return await repository.getShiftsForDate(date);
});
