import 'package:freezed_annotation/freezed_annotation.dart';

part 'work.freezed.dart';

/// Сущность "Смена".
///
/// Описывает рабочую смену на объекте, включая дату, объект, инициатора, статус и фотографии.
@freezed
abstract class Work with _$Work {
  /// Создаёт сущность смены.
  ///
  /// [id] — идентификатор смены (опционально)
  /// [date] — дата смены
  /// [objectId] — идентификатор объекта
  /// [openedBy] — идентификатор пользователя, открывшего смену
  /// [status] — статус смены (например, open/closed)
  /// [photoUrl] — ссылка на фото смены (опционально)
  /// [eveningPhotoUrl] — ссылка на вечернее фото (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory Work({
    /// Идентификатор смены.
    String? id,
    /// Дата смены.
    required DateTime date,
    /// Идентификатор объекта.
    required String objectId,
    /// Идентификатор пользователя, открывшего смену.
    required String openedBy,
    /// Статус смены (например, open/closed).
    required String status,
    /// Ссылка на фото смены.
    String? photoUrl,
    /// Ссылка на вечернее фото смены.
    String? eveningPhotoUrl,
    /// Дата создания записи.
    DateTime? createdAt,
    /// Дата последнего обновления.
    DateTime? updatedAt,
  }) = _Work;
} 