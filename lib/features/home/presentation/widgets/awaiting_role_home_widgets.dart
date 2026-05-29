import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Горизонтальный таймлайн: вход → ожидание роли → рабочий доступ.
class AwaitingRoleProgressTimeline extends StatelessWidget {
  /// Создаёт таймлайн шагов онбординга доступа.
  const AwaitingRoleProgressTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _StepNode(
            index: 1,
            label: 'Вход',
            state: _StepState.done,
            primary: primary,
            onSurface: onSurface,
          ),
          _StepConnector(active: true, onSurface: onSurface),
          _StepNode(
            index: 2,
            label: 'Роль',
            state: _StepState.active,
            primary: primary,
            onSurface: onSurface,
          ),
          _StepConnector(active: false, onSurface: onSurface),
          _StepNode(
            index: 3,
            label: 'Доступ',
            state: _StepState.pending,
            primary: primary,
            onSurface: onSurface,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}

enum _StepState { done, active, pending }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.state,
    required this.primary,
    required this.onSurface,
  });

  final int index;
  final String label;
  final _StepState state;
  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = state == _StepState.active;
    final isDone = state == _StepState.done;

    final circleColor = isDone
        ? primary
        : isActive
            ? primary.withValues(alpha: 0.15)
            : onSurface.withValues(alpha: 0.06);

    final icon = isDone
        ? Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.onPrimary)
        : isActive
            ? SizedBox(
                width: 16,
                height: 16,
                child: CupertinoActivityIndicator(
                  radius: 7,
                  color: primary,
                ),
              )
            : Text(
                '$index',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onSurface.withValues(alpha: 0.45),
                ),
              );

    Widget circle = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: primary.withValues(alpha: 0.55), width: 1.5)
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: icon,
    );

    if (isActive) {
      circle = circle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.04, 1.04),
            duration: 1400.ms,
            curve: Curves.easeInOut,
          );
    }

    return Expanded(
      child: Column(
        children: [
          circle,
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive
                  ? primary
                  : onSurface.withValues(alpha: isDone ? 0.72 : 0.42),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({
    required this.active,
    required this.onSurface,
  });

  final bool active;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: SizedBox(
        width: 28,
        child: Divider(
          height: 2,
          thickness: 2,
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : onSurface.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

/// Карточка статуса с бейджем компании.
class AwaitingRoleStatusCard extends StatelessWidget {
  /// Создаёт карточку статуса.
  const AwaitingRoleStatusCard({
    super.key,
    required this.message,
    this.companyName,
  });

  /// Основной текст для пользователя.
  final String message;

  /// Название компании (если известно).
  final String? companyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.88),
            theme.colorScheme.surface.withValues(alpha: 0.62),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.hourglass,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ждём назначения роли',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.building_2_fill,
                size: 22,
                color: onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
          if (companyName != null && companyName!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              companyName!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurface.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
        ],
      ),
    )
        .animate(delay: 80.ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.08, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}

/// Пошаговая инструкция (заголовок блока + пункты).
class AwaitingRoleInstructionGroup {
  /// Создаёт группу шагов.
  const AwaitingRoleInstructionGroup({
    required this.title,
    required this.icon,
    required this.steps,
    required this.accent,
  });

  /// Заголовок блока.
  final String title;

  /// Иконка блока.
  final IconData icon;

  /// Список шагов.
  final List<String> steps;

  /// Акцентный цвет блока.
  final Color accent;
}

/// Блоки инструкций для сотрудника и администратора.
class AwaitingRoleGuidanceSection extends StatelessWidget {
  /// Создаёт секцию с инструкциями.
  ///
  /// При [isWide] карточки шагов выстраиваются в две колонки (десктоп).
  const AwaitingRoleGuidanceSection({super.key, this.isWide = false});

  /// Горизонтальная раскладка для широких экранов.
  final bool isWide;

  static const _forUser = AwaitingRoleInstructionGroup(
    title: 'Что можно сделать сейчас',
    icon: CupertinoIcons.person_crop_circle,
    accent: Color(0xFF059669),
    steps: [
      'Проверьте профиль: ФИО и телефон должны быть заполнены верно.',
      'Сообщите администратору, что вы вошли в систему и ждёте роль.',
      'Нажимайте «Проверить, назначена ли роль» — экран обновится автоматически.',
      'Пока ждёте — изучите возможности приложения в карточках ниже.',
    ],
  );

  static const _forAdmin = AwaitingRoleInstructionGroup(
    title: 'Что делает администратор',
    icon: CupertinoIcons.shield_lefthalf_fill,
    accent: Color(0xFF2563EB),
    steps: [
      'Открывает раздел «Пользователи» в меню приложения.',
      'Находит ваш профиль в списке сотрудников компании.',
      'Назначает роль (например: монтажник, прораб, бухгалтер) — от неё зависят доступные разделы.',
      'При необходимости привязывает вас к сотруднику в справочнике.',
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Как получить доступ',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Роль определяет, какие разделы и данные вам будут доступны. '
          'Без роли открыт только этот экран и профиль.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        if (isWide)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _InstructionCard(group: _forUser)),
              SizedBox(width: 16),
              Expanded(child: _InstructionCard(group: _forAdmin)),
            ],
          )
        else ...[
          const _InstructionCard(group: _forUser),
          const SizedBox(height: 12),
          const _InstructionCard(group: _forAdmin),
        ],
      ],
    )
        .animate(delay: 120.ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.06, end: 0);
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.group});

  final AwaitingRoleInstructionGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = group.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.08),
            theme.colorScheme.surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(group.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < group.steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _InstructionStepRow(
              number: i + 1,
              text: group.steps[i],
              accent: accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructionStepRow extends StatelessWidget {
  const _InstructionStepRow({
    required this.number,
    required this.text,
    required this.accent,
  });

  final int number;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ),
      ],
    );
  }
}

/// Современная презентационная карточка «О приложении».
///
/// Содержит брендовый заголовок, краткое позиционирование продукта,
/// ключевые ценности с иконками и список ролей, для которых создано
/// приложение.
class AwaitingRoleAboutAppCard extends StatelessWidget {
  /// Создаёт карточку «О приложении».
  const AwaitingRoleAboutAppCard({super.key});

  static const _values = [
    (
      CupertinoIcons.device_phone_portrait,
      'Везде под рукой',
      'Телефон и компьютер — одни данные для всей команды в реальном времени.',
      Color(0xFF0D9488),
    ),
    (
      CupertinoIcons.lock_shield_fill,
      'Доступ по роли',
      'Каждый видит только то, что разрешено его должностью. Безопасно и прозрачно.',
      Color(0xFF7C3AED),
    ),
    (
      CupertinoIcons.chart_bar_alt_fill,
      'План и факт',
      'Руководитель видит сводку по деньгам и срокам, сотрудник — свои смены.',
      Color(0xFF2563EB),
    ),
    (
      CupertinoIcons.square_stack_3d_up_fill,
      'Всё в одном',
      'Смены, договоры, сметы, команда и аналитика без разрозненных таблиц.',
      Color(0xFFEA580C),
    ),
  ];

  static const _audience = [
    (CupertinoIcons.briefcase_fill, 'Руководитель', Color(0xFF2563EB)),
    (CupertinoIcons.person_2_fill, 'Прораб', Color(0xFF0D9488)),
    (CupertinoIcons.money_rubl_circle_fill, 'Бухгалтер', Color(0xFF059669)),
    (CupertinoIcons.hammer_fill, 'Монтажник', Color(0xFFEA580C)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.1),
            theme.colorScheme.surface.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Единая цифровая среда для строительной компании. Заменяет '
                  'десятки таблиц и переписок: смены на объектах, договоры, '
                  'сметы и ВОР, команда и аналитика — в одном приложении, '
                  'с понятными правами доступа для каждого сотрудника.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: onSurface.withValues(alpha: 0.74),
                  ),
                ),
                const SizedBox(height: 18),
                _buildValuesGrid(theme),
                const SizedBox(height: 20),
                Text(
                  'Создано для всей команды',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in _audience)
                      _AudienceChip(icon: a.$1, label: a.$2, accent: a.$3),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 480.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildHeader(ThemeData theme, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.22),
            primary.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Icon(CupertinoIcons.cube_box_fill, color: primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Стройка PRO',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Управление стройкой от объекта до отчёта',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesGrid(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 460;
        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < _values.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _ValueRow(
                  icon: _values[i].$1,
                  title: _values[i].$2,
                  text: _values[i].$3,
                  accent: _values[i].$4,
                ),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < _values.length; i += 2) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 14));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ValueRow(
                    icon: _values[i].$1,
                    title: _values[i].$2,
                    text: _values[i].$3,
                    accent: _values[i].$4,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < _values.length
                      ? _ValueRow(
                          icon: _values[i + 1].$1,
                          title: _values[i + 1].$2,
                          text: _values[i + 1].$3,
                          accent: _values[i + 1].$4,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: onSurface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

/// Элемент карусели возможностей приложения.
class AwaitingRoleFeatureItem {
  /// Создаёт описание слайда.
  const AwaitingRoleFeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.highlights = const [],
  });

  /// Иконка слайда.
  final IconData icon;

  /// Заголовок.
  final String title;

  /// Подзаголовок.
  final String subtitle;

  /// Акцентный цвет слайда.
  final Color accent;

  /// Дополнительные пункты на слайде.
  final List<String> highlights;
}

/// Карусель с акцентными карточками модулей.
class AwaitingRoleFeatureCarousel extends StatelessWidget {
  /// Создаёт карусель.
  const AwaitingRoleFeatureCarousel({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.items,
    this.isDesktop = false,
  });

  /// Контроллер страниц карусели.
  final PageController controller;

  /// Индекс активного слайда.
  final int currentIndex;

  /// Колбэк смены слайда.
  final ValueChanged<int> onPageChanged;

  /// Слайды карусели.
  final List<AwaitingRoleFeatureItem> items;

  /// Увеличенная высота карточек на десктопе.
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carouselHeight = isDesktop ? 280.0 : 248.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: controller,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  var scale = 1.0;
                  var offsetY = 0.0;
                  if (controller.position.haveDimensions) {
                    final page =
                        controller.page ?? controller.initialPage.toDouble();
                    final delta = (page - index).abs();
                    scale = (1 - (delta * 0.06)).clamp(0.9, 1.0);
                    offsetY = delta * 10;
                  }
                  return Transform.translate(
                    offset: Offset(0, offsetY),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: _FeatureSlideCard(
                  item: item,
                  index: index + 1,
                  total: items.length,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 22 : 6,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    )
        .animate(delay: 160.ms)
        .fadeIn(duration: 480.ms)
        .slideY(begin: 0.1, end: 0, duration: 480.ms);
  }
}

class _FeatureSlideCard extends StatelessWidget {
  const _FeatureSlideCard({
    required this.item,
    required this.index,
    required this.total,
  });

  final AwaitingRoleFeatureItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.accent.withValues(alpha: 0.14),
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: item.accent.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: item.accent.withValues(alpha: 0.12),
            blurRadius: 20,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.accent, size: 26),
              ),
              const Spacer(),
              Text(
                '$index / $total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item.highlights.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final line in item.highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: item.accent.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.3,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Горизонтальные чипы модулей «скоро откроются».
class AwaitingRoleModuleChips extends StatelessWidget {
  /// Создаёт список модулей.
  ///
  /// При [isWide] — сетка из двух колонок.
  const AwaitingRoleModuleChips({super.key, this.isWide = false});

  /// Двухколоночная сетка на десктопе.
  final bool isWide;

  static const _modules = [
    ('Смены', 'Учёт бригад и выработки'),
    ('Договоры', 'Объекты и сроки'),
    ('Сметы', 'Плановые объёмы'),
    ('ВОР', 'Ведомости работ'),
    ('Команда', 'Роли и доступ'),
    ('Аналитика', 'План / факт'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Разделы после назначения роли',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Набор модулей зависит от выбранной роли — не всем нужны все разделы.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        if (isWide)
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _modules.map((m) {
                  final tileWidth = (constraints.maxWidth - 12) / 2;
                  return SizedBox(
                    width: tileWidth,
                    child: _ModuleTile(label: m.$1, hint: m.$2),
                  );
                }).toList(),
              );
            },
          )
        else
          ..._modules.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ModuleTile(label: m.$1, hint: m.$2),
            ),
          ),
      ],
    )
        .animate(delay: 240.ms)
        .fadeIn(duration: 420.ms)
        .slideX(begin: 0.04, end: 0);
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.lock_fill,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
