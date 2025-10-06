import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/repositories/version_repository.dart';
import 'package:projectgt/domain/entities/app_version.dart';
import 'package:projectgt/core/constants/app_constants.dart';
import 'package:projectgt/core/utils/version_utils.dart';

/// Провайдер Supabase клиента.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Провайдер репозитория версий.
final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return VersionRepository(client);
});

/// Провайдер для отслеживания изменений версии приложения в реальном времени.
///
/// Подписывается на изменения в таблице app_versions через Supabase Realtime.
final watchAppVersionProvider = StreamProvider<AppVersion>((ref) {
  final repository = ref.watch(versionRepositoryProvider);
  return repository.watchVersionChanges();
});

/// Провайдер для проверки актуальности версии приложения.
///
/// Возвращает true если текущая версия поддерживается, false если требуется обновление.
final versionCheckerProvider = FutureProvider<bool>((ref) async {
  try {
    final repository = ref.watch(versionRepositoryProvider);
    final versionInfo = await repository.getVersionInfo();

    // Сравниваем текущую версию приложения с минимальной требуемой
    final isSupported = VersionUtils.isVersionSupported(
      AppConstants.appVersion,
      versionInfo.minimumVersion,
    );

    return isSupported;
  } catch (e) {
    // В случае ошибки считаем версию поддерживаемой, чтобы не блокировать доступ
    return true;
  }
});

/// Провайдер текущей информации о версии.
///
/// Используется для отображения сообщения об обновлении и минимальной версии.
final currentVersionInfoProvider = FutureProvider<AppVersion?>((ref) async {
  try {
    final repository = ref.watch(versionRepositoryProvider);
    return await repository.getVersionInfo();
  } catch (e) {
    return null;
  }
});
