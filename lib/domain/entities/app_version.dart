import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';

/// Сущность версии приложения.
///
/// Содержит информацию о текущей и минимальной поддерживаемой версии для всех платформ.
@freezed
abstract class AppVersion with _$AppVersion {
  /// Создаёт экземпляр [AppVersion].
  const factory AppVersion({
    /// Идентификатор версии.
    required String id,

    /// Текущая последняя версия приложения.
    required String currentVersion,

    /// Минимальная поддерживаемая версия.
    required String minimumVersion,

    /// Флаг принудительного обновления.
    required bool forceUpdate,

    /// Сообщение для пользователя об обновлении.
    String? updateMessage,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления записи.
    DateTime? updatedAt,
  }) = _AppVersion;
}
