import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Горизонтальный блок быстрых переходов в ключевые модули (с учётом RBAC).
class HomeDesktopQuickActionsBar extends ConsumerWidget {
  /// Создаёт панель быстрых действий для десктопной главной.
  const HomeDesktopQuickActionsBar({super.key});

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
        routeName: 'works',
        label: 'Работы',
        icon: CupertinoIcons.wrench,
      ),
      const _QuickActionSpec(
        module: 'works',
        routeName: 'work_plans',
        label: 'Планы работ',
        icon: CupertinoIcons.calendar,
      ),
      const _QuickActionSpec(
        module: 'objects',
        routeName: 'objects',
        label: 'Объекты',
        icon: CupertinoIcons.map,
      ),
      const _QuickActionSpec(
        module: 'contractors',
        routeName: 'contractors',
        label: 'Контрагенты',
        icon: CupertinoIcons.person_2,
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
        label: 'Сотрудники',
        icon: CupertinoIcons.person_3,
      ),
      const _QuickActionSpec(
        module: 'cash_flow',
        routeName: 'cash_flow',
        label: 'Cash Flow',
        icon: CupertinoIcons.money_rubl_circle,
      ),
      const _QuickActionSpec(
        module: 'materials',
        routeName: 'material',
        label: 'Материал',
        icon: CupertinoIcons.cube_box,
      ),
      const _QuickActionSpec(
        module: 'payroll',
        routeName: 'payrolls',
        label: 'ФОТ',
        icon: CupertinoIcons.creditcard,
      ),
      const _QuickActionSpec(
        module: 'subcontractors',
        routeName: 'subcontractors',
        label: 'Подрядчики',
        icon: Icons.engineering_outlined,
      ),
      const _QuickActionSpec(
        module: 'export',
        routeName: 'export',
        label: 'Выгрузка',
        icon: CupertinoIcons.tray_arrow_down,
      ),
      const _QuickActionSpec(
        module: 'company',
        routeName: 'company',
        label: 'Компания',
        icon: CupertinoIcons.briefcase,
      ),
    ];

    final visible = actions
        .where((a) => permissions.can(a.module, 'read'))
        .toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрый переход',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisExtent: 100,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final action = visible[index];
            return _QuickActionCard(action: action);
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final _QuickActionSpec action;

  const _QuickActionCard({required this.action});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Генерируем цвет на основе названия модуля для консистентности
    final Color accentColor = _getModuleColor(widget.action.module);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.goNamed(widget.action.routeName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _hover
                ? accentColor.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover
                  ? accentColor.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1.2,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.action.icon,
                size: 28,
                color: _hover ? accentColor : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                widget.action.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: _hover ? FontWeight.w700 : FontWeight.w600,
                  color: _hover ? accentColor : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getModuleColor(String module) {
    switch (module) {
      case 'contracts':
        return const Color(0xFF1E3A8A);
      case 'estimates':
        return const Color(0xFFF97316);
      case 'works':
        return const Color(0xFF0D9488);
      case 'objects':
        return const Color(0xFF8B5CF6);
      case 'contractors':
        return const Color(0xFFEC4899);
      case 'timesheet':
        return const Color(0xFF10B981);
      case 'employees':
        return const Color(0xFF3B82F6);
      case 'cash_flow':
        return const Color(0xFFF59E0B);
      case 'materials':
        return const Color(0xFF6366F1);
      case 'payroll':
        return const Color(0xFFEF4444);
      case 'subcontractors':
        return const Color(0xFF14B8A6);
      case 'export':
        return const Color(0xFF64748B);
      case 'company':
        return const Color(0xFF440154);
      default:
        return Colors.blueGrey;
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
