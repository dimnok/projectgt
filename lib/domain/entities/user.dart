import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// Сущность "Пользователь" (доменная модель).
///
/// Описывает основные данные пользователя для аутентификации и авторизации.
@freezed
abstract class User with _$User {
  /// Основной конструктор [User].
  ///
  /// Все параметры соответствуют полям пользователя в базе данных.
  const factory User({
    /// Уникальный идентификатор пользователя.
    required String id,

    /// Email пользователя.
    required String email,

    /// Имя пользователя.
    String? name,

    /// URL фотографии пользователя.
    String? photoUrl,

    /// ID роли пользователя (связь с таблицей roles).
    String? roleId,
  }) = _User;

  /// Приватный конструктор для расширения функциональности через методы.
  const User._();
}
