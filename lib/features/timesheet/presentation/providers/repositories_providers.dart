import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/timesheet_data_source.dart';
import '../../data/datasources/timesheet_data_source_impl.dart';
import '../../data/repositories/timesheet_repository_impl.dart';
import '../../domain/repositories/timesheet_repository.dart';

/// Провайдер клиента Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер источника данных для таймшита
final timesheetDataSourceProvider = Provider<TimesheetDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TimesheetDataSourceImpl(client);
});

/// Провайдер репозитория таймшита
final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref) {
  final dataSource = ref.watch(timesheetDataSourceProvider);
  final employeeRepository = ref.watch(employeeRepositoryProvider);
  final objectRepository = ref.watch(objectRepositoryProvider);
  
  return TimesheetRepositoryImpl(
    dataSource: dataSource,
    employeeRepository: employeeRepository,
    objectRepository: objectRepository,
  );
}); 