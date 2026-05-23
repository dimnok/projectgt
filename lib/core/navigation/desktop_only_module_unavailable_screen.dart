import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/navigation/app_module_availability.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Экран-заглушка для desktop-only модулей на неподдерживаемых устройствах.
class DesktopOnlyModuleUnavailableScreen extends StatelessWidget {
  /// Создаёт заглушку.
  const DesktopOnlyModuleUnavailableScreen({
    super.key,
    required this.moduleId,
  });

  /// RBAC-идентификатор модуля ([AppModuleAvailability.desktopOnlyModuleIds]).
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = AppModuleAvailability.moduleTitle(moduleId);
    final minWidth = ResponsiveUtils.desktopBreakpoint.round();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'На главную',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.desktop_windows_outlined,
                  size: 72,
                  color: theme.colorScheme.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 24),
                Text(
                  '«$title» доступен на компьютере',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Откройте раздел в браузере на компьютере или увеличьте ширину окна '
                  'до $minWidth px и более (например, планшет в альбомной ориентации).',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('На главную'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
