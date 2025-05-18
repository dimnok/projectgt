import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/profile_model.dart';
import 'package:logger/logger.dart';

/// Абстракция источника данных для работы с профилями пользователей ([ProfileModel]).
/// 
/// Определяет базовые операции для получения, обновления и удаления профилей.
/// 
/// Пример использования:
/// ```dart
/// final dataSource = SupabaseProfileDataSource(client);
/// final profile = await dataSource.getProfile(userId);
/// ```
abstract class ProfileDataSource {
  /// Получить профиль пользователя по его идентификатору [userId].
  ///
  /// [userId] — уникальный идентификатор пользователя.
  /// Возвращает [ProfileModel], либо `null`, если профиль не найден.
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<ProfileModel?> getProfile(String userId);

  /// Получить список всех профилей пользователей.
  ///
  /// Возвращает [List<ProfileModel>].
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<List<ProfileModel>> getProfiles();

  /// Обновить данные профиля пользователя.
  ///
  /// [profile] — объект с обновлёнными данными профиля (id обязателен).
  /// Возвращает обновлённый [ProfileModel].
  /// Может выбросить исключение, если профиль не найден или не удалось обновить.
  Future<ProfileModel> updateProfile(ProfileModel profile);

  /// Удалить профиль пользователя по идентификатору [userId].
  ///
  /// [userId] — уникальный идентификатор пользователя.
  /// Возвращает `void`.
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<void> deleteProfile(String userId);
}

/// Реализация [ProfileDataSource] для Supabase.
/// 
/// Использует [SupabaseClient] для взаимодействия с таблицей профилей.
/// 
/// Пример:
/// ```dart
/// final dataSource = SupabaseProfileDataSource(client);
/// final profiles = await dataSource.getProfiles();
/// ```
class SupabaseProfileDataSource implements ProfileDataSource {
  /// Клиент Supabase для работы с БД.
  final SupabaseClient client;

  /// Создаёт экземпляр с переданным [client].
  SupabaseProfileDataSource(this.client);

  @override
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      
      return ProfileModel.fromJson(response);
    } catch (e) {
      Logger().e('Error fetching profile: $e');
      return null;
    }
  }

  @override
  Future<List<ProfileModel>> getProfiles() async {
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .order('full_name');
      
      return response.map<ProfileModel>((json) => ProfileModel.fromJson(json)).toList();
    } catch (e) {
      Logger().e('Error fetching profiles: $e');
      return [];
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final response = await client
          .from('profiles')
          .update({
            'full_name': profile.fullName,
            'short_name': profile.shortName,
            'photo_url': profile.photoUrl,
            'phone': profile.phone,
            'status': profile.status,
            'role': profile.role,
            'object': profile.object,
            'object_ids': profile.objectIds,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id)
          .select('*')
          .single();
      
      return ProfileModel.fromJson(response);
    } catch (e) {
      Logger().e('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfile(String userId) async {
    await client
        .from('profiles')
        .delete()
        .eq('id', userId);
  }
} 