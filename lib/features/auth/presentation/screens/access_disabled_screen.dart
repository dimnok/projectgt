import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Экран блокировки доступа пользователя.
///
/// Показывает информацию о временно отключённом доступе и предоставляет
/// действие для повторной проверки статуса профиля.
class AccessDisabledScreen extends ConsumerStatefulWidget {
  /// Создаёт экран блокировки доступа.
  const AccessDisabledScreen({super.key});

  @override
  ConsumerState<AccessDisabledScreen> createState() =>
      _AccessDisabledScreenState();
}

class _AccessDisabledScreenState extends ConsumerState<AccessDisabledScreen> {
  bool _isChecking = false;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId == null) return;
      await ref
          .read(currentUserProfileProvider.notifier)
          .refreshCurrentUserProfile(userId);
      await ref.read(authProvider.notifier).checkAuthStatus(force: true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentProfileState = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Доступ временно отключён',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Обратитесь к администратору, чтобы восстановить доступ.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _FeatureSlider(
                  controller: _pageController,
                  currentIndex: _currentPage,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    onPressed: _isChecking ? null : _checkAccess,
                    child: _isChecking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CupertinoActivityIndicator(),
                          )
                        : const Text('Проверить доступ'),
                  ),
                ),
                if (currentProfileState.status == ProfileStatus.error &&
                    currentProfileState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    currentProfileState.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureSlider extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _FeatureSlider({
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _featureItems(theme);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (controller.position.haveDimensions) {
                    final page =
                        controller.page ?? controller.initialPage.toDouble();
                    scale = (1 - ((page - index).abs() * 0.08)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _FeatureCard(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 16 : 6,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        )
      ],
    );
  }

  List<_FeatureItem> _featureItems(ThemeData theme) => const [
        _FeatureItem(
          icon: Icons.description_outlined,
          title: 'Договоры',
          subtitle: 'Создавайте и управляйте договорами в один клик',
        ),
        _FeatureItem(
          icon: Icons.people_alt_outlined,
          title: 'Сотрудники',
          subtitle: 'Управляйте доступом и профилями команды',
        ),
        _FeatureItem(
          icon: Icons.attach_money_outlined,
          title: 'Сметы',
          subtitle: 'Быстрый экспорт в Excel и сверка затрат',
        ),
        _FeatureItem(
          icon: Icons.notifications_outlined,
          title: 'Уведомления',
          subtitle: 'Будьте в курсе важных событий и изменений',
        ),
      ];
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureItem(
      {required this.icon, required this.title, required this.subtitle});
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
