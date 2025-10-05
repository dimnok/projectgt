import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/timesheet_data_source.dart';
import '../../data/datasources/timesheet_data_source_impl.dart';
import '../../data/datasources/employee_attendance_data_source.dart';
import '../../data/datasources/employee_attendance_data_source_impl.dart';
import '../../data/repositories/timesheet_repository_impl.dart';
import '../../data/repositories/employee_attendance_repository_impl.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../../domain/repositories/employee_attendance_repository.dart';

/// Провайдер клиента Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер источника данных для таймшита
final timesheetDataSourceProvider = Provider<TimesheetDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TimesheetDataSourceImpl(client);
});

/// Провайдер источника данных для посещаемости сотрудников
final employeeAttendanceDataSourceProvider =
    Provider<EmployeeAttendanceDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmployeeAttendanceDataSourceImpl(client);
});

/// Провайдер репозитория таймшита
final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref) {
  final dataSource = ref.watch(timesheetDataSourceProvider);
  final attendanceRepository = ref.watch(employeeAttendanceRepositoryProvider);
  final employeeRepository = ref.watch(employeeRepositoryProvider);
  final objectRepository = ref.watch(objectRepositoryProvider);

  return TimesheetRepositoryImpl(
    dataSource: dataSource,
    attendanceRepository: attendanceRepository,
    employeeRepository: employeeRepository,
    objectRepository: objectRepository,
  );
});

/// Провайдер репозитория посещаемости сотрудников
final employeeAttendanceRepositoryProvider =
    Provider<EmployeeAttendanceRepository>((ref) {
  final dataSource = ref.watch(employeeAttendanceDataSourceProvider);
  final employeeRepository = ref.watch(employeeRepositoryProvider);
  final objectRepository = ref.watch(objectRepositoryProvider);

  return EmployeeAttendanceRepositoryImpl(
    dataSource: dataSource,
    employeeRepository: employeeRepository,
    objectRepository: objectRepository,
  );
});
