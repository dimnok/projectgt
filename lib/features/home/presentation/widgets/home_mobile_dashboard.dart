import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/home/presentation/widgets/contract_progress_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/ai_contract_plan_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/home_mobile_kpi_section.dart';
import 'package:projectgt/features/home/presentation/widgets/home_mobile_quick_actions.dart';
import 'package:projectgt/features/home/presentation/widgets/home_my_open_shift_entry.dart';
import 'package:projectgt/features/home/presentation/widgets/home_shifts_summary_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/shifts_calendar_widgets.dart';
import 'package:projectgt/features/home/presentation/widgets/work_plan_summary_widget.dart';

/// Мобильный дашборд, объединяющий KPI, быстрые действия и основные карточки.
class HomeMobileDashboard extends StatelessWidget {
  /// Создаёт мобильный дашборд.
  const HomeMobileDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = MobileAtmosphereAppearance.of(context);
    final style = MobileAtmosphereCardStyle.fromAppearance(appearance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const HomeMobileKpiSection(),
        const SizedBox(height: 24),
        const HomeMyOpenShiftEntry(),
        const HomeMobileQuickActions(),
        const SizedBox(height: 32),
        _buildSectionHeader(theme, 'Рабочие процессы'),
        const SizedBox(height: 16),
        _MobileMainCard(
          style: style,
          title: 'Календарь смен',
          icon: CupertinoIcons.calendar,
          accentColor: const Color(0xFF3B82F6),
          child: const ShiftsCalendarFlipCard(hideHeader: true),
        ),
        const SizedBox(height: 16),
        _MobileMainCard(
          style: style,
          title: 'Сводка смен',
          icon: CupertinoIcons.briefcase_fill,
          accentColor: theme.colorScheme.primary,
          child: const HomeShiftsSummaryWidget(hideHeader: true),
        ),
        const SizedBox(height: 16),
        _MobileMainCard(
          style: style,
          title: 'Прогресс договора',
          icon: CupertinoIcons.chart_pie_fill,
          accentColor: const Color(0xFF10B981),
          child: const ContractProgressWidget(),
        ),
        const SizedBox(height: 16),
        _MobileMainCard(
          style: style,
          title: 'ИИ План по договору',
          icon: CupertinoIcons.sparkles,
          accentColor: const Color(0xFF8B5CF6),
          child: const AiContractPlanWidget(),
        ),
        const SizedBox(height: 16),
        _MobileMainCard(
          style: style,
          title: 'План работ',
          icon: CupertinoIcons.doc_text_fill,
          accentColor: const Color(0xFFF97316),
          child: const WorkPlanSummaryWidget(hideHeader: true),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _MobileMainCard extends StatelessWidget {
  final MobileAtmosphereCardStyle style;
  final Widget child;
  final String title;
  final IconData icon;
  final Color accentColor;

  const _MobileMainCard({
    required this.style,
    required this.child,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.cardTop, style.cardBottom],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.cardBorder),
        boxShadow: style.cardShadows,
      ),
      child: Stack(
        children: [
          // Фоновый акцентный градиент (очень слабый)
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.08),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
