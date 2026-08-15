import 'package:supabase_flutter/supabase_flutter.dart';

/// Человекочитаемое сообщение ошибки Supabase/PostgREST для UI.
String formatSupabaseErrorMessage(Object error) {
  if (error is PostgrestException && error.message.isNotEmpty) {
    return error.message;
  }
  if (error is AuthException && error.message.isNotEmpty) {
    return error.message;
  }

  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  if (text.contains('PostgrestException(message: ')) {
    final match = RegExp(r'message: (.+?), code:').firstMatch(text);
    if (match != null) return match.group(1)!;
  }
  return text.isNotEmpty ? text : 'Неизвестная ошибка';
}
