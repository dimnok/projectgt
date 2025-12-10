import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/procurement/domain/entities/procurement_application.dart';
import 'package:projectgt/features/procurement/data/models/bot_user_model.dart';

part 'procurement_repository.g.dart';

/// Провайдер репозитория закупок.
@riverpod
ProcurementRepository procurementRepository(Ref ref) {
  return ProcurementRepository(ref.watch(supabaseClientProvider));
}

/// Репозиторий для работы с модулем закупок.
///
/// Отвечает за взаимодействие с Supabase по сущностям:
/// - Заявки на закупку (procurement_applications)
/// - Конфигурация согласования (procurement_approval_config)
/// - Пользователи (profiles)
class ProcurementRepository {
  final SupabaseClient _supabase;

  /// Создаёт экземпляр репозитория закупок.
  ProcurementRepository(this._supabase);

  /// Получает список всех заявок на закупку.
  ///
  /// Загружает также связанные данные: объект, заявителя, список товаров и историю.
  /// История сортируется по убыванию даты и обогащается данными пользователей из profiles.
  Future<List<ProcurementApplication>> getApplications() async {
    try {
      final response = await _supabase
          .from('procurement_applications')
          .select('''
            id,
            readable_id,
            created_at,
            updated_at,
            status,
            object:objects(id, name, address, description),
            requester:profiles!procurement_applications_requester_telegram_id_fkey(id, full_name, telegram_user_id),
            items:procurement_requests(
              id,
              item_name,
              quantity,
              description,
              status,
              created_at,
              updated_at
            ),
            history:procurement_history(
              id,
              new_status,
              changed_at,
              comment,
              actor_telegram_id
            )
          ''')
          .order('created_at', ascending: false);

      // Загружаем пользователей для обогащения истории (из profiles)
      // Используем telegram_user_id для связи с историей, так как там записан actor_telegram_id
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, telegram_user_id')
          .not('telegram_user_id', 'is', null);

      final profilesMap = <int, BotUserModel>{};
      for (final user in profilesResponse as List) {
        final telegramId = user['telegram_user_id'] as int;
        final model = BotUserModel(
          id: user['id'] as String,
          telegramChatId: telegramId,
          fullName: user['full_name'] as String? ?? 'Без имени',
          roleId: null, // Not needed for history display
        );
        profilesMap[telegramId] = model;
      }

      // Сортируем историю внутри каждой заявки по убыванию даты и обогащаем данными пользователей
      final data = (response as List).map((json) {
        try {
          final appJson = json as Map<String, dynamic>;

          // Маппинг requester из структуры profiles в структуру, ожидаемую BotUserModel
          if (appJson['requester'] != null) {
            final requesterProfile = appJson['requester'] as Map<String, dynamic>;
            appJson['requester'] = {
              'id': requesterProfile['id'],
              'full_name': requesterProfile['full_name'],
              'telegram_chat_id': requesterProfile['telegram_user_id'],
            };
          }
          
          // Обогащаем историю данными пользователей
          if (appJson['history'] != null) {
            final historyList = appJson['history'] as List;
            for (final historyItem in historyList) {
              final historyMap = historyItem as Map<String, dynamic>;
              final actorTelegramId = historyMap['actor_telegram_id'] as int?;
              if (actorTelegramId != null && profilesMap.containsKey(actorTelegramId)) {
                final user = profilesMap[actorTelegramId]!;
                historyMap['actor'] = {
                  'id': user.id,
                  'full_name': user.fullName,
                  'telegram_chat_id': user.telegramChatId,
                };
              }
            }
          }

          final app = ProcurementApplication.fromJson(appJson);
          final sortedHistory = List<ProcurementHistory>.from(app.history)
            ..sort((a, b) => b.changedAt.compareTo(a.changedAt));
          return app.copyWith(history: sortedHistory);
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing application: $e');
          rethrow;
        }
      }).toList();

      return data;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching procurement applications: $e');
      rethrow;
    }
  }

  /// Получает список пользователей, имеющих доступ к согласованию (из профилей с указанным Telegram ID).
  Future<List<BotUserModel>> getBotUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, telegram_user_id, role_id')
          .not('telegram_user_id', 'is', null)
          .order('full_name');

      return (response as List).map((json) {
        // Map profiles data to BotUserModel format
        return BotUserModel(
          id: json['id'] as String,
          telegramChatId: (json['telegram_user_id'] as int),
          fullName: json['full_name'] as String? ?? 'Без имени',
          roleId: json['role_id'] as String?,
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching bot users from profiles: $e');
      rethrow;
    }
  }

  /// Получает конфигурацию согласования, сгруппированную по этапам.
  /// Возвращает Map где ключ - название этапа (stage), значение - список ID пользователей (из profiles).
  Future<Map<String, List<String>>> getApprovalConfig() async {
    try {
      final response = await _supabase
          .from('procurement_approval_config')
          .select('stage, user_id')
          .order('stage');

      final Map<String, List<String>> config = {};
      for (final item in response as List) {
        final stage = item['stage'] as String;
        final userId = item['user_id'] as String;
        config.putIfAbsent(stage, () => []).add(userId);
      }

      return config;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching approval config: $e');
      rethrow;
    }
  }

  /// Сохраняет список согласующих для указанного этапа.
  /// Удаляет старые записи для этапа и добавляет новые (ссылаются на profiles.id).
  Future<void> saveStageApprovers(String stage, List<String> userIds) async {
    try {
      // Удаляем старые записи для этого этапа
      await _supabase
          .from('procurement_approval_config')
          .delete()
          .eq('stage', stage);

      // Добавляем новые записи
      if (userIds.isNotEmpty) {
        final inserts = userIds.map((userId) => {
          'stage': stage,
          'user_id': userId,
        }).toList();

        await _supabase.from('procurement_approval_config').insert(inserts);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving stage approvers: $e');
      rethrow;
    }
  }
}
