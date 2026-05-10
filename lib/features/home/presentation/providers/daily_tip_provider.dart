import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

/// Модель совета дня.
class DailyTip {
  /// Заголовок совета (краткая строка для карточки).
  final String title;

  /// Полный текст совета.
  final String content;

  /// Тематическая категория (например, область применения на объекте).
  final String category;

  /// Создаёт совет дня с заданными полями.
  const DailyTip({
    required this.title,
    required this.content,
    this.category = 'Электрика',
  });

  /// Создаёт [DailyTip] из JSON-ответа Edge Function `get-daily-tip`.
  ///
  /// Поля [json]: `title`, `content`, `category` (опционально).
  factory DailyTip.fromJson(Map<String, dynamic> json) {
    return DailyTip(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Электрика',
    );
  }
}

/// Провайдер для получения совета дня из Edge Function.
final dailyTipProvider = FutureProvider.autoDispose<DailyTip>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  
  try {
    final response = await client.functions.invoke('get-daily-tip');
    
    if (response.status == 200 && response.data != null) {
      return DailyTip.fromJson(response.data);
    } else {
      throw Exception('Ошибка при получении совета: ${response.status}');
    }
  } catch (e) {
    // В случае ошибки возвращаем фолбек-совет, чтобы UI не ломался
    return const DailyTip(
      title: 'Безопасность прежде всего',
      content: 'Всегда проверяйте отсутствие напряжения перед началом работ. Мультиметр — ваш лучший друг.',
    );
  }
});
