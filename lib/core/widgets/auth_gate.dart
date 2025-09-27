import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/home/presentation/screens/home_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/login_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/access_disabled_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/profile_completion_screen.dart';

/// Простой gate без редиректов: возвращает нужный экран по статусу
class AuthGate extends ConsumerWidget {
  /// Конструктор виджета `AuthGate`.
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(currentUserProfileProvider);

    switch (authState.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        // Проверяем, заполнен ли профиль текущего пользователя
        final profile = profileState.profile;
        if (profile != null &&
            (profile.fullName == null ||
                profile.fullName!.isEmpty ||
                profile.phone == null ||
                profile.phone!.isEmpty)) {
          return const ProfileCompletionScreen();
        }
        return const HomeScreen();
      case AuthStatus.pendingApproval:
        // Проверяем, заполнен ли профиль при ожидании одобрения
        final profile = profileState.profile;
        if (profile != null &&
            (profile.fullName == null ||
                profile.fullName!.isEmpty ||
                profile.phone == null ||
                profile.phone!.isEmpty)) {
          return const ProfileCompletionScreen();
        }
        return const PendingApprovalScreen();
      case AuthStatus.disabled:
        return const AccessDisabledScreen();
      // Telegram статусы удалены; показываем экран логина
      case AuthStatus.error:
        return const LoginScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
