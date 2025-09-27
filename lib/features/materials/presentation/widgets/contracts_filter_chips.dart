import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/materials_providers.dart';

/// Чипы фильтра договоров с режимом сворачивания/раскрытия.
/// - По умолчанию виден один выбранный чип (или «Все»)
/// - По нажатию чип раскрывается и показывает все доступные договоры
/// - По выбору договора список снова сворачивается и остаётся только выбранный
class ContractsFilterChips extends ConsumerStatefulWidget {
  /// Конструктор чипов фильтра договоров.
  const ContractsFilterChips({super.key});

  @override
  ConsumerState<ContractsFilterChips> createState() =>
      _ContractsFilterChipsState();
}

class _ContractsFilterChipsState extends ConsumerState<ContractsFilterChips>
    with TickerProviderStateMixin {
  bool _expanded = false;
  static const Duration _animDuration = Duration(milliseconds: 750);
  late final AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedContractNumberProvider);
    final contractsAsync = ref.watch(materialsContractNumbersProvider);

    String titleFor(String? value) => value?.trim() ?? '';

    return contractsAsync.when(
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSingleChip(theme, titleFor(selected)),
        ],
      ),
      error: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSingleChip(theme, titleFor(selected)),
        ],
      ),
      data: (contracts) {
        if ((selected == null || selected.trim().isEmpty) &&
            contracts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedContractNumberProvider.notifier).state =
                contracts.first;
          });
        }
        final selectedLabel = titleFor(selected);

        // Постоянный выбранный чип (не участвует в переключении состояний)
        final selectedChip = _buildSingleChip(theme, selectedLabel, onTap: () {
          _toggle();
        });

        // Панель остальных чипов (без выбранного) — анимируется отдельно
        final rest = <Widget>[];
        for (final c in contracts) {
          if (c == selected) continue; // исключаем выбранный
          rest.add(
              _buildChoiceChip(context, label: c, value: c, selected: false));
        }

        final expandedPane = rest.isEmpty
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                key: const ValueKey('expanded-pane'),
                scrollDirection: Axis.horizontal,
                child: Row(children: rest),
              );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            selectedChip,
            // Панель чипов: одна и та же, анимируется контроллером
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOutCubic,
              ),
              axis: Axis.horizontal,
              axisAlignment: 1.0,
              child: Align(
                alignment: Alignment.centerRight,
                child: ClipRect(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.2, 1.0,
                          curve: Curves.easeInOutCubic),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeInOutCubic,
                      )),
                      child: expandedPane,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleChip(ThemeData theme, String label,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Theme(
        data: theme.copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ChoiceChip(
          label: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          selected: true,
          onSelected: (_) =>
              (onTap ?? () => setState(() => _expanded = true))(),
          selectedColor: Colors.green.withValues(alpha: 0.15),
          checkmarkColor: theme.colorScheme.onSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(BuildContext context,
      {required String label, required String? value, required bool selected}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Theme(
        data: theme.copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ChoiceChip(
          label: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          selected: selected,
          onSelected: (_) {
            ref.read(selectedContractNumberProvider.notifier).state = value;
            _close();
          },
          selectedColor: Colors.green.withValues(alpha: 0.15),
          checkmarkColor: theme.colorScheme.onSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  void _open() {
    if (_expanded) return;
    setState(() => _expanded = true);
    _controller.forward();
  }

  void _close() {
    if (!_expanded) return;
    _controller.reverse().whenComplete(() {
      if (mounted) setState(() => _expanded = false);
    });
  }

  void _toggle() {
    if (_controller.isAnimating) return;
    if (_expanded) {
      _close();
    } else {
      _open();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
