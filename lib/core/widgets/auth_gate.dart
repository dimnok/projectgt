import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/home/domain/awaiting_role_assignment.dart';
import 'package:projectgt/features/home/presentation/screens/awaiting_role_home_screen.dart';
import 'package:projectgt/features/home/presentation/screens/home_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/login_screen.dart';
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

    final Widget child = switch (authState.status) {
      AuthStatus.loading || AuthStatus.initial => const Scaffold(
        key: ValueKey('loading'),
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.disabled => const AccessDisabledScreen(
        key: ValueKey('disabled'),
      ),
      AuthStatus.error || AuthStatus.unauthenticated => const LoginScreen(
        key: ValueKey('login'),
      ),
      AuthStatus.authenticated || AuthStatus.onboarding => _buildSignedIn(
        authState: authState,
        profileState: profileState,
        ref: ref,
      ),
    };

    return AnimatedSwitcher(
      duration: 400.ms,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        final isProfileComplete =
            child.key == const ValueKey('profile_complete');

        if (isProfileComplete) {
          return FadeTransition(opacity: animation, child: child);
        }

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSignedIn({
    required AuthState authState,
    required ProfileState profileState,
    required WidgetRef ref,
  }) {
    final profile = profileState.profile;

    if (profileState.status == ProfileStatus.error || profile == null) {
      return Scaffold(
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
                    final userId = authState.user?.id;
                    if (userId != null) {
                      ref
                          .read(currentUserProfileProvider.notifier)
                          .getCurrentUserProfile(userId, force: true);
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
    }

    if (profile.fullName == null || profile.fullName!.trim().isEmpty) {
      return const ProfileCompletionScreen(key: ValueKey('profile_complete'));
    }

    if (profile.lastCompanyId == null) {
      return const OnboardingScreen(key: ValueKey('onboarding'));
    }

    final roleId = profile.roleId ?? authState.user?.roleId;
    final systemRole = profile.systemRole ?? authState.user?.systemRole;
    if (isAwaitingRoleAssignment(roleId: roleId, systemRole: systemRole)) {
      return const AwaitingRoleHomeScreen(key: ValueKey('awaiting_role'));
    }

    return const HomeScreen(key: ValueKey('home'));
  }
}
