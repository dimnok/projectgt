import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/features/home/presentation/widgets/contract_progress_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/home_desktop_kpi_section.dart';
import 'package:projectgt/features/home/presentation/widgets/home_desktop_quick_actions_bar.dart';
import 'package:projectgt/features/home/presentation/widgets/home_shifts_summary_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/shifts_calendar_widgets.dart';
import 'package:projectgt/features/home/presentation/widgets/work_plan_summary_widget.dart';

/// Полноценный десктопный дашборд главной страницы (ширина ≥ [kHomeDesktopDashboardBreakpoint]).
class HomeDesktopDashboard extends StatelessWidget {
  /// Создаёт десктопный дашборд с KPI, быстрыми переходами и основными карточками.
  const HomeDesktopDashboard({super.key});

  static const double _mainCardHeight = 320;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeDesktopKpiSection(),
        const SizedBox(height: 32),
        const HomeDesktopQuickActionsBar(),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _DesktopMainCard(
                theme: theme,
                title: 'Календарь смен',
                icon: CupertinoIcons.calendar,
                accentColor: const Color(0xFF3B82F6),
                child: const SizedBox(
                  height: _mainCardHeight,
                  child: ShiftsCalendarFlipCard(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _DesktopMainCard(
                theme: theme,
                title: 'Сводка смен',
                icon: CupertinoIcons.briefcase_fill,
                accentColor: theme.colorScheme.primary,
                child: const SizedBox(
                  height: _mainCardHeight,
                  child: HomeShiftsSummaryWidget(hideHeader: true),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _DesktopMainCard(
                theme: theme,
                title: 'Прогресс договора',
                icon: CupertinoIcons.chart_pie_fill,
                accentColor: const Color(0xFF10B981),
                child: const SizedBox(
                  height: _mainCardHeight,
                  child: ContractProgressWidget(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _DesktopMainCard(
                theme: theme,
                title: 'План работ',
                icon: CupertinoIcons.doc_text_fill,
                accentColor: const Color(0xFFF97316),
                child: const SizedBox(
                  height: _mainCardHeight,
                  child: WorkPlanSummaryWidget(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopMainCard extends StatefulWidget {
  final ThemeData theme;
  final Widget child;
  final String title;
  final IconData icon;
  final Color accentColor;

  const _DesktopMainCard({
    required this.theme,
    required this.child,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  State<_DesktopMainCard> createState() => _DesktopMainCardState();
}

class _DesktopMainCardState extends State<_DesktopMainCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hover
                ? widget.accentColor.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Фоновый акцентный градиент (очень слабый)
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor.withValues(alpha: 0.05),
                        widget.accentColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
