import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_model.freezed.dart';
part 'work_model.g.dart';

/// Data-модель смены для хранения и передачи данных между слоями data и источником данных.
@freezed
abstract class WorkModel with _$WorkModel {
  /// Создаёт data-модель смены.
  ///
  /// [id] — идентификатор смены (опционально)
  /// [date] — дата смены
  /// [objectId] — идентификатор объекта
  /// [openedBy] — идентификатор пользователя, открывшего смену
  /// [status] — статус смены
  /// [photoUrl] — ссылка на фото смены (опционально)
  /// [eveningPhotoUrl] — ссылка на вечернее фото (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkModel({
    /// Идентификатор смены.
    String? id,

    /// Дата смены.
    @JsonKey(name: 'date') required DateTime date,

    /// Идентификатор объекта.
    @JsonKey(name: 'object_id') required String objectId,

    /// Идентификатор пользователя, открывшего смену.
    @JsonKey(name: 'opened_by') required String openedBy,

    /// Статус смены.
    @JsonKey(name: 'status') required String status,

    /// Ссылка на фото смены.
    @JsonKey(name: 'photo_url') String? photoUrl,

    /// Ссылка на вечернее фото смены.
    @JsonKey(name: 'evening_photo_url') String? eveningPhotoUrl,

    /// Дата создания записи.
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// Дата последнего обновления.
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _WorkModel;

  /// Создаёт data-модель смены из JSON.
  factory WorkModel.fromJson(Map<String, dynamic> json) =>
      _$WorkModelFromJson(json);
}
