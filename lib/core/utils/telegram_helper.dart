/// Вспомогательный класс для отправки сообщений в Telegram
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Вспомогательный класс для отправки сообщений в Telegram через Supabase Edge Functions.
///
/// Предоставляет статические методы для:
/// - Отправки утренних отчетов о начале смены
/// - Обновления утренних отчетов с информацией о часах работы
/// - Отправки вечерних отчетов о работах смены
class TelegramHelper {
  /// Отправляет утренний отчет о начале смены в Telegram
  static Future<Map<String, dynamic>?> sendWorkOpeningReport(
    String workId, {
    List<String> workerNames = const [],
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final authSession = supabase.auth.currentSession;

      if (authSession == null) {
        return {
          'success': false,
          'error': 'No authentication session',
        };
      }

      final token = authSession.accessToken;

      final response = await supabase.functions.invoke(
        'send_work_opening_report_to_telegram',
        body: {
          'work_id': workId,
          'worker_names': workerNames,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          return data;
        } else {
          return data;
        }
      } else {
        return {
          'success': false,
          'error': 'Unexpected response format',
          'data': response.data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Обновляет утреннее сообщение о начале смены с информацией о часах работы
  static Future<Map<String, dynamic>?> updateWorkOpeningReport(
    String workId,
    int telegramMessageId,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final authSession = supabase.auth.currentSession;

      if (authSession == null) {
        return {
          'success': false,
          'error': 'No authentication session',
        };
      }

      final token = authSession.accessToken;

      final response = await supabase.functions.invoke(
        'update_work_opening_report_to_telegram',
        body: {
          'work_id': workId,
          'telegram_message_id': telegramMessageId,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          return data;
        } else {
          return data;
        }
      } else {
        return {
          'success': false,
          'error': 'Unexpected response format',
          'data': response.data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Отправляет вечерний отчет о работах смены в Telegram
  /// Автоматически связывает с утренним отчетом если доступен telegram_message_id
  static Future<Map<String, dynamic>?> sendWorkReport(String workId) async {
    try {
      final supabase = Supabase.instance.client;
      final authSession = supabase.auth.currentSession;

      if (authSession == null) {
        return {
          'success': false,
          'error': 'No authentication session',
        };
      }

      final token = authSession.accessToken;

      final response = await supabase.functions.invoke(
        'send_work_report_to_telegram',
        body: {
          'work_id': workId,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          return data;
        } else {
          return data;
        }
      } else {
        return {
          'success': false,
          'error': 'Unexpected response format',
          'data': response.data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
