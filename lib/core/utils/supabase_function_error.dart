import 'package:supabase_flutter/supabase_flutter.dart';

/// Извлекает текст ошибки из [FunctionException] (в т.ч. вложенный JSON `error`).
String formatFunctionExceptionMessage(FunctionException error) {
  final details = error.details;
  if (details is Map) {
    final err = details['error'];
    if (err is String &&
        err.isNotEmpty &&
        !err.contains('[object Object]')) {
      return err;
    }
    if (err is Map) {
      final msg = err['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    final msg = details['message']?.toString();
    if (msg != null && msg.isNotEmpty) return msg;
  }
  if (error.reasonPhrase != null && error.reasonPhrase!.isNotEmpty) {
    return error.reasonPhrase!;
  }
  return 'Ошибка сервера (${error.status})';
}

/// Сообщение для UI после `functions.invoke` (в т.ч. обёрнутый [Exception]).
String formatInvokeErrorMessage(Object error) {
  if (error is FunctionException) {
    return formatFunctionExceptionMessage(error);
  }
  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}
