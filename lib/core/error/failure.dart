import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'failure.freezed.dart';

/// Базовый класс для всех ошибок в приложении.
///
/// Позволяет типизировать ошибки для удобной обработки в UI.
@freezed
abstract class Failure with _$Failure {
  /// Ошибка сервера или базы данных.
  const factory Failure.server({String? message, String? code}) = ServerFailure;

  /// Ошибка сети.
  const factory Failure.network({String? message}) = NetworkFailure;

  /// Ошибка аутентификации.
  const factory Failure.auth({String? message}) = AuthFailure;

  /// Объект не найден.
  const factory Failure.notFound({String? message}) = NotFoundFailure;

  /// Доступ запрещен.
  const factory Failure.permissionDenied({String? message}) =
      PermissionDeniedFailure;

  /// Неизвестная ошибка.
  const factory Failure.unknown({String? message, Object? error}) =
      UnknownFailure;

  /// Фабричный метод для создания Failure из исключения.
  factory Failure.fromException(Object e) {
    if (e is PostgrestException) {
      return Failure.server(message: e.message, code: e.code);
    }
    if (e is AuthException) {
      return Failure.auth(message: e.message);
    }
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Network')) {
      return const Failure.network(message: 'Проблемы с интернет-соединением');
    }
    if (e is Failure) return e;

    return Failure.unknown(message: e.toString(), error: e);
  }
}
