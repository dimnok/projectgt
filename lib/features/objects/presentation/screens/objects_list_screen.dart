import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_form_modal.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_actions.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'desktop/objects_list_desktop_view.dart';
import 'mobile/objects_list_mobile_view.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_details_view.dart';

/// Экран для отображения списка объектов.
/// Поддерживает адаптивную верстку (desktop/mobile).
class ObjectsListScreen extends ConsumerStatefulWidget {
  /// Создаёт экземпляр экрана списка объектов.
  const ObjectsListScreen({super.key});

  @override
  ConsumerState<ObjectsListScreen> createState() => _ObjectsListScreenState();
}

class _ObjectsListScreenState extends ConsumerState<ObjectsListScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(objectProvider.notifier).loadObjects();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(objectProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final sortedObjects = List<ObjectEntity>.from(state.objects)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Объекты'),
      drawer: const AppDrawer(activeRoute: AppRoute.objects),
      floatingActionButton: isDesktop
          ? null
          : PermissionGuard(
              module: 'objects',
              permission: 'create',
              child: FloatingActionButton(
                onPressed: () => ObjectFormModal.show(
                  context,
                  onSuccess: (isNew) => SnackBarUtils.showSuccess(
                    context,
                    isNew ? 'Объект успешно создан' : 'Изменения сохранены',
                  ),
                ),
                backgroundColor: theme.colorScheme.primary,
                child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
              ),
            ),
      body: isDesktop
          ? ObjectsListDesktopView(
              objects: sortedObjects,
              isLoading: state.status == ObjectStatus.loading,
            )
          : ObjectsListMobileView(
              state: state,
              objects: sortedObjects,
              onRefresh: _handleRefresh,
              onTap: (obj) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => _ObjectDetailsScreen(object: obj),
                ),
              ),
              scrollController: _scrollController,
            ),
    );
  }
}

class _ObjectDetailsScreen extends ConsumerWidget {
  final ObjectEntity object;
  const _ObjectDetailsScreen({required this.object});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: object.name,
        leading: const BackButton(),
        actions: [
          ObjectAppBarActions(
            object: object,
            onDeleteSuccess: () => Navigator.of(context).pop(),
          ),
        ],
        showThemeSwitch: false,
      ),
      body: ObjectDetailsView(object: object),
    );
  }
}
