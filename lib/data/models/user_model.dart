import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data-модель пользователя для работы с API и БД.
///
/// Используется для сериализации/десериализации, преобразования между слоями data и domain.
@freezed
abstract class UserModel with _$UserModel {
  /// Основной конструктор [UserModel].
  ///
  /// [id] — уникальный идентификатор пользователя.
  /// [email] — email пользователя.
  /// [name] — имя пользователя (опционально).
  /// [photoUrl] — URL фото пользователя (опционально).
  /// [role] — роль пользователя (по умолчанию 'user').
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory UserModel({
    required String id,
    required String email,
    String? name,
    String? photoUrl,
    @Default('user') String role,
  }) = _UserModel;

  /// Приватный конструктор для расширения функциональности через методы.
  const UserModel._();

  /// Создаёт [UserModel] из JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// Преобразует доменную сущность [User] в [UserModel].
  factory UserModel.fromDomain(User user) => UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        photoUrl: user.photoUrl,
        role: user.role,
      );
  
  /// Преобразует [UserModel] в доменную сущность [User].
  User toDomain() => User(
        id: id,
        email: email,
        name: name,
        photoUrl: photoUrl,
        role: role,
      );
} 