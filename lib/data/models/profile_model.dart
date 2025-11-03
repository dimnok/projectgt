import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/profile.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

/// Data-модель профиля пользователя для работы с Supabase и сериализации/десериализации.
///
/// Используется для хранения и передачи информации о пользователе между слоями data и domain.
/// Позволяет преобразовывать данные из/в доменную сущность [Profile].
///
/// Пример создания:
/// ```dart
/// final profile = ProfileModel(
///   id: 'user-1',
///   email: 'user@example.com',
///   fullName: 'Иван Иванов',
///   shortName: 'Иван',
///   photoUrl: 'https://...',
///   phone: '+79991234567',
///   role: 'admin',
///   status: true,
///   object: {'id': 'obj-1'},
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
@freezed
abstract class ProfileModel with _$ProfileModel {
  /// Основной конструктор для создания [ProfileModel].
  ///
  /// - [id] — уникальный идентификатор пользователя.
  /// - [email] — email пользователя.
  /// - [fullName] — полное имя пользователя (опционально).
  /// - [shortName] — короткое имя или никнейм (опционально).
  /// - [photoUrl] — ссылка на фото профиля (опционально).
  /// - [phone] — телефон (опционально).
  /// - [role] — роль пользователя (по умолчанию 'user').
  /// - [status] — активен ли пользователь (по умолчанию true).
  /// - [object] — дополнительная информация об объекте (опционально).
  /// - [objectIds] — список идентификаторов объектов (опционально).
  /// - [createdAt] — дата создания (опционально).
  /// - [updatedAt] — дата обновления (опционально).
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory ProfileModel({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') String? fullName,
    @JsonKey(name: 'short_name') String? shortName,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? phone,
    String? position,
    @Default('user') String role,
    @Default(true) bool status,
    Map<String, dynamic>? object,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'object_ids') List<String>? objectIds,
  }) = _ProfileModel;

  /// Приватный конструктор для поддержки расширения через [freezed].
  const ProfileModel._();

  /// Создаёт [ProfileModel] из JSON.
  ///
  /// [json] — карта с данными профиля.
  /// Возвращает экземпляр [ProfileModel].
  ///
  /// Пример:
  /// ```dart
  /// final model = ProfileModel.fromJson(jsonMap);
  /// ```
  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  /// Создаёт [ProfileModel] из доменной сущности [Profile].
  ///
  /// [profile] — доменная сущность пользователя.
  /// Возвращает экземпляр [ProfileModel].
  factory ProfileModel.fromDomain(Profile profile) => ProfileModel(
        id: profile.id,
        email: profile.email,
        fullName: profile.fullName,
        shortName: profile.shortName,
        photoUrl: profile.photoUrl,
        phone: profile.phone,
        position: profile.position,
        role: profile.role,
        status: profile.status,
        object: profile.object,
        objectIds: profile.objectIds,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );

  /// Преобразует [ProfileModel] в доменную сущность [Profile].
  ///
  /// Возвращает [Profile] с соответствующими полями.
  Profile toDomain() => Profile(
        id: id,
        email: email,
        fullName: fullName,
        shortName: shortName,
        photoUrl: photoUrl,
        phone: phone,
        position: position,
        role: role,
        status: status,
        object: object,
        objectIds: objectIds,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
