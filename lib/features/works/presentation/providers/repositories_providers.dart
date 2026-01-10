import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/work_item_repository_impl.dart';
import '../../data/repositories/work_material_repository_impl.dart';
import '../../data/repositories/work_hour_repository_impl.dart';
import '../../data/repositories/work_repository_impl.dart';
import '../../data/datasources/work_item_data_source_impl.dart';
import '../../data/datasources/work_material_data_source_impl.dart';
import '../../data/datasources/work_hour_data_source_impl.dart';
import '../../data/datasources/work_data_source_impl.dart';
import '../../../../core/di/providers.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';

/// Провайдер для репозитория смен.
final workRepositoryProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return WorkRepositoryImpl(
      WorkDataSourceImpl(client, activeCompanyId ?? ''));
});

/// Провайдер для репозитория работ в смене.
final workItemRepositoryProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return WorkItemRepositoryImpl(
      WorkItemDataSourceImpl(client, activeCompanyId ?? ''));
});

/// Провайдер для репозитория материалов в смене.
final workMaterialRepositoryProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return WorkMaterialRepositoryImpl(
      WorkMaterialDataSourceImpl(client, activeCompanyId ?? ''));
});

/// Провайдер для репозитория часов сотрудников в смене.
final workHourRepositoryProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  return WorkHourRepositoryImpl(
      WorkHourDataSourceImpl(client, activeCompanyId ?? ''));
});
