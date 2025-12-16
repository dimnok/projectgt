import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart'
    as role_entity;
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_edit_field.dart';

/// Форма редактирования профиля пользователя.
///
/// Позволяет изменить ФИО, телефон и список объектов пользователя.
class ProfileEditForm extends ConsumerStatefulWidget {
  /// Профиль для редактирования.
  final Profile profile;

  /// Список всех объектов для выбора.
  final List<ObjectEntity> allObjects;

  /// Признак, что текущий пользователь — администратор.
  final bool isAdmin;

  /// Изначально привязанный employee_id (если есть).
  final String? initialEmployeeId;

  /// Изначально привязанная роль (если есть).
  final String? initialRoleId;

  /// Коллбэк сохранения изменений: (ФИО, телефон, список id объектов, employeeId, roleId).
  final void Function(
      String fullName,
      String phone,
      List<String> selectedObjectIds,
      String? employeeId,
      String? roleId) onSave;

  /// Коллбэк при успешном сохранении (опционально, для закрытия модалки и т.п. если логика внутри)
  /// В текущей реализации логика сохранения передается в onSave, но иногда полезно иметь onSuccess
  final VoidCallback? onSuccess;

  /// Коллбэк отмены (опционально). Если передан, вызывается вместо Navigator.pop.
  final VoidCallback? onCancel;

  /// Отображать ли кнопки управления (Сохранить/Отмена).
  /// Если false, управление должно осуществляться извне через submit().
  final bool showButtons;

  /// Создаёт форму редактирования профиля.
  const ProfileEditForm({
    required this.profile,
    this.allObjects = const [], // Делаем опциональным с дефолтным значением
    this.isAdmin = false, // Дефолт false
    this.initialEmployeeId,
    this.initialRoleId,
    this.onSave =
        _defaultOnSave, // Дефолтная заглушка, если не передано (для обратной совместимости)
    this.onSuccess,
    this.onCancel,
    this.showButtons = true,
    super.key,
  });

  // Статическая заглушка
  static void _defaultOnSave(
      String f, String p, List<String> o, String? e, String? r) {}

  @override
  ConsumerState<ProfileEditForm> createState() => ProfileEditFormState();
}

/// Состояние для [ProfileEditForm].
///
/// Управляет контроллерами, обработкой выбора объектов и валидацией формы.
class ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late List<String> _selectedObjectIds;
  final _formKey = GlobalKey<FormState>();
  late String _selectedEmployeeId;
  String? _selectedRoleId;
  List<role_entity.Role> _roles = [];

  /// Капитализирует каждое слово в строке (делает первую букву заглавной).
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Обрабатывает изменение текста в поле ФИО.
  void _onFullNameChanged(String value) {
    final capitalized = _capitalizeWords(value);
    if (capitalized != value) {
      _fullNameController.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
  }

  /// Отправляет форму на валидацию и сохранение.
  ///
  /// Должна вызываться извне, если [widget.showButtons] == false.
  void submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        _selectedObjectIds,
        _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
        _selectedRoleId,
      );
      widget.onSuccess?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.profile.fullName ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _selectedObjectIds = List<String>.from(widget.profile.objectIds ?? []);
    _selectedEmployeeId = (widget.initialEmployeeId ?? '').trim();
    _selectedRoleId = widget.initialRoleId;

    if (widget.isAdmin) {
      _loadRoles();
    }
  }

  Future<void> _loadRoles() async {
    try {
      final repo = ref.read(rolesRepositoryProvider);
      final roles = await repo.getAllRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    role_entity.Role? selectedRole;
    if (_selectedRoleId != null && _roles.isNotEmpty) {
      try {
        selectedRole = _roles.firstWhere((r) => r.id == _selectedRoleId);
      } catch (_) {
        // Role ID exists but not found in loaded list (or list not loaded yet)
      }
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'ФИО',
              prefixIcon: Icon(CupertinoIcons.person),
            ),
            onChanged: _onFullNameChanged,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите ФИО';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Телефон',
              prefixIcon: Icon(CupertinoIcons.phone),
              hintText: '+7-(XXX)-XXX-XXXX',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          if (widget.isAdmin) ...[
            ProfileEmployeeLinkEditField(
              initialEmployeeId:
                  _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
              onChanged: (id) {
                setState(() {
                  _selectedEmployeeId = (id ?? '').trim();
                });
              },
            ),
            const SizedBox(height: 16),
            GTDropdown<role_entity.Role>(
              items: _roles,
              itemDisplayBuilder: (role) => role.name,
              selectedItem: selectedRole,
              onSelectionChanged: (role) {
                setState(() {
                  _selectedRoleId = role?.id;
                });
              },
              labelText: 'Роль',
              hintText: 'Без роли (User)',
              allowClear: true,
              // Можно добавить isLoading, если мы хотим показывать лоадер пока роли грузятся
              // isLoading: _roles.isEmpty, // но лучше отдельный стейт
            ),
            const SizedBox(height: 16),
          ],
          if (widget.isAdmin && widget.allObjects.isNotEmpty) ...[
            Text('Объекты', style: theme.textTheme.bodyLarge),
            SizedBox(
              height: 180,
              child: ListView(
                children: widget.allObjects.map((obj) {
                  return CheckboxListTile(
                    title: Text(obj.name),
                    value: _selectedObjectIds.contains(obj.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedObjectIds.add(obj.id);
                        } else {
                          _selectedObjectIds.remove(obj.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 24),
          ],
          if (widget.showButtons) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GTSecondaryButton(
                    text: 'Отмена',
                    onPressed: () {
                      if (widget.onCancel != null) {
                        widget.onCancel!();
                      } else if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GTPrimaryButton(
                    text: 'Сохранить',
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSave(
                          _fullNameController.text.trim(),
                          _phoneController.text.trim(),
                          _selectedObjectIds,
                          _selectedEmployeeId.isEmpty
                              ? null
                              : _selectedEmployeeId,
                          _selectedRoleId,
                        );
                        widget.onSuccess?.call();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
