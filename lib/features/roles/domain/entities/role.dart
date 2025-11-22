import 'package:freezed_annotation/freezed_annotation.dart';

part 'role.freezed.dart';

/// Доменная сущность роли
@freezed
abstract class Role with _$Role {
  /// Конструктор для создания доменной сущности [Role].
  const factory Role({
    required String id,
    required String name,
    required String description,
    @Default(false) bool isSystem,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Role;
}
