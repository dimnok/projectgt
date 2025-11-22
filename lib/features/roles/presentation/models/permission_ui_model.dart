import 'package:flutter/cupertino.dart';

/// Модель разрешения (права доступа) для отображения в матрице.
class PermissionUiModel {
  /// Уникальный идентификатор разрешения.
  final String id;

  /// Название разрешения.
  final String name;

  /// Код разрешения (например, 'read', 'create').
  final String code;

  /// Иконка разрешения.
  final IconData icon;

  /// Конструктор для создания разрешения.
  const PermissionUiModel({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
  });
}

/// Список доступных разрешений.
final permissionsList = [
  const PermissionUiModel(
    id: 'read',
    name: 'Просмотр',
    code: 'read',
    icon: CupertinoIcons.eye,
  ),
  const PermissionUiModel(
    id: 'create',
    name: 'Создание',
    code: 'create',
    icon: CupertinoIcons.plus,
  ),
  const PermissionUiModel(
    id: 'update',
    name: 'Редактирование',
    code: 'update',
    icon: CupertinoIcons.pencil,
  ),
  const PermissionUiModel(
    id: 'delete',
    name: 'Удаление',
    code: 'delete',
    icon: CupertinoIcons.trash,
  ),
  const PermissionUiModel(
    id: 'export',
    name: 'Экспорт',
    code: 'export',
    icon: CupertinoIcons.arrow_down_circle,
  ),
  const PermissionUiModel(
    id: 'import',
    name: 'Импорт',
    code: 'import',
    icon: CupertinoIcons.arrow_up_circle,
  ),
];
