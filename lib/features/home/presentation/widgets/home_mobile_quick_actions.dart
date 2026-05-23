import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/navigation/app_module_availability.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Панель быстрых действий для мобильного экрана.
class HomeMobileQuickActions extends ConsumerWidget {
  /// Создаёт мобильную панель быстрых действий.
  const HomeMobileQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionServiceProvider);

    final actions = <_QuickActionSpec>[
      const _QuickActionSpec(
        module: 'contracts',
        routeName: 'contracts',
        label: 'Договоры',
        icon: CupertinoIcons.doc_text,
      ),
      const _QuickActionSpec(
        module: 'estimates',
        routeName: 'estimates',
        label: 'Сметы',
        icon: CupertinoIcons.list_number,
      ),
      const _QuickActionSpec(
        module: 'works',
        routeName: 'work_plans',
        label: 'Планы',
        icon: CupertinoIcons.calendar,
      ),
      const _QuickActionSpec(
        module: 'timesheet',
        routeName: 'timesheet',
        label: 'Табель',
        icon: CupertinoIcons.clock,
      ),
      const _QuickActionSpec(
        module: 'employees',
        routeName: 'employees',
        label: 'Команда',
        icon: CupertinoIcons.person_3,
      ),
      const _QuickActionSpec(
        module: 'cash_flow',
        routeName: 'cash_flow',
        label: 'Финансы',
        icon: CupertinoIcons.money_rubl_circle,
      ),
      const _QuickActionSpec(
        module: 'subcontractors',
        routeName: 'subcontractors',
        label: 'Подрядчики',
        icon: Icons.engineering_outlined,
      ),
    ];

    final visible = actions
        .where(
          (a) =>
              permissions.can(a.module, 'read') &&
              AppModuleAvailability.canOpenModule(a.module, context),
        )
        .toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Быстрый доступ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final action = visible[index];
              final color = _getModuleColor(action.module);
              
              return GestureDetector(
                onTap: () => context.goNamed(action.routeName),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        action.icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getModuleColor(String module) {
    switch (module) {
      case 'contracts': return const Color(0xFF3B82F6);
      case 'estimates': return const Color(0xFFF97316);
      case 'works': return const Color(0xFF0D9488);
      case 'timesheet': return const Color(0xFF10B981);
      case 'employees': return const Color(0xFF8B5CF6);
      case 'cash_flow': return const Color(0xFFF59E0B);
      case 'subcontractors': return const Color(0xFF14B8A6);
      default: return Colors.blueGrey;
    }
  }
}

class _QuickActionSpec {
  final String module;
  final String routeName;
  final String label;
  final IconData icon;

  const _QuickActionSpec({
    required this.module,
    required this.routeName,
    required this.label,
    required this.icon,
  });
}
