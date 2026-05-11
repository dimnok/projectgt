import 'package:flutter/material.dart';

/// Горизонтальная полоса чипов списка смен: «Все» / «Мои смены» / «Планы».
///
/// Тот же визуальный язык, что на мобильном [WorksListMobileScreen].
class WorksListScopeChipsBar extends StatelessWidget {
  /// Создаёт полосу чипов над списком смен.
  const WorksListScopeChipsBar({
    super.key,
    required this.scheme,
    required this.profileId,
    required this.onlyMineActive,
    required this.canOpenPlans,
    required this.onAllTap,
    required this.onMineTap,
    required this.onPlansTap,
  });

  /// Цветовая схема темы.
  final ColorScheme scheme;

  /// Текущий пользователь (для «Мои смены»); если `null`, чип скрыт.
  final String? profileId;

  /// Активен ли фильтр «только мои смены».
  final bool onlyMineActive;

  /// Показывать ли чип перехода к планам (права на модуль планов).
  final bool canOpenPlans;

  /// Переключить список на все смены компании.
  final Future<void> Function() onAllTap;

  /// Переключить список на смены текущего пользователя.
  final Future<void> Function() onMineTap;

  /// Перейти к экрану/колонке планов работ.
  final VoidCallback onPlansTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Row(
          children: [
            WorksListScopeTextChip(
              scheme: scheme,
              label: 'Все',
              selected: !onlyMineActive,
              onTap: onAllTap,
            ),
            if (profileId != null) ...[
              const SizedBox(width: 22),
              WorksListScopeTextChip(
                scheme: scheme,
                label: 'Мои смены',
                selected: onlyMineActive,
                onTap: onMineTap,
              ),
            ],
            if (canOpenPlans) ...[
              const SizedBox(width: 22),
              WorksListScopeTextChip(
                scheme: scheme,
                label: 'Планы',
                selected: false,
                onTap: () async {
                  onPlansTap();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Текстовый чип фильтра: в активном состоянии — цвет primary и подчёркивание.
class WorksListScopeTextChip extends StatelessWidget {
  /// Создаёт чип.
  const WorksListScopeTextChip({
    super.key,
    required this.scheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Цветовая схема.
  final ColorScheme scheme;

  /// Подпись.
  final String label;

  /// Выбранное состояние.
  final bool selected;

  /// Обработчик нажатия.
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: () async {
        await onTap();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.35,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: scheme.primary,
            decorationThickness: 2,
            decorationStyle: TextDecorationStyle.solid,
          ),
        ),
      ),
    );
  }
}
