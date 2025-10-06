import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/domain/entities/app_version.dart';
import 'package:projectgt/data/models/app_version_model.dart';

/// Репозиторий для работы с версиями приложения.
///
/// Предоставляет методы для получения информации о версиях и подписки на изменения через Realtime.
class VersionRepository {
  /// Supabase клиент.
  final SupabaseClient _client;

  /// Создаёт экземпляр [VersionRepository].
  VersionRepository(this._client);

  /// Получает информацию о версии приложения.
  ///
  /// Выбрасывает исключение если данные не найдены или произошла ошибка.
  Future<AppVersion> getVersionInfo() async {
    try {
      final response =
          await _client.from('app_versions').select().limit(1).single();

      final model = AppVersionModel.fromJson(response);
      return AppVersion(
        id: model.id,
        currentVersion: model.currentVersion,
        minimumVersion: model.minimumVersion,
        forceUpdate: model.forceUpdate,
        updateMessage: model.updateMessage,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
      );
    } catch (e) {
      throw Exception('Ошибка получения информации о версии: $e');
    }
  }

  /// Создаёт поток для отслеживания изменений версии в реальном времени.
  ///
  /// Возвращает Stream с обновлениями версии при каждом изменении в БД.
  Stream<AppVersion> watchVersionChanges() {
    return _client
        .from('app_versions')
        .stream(primaryKey: ['id'])
        .limit(1)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('Данные о версии не найдены');
          }
          final model = AppVersionModel.fromJson(data.first);
          return AppVersion(
            id: model.id,
            currentVersion: model.currentVersion,
            minimumVersion: model.minimumVersion,
            forceUpdate: model.forceUpdate,
            updateMessage: model.updateMessage,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
          );
        });
  }

  /// Обновляет информацию о версии приложения.
  ///
  /// [id] - идентификатор записи версии.
  /// [minimumVersion] - новая минимальная версия.
  /// [forceUpdate] - флаг принудительного обновления.
  /// [updateMessage] - сообщение для пользователя.
  ///
  /// Доступно только администраторам (защищено RLS политиками).
  Future<void> updateVersion({
    required String id,
    required String minimumVersion,
    required bool forceUpdate,
    String? updateMessage,
  }) async {
    try {
      await _client.from('app_versions').update({
        'minimum_version': minimumVersion,
        'force_update': forceUpdate,
        'update_message': updateMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Ошибка обновления версии: $e');
    }
  }
}
