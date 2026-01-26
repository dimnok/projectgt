import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/work_search_repository_impl.dart';
import '../../data/datasources/work_search_data_source_impl.dart';
import '../services/work_search_export_server_service.dart';

/// Провайдер клиента Supabase.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер сервиса серверного экспорта
final workSearchExportServerServiceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WorkSearchExportServerService(client: client);
});

/// Провайдер для репозитория поиска материалов по работам.
final workSearchRepositoryProvider = Provider((ref) {
  final client = Supabase.instance.client;
  return WorkSearchRepositoryImpl(WorkSearchDataSourceImpl(client));
});
