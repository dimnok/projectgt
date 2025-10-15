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
          .select('*, slot_times')
          .eq('id', userId)
          .single();

      {
        final json = Map<String, dynamic>.from(response as Map);
        final slotTimes = json['slot_times'];
        final obj = Map<String, dynamic>.from((json['object'] ?? {}) as Map);
        // Проксируем employee_id в object для UI
        final employeeId = json['employee_id'];
        if (employeeId != null) {
          obj['employee_id'] = employeeId;
        }
        if (slotTimes != null) {
          obj['slot_times'] = slotTimes;
          json['object'] = obj;
        }
        // Если slot_times отсутствует, но obj уже модифицирован — всё равно проставим object
        if (slotTimes == null) {
          json['object'] = obj;
        }
        return ProfileModel.fromJson(json);
      }
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
          .select('*, slot_times')
          .order('full_name');

      return (response as List).map<ProfileModel>((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        final slotTimes = json['slot_times'];
        final obj = Map<String, dynamic>.from((json['object'] ?? {}) as Map);
        // Проксируем employee_id в object для UI
        final employeeId = json['employee_id'];
        if (employeeId != null) {
          obj['employee_id'] = employeeId;
        }
        if (slotTimes != null) {
          obj['slot_times'] = slotTimes;
          json['object'] = obj;
        }
        if (slotTimes == null) {
          json['object'] = obj;
        }
        return ProfileModel.fromJson(json);
      }).toList();
    } catch (e) {
      Logger().e('Error fetching profiles: $e');
      return [];
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      // Извлекаем slot_times из object, если переданы из UI
      final List<String>? slotTimesFromObject =
          (profile.object != null && profile.object!.containsKey('slot_times'))
              ? (profile.object!['slot_times'] as List?)
                  ?.map((e) => e.toString())
                  .toList()
              : null;

      final Map<String, dynamic> cleanedObject =
          Map<String, dynamic>.from(profile.object ?? <String, dynamic>{});
      // Удаляем служебные поля из object, т.к. они хранятся в отдельных колонках
      cleanedObject.remove('slot_times');
      final String? employeeIdFromObject =
          cleanedObject.remove('employee_id') as String?;

      final Map<String, dynamic> updates = {
        'full_name': profile.fullName,
        'short_name': profile.shortName,
        'photo_url': profile.photoUrl,
        'phone': profile.phone,
        'status': profile.status,
        'role': profile.role,
        'object': cleanedObject,
        'object_ids': profile.objectIds,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (slotTimesFromObject != null) {
        updates['slot_times'] = slotTimesFromObject;
      }
      // Обновляем колонку employee_id если пришло значение из UI
      if (employeeIdFromObject != null) {
        updates['employee_id'] = employeeIdFromObject;
      } else {
        // Если явного значения нет и пользователь очистил поле — установим NULL
        if ((profile.object != null) &&
            !(profile.object!.containsKey('employee_id'))) {
          updates['employee_id'] = null;
        }
      }

      final response = await client
          .from('profiles')
          .update(updates)
          .eq('id', profile.id)
          .select('*')
          .maybeSingle();

      // Если ничего не вернулось - попробуем прочитать профиль напрямую
      final responseData = response ??
          await client
              .from('profiles')
              .select('*, slot_times')
              .eq('id', profile.id)
              .single();

      // В ответе slot_times приходит в отдельной колонке — подмешаем обратно в object
      final json = Map<String, dynamic>.from(responseData as Map);
      final slotTimes = json['slot_times'];
      final obj = Map<String, dynamic>.from((json['object'] ?? {}) as Map);
      if (slotTimes != null) {
        obj['slot_times'] = slotTimes;
      }
      // Проксируем employee_id обратно для UI
      if (json.containsKey('employee_id') && json['employee_id'] != null) {
        obj['employee_id'] = json['employee_id'];
      }
      json['object'] = obj;
      return ProfileModel.fromJson(json);
    } catch (e) {
      Logger().e('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfile(String userId) async {
    await client.from('profiles').delete().eq('id', userId);
  }
}
