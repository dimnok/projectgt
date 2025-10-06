import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version_model.freezed.dart';
part 'app_version_model.g.dart';

/// Модель версии приложения для работы с JSON.
///
/// Используется для сериализации/десериализации данных из Supabase.
@freezed
abstract class AppVersionModel with _$AppVersionModel {
  /// Создаёт экземпляр [AppVersionModel].
  const factory AppVersionModel({
    required String id,
    @JsonKey(name: 'current_version') required String currentVersion,
    @JsonKey(name: 'minimum_version') required String minimumVersion,
    @JsonKey(name: 'force_update') required bool forceUpdate,
    @JsonKey(name: 'update_message') String? updateMessage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AppVersionModel;

  /// Создаёт [AppVersionModel] из JSON.
  factory AppVersionModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionModelFromJson(json);
}
