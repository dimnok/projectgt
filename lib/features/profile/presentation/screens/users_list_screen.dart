import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Экран отображения и поиска пользователей системы.
///
/// Позволяет просматривать, фильтровать и переходить к профилям пользователей. Адаптирован под desktop и mobile.
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
/// Управляет поиском, фильтрацией, обновлением и отображением пользователей.
class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  
  // Флаг для отслеживания первичной загрузки
  bool _initialLoadDone = false;
  
  // Флаг видимости поиска на мобильных устройствах
  bool _isSearchVisible = false;
  
  // Флаг для предотвращения одновременного открытия поиска и обновления списка
  bool _preventRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilesIfNeeded();
    });
    
    // Добавляем слушателя скролла для мобильной версии
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Слушатель прокрутки для показа/скрытия поиска
  void _scrollListener() {
    // Если устройство мобильное и прокрутка вверх (отрицательное смещение)
    if (_isMobileDevice() && _scrollController.position.pixels < -50) {
      if (!_isSearchVisible) {
        // Первое потягивание - показываем поиск и предотвращаем обновление
        setState(() {
          _isSearchVisible = true;
          _preventRefresh = true;
        });
        
        // Сбрасываем флаг предотвращения обновления через небольшую задержку
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _preventRefresh = false;
            });
          }
        });
      }
    } 
    // Скрываем при прокрутке вниз после того, как поле уже видимо
    else if (_scrollController.position.pixels > 0 && _isSearchVisible && _isMobileDevice()) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  // Определение мобильного устройства по ширине экрана
  bool _isMobileDevice() {
    final width = MediaQuery.of(context).size.width;
    return width < 600; // Стандартная граница для мобильных устройств
  }

  void _loadProfilesIfNeeded() {
    // Загружаем список профилей только один раз при первом открытии экрана
    if (!_initialLoadDone) {
      ref.read(profileProvider.notifier).getProfiles();
      _initialLoadDone = true;
    }
  }

  void _filterProfiles(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // Функция обновления списка, учитывающая состояние флага _preventRefresh
  Future<void> _handleRefresh() async {
    if (_preventRefresh) {
      // Если это первое открытие поиска, просто возвращаем Future
      return Future.value();
    }
    
    // В противном случае обновляем список
    await ref.read(profileProvider.notifier).refreshProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final isMobile = _isMobileDevice();
    
    // На десктопе всегда показываем поиск
    if (!isMobile && !_isSearchVisible) {
      _isSearchVisible = true;
    }
    
    final isLoading = authState.status == AuthStatus.loading || 
                      profileState.status == ProfileStatus.loading;
    
    List<Profile> filteredProfiles = profileState.profiles;
    
    if (_searchQuery.isNotEmpty) {
      filteredProfiles = profileState.profiles.where((profile) {
        final fullName = profile.fullName?.toLowerCase() ?? '';
        final email = profile.email.toLowerCase();
        final phone = profile.phone?.toLowerCase() ?? '';
        
        return fullName.contains(_searchQuery) || 
               email.contains(_searchQuery) || 
               phone.contains(_searchQuery);
      }).toList();
    }
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Список пользователей'),
      drawer: const AppDrawer(activeRoute: AppRoute.users),
      body: Column(
        children: [
          // Блок поиска, который отображается условно
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchVisible ? 80 : 0,
            child: _isSearchVisible 
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Поиск пользователей',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProfiles('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _filterProfiles,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (isMobile && !_isSearchVisible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  "↓ Потяните вниз для поиска ↓",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          if (isMobile && _isSearchVisible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Center(
                child: Text(
                  "↓ Потяните ещё раз для обновления списка ↓",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProfiles.isEmpty
                      ? const Center(child: Text('Пользователи не найдены'))
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredProfiles.length,
                          itemBuilder: (context, index) {
                            final profile = filteredProfiles[index];
                            return _UserListItem(
                              profile: profile,
                              onTap: () {
                                // Переход на детальный просмотр профиля пользователя
                                context.pushNamed(
                                  'user_profile', 
                                  pathParameters: {'userId': profile.id}
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Profile profile;
  final VoidCallback? onTap;

  const _UserListItem({
    required this.profile,
    this.onTap,
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (profile.phone != null && profile.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          profile.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.role == 'admin'
                          ? Colors.purple.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.role == 'admin' ? 'ADMIN' : 'USER',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: profile.role == 'admin' ? Colors.purple : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.status
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.status ? 'Активен' : 'Неактивен',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: profile.status ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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