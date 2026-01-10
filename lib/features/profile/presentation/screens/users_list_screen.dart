import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/profile/presentation/screens/users_list_desktop_screen.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/profile/presentation/screens/users_list_mobile_screen.dart';

/// Экран управления списком пользователей.
///
/// Функции:
/// - Просмотр всех зарегистрированных пользователей
/// - Редактирование профиля
/// - Блокировка/разблокировка пользователей
/// - Привязка пользователя к сотруднику
class UsersListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран управления списком пользователей.
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  List<ObjectEntity> _allObjects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).getProfiles();
      _loadObjects();
    });
  }

  Future<void> _loadObjects() async {
    final objects = await ref.read(objectRepositoryProvider).getObjects();
    if (!mounted) return;
    setState(() {
      _allObjects = objects;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      drawer: const AppDrawer(activeRoute: AppRoute.users),
      appBar: const AppBarWidget(
        title: 'Пользователи',
      ),
      body: isDesktop
          ? UsersListDesktopScreen(
              profiles: profileState.profiles,
              allObjects: _allObjects,
              isLoading: profileState.status == ProfileStatus.loading,
            )
          : UsersListMobileScreen(
              profiles: profileState.profiles,
              allObjects: _allObjects,
              isLoading: profileState.status == ProfileStatus.loading,
              isError: profileState.status == ProfileStatus.error,
              errorMessage: profileState.errorMessage,
            ),
    );
  }
}
