import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/export_repository.dart';
import '../../data/repositories/export_repository_impl.dart';
import '../../data/datasources/export_data_source.dart';
import '../../data/datasources/export_data_source_impl.dart';
import '../services/export_service.dart';
import '../../data/repositories/work_search_repository_impl.dart';
import '../../data/datasources/work_search_data_source_impl.dart';

/// Провайдер клиента Supabase.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер источника данных выгрузки.
final exportDataSourceProvider = Provider<ExportDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ExportDataSourceImpl(
    supabaseClient: supabaseClient,
  );
});

/// Провайдер репозитория выгрузки.
final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  final dataSource = ref.watch(exportDataSourceProvider);
  return ExportRepositoryImpl(dataSource: dataSource);
});

/// Провайдер сервиса экспорта.
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

/// Провайдер для репозитория поиска материалов по работам.
final workSearchRepositoryProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return WorkSearchRepositoryImpl(WorkSearchDataSourceImpl(client));
});
