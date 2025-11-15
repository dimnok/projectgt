import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран отображения пользователей системы.
///
/// Позволяет просматривать и переходить к профилям пользователей. Адаптирован под desktop и mobile.
///
/// Пример использования:
/// ```dart
/// const UsersListScreen();
/// ```
class UsersListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка пользователей.
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

/// Состояние для [UsersListScreen].
///
/// Управляет загрузкой, обновлением и отображением пользователей.
class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _scrollController = ScrollController();

  // Флаг для отслеживания первичной загрузки
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilesIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProfilesIfNeeded() {
    // Загружаем список профилей только один раз при первом открытии экрана
    if (!_initialLoadDone) {
      ref.read(profileProvider.notifier).getProfiles();
      _initialLoadDone = true;
    }
  }

  /// Обновляет список пользователей (Pull-to-Refresh).
  Future<void> _handleRefresh() async {
    await ref.read(profileProvider.notifier).refreshProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);

    final isLoading = authState.status == AuthStatus.loading ||
        profileState.status == ProfileStatus.loading;

    List<Profile> profiles = profileState.profiles;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Пользователи'),
      drawer: const AppDrawer(activeRoute: AppRoute.users),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : profiles.isEmpty
                ? const Center(child: Text('Пользователи не найдены'))
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return _UserListItem(
                        profile: profile,
                        onTap: () {
                          context.pushNamed('user_profile',
                              pathParameters: {'userId': profile.id});
                        },
                        onToggleStatus: (value) async {
                          // Разрешить только админам
                          final currentUser = ref.read(authProvider).user;
                          final currentProfile =
                              ref.read(currentUserProfileProvider).profile;
                          final isAdmin = currentProfile?.role == 'admin' ||
                              currentUser?.role == 'admin';
                          if (!isAdmin) return;

                          // Оптимистичное обновление без перерисовки страницы
                          final notifier = ref.read(profileProvider.notifier);
                          final updated = profile.copyWith(status: value);
                          await notifier.updateProfileSilently(updated);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Profile profile;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleStatus;

  const _UserListItem({
    required this.profile,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? Text(
                        profile.fullName?.isNotEmpty == true
                            ? profile.fullName![0].toUpperCase()
                            : profile.email[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName ?? 'Без имени',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (profile.phone != null && profile.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          profile.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.role == 'admin'
                          ? Colors.purple.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.role == 'admin' ? 'ADMIN' : 'USER',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: profile.role == 'admin'
                            ? Colors.purple
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.status ? 'Активен' : 'Неактивен',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: profile.status ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AdaptiveSwitch(
                        value: profile.status,
                        onChanged: onToggleStatus,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
