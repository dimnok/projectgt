import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/presentation/widgets/create_role_dialog.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart' as domain;
import 'package:projectgt/features/roles/domain/entities/module.dart' as domain;
import 'package:projectgt/features/roles/presentation/models/permission_ui_model.dart';
import 'package:projectgt/features/roles/presentation/widgets/role_list_item.dart';
import 'package:projectgt/features/roles/presentation/widgets/permissions_matrix.dart';
import 'package:projectgt/features/roles/presentation/widgets/unsaved_changes_panel.dart';

/// Экран управления ролями пользователей.
///
/// Позволяет просматривать список ролей, создавать новые роли
/// и настраивать матрицу прав доступа для каждой роли.
class RolesListScreen extends ConsumerStatefulWidget {
  /// Начальная выбранная роль
  final String? initialRoleId;

  /// Конструктор экрана управления ролями.
  const RolesListScreen({
    super.key,
    this.initialRoleId,
  });

  @override
  ConsumerState<RolesListScreen> createState() => _RolesListScreenState();
}

class _RolesListScreenState extends ConsumerState<RolesListScreen>
    with TickerProviderStateMixin {
  // Временное хранилище изменений
  final Map<String, Map<String, Map<String, bool>>> _tempPermissions = {};
  // Выбранная роль
  String? _selectedRoleId;
  // Флаг наличия изменений
  bool _hasChanges = false;

  // Анимация для панели изменений
  late AnimationController _panelAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    // Устанавливаем начальную роль, если она передана
    _selectedRoleId = widget.initialRoleId;

    // Инициализация анимаций
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _widthAnimation = Tween<double>(
      begin: 0.0,
      end: 300.0,
    ).animate(CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_selectedRoleId == null) return;

    // Применяем изменения
    final permissionsToUpdate = _tempPermissions[_selectedRoleId!] ?? {};

    try {
      await ref
          .read(rolePermissionsControllerProvider)
          .updatePermissions(_selectedRoleId!, permissionsToUpdate);

      setState(() {
        _tempPermissions.clear();
        _hasChanges = false;
        _panelAnimationController.reverse();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Изменения сохранены',
              style: TextStyle(color: CupertinoColors.white),
            ),
            backgroundColor: CupertinoColors.systemGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при сохранении: $e',
              style: const TextStyle(color: CupertinoColors.white),
            ),
            backgroundColor: CupertinoColors.systemRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rolesState = ref.watch(rolesNotifierProvider);
    final modulesState = ref.watch(modulesProvider);

    return Scaffold(
      drawer: const AppDrawer(activeRoute: AppRoute.roles),
      appBar: AppBarWidget(
        title: 'Управление ролями',
        showThemeSwitch: true,
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
      ),
      body: rolesState.when(
        data: (roles) {
          return modulesState.when(
            data: (modules) {
              // Сортировка: системные сверху (по алфавиту), затем пользовательские (по алфавиту)
              final sortedRoles = List<domain.Role>.from(roles)
                ..sort((a, b) {
                  // Сначала проверяем системная или нет
                  if (a.isSystem != b.isSystem) {
                    return a.isSystem ? -1 : 1;
                  }
                  // Затем сортируем по имени
                  return a.name.compareTo(b.name);
                });

              // Если роль не выбрана и есть роли, выбираем первую из отсортированных
              if (_selectedRoleId == null && sortedRoles.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedRoleId = sortedRoles.first.id;
                    });
                  }
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.hammer_fill,
                            size: 64,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Мобильная версия в разработке',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Пожалуйста, используйте десктопную версию\nдля управления ролями',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildDesktopLayout(
                      theme, isDark, sortedRoles, modules);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Ошибка загрузки модулей: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    ThemeData theme,
    bool isDark,
    List<domain.Role> roles,
    List<domain.Module> modules,
  ) {
    final selectedRole = _selectedRoleId != null
        ? roles.firstWhere(
            (r) => r.id == _selectedRoleId,
            orElse: () => roles.first,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(
                  38, 40, 42, 1) // Тёмно-серый с минимальной голубизной
              : const Color.fromRGBO(
                  248, 249, 250, 1), // Очень светло-серый с лёгким оттенком
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Левая панель - список ролей в карточке
              Container(
                width: 350,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Список ролей
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          top: 56, // Отступ сверху для кнопки
                        ),
                        itemCount: roles.length,
                        itemBuilder: (context, index) {
                          final role = roles[index];
                          final isSelected = _selectedRoleId == role.id;
                          return RoleListItem(
                            role: role,
                            isSelected: isSelected,
                            theme: theme,
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                // Сбрасываем несохраненные изменения при переключении роли
                                if (_hasChanges) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          const Text('Несохраненные изменения'),
                                      content: const Text(
                                          'У вас есть несохраненные изменения. Сохранить их перед переключением?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              _tempPermissions.clear();
                                              _hasChanges = false;
                                              _panelAnimationController
                                                  .reverse();
                                              _selectedRoleId = role.id;
                                            });
                                          },
                                          child:
                                              const Text('Отменить изменения'),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _saveChanges();
                                            setState(() {
                                              _selectedRoleId = role.id;
                                            });
                                          },
                                          child: const Text('Сохранить'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  _selectedRoleId = role.id;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    // Кнопка добавления в углу
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () async {
                          final result = await showCreateRoleDialog(context);
                          if (result != null && mounted) {
                            try {
                              await ref
                                  .read(rolesNotifierProvider.notifier)
                                  .createRole(
                                    name: result['name']!,
                                    description: result['description']!,
                                  );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Роль "${result['name']}" создана'),
                                    backgroundColor:
                                        CupertinoColors.systemGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: CupertinoColors.systemRed,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(CupertinoIcons.plus, size: 24),
                        tooltip: 'Создать роль',
                      ),
                    ),
                  ],
                ),
              ),
              // Правая панель - матрица прав
              Expanded(
                child: Stack(
                  children: [
                    _selectedRoleId != null && selectedRole != null
                        ? _buildRighPanel(theme, isDark, selectedRole, modules)
                        : Center(
                            child: Text(
                              'Выберите роль',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                    // Кнопка сохранения
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      top: _hasChanges ? 16 : -60,
                      right: 16,
                      child: IgnorePointer(
                        ignoring: !_hasChanges,
                        child: AnimatedOpacity(
                          opacity: _hasChanges ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: GestureDetector(
                            onTap: _saveChanges,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGreen
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.checkmark,
                                  color: CupertinoColors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRighPanel(
    ThemeData theme,
    bool isDark,
    domain.Role selectedRole,
    List<domain.Module> modules,
  ) {
    final permissionsAsync =
        ref.watch(rolePermissionsProvider(selectedRole.id));

    return Column(
      children: [
        // Название роли и описание
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRole.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedRole.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Матрица прав и панель изменений
        Expanded(
          child: permissionsAsync.when(
            data: (rolePermissions) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Матрица прав
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: PermissionsMatrix(
                        role: selectedRole,
                        modules: modules,
                        rolePermissions: rolePermissions,
                        tempPermissions:
                            _tempPermissions[selectedRole.id] ?? {},
                        theme: theme,
                        isDark: isDark,
                        onPermissionToggle: (moduleId, permId, isChecked) {
                          setState(() {
                            _tempPermissions[selectedRole.id] ??= {};
                            _tempPermissions[selectedRole.id]![moduleId] ??= {};

                            final newValue = !isChecked;

                            // Логика обновления разрешения с учетом оригинального значения
                            void updatePermission(String pId, bool value) {
                              final originalVal =
                                  rolePermissions[moduleId]?[pId] ?? false;

                              if (value == originalVal) {
                                // Если новое значение совпадает с оригинальным, удаляем из temp
                                _tempPermissions[selectedRole.id]![moduleId]!
                                    .remove(pId);
                              } else {
                                // Иначе записываем в temp
                                _tempPermissions[selectedRole.id]![moduleId]![
                                    pId] = value;
                              }
                            }

                            // 1. Обновляем текущее разрешение
                            updatePermission(permId, newValue);

                            // 2. Если включаем любое разрешение кроме "Просмотр",
                            // автоматически включаем "Просмотр" (id: 'read')
                            if (newValue && permId != 'read') {
                              updatePermission('read', true);
                            }

                            // 3. Если выключаем "Просмотр", автоматически выключаем все остальные разрешения
                            if (!newValue && permId == 'read') {
                              for (final p in permissionsList) {
                                if (p.id != 'read') {
                                  updatePermission(p.id, false);
                                }
                              }
                            }

                            // Очищаем пустые контейнеры
                            if (_tempPermissions[selectedRole.id]![moduleId]
                                    ?.isEmpty ??
                                false) {
                              _tempPermissions[selectedRole.id]!
                                  .remove(moduleId);
                            }
                            if (_tempPermissions[selectedRole.id]?.isEmpty ??
                                false) {
                              _tempPermissions.remove(selectedRole.id);
                            }

                            _hasChanges = _tempPermissions.isNotEmpty;
                            if (_hasChanges) {
                              _panelAnimationController.forward();
                            } else {
                              _panelAnimationController.reverse();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  // Панель изменений
                  AnimatedBuilder(
                    animation: _panelAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: _widthAnimation.value,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: OverflowBox(
                          minWidth: 300,
                          maxWidth: 300,
                          alignment: Alignment.centerRight,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SizedBox(
                                width: 300,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: UnsavedChangesPanel(
                                    role: selectedRole,
                                    modules: modules,
                                    theme: theme,
                                    isDark: isDark,
                                    rolePermissions: rolePermissions,
                                    tempPermissions:
                                        _tempPermissions[selectedRole.id] ?? {},
                                    onRevertAll: () {
                                      setState(() {
                                        _tempPermissions.clear();
                                        _hasChanges = false;
                                        _panelAnimationController.reverse();
                                      });
                                    },
                                    onRevertChange: (moduleId, permId) {
                                      setState(() {
                                        // Отменяем конкретное изменение
                                        if (_tempPermissions[selectedRole.id]
                                                ?[moduleId] !=
                                            null) {
                                          _tempPermissions[selectedRole.id]![
                                                  moduleId]!
                                              .remove(permId);
                                          if (_tempPermissions[
                                                  selectedRole.id]![moduleId]!
                                              .isEmpty) {
                                            _tempPermissions[selectedRole.id]!
                                                .remove(moduleId);
                                          }
                                          if (_tempPermissions[selectedRole.id]!
                                              .isEmpty) {
                                            _tempPermissions
                                                .remove(selectedRole.id);
                                          }
                                        }
                                        _hasChanges =
                                            _tempPermissions.isNotEmpty;
                                        if (!_hasChanges) {
                                          _panelAnimationController.reverse();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Ошибка: $error')),
          ),
        ),
      ],
    );
  }
}
