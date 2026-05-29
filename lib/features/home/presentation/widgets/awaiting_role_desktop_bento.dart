import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/home/presentation/widgets/awaiting_role_home_widgets.dart';

/// Десктопная bento-раскладка экрана ожидания роли.
class AwaitingRoleDesktopLayout extends StatelessWidget {
  /// Создаёт десктопную раскладку.
  const AwaitingRoleDesktopLayout({
    super.key,
    required this.companyName,
    required this.statusMessage,
    required this.features,
    required this.isChecking,
    required this.onCheckRole,
    required this.onContactAdmin,
  });

  /// Название компании пользователя.
  final String? companyName;

  /// Текст статуса на карточке ожидания.
  final String statusMessage;

  /// Модули для bento-сетки.
  final List<AwaitingRoleFeatureItem> features;

  /// Идёт проверка назначения роли.
  final bool isChecking;

  /// Проверить, назначена ли роль.
  final VoidCallback onCheckRole;

  /// Связаться с администратором.
  final VoidCallback onContactAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AwaitingRoleProgressTimeline(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AwaitingRoleStatusCard(
                    companyName: companyName,
                    message: statusMessage,
                  ),
                  const SizedBox(height: 14),
                  const AwaitingRoleKpiStrip(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: AwaitingRoleActionPanel(
                isChecking: isChecking,
                onCheckRole: onCheckRole,
                onContactAdmin: onContactAdmin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const AwaitingRoleAboutAppCard(),
        const SizedBox(height: 28),
        const _SectionHeader(
          title: 'Возможности «Стройка PRO»',
          subtitle:
              'Модули откроются после назначения роли — наведите на карточку для деталей.',
        ),
        const SizedBox(height: 16),
        AwaitingRoleFeatureBentoGrid(items: features),
        const SizedBox(height: 28),
        const AwaitingRoleGuidanceSection(isWide: true),
        const SizedBox(height: 24),
        const AwaitingRoleFaqSection(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Полоска KPI: шаг до доступа, модули, RBAC.
class AwaitingRoleKpiStrip extends StatelessWidget {
  /// Создаёт полоску KPI.
  const AwaitingRoleKpiStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const tiles = [
      _KpiTile(
        icon: CupertinoIcons.flag_fill,
        value: '1',
        label: 'шаг до полного доступа',
        accent: Color(0xFF2563EB),
      ),
      _KpiTile(
        icon: CupertinoIcons.square_grid_2x2_fill,
        value: '5+',
        label: 'модулей платформы',
        accent: Color(0xFF0D9488),
      ),
      _KpiTile(
        icon: CupertinoIcons.lock_shield_fill,
        value: 'RBAC',
        label: 'доступ только по роли',
        accent: Color(0xFF7C3AED),
      ),
    ];

    final stackVertically = MediaQuery.sizeOf(context).width < 520;

    final content = stackVertically
        ? Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                tiles[i],
              ],
            ],
          )
        : Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: tiles[i]),
              ],
            ],
          );

    return content
        .animate(delay: 100.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _KpiTile extends StatefulWidget {
  const _KpiTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  State<_KpiTile> createState() => _KpiTileState();
}

class _KpiTileState extends State<_KpiTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? widget.accent.withValues(alpha: 0.35)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Панель быстрых действий: проверка роли и контакт с админом.
class AwaitingRoleActionPanel extends StatelessWidget {
  /// Создаёт панель действий.
  const AwaitingRoleActionPanel({
    super.key,
    required this.isChecking,
    required this.onCheckRole,
    required this.onContactAdmin,
  });

  /// Идёт проверка назначения роли.
  final bool isChecking;

  /// Проверить, назначена ли роль.
  final VoidCallback onCheckRole;

  /// Связаться с администратором.
  final VoidCallback onContactAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.14),
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.bolt_fill, color: primary, size: 28),
          const SizedBox(height: 14),
          Text(
            'Готовы начать?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'После назначения роли нажмите проверку — главная обновится автоматически.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          GTPrimaryButton(
            text: 'Проверить роль',
            isLoading: isChecking,
            onPressed: onCheckRole,
          ),
          const SizedBox(height: 10),
          GTTextButton(
            text: 'Написать администратору',
            icon: Icons.support_agent_outlined,
            onPressed: onContactAdmin,
          ),
        ],
      ),
    )
        .animate(delay: 140.ms)
        .fadeIn(duration: 450.ms)
        .slideX(begin: 0.04, end: 0);
  }
}

/// Bento-сетка модулей (десктоп): hero 2×2 + компактные плитки.
class AwaitingRoleFeatureBentoGrid extends StatelessWidget {
  /// Создаёт bento-сетку модулей.
  const AwaitingRoleFeatureBentoGrid({super.key, required this.items});

  /// Модули для отображения в bento-сетке.
  final List<AwaitingRoleFeatureItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final hero = items.first;
    final rest = items.length > 1 ? items.sublist(1) : <AwaitingRoleFeatureItem>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final cellWidth = (constraints.maxWidth - gap) / 2;

        return Column(
          children: [
            SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: _BentoFeatureCell(
                      item: hero,
                      isHero: true,
                      animationIndex: 0,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        if (rest.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _BentoFeatureCell(
                                    item: rest[0],
                                    animationIndex: 1,
                                  ),
                                ),
                                if (rest.length > 1) ...[
                                  const SizedBox(width: gap),
                                  Expanded(
                                    child: _BentoFeatureCell(
                                      item: rest[1],
                                      animationIndex: 2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (rest.length > 2) ...[
                          const SizedBox(height: gap),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _BentoFeatureCell(
                                    item: rest.length > 2 ? rest[2] : rest[0],
                                    animationIndex: 3,
                                  ),
                                ),
                                if (rest.length > 3) ...[
                                  const SizedBox(width: gap),
                                  Expanded(
                                    child: _BentoFeatureCell(
                                      item: rest[3],
                                      animationIndex: 4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (rest.length > 4) ...[
              const SizedBox(height: gap),
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    for (var i = 4; i < items.length; i++) ...[
                      if (i > 4) const SizedBox(width: gap),
                      Expanded(
                        child: _BentoFeatureCell(
                          item: items[i],
                          compact: true,
                          animationIndex: i,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    )
        .animate(delay: 180.ms)
        .fadeIn(duration: 500.ms);
  }
}

class _BentoFeatureCell extends StatefulWidget {
  const _BentoFeatureCell({
    required this.item,
    this.isHero = false,
    this.compact = false,
    this.animationIndex = 0,
  });

  final AwaitingRoleFeatureItem item;
  final bool isHero;
  final bool compact;
  final int animationIndex;

  @override
  State<_BentoFeatureCell> createState() => _BentoFeatureCellState();
}

class _BentoFeatureCellState extends State<_BentoFeatureCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final isHero = widget.isHero;
    final compact = widget.compact;
    final index = widget.animationIndex;

    final cell = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -4.0 : 0, 0),
        padding: EdgeInsets.all(isHero ? 24 : compact ? 14 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isHero ? 24 : 18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.accent.withValues(alpha: _hover ? 0.2 : 0.12),
              theme.colorScheme.surface.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: item.accent.withValues(alpha: _hover ? 0.45 : 0.22),
            width: _hover ? 1.5 : 1,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: item.accent.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isHero ? 56 : 40,
                  height: isHero ? 56 : 40,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(isHero ? 16 : 12),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.accent,
                    size: isHero ? 28 : 22,
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
            SizedBox(height: isHero ? 16 : 10),
            Text(
              item.title,
              style: (isHero
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.subtitle,
              maxLines: isHero ? 3 : compact ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
            if (isHero && item.highlights.isNotEmpty) ...[
              const Spacer(),
              const SizedBox(height: 12),
              for (final h in item.highlights.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: item.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    return cell
        .animate(delay: (200 + index * 60).ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}

/// Аккордеон с частыми вопросами об ожидании роли.
class AwaitingRoleFaqSection extends StatefulWidget {
  /// Создаёт блок FAQ.
  const AwaitingRoleFaqSection({super.key});

  @override
  State<AwaitingRoleFaqSection> createState() => _AwaitingRoleFaqSectionState();
}

class _AwaitingRoleFaqSectionState extends State<AwaitingRoleFaqSection> {
  int? _expandedIndex;

  static const _items = [
    (
      'Сколько ждать назначения роли?',
      'Обычно это занимает от нескольких минут до одного рабочего дня. '
          'Напомните администратору в мессенджере — часто роль назначают сразу.',
    ),
    (
      'Почему я вижу «Без роли»?',
      'Вы успешно вошли в компанию по коду, но администратор ещё не выбрал '
          'вашу должность в системе. Это промежуточный этап, не ошибка.',
    ),
    (
      'Что откроется после назначения?',
      'Только те разделы, которые разрешены вашей ролью: смены, сметы, '
          'договоры и т.д. Лишние данные других отделов вы не увидите.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Частые вопросы',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_items.length, (i) {
          final expanded = _expandedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() {
                  _expandedIndex = expanded ? null : i;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _items[i].$1,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _items[i].$2,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.68),
                              height: 1.45,
                            ),
                          ),
                        ),
                        crossFadeState: expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    )
        .animate(delay: 260.ms)
        .fadeIn(duration: 420.ms);
  }
}
