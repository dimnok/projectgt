import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Экран ожидания одобрения доступа администратором.
///
/// Показывает пользователю статус «заявка отправлена» и позволяет
/// повторно проверить доступ.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  /// Создаёт экран ожидания одобрения доступа.
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isChecking = false;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
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
      // Обновляем профиль и состояние авторизации
      await ref
          .read(currentUserProfileProvider.notifier)
          .refreshCurrentUserProfile(userId);
      if (!mounted) return;
      // После обновления профиля перезапрашиваем auth-статус принудительно
      await ref.read(authProvider.notifier).checkAuthStatus(force: true);
      if (!mounted) return;
      final updated = ref.read(currentUserProfileProvider).profile;
      if (updated?.status == true && mounted) {
        context.goNamed('home');
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentProfileState = ref.watch(currentUserProfileProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFDCF8C6),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: isDesktop ? 24 : 4,
              right: isDesktop ? 24 : 4,
              top: 24,
              bottom: isDesktop ? 24 : 10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: isDesktop ? 720 : 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CupertinoActivityIndicator(radius: 32),
                          const SizedBox(height: 16),
                          Text(
                            'Заявка на доступ отправлена',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ожидайте подтверждения администратора. Вы получите доступ сразу после одобрения.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Мы уже создали вашу учётную запись. Обычно проверка занимает немного времени. \nВы можете закрыть приложение — статус можно обновить в любой момент.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (currentProfileState.status ==
                                  ProfileStatus.error &&
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
                Padding(
                  padding: EdgeInsets.only(
                    left: isDesktop ? 24 : 4,
                    right: isDesktop ? 24 : 4,
                    bottom: isDesktop ? 16 : 10,
                  ),
                  child: _FeatureSlider(
                    controller: _pageController,
                    currentIndex: _currentPage,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    isDesktop: isDesktop,
                    isChecking: _isChecking,
                    onCtaPressed: _isChecking ? null : _checkAccess,
                  ),
                ),
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
  final bool isDesktop;
  final bool isChecking;
  final VoidCallback? onCtaPressed;

  const _FeatureSlider({
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isDesktop,
    required this.isChecking,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _featureItems(theme);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: isDesktop ? 380 : 360,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -100) {
                final ni = (currentIndex + 1).clamp(0, items.length - 1);
                if (ni != currentIndex) onPageChanged(ni);
              } else if (velocity > 100) {
                final ni = (currentIndex - 1).clamp(0, items.length - 1);
                if (ni != currentIndex) onPageChanged(ni);
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _FeatureCard(
                key: ValueKey<int>(currentIndex),
                icon: items[currentIndex].icon,
                title: items[currentIndex].title,
                subtitle: items[currentIndex].subtitle,
                accentColor: items[currentIndex].accentColor,
                isDesktop: isDesktop,
                totalCount: items.length,
                currentIndex: currentIndex,
                isChecking: isChecking,
                onCtaPressed: onCtaPressed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 0),
      ],
    );
  }

  List<_FeatureItem> _featureItems(ThemeData theme) => const [
        _FeatureItem(
          icon: Icons.work_outline,
          title: 'Работы',
          subtitle:
              'Планируйте работы по объектам, назначайте ответственных, отслеживайте статусы и сроки. Ведите фактические трудозатраты и материалы.',
          accentColor: Colors.orange,
        ),
        _FeatureItem(
          icon: Icons.people_alt_outlined,
          title: 'Сотрудники',
          subtitle:
              'Профили и роли, доступы к модулям, контакты, карточка сотрудника, архив и поиск. Быстрое подключение/отключение доступа.',
          accentColor: Colors.teal,
        ),
        _FeatureItem(
          icon: Icons.schedule_outlined,
          title: 'Табель',
          subtitle:
              'Учёт времени и смен, переработки и выходные, подтверждения руководителя. Готовые отчёты по людям и объектам.',
          accentColor: Colors.indigo,
        ),
        _FeatureItem(
          icon: Icons.attach_money_outlined,
          title: 'Сметы',
          subtitle:
              'Создание смет по шаблонам, статьи затрат, позиции и объёмы, сравнение план/факт. Экспорт в Excel.',
          accentColor: Colors.amber,
        ),
        _FeatureItem(
          icon: Icons.file_download_outlined,
          title: 'Выгрузка',
          subtitle:
              'Экспорт данных в CSV/Excel/PDF, сохранённые пресеты, фильтры и предпросмотр. Лёгкая передача отчётов заказчику.',
          accentColor: Colors.green,
        ),
      ];
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDesktop;
  final int totalCount;
  final int currentIndex;
  final bool isChecking;
  final VoidCallback? onCtaPressed;

  const _FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDesktop,
    required this.totalCount,
    required this.currentIndex,
    required this.isChecking,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isDesktop ? 80 : 68,
                height: isDesktop ? 80 : 68,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: (isDesktop
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: (isDesktop
                    ? theme.textTheme.bodyLarge
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCount, (i) {
              final active = i == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: active ? 18 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                side: const BorderSide(color: Colors.transparent),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: onCtaPressed,
              child: isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(),
                    )
                  : const SizedBox(
                      height: 20,
                      child: Center(child: Text('Проверить доступ')),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
