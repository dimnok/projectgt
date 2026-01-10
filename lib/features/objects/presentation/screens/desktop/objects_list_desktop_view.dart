import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_list_item_desktop.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_details_panel.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_form_modal.dart';

/// Десктопная версия экрана списка объектов.
///
/// Реализует двухпанельный интерфейс: список слева и детализация справа.
class ObjectsListDesktopView extends ConsumerStatefulWidget {
  /// Список объектов для отображения.
  final List<ObjectEntity> objects;

  /// Флаг состояния загрузки данных.
  final bool isLoading;

  /// Создает десктопную версию списка объектов.
  const ObjectsListDesktopView({
    super.key,
    required this.objects,
    required this.isLoading,
  });

  @override
  ConsumerState<ObjectsListDesktopView> createState() =>
      _ObjectsListDesktopViewState();
}

class _ObjectsListDesktopViewState
    extends ConsumerState<ObjectsListDesktopView> {
  final _scrollController = ScrollController();
  String? _selectedObjectId;

  @override
  void initState() {
    super.initState();
    if (widget.objects.isNotEmpty) {
      _selectedObjectId = widget.objects.first.id;
    }
  }

  @override
  void didUpdateWidget(ObjectsListDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedObjectId != null) {
      final containsSelected = widget.objects.any(
        (o) => o.id == _selectedObjectId,
      );
      if (!containsSelected && widget.objects.isNotEmpty) {
        _selectedObjectId = widget.objects.first.id;
      }
    } else if (widget.objects.isNotEmpty) {
      _selectedObjectId = widget.objects.first.id;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showObjectForm([ObjectEntity? object]) {
    ObjectFormModal.show(
      context,
      object: object,
      onSuccess: (isNew) {
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            isNew ? 'Объект успешно создан' : 'Изменения сохранены',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedObject = _selectedObjectId != null
        ? widget.objects.firstWhere(
            (o) => o.id == _selectedObjectId,
            orElse: () => widget.objects.first,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(38, 40, 42, 1)
              : const Color.fromRGBO(248, 249, 250, 1),
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
              // Left Panel
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
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: PermissionGuard(
                        module: 'objects',
                        permission: 'create',
                        child: SizedBox(
                          width: double.infinity,
                          child: GTPrimaryButton(
                            text: 'Добавить объект',
                            icon: CupertinoIcons.plus,
                            onPressed: () => _showObjectForm(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: widget.isLoading && widget.objects.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : widget.objects.isEmpty
                              ? const Center(child: Text('Объекты не найдены'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  controller: _scrollController,
                                  itemCount: widget.objects.length,
                                  itemBuilder: (context, index) {
                                    final object = widget.objects[index];
                                    return ObjectListItemDesktop(
                                      object: object,
                                      isSelected:
                                          _selectedObjectId == object.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedObjectId = object.id;
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              // Right Panel
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: _selectedObjectId != null && selectedObject != null
                      ? ObjectDetailsPanel(
                          object: selectedObject,
                          onEdit: () => _showObjectForm(selectedObject),
                          onDeleteSuccess: () {
                            setState(() {
                              _selectedObjectId = null;
                            });
                          },
                        )
                      : Center(
                          child: Text(
                            'Выберите объект из списка',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

