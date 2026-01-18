import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/home/presentation/screens/home_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/login_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/access_disabled_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/onboarding_screen.dart';

/// Gate с плавными переходами: возвращает нужный экран по статусу.
class AuthGate extends ConsumerWidget {
  /// Создает экземпляр [AuthGate].
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(currentUserProfileProvider);

    Widget child;

    switch (authState.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        child = const Scaffold(
          key: ValueKey('loading'),
          body: Center(child: CircularProgressIndicator()),
        );
        break;

      case AuthStatus.authenticated:
        final profile = profileState.profile;
        if (profileState.status == ProfileStatus.error || profile == null) {
          // Если ошибка загрузки профиля или профиль не найден
          child = Scaffold(
            key: const ValueKey('error_profile'),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      profileState.errorMessage ?? 'Ошибка при загрузке профиля',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (authState.user != null) {
                          ref.read(currentUserProfileProvider.notifier).getCurrentUserProfile(authState.user!.id, force: true);
                        }
                      },
                      child: const Text('Повторить'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      child: const Text('Выйти'),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (profile.fullName == null || profile.fullName!.trim().isEmpty) {
          child = const ProfileCompletionScreen(key: ValueKey('profile_complete'));
        } else if (profile.lastCompanyId == null) {
          child = const OnboardingScreen(key: ValueKey('onboarding'));
        } else {
          child = const HomeScreen(key: ValueKey('home'));
        }
        break;

      case AuthStatus.onboarding:
        final profile = profileState.profile;
        if (profile == null) {
          child = const Scaffold(
            key: ValueKey('loading_onboarding'),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (profile.fullName == null || profile.fullName!.trim().isEmpty) {
          child = const ProfileCompletionScreen(key: ValueKey('profile_complete_onboarding'));
        } else {
          child = const OnboardingScreen(key: ValueKey('onboarding_direct'));
        }
        break;

      case AuthStatus.pendingApproval:
        final profile = profileState.profile;
        if (profile == null) {
          child = const Scaffold(
            key: ValueKey('loading_pending'),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (profile.fullName == null || profile.fullName!.trim().isEmpty) {
          child = const ProfileCompletionScreen(key: ValueKey('profile_complete_pending'));
        } else {
          child = const PendingApprovalScreen(key: ValueKey('pending_approval'));
        }
        break;

      case AuthStatus.disabled:
        child = const AccessDisabledScreen(key: ValueKey('disabled'));
        break;

      case AuthStatus.error:
      case AuthStatus.unauthenticated:
        child = const LoginScreen(key: ValueKey('login'));
        break;
    }

    return AnimatedSwitcher(
      duration: 400.ms,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        final isProfileComplete = child.key == const ValueKey('profile_complete') || 
                                 child.key == const ValueKey('profile_complete_onboarding') ||
                                 child.key == const ValueKey('profile_complete_pending');

        // Для экрана профиля используем только Fade, так как форма внутри сама слайдится
        if (isProfileComplete) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        }

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
