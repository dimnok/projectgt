import 'package:flutter/material.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';

/// Табличное представление списка договоров для десктопа.
///
/// Над карточками выводится одна строка заголовков колонок ([ContractTableHeaderRow]);
/// внутри каждой карточки — только значения, без повторяющихся подписей полей.
///
/// Строки оформлены как атмосферные карточки (градиент, тень, подсветка границы)
/// и состояниями выбора и наведения на десктопе.
///
/// Редактирование и удаление выполняются из панели деталей или иных действий экрана,
/// не из строки списка.
class ContractTableView extends StatelessWidget {
  /// Горизонтальный отступ заголовков колонок: [ContractListScreenDesktopChrome.tableListHorizontalPadding] +
  /// внутренний отступ текста карточки (ровно под колонки строки).
  static const double _headerInsetH =
      ContractListScreenDesktopChrome.tableListHorizontalPadding +
      _ContractCard.clipHorizontalPadding;

  /// Создаёт табличное представление списка договоров.
  const ContractTableView({
    super.key,
    required this.contracts,
    this.onSelect,
    this.selectedId,
  });

  /// Список договоров для отображения.
  final List<Contract> contracts;

  /// ID выбранного договора для выделения.
  final String? selectedId;

  /// Обратный вызов при выборе договора.
  final void Function(Contract)? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (contracts.isEmpty) {
      return Center(
        child: Text(
          'Нет договоров',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            _headerInsetH,
            0,
            _headerInsetH,
            ContractListTableLayout.headerBottomSpacing,
          ),
          child: ContractTableHeaderRow(),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(
              bottom: ContractListTableLayout.listBottomPadding,
            ),
            itemCount: contracts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final contract = contracts[index];
              final isSelected = selectedId == contract.id;

              return _ContractCard(
                contract: contract,
                isSelected: isSelected,
                onTap: () => onSelect?.call(contract),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Карточка договора на всю ширину (десктоп).
class _ContractCard extends StatefulWidget {
  /// Горизонтальный отступ текста внутри карточки (для выравнивания с [ContractTableHeaderRow]).
  static const double clipHorizontalPadding = 18;

  const _ContractCard({
    required this.contract,
    required this.isSelected,
    required this.onTap,
  });

  final Contract contract;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<_ContractCard>
    with SingleTickerProviderStateMixin {
  static const double _outerRadius = 16;
  static const double _clipRadius = 15;
  static const double _columnGap = 16;
  static const double _hoverLiftPx = 4;

  late final AnimationController _liftController;
  late final Animation<double> _liftY;

  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _liftY = Tween<double>(begin: 0, end: -_hoverLiftPx).animate(
      CurvedAnimation(
        parent: _liftController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _liftController.dispose();
    super.dispose();
  }

  void _setHover(bool value) {
    setState(() => _hover = value);
    if (value) {
      _liftController.forward();
    } else {
      _liftController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = MobileAtmosphereAppearance.of(context);
    final cardStyle = MobileAtmosphereCardStyle.fromAppearance(appearance);
    final scheme = appearance.scheme;
    final hi = cardStyle.cardHighlight;

    final warningIcon = ContractWarningHelper.buildWarningIcon(widget.contract);
    final statusBadge = ContractStatusHelper.tableBadgePalette(
      widget.contract.status,
      scheme,
    );

    final borderColor = widget.isSelected
        ? scheme.primary
        : _hover
        ? hi.withValues(alpha: appearance.isDark ? 0.35 : 0.55)
        : cardStyle.cardBorder;

    final borderWidth = widget.isSelected ? 1.5 : 1.0;

    final shadows = <BoxShadow>[
      ...cardStyle.cardShadows,
      if (_hover && !widget.isSelected)
        BoxShadow(
          color: scheme.shadow.withValues(
            alpha: appearance.isDark ? 0.35 : 0.07,
          ),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
    ];

    final amountStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: scheme.onSurface,
    );

    final cellValueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.15,
      color: scheme.onSurface.withValues(alpha: 0.92),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _liftY,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _liftY.value),
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_outerRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardStyle.cardTop, cardStyle.cardBottom],
              ),
              boxShadow: shadows,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_outerRadius),
              border: Border.fromBorderSide(
                BorderSide(
                  color: borderColor,
                  width: borderWidth,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_clipRadius),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            hi.withValues(alpha: 0),
                            hi.withValues(
                              alpha: widget.isSelected ? 0.95 : 0.65,
                            ),
                            hi.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _ContractCard.clipHorizontalPadding,
                      15,
                      _ContractCard.clipHorizontalPadding,
                      15,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: ContractListTableColumnFlex.number,
                          child: Row(
                            children: [
                              if (warningIcon != null) ...[
                                warningIcon,
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  '№ ${widget.contract.number}',
                                  style: cellValueStyle,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          flex: ContractListTableColumnFlex.kind,
                          child: Text(
                            ContractKindUi.label(widget.contract.kind),
                            style: cellValueStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          flex: ContractListTableColumnFlex.contractor,
                          child: Text(
                            widget.contract.contractorName ?? '—',
                            style: cellValueStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          flex: ContractListTableColumnFlex.object,
                          child: Text(
                            widget.contract.objectName ?? '—',
                            style: cellValueStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          flex: ContractListTableColumnFlex.period,
                          child: ContractPeriodTableCell(
                            contract: widget.contract,
                            valueStyle: cellValueStyle,
                          ),
                        ),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          flex: ContractListTableColumnFlex.amount,
                          child: Text(
                            formatCurrency(widget.contract.amount),
                            style: amountStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          flex: ContractListTableColumnFlex.status,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AppBadge(
                              text: statusBadge.label,
                              color: statusBadge.foreground,
                              fillColor: statusBadge.fill,
                              borderColor: statusBadge.border,
                              borderRadius: 8,
                              fontSize: 12,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
