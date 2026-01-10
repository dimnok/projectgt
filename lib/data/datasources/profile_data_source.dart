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
  /// [companyId] — опциональный идентификатор компании для получения контекстных данных (роль, статус).
  /// Если [companyId] не передан, будут использованы данные из последней активной компании профиля.
  ///
  /// Возвращает [ProfileModel], либо `null`, если профиль не найден.
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<ProfileModel?> getProfile(String userId, [String? companyId]);

  /// Получить список всех профилей пользователей для конкретной компании [companyId].
  ///
  /// [companyId] — идентификатор компании для фильтрации.
  /// Возвращает [List<ProfileModel>].
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<List<ProfileModel>> getProfiles(String companyId);

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
  Future<ProfileModel?> getProfile(String userId, [String? companyId]) async {
    // Вспомогательная функция для выполнения запроса с ретраем
    Future<dynamic> fetchWithRetry(Future<dynamic> Function() action, {int retries = 2}) async {
      int attempt = 0;
      while (attempt < retries) {
        try {
          return await action().timeout(const Duration(seconds: 10));
        } catch (e) {
          attempt++;
          if (attempt >= retries) rethrow;
          await Future.delayed(Duration(seconds: 1 * attempt));
        }
      }
    }

    try {
      // 1. Получаем профиль (с ретраем)
      final response = await fetchWithRetry(() => client
          .from('profiles')
          .select('*, slot_times, employees(position)')
          .eq('id', userId)
          .single());

      final json = Map<String, dynamic>.from(response as Map);
      final effectiveCompanyId = companyId ?? json['last_company_id'];
      
      // 2. Получаем данные о членстве в компании (с ретраем)
      if (effectiveCompanyId != null && effectiveCompanyId.toString().isNotEmpty && effectiveCompanyId.toString() != 'null') {
        try {
          final memberData = await fetchWithRetry(() => client
              .from('company_members')
              .select('role_id, system_role, is_active')
              .eq('company_id', effectiveCompanyId.toString())
              .eq('user_id', userId)
              .maybeSingle());

          if (memberData != null) {
            json['role_id'] = memberData['role_id'];
            json['system_role'] = memberData['system_role'];
            json['status'] = memberData['is_active'] ?? json['status'];
            json['last_company_id'] = effectiveCompanyId;
          }
        } catch (e) {
          // Ошибка получения данных членства (некритичная)
        }
      }

      // Обработка данных (как раньше)
      final slotTimes = json['slot_times'];
      final obj = Map<String, dynamic>.from((json['object'] ?? {}) as Map);
      final employeeId = json['employee_id'];
      if (employeeId != null) obj['employee_id'] = employeeId;
      
      final employee = json['employees'];
      if (employee != null && employee is Map) {
        final position = employee['position'];
        if (position != null) json['position'] = position;
      }
      
      if (slotTimes != null) {
        obj['slot_times'] = slotTimes;
        json['object'] = obj;
      } else {
        json['object'] = obj;
      }

      return ProfileModel.fromJson(json);
    } catch (e) {
      Logger().e('Error fetching profile: $e');
      if (e.toString().contains('PGRST116')) {
        await client.auth.signOut();
      }
      return null;
    }
  }

  @override
  Future<List<ProfileModel>> getProfiles(String companyId) async {
    try {
      // [RBAC v3] Запрашиваем через company_members для строгой фильтрации по компании
      final response = await client
          .from('company_members')
          .select('''
            role_id,
            system_role,
            is_active,
            profiles (
              *,
              slot_times,
              employees (
                position
              )
            )
          ''')
          .eq('company_id', companyId);

      final members = response as List;
      final results = <ProfileModel>[];

      for (final member in members) {
        final profileData = member['profiles'] as Map<String, dynamic>?;
        if (profileData == null) {
          continue;
        }

        final json = Map<String, dynamic>.from(profileData);

        // [RBAC v3] Используем данные из company_members как источник истины для контекста компании
        json['role_id'] = member['role_id'];
        json['system_role'] = member['system_role'];
        json['status'] = member['is_active'] ?? json['status'];
        json['last_company_id'] = companyId;

        final slotTimes = json['slot_times'];
        final obj = Map<String, dynamic>.from((json['object'] ?? {}) as Map);
        // Проксируем employee_id в object для UI
        final employeeId = json['employee_id'];
        if (employeeId != null) {
          obj['employee_id'] = employeeId;
        }
        // Получаем должность из привязанного сотрудника
        final employee = json['employees'];
        if (employee != null && employee is Map) {
          final position = employee['position'];
          if (position != null) {
            json['position'] = position;
          }
        }
        if (slotTimes != null) {
          obj['slot_times'] = slotTimes;
          json['object'] = obj;
        }
        if (slotTimes == null) {
          json['object'] = obj;
        }
        results.add(ProfileModel.fromJson(json));
      }

      // Сортируем по имени на стороне клиента, так как join может нарушить порядок
      results.sort((a, b) =>
          (a.fullName ?? '').compareTo(b.fullName ?? ''));

      return results;
    } catch (e) {
      Logger().e('Error fetching profiles for company $companyId: $e');
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
              .select('*, slot_times, employees(position)')
              .eq('id', profile.id)
              .maybeSingle();

      if (responseData == null) {
        throw Exception('Profile not found or access denied after update');
      }

      // В ответе slot_times приходит в отдельной колонке — подмешаем обратно в object
      final json = Map<String, dynamic>.from(responseData as Map);
      final slotTimes = json['slot_times'];
      final obj = Map<String, dynamic>.from((json['object'] ?? {}) as Map);
      // Получаем должность из привязанного сотрудника
      final employee = json['employees'];
      if (employee != null && employee is Map) {
        final position = employee['position'];
        if (position != null) {
          json['position'] = position;
        }
      }
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
