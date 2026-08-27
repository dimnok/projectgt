import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/features/roles/presentation/models/permission_ui_model.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart' as domain;
import 'package:projectgt/features/roles/domain/entities/module.dart' as domain;

/// Виджет матрицы прав доступа.
///
/// Таблица модулей и прав с вертикальной и горизонтальной прокруткой.
class PermissionsMatrix extends StatefulWidget {
  /// Выбранная роль.
  final domain.Role role;

  /// Список модулей.
  final List<domain.Module> modules;

  /// Текущие права роли.
  final Map<String, Map<String, bool>> rolePermissions;

  /// Временные изменения прав.
  final Map<String, Map<String, bool>> tempPermissions;

  /// Текущая тема приложения.
  final ThemeData theme;

  /// Темная тема или нет.
  final bool isDark;

  /// Коллбэк при переключении права.
  final Function(String moduleId, String permissionId, bool currentValue)
  onPermissionToggle;

  /// Карта отключенных прав для модулей.
  /// Ключ: код модуля, Значение: список кодов прав, которые недоступны.
  static const Map<String, List<String>> _disabledPermissions = {
    'materials': ['create', 'delete'],
    'work_plans': ['export', 'import'],
    'objects': ['export', 'import'],
    'contracts': ['export', 'import'],
    'contractors': ['export', 'import'],
    'export': ['create', 'update', 'delete', 'import'],
    // 'estimates': ['create'], // Разрешаем создание смет
    'employees': ['import'],
    'payroll': ['import'],
    'timesheet': ['import'],
    'works': ['export', 'import'],
    'tmc': ['import'],
    'purchase_requests': [
      'export',
      'import',
      'issue',
      'move',
      'repair',
      'write_off',
      'inventory',
      'view_cost',
      'manage_catalogs',
    ],
  };

  /// Ширина колонки с названием модуля.
  static const double moduleColumnWidth = 240;

  /// Ширина колонки одного права.
  static const double permissionColumnWidth = 88;

  /// Конструктор виджета.
  const PermissionsMatrix({
    super.key,
    required this.role,
    required this.modules,
    required this.rolePermissions,
    required this.tempPermissions,
    required this.theme,
    required this.isDark,
    required this.onPermissionToggle,
  });

  @override
  State<PermissionsMatrix> createState() => _PermissionsMatrixState();
}

class _PermissionsMatrixState extends State<PermissionsMatrix> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  /// Суммарная ширина таблицы (модуль + все колонки прав).
  double get _tableWidth =>
      PermissionsMatrix.moduleColumnWidth +
      permissionsList.length * PermissionsMatrix.permissionColumnWidth;

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Semantics(
      label: 'Матрица прав доступа',
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            primary: false,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                primary: false,
                child: SizedBox(
                  width: _tableWidth,
                  child: Table(
                    columnWidths: {
                      0: const FixedColumnWidth(
                        PermissionsMatrix.moduleColumnWidth,
                      ),
                      for (var i = 0; i < permissionsList.length; i++)
                        i + 1: const FixedColumnWidth(
                          PermissionsMatrix.permissionColumnWidth,
                        ),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildHeaderRow(isDark),
                      ...widget.modules.asMap().entries.map((entry) {
                        return _buildModuleRow(entry.value, entry.key, isDark);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Строка заголовка матрицы (модуль + иконки прав).
  TableRow _buildHeaderRow(bool isDark) {
    return TableRow(
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromRGBO(59, 130, 246, 0.1)
            : const Color.fromRGBO(59, 130, 246, 0.05),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color.fromRGBO(59, 130, 246, 0.3)
                : const Color.fromRGBO(59, 130, 246, 0.2),
            width: 1,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            'Модуль',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? Colors.blue[300] : Colors.blue[700],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...permissionsList.map(
          (perm) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Center(
              child: Tooltip(
                message: perm.name,
                child: Icon(
                  perm.icon,
                  size: 20,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Строка модуля с ячейками прав.
  TableRow _buildModuleRow(domain.Module module, int index, bool isDark) {
    final permissions = widget.rolePermissions[module.code] ?? {};
    final tempPerms = widget.tempPermissions[module.code] ?? {};

    return TableRow(
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Colors.transparent
            : (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.withValues(alpha: 0.02)),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                module.icon,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  module.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        ...permissionsList.map((perm) {
          final isDisabled =
              PermissionsMatrix._disabledPermissions[module.code]?.contains(
                perm.id,
              ) ??
              false;

          if (isDisabled) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ),
              ),
            );
          }

          final isChecked = tempPerms.containsKey(perm.id)
              ? tempPerms[perm.id]!
              : (permissions[perm.id] ?? false);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Center(
              child: widget.role.isSystem
                  ? Icon(
                      isChecked
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.xmark_circle,
                      color: tempPerms.containsKey(perm.id)
                          ? (isChecked
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed)
                          : (isChecked
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemGrey),
                      size: 22,
                    )
                  : IconButton(
                      icon: Icon(
                        isChecked
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.xmark_circle,
                        color: tempPerms.containsKey(perm.id)
                            ? (isChecked
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemRed)
                            : (isChecked
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemGrey),
                        size: 22,
                      ),
                      onPressed: () => widget.onPermissionToggle(
                        module.code,
                        perm.id,
                        isChecked,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }
}
