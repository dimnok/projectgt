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
  const PermissionUiModel(
    id: 'issue',
    name: 'Выдача / возврат',
    code: 'issue',
    icon: CupertinoIcons.arrow_right_circle,
  ),
  const PermissionUiModel(
    id: 'move',
    name: 'Перемещение',
    code: 'move',
    icon: CupertinoIcons.arrow_2_circlepath,
  ),
  const PermissionUiModel(
    id: 'repair',
    name: 'Ремонт',
    code: 'repair',
    icon: CupertinoIcons.wrench,
  ),
  const PermissionUiModel(
    id: 'write_off',
    name: 'Списание',
    code: 'write_off',
    icon: CupertinoIcons.trash_circle,
  ),
  const PermissionUiModel(
    id: 'inventory',
    name: 'Инвентаризация',
    code: 'inventory',
    icon: CupertinoIcons.list_bullet,
  ),
  const PermissionUiModel(
    id: 'view_cost',
    name: 'Стоимость',
    code: 'view_cost',
    icon: CupertinoIcons.money_rubl,
  ),
  const PermissionUiModel(
    id: 'manage_catalogs',
    name: 'Справочники',
    code: 'manage_catalogs',
    icon: CupertinoIcons.book,
  ),
];
