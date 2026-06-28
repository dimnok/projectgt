import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Блок «Заявления» на главном экране (заглушка до полной реализации).
///
/// В будущем: скачивание образцов и заполнение заявлений для печати и подписи.
class HomeEmployeeApplicationsWidget extends StatelessWidget {
  /// Если `true`, заголовок карточки не отображается (заголовок снаружи).
  final bool hideHeader;

  /// Создаёт содержимое карточки заявлений.
  const HomeEmployeeApplicationsWidget({
    super.key,
    this.hideHeader = false,
  });

  static const Color _accent = Color(0xFF6366F1);

  static const List<String> _plannedApplicationTypes = [
    'Отпуск',
    'Без содержания',
    'Увольнение',
    'Перевод',
    'Отгул',
    'Больничный',
    'Материальная помощь',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Semantics(
      label: 'Заявления. Раздел в разработке',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hideHeader) ...[
            Row(
              children: [
                Icon(
                  CupertinoIcons.doc_plaintext,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Заявления',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _DevelopmentBadge(theme: theme),
          const SizedBox(height: 16),
          Text(
            'Скоро здесь можно будет скачать образец заявления или '
            'заполнить форму и получить готовый документ для подписи.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _FeatureRow(
            icon: CupertinoIcons.arrow_down_doc,
            text: 'Образцы всех типов заявлений',
            muted: muted,
          ),
          const SizedBox(height: 8),
          _FeatureRow(
            icon: CupertinoIcons.pencil_ellipsis_rectangle,
            text: 'Заполнение и выгрузка готового заявления',
            muted: muted,
          ),
          const SizedBox(height: 20),
          Text(
            'Планируемые типы',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _plannedApplicationTypes)
                _TypeChip(label: type, accent: _accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevelopmentBadge extends StatelessWidget {
  const _DevelopmentBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final outline = theme.colorScheme.outline.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.hammer_fill,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            'В разработке',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.muted,
  });

  final IconData icon;
  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: HomeEmployeeApplicationsWidget._accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
