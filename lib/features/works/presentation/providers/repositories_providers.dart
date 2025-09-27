import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/work_item_repository_impl.dart';
import '../../data/repositories/work_material_repository_impl.dart';
import '../../data/repositories/work_hour_repository_impl.dart';
import '../../data/repositories/work_repository_impl.dart';
import '../../data/datasources/work_item_data_source_impl.dart';
import '../../data/datasources/work_material_data_source_impl.dart';
import '../../data/datasources/work_hour_data_source_impl.dart';
import '../../data/datasources/work_data_source_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Провайдер для репозитория смен.
final workRepositoryProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return WorkRepositoryImpl(WorkDataSourceImpl(client));
});

/// Провайдер для репозитория работ в смене.
final workItemRepositoryProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return WorkItemRepositoryImpl(WorkItemDataSourceImpl(client));
});

/// Провайдер для репозитория материалов в смене.
final workMaterialRepositoryProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return WorkMaterialRepositoryImpl(WorkMaterialDataSourceImpl(client));
});

/// Провайдер для репозитория часов сотрудников в смене.
final workHourRepositoryProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return WorkHourRepositoryImpl(WorkHourDataSourceImpl(client));
});
