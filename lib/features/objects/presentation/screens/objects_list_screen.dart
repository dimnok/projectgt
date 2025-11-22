import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/presentation/state/object_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'object_form_screen.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Отображает сообщение об успешной операции через SnackBar.
///
/// [context] — контекст виджета для отображения.
/// [message] — текст сообщения.
void showSuccessMessage(BuildContext context, String message) {
  SnackBarUtils.showSuccess(context, message);
}

/// Отображает информационное сообщение через SnackBar.
///
/// [context] — контекст виджета для отображения.
/// [message] — текст сообщения.
void showInfoMessage(BuildContext context, String message) {
  SnackBarUtils.showInfo(context, message);
}

/// Отображает сообщение об ошибке через SnackBar.
///
/// [context] — контекст виджета для отображения.
/// [message] — текст сообщения.
void showErrorMessage(BuildContext context, String message) {
  SnackBarUtils.showError(context, message);
}

/// Экран для отображения списка объектов.
///
/// Позволяет просматривать и выбирать объекты.
/// Поддерживает адаптивную верстку (desktop/mobile), создание, редактирование и удаление объектов.
/// Использует [objectProvider] для управления состоянием.
///
/// Пример использования:
/// ```dart
/// const ObjectsListScreen();
/// ```
class ObjectsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка объектов.
  const ObjectsListScreen({super.key});

  @override
  ConsumerState<ObjectsListScreen> createState() => _ObjectsListScreenState();
}

/// Состояние для [ObjectsListScreen].
///
/// Управляет выбором, обновлением и отображением объектов.
class _ObjectsListScreenState extends ConsumerState<ObjectsListScreen> {
  /// Контроллер для прокрутки списка.
  final _scrollController = ScrollController();

  /// Текущий выбранный объект (desktop режим).
  ObjectEntity? selectedObject;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Обновляет список объектов (pull-to-refresh).
  Future<void> _handleRefresh() async {
    await ref.read(objectProvider.notifier).loadObjects();
  }

  /// Открывает модальное окно создания/редактирования объекта.
  void _openObjectForm({ObjectEntity? object}) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isDesktopWidth = mediaQuery.size.width >= 900;
    final maxHeight =
        mediaQuery.size.height - mediaQuery.padding.top - kToolbarHeight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: maxHeight),
      builder: (modalContext) {
        Widget modalContent = Container(
          margin: isDesktopWidth ? const EdgeInsets.only(top: 48) : null,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (sheetContext, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: ObjectFormModal(
                  object: object,
                  onSuccess: (isNew) {
                    if (isNew) {
                      showSuccessMessage(context, 'Объект успешно создан');
                    } else {
                      showInfoMessage(context, 'Изменения успешно сохранены');
                    }
                  },
                ),
              ),
            ),
          ),
        );

        if (isDesktopWidth) {
          final width = MediaQuery.of(modalContext).size.width;
          return Center(
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 220),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width * 0.5),
                    child: modalContent,
                  ),
                ),
              ),
            ),
          );
        }

        return modalContent;
      },
    );
  }

  Widget _buildObjectCard({
    required BuildContext context,
    required ObjectEntity object,
    required VoidCallback onTap,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? Colors.green
        : theme.colorScheme.outline.withValues(alpha: 0.1);
    final borderWidth = isSelected ? 2.0 : 1.0;

    return Card(
      margin: margin,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                object.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                object.address,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(objectProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final objects = state.objects;
    final isLoading = state.status == ObjectStatus.loading;
    final isError = state.status == ObjectStatus.error;
    final sortedObjects = List<ObjectEntity>.from(objects)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: 'Объекты',
        actions: [
          if (isDesktop && selectedObject != null) ...[
            PermissionGuard(
              module: 'objects',
              permission: 'update',
              child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              tooltip: 'Редактировать',
              onPressed: () => _openObjectForm(object: selectedObject),
            ),
            ),
            PermissionGuard(
              module: 'objects',
              permission: 'delete',
              child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: () async {
                if (selectedObject == null) return;
                final ctx = context;
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Удалить объект?'),
                    content: const Text(
                        'Вы уверены, что хотите удалить этот объект?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx2).pop(true),
                        child: const Text('Удалить',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (!ctx.mounted) return;
                if (confirmed == true) {
                  try {
                    await ref
                        .read(objectProvider.notifier)
                        .deleteObject(selectedObject!.id);
                    if (!ctx.mounted) return;
                    setState(() {
                      selectedObject = null;
                    });
                    showErrorMessage(ctx, 'Объект удалён');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    showErrorMessage(ctx, 'Ошибка удаления: ${e.toString()}');
                  }
                }
              },
              ),
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.objects),
      floatingActionButton: PermissionGuard(
        module: 'objects',
        permission: 'create',
        child: FloatingActionButton(
        onPressed: () => _openObjectForm(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return Row(
              children: [
                // Список объектов (мастер)
                SizedBox(
                  width: 570,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Всего объектов: ${sortedObjects.length}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : isError
                                  ? Center(
                                      child:
                                          Text(state.errorMessage ?? 'Ошибка'))
                                  : sortedObjects.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Список объектов пуст',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount: sortedObjects.length,
                                          itemBuilder: (context, index) {
                                            final object = sortedObjects[index];
                                            final isSelected =
                                                selectedObject?.id == object.id;
                                            return _buildObjectCard(
                                              context: context,
                                              object: object,
                                              isSelected: isSelected,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  selectedObject = object;
                                                });
                                              },
                                            );
                                          },
                                        ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Детали объекта (детейл)
                Expanded(
                  child: selectedObject == null
                      ? Center(
                          child: Text(
                            'Выберите объект из списка',
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : _ObjectDetailsPanel(object: selectedObject!),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Всего объектов: ${sortedObjects.length}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : isError
                            ? Center(
                                child: Text(state.errorMessage ?? 'Ошибка'))
                            : sortedObjects.isEmpty
                                ? Center(
                                    child: Text(
                                      'Список объектов пуст',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: sortedObjects.length,
                                    itemBuilder: (context, index) {
                                      final object = sortedObjects[index];
                                      return _buildObjectCard(
                                        context: context,
                                        object: object,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ObjectDetailsScreen(
                                                      object: object),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

/// Панель деталей объекта для desktop-режима.
///
/// Отображает подробную информацию о выбранном объекте с табами.
class _ObjectDetailsPanel extends StatefulWidget {
  /// Объект для отображения.
  final ObjectEntity object;

  /// Создает панель деталей для [object].
  const _ObjectDetailsPanel({required this.object});

  @override
  State<_ObjectDetailsPanel> createState() => _ObjectDetailsPanelState();
}

class _ObjectDetailsPanelState extends State<_ObjectDetailsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    return Column(
      children: [
        // Шапка с иконкой и названием
        ObjectDetailsHeader(object: object),
        Expanded(
          child: ObjectDetailsTabSection(
            controller: _tabController,
            object: object,
          ),
        ),
      ],
    );
  }
}

/// Строит строку информации для карточки объекта.
///
/// [label] — название поля, [value] — значение.
Widget buildInfoItem(BuildContext context, String label, String value) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

/// Экран деталей объекта для мобильного режима.
///
/// Используется для отображения информации об объекте на мобильных устройствах.
class ObjectDetailsScreen extends ConsumerStatefulWidget {
  /// Объект для отображения.
  final ObjectEntity object;

  /// Создает экран деталей для [object].
  const ObjectDetailsScreen({required this.object, super.key});

  @override
  ConsumerState<ObjectDetailsScreen> createState() =>
      _ObjectDetailsScreenState();
}

class _ObjectDetailsScreenState extends ConsumerState<ObjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final object = widget.object;
    return Scaffold(
      appBar: AppBar(
        title: Text(object.name),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          PermissionGuard(
            module: 'objects',
            permission: 'update',
            child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.amber),
            tooltip: 'Редактировать',
            onPressed: () {
              final theme = Theme.of(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      kToolbarHeight,
                ),
                builder: (context) => Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: DraggableScrollableSheet(
                    initialChildSize: 1.0,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
                    expand: false,
                    builder: (context, scrollController) =>
                        SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ObjectFormModal(
                            object: object,
                            onSuccess: (isNew) {
                              if (isNew) {
                                showSuccessMessage(
                                    context, 'Объект успешно создан');
                              } else {
                                showInfoMessage(
                                    context, 'Изменения успешно сохранены');
                              }
                            }),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ),
          PermissionGuard(
            module: 'objects',
            permission: 'delete',
            child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Удалить',
            onPressed: () async {
              final ctx = context;
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Удалить объект?'),
                    content: const Text(
                        'Вы уверены, что хотите удалить этот объект?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx2).pop(false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx2).pop(true),
                      child: const Text('Удалить',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (!ctx.mounted) return;
              if (confirmed == true) {
                try {
                  await ref
                      .read(objectProvider.notifier)
                      .deleteObject(widget.object.id);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  showErrorMessage(ctx, 'Объект удалён');
                } catch (e) {
                  if (!ctx.mounted) return;
                  showErrorMessage(ctx, 'Ошибка удаления: ${e.toString()}');
                }
              }
            },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ObjectDetailsHeader(object: object),
          Expanded(
            child: ObjectDetailsTabSection(
              controller: _tabController,
              object: object,
            ),
          ),
        ],
      ),
    );
  }
}

/// Заголовок с ключевой информацией об объекте.
class ObjectDetailsHeader extends StatelessWidget {
  /// Объект для отображения.
  final ObjectEntity object;

  /// Создаёт заголовок с названием, адресом и иконкой объекта.
  const ObjectDetailsHeader({required this.object, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Icon(
              Icons.location_city_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  object.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 20,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        object.address,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Табы с подробной информацией об объекте.
class ObjectDetailsTabSection extends StatelessWidget {
  /// Контроллер табов для синхронизации с `TabBarView`.
  final TabController controller;

  /// Данные выбранного объекта.
  final ObjectEntity object;

  /// Создаёт секцию табов с основными данными и описанием.
  const ObjectDetailsTabSection({
    required this.controller,
    required this.object,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TabBar(
          controller: controller,
          tabs: const [
            Tab(text: 'Основное'),
            Tab(text: 'Описание'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Основная информация',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          buildInfoItem(context, 'Наименование', object.name),
                          buildInfoItem(context, 'Адрес', object.address),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Описание',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (object.description != null &&
                              object.description!.isNotEmpty)
                            Text(
                              object.description!,
                              style: theme.textTheme.bodyLarge,
                            )
                          else
                            Text(
                              'Нет описания',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Модальное окно для создания/редактирования объекта.
///
/// Использует [ObjectFormContent] для отображения формы.
class ObjectFormModal extends ConsumerStatefulWidget {
  /// Объект для редактирования. Если null — создается новый объект.
  final ObjectEntity? object;

  /// Колбэк, вызывается после успешного сохранения объекта.
  ///
  /// [isNew] — true, если создан новый объект, false — если редактирование.
  final Function(bool) onSuccess;

  /// Создает модальное окно для [object].
  const ObjectFormModal({super.key, this.object, required this.onSuccess});

  @override
  ConsumerState<ObjectFormModal> createState() => _ObjectFormModalState();
}

class _ObjectFormModalState extends ConsumerState<ObjectFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.object?.name ?? '');
    _addressController =
        TextEditingController(text: widget.object?.address ?? '');
    _descriptionController =
        TextEditingController(text: widget.object?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Обрабатывает нажатие на кнопку "Сохранить".
  ///
  /// Валидирует форму, формирует [ObjectEntity] и вызывает add/update через провайдер.
  /// После успешного сохранения закрывает модальное окно.
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(objectProvider.notifier);
    final isNew = widget.object == null;
    final object = ObjectEntity(
      id: widget.object?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    final navigator = Navigator.of(context);
    if (isNew) {
      await notifier.addObject(object);
    } else {
      await notifier.updateObject(object);
    }
    setState(() => _isLoading = false);
    if (mounted) navigator.pop();
    widget.onSuccess(isNew);
  }

  @override
  Widget build(BuildContext context) {
    return ObjectFormContent(
      isNew: widget.object == null,
      isLoading: _isLoading,
      nameController: _nameController,
      addressController: _addressController,
      descriptionController: _descriptionController,
      formKey: _formKey,
      onSave: _handleSave,
      onCancel: () => Navigator.pop(context),
    );
  }
}
