import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// Сущность "Профиль пользователя" (доменная модель).
///
/// Описывает основные данные профиля пользователя, включая email, ФИО, роль и статус.
@freezed
abstract class Profile with _$Profile {
  /// Основной конструктор [Profile].
  ///
  /// Все параметры соответствуют полям профиля в базе данных.
  const factory Profile({
    /// Уникальный идентификатор профиля.
    required String id,

    /// Email пользователя.
    required String email,

    /// Полное имя пользователя.
    String? fullName,

    /// Краткое имя пользователя.
    String? shortName,

    /// URL фотографии пользователя.
    String? photoUrl,

    /// Телефон пользователя.
    String? phone,

    /// Должность пользователя.
    String? position,

    /// ID роли пользователя (связь с таблицей roles).
    String? roleId,

    /// Системная роль пользователя (owner, admin).
    String? system_role,

    /// Статус профиля (активен/неактивен).
    @Default(true) bool status,

    /// Связанный объект (например, организация или проект).
    Map<String, dynamic>? object,

    /// Связанные объекты (uuid объектов, связанных с профилем).
    List<String>? objectIds,

    /// Дата создания профиля.
    DateTime? createdAt,

    /// Дата последнего обновления профиля.
    DateTime? updatedAt,

    /// ID последней активной компании пользователя.
    String? lastCompanyId,
  }) = _Profile;

  /// Приватный конструктор для расширения функциональности через методы.
  const Profile._();
}
