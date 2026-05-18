import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_detail_navigation_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_detail_section_nav_links.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_details_panel.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_table_view.dart';

/// Геометрия встроенных деталей; [sidebarTopAlignInset] синхронизирует сайдбар десктопа с верхом карточки.
abstract final class ContractsListInlineDetailLayout {
  /// Нижний отступ строки «назад» до карточки деталей.
  static const double toolbarBottomSpacing = 8;

  /// Высота строки инструментов — совпадает с [MobileAtmosphereChromeCircleButton] (44×44).
  static const double toolbarRowHeight = 44;

  /// Вертикальный сдвиг сайдбара в режиме деталей = высота блока над карточкой.
  static double get sidebarTopAlignInset =>
      toolbarRowHeight + toolbarBottomSpacing;

  /// Высота компактной строки фильтров до измерения реального layout.
  static const double fallbackFiltersBarHeight = 36;

  /// Смещение от верха body до верхнего края карточки деталей.
  ///
  /// Совпадает с позицией первой карточки списка: высота строки фильтров,
  /// которая скрывается в режиме деталей, плюс заголовок таблицы над карточками.
  static double detailTopAlignInset(
    BuildContext context, {
    required double? filtersBarHeight,
  }) {
    final listCardInset =
        (filtersBarHeight ?? fallbackFiltersBarHeight) +
        ContractListTableLayout.offsetTopToFirstCard(context);
    return listCardInset > sidebarTopAlignInset
        ? listCardInset
        : sidebarTopAlignInset;
  }
}

/// Представление списка договоров с **встроенными** деталями (без модалки).
///
/// По нажатию на строку таблицы область списка заменяется на [ContractDetailsPanel]
/// с кнопкой возврата к списку. Альтернатива [ContractsListDesktopView], где детали
/// открываются через [ContractDetailsPanel.show].
class ContractsListInlineDetailView extends ConsumerStatefulWidget {
  /// Отфильтрованный список договоров.
  final List<Contract> filteredContracts;

  /// Загрузка данных.
  final bool isLoading;

  /// Ошибка загрузки.
  final bool isError;

  /// Текст ошибки.
  final String? errorMessage;

  /// Открыть форму редактирования договора.
  final void Function(Contract contract) onEditContract;

  /// Есть ли непустой поисковый запрос (влияет на текст пустого состояния).
  final bool hasActiveSearch;

  /// Вызывается при переключении между таблицей и встроенными деталями (для синхронизации
  /// хрома родителя, например выравнивания сайдбара).
  final ValueChanged<bool>? onPresentationModeChanged;

  /// Смещение карточки деталей от верха body для выравнивания с первой карточкой списка.
  final double? detailTopInset;

  /// Текущий договор в карточке деталей (`null`, если пользователь вернулся к таблице).
  ///
  /// Например для контекста в [ContractsQuickActionsSidebar].
  final ValueChanged<Contract?>? onDisplayedContractChanged;

  /// Выбранный подраздел навигации карточки (для синхронизации сайдбара быстрых действий).
  final ValueChanged<ContractDetailNavigationSection>? onDetailSectionChanged;

  /// Создаёт виджет со встроенным экраном деталей.
  const ContractsListInlineDetailView({
    super.key,
    required this.filteredContracts,
    required this.isLoading,
    required this.isError,
    this.errorMessage,
    required this.hasActiveSearch,
    required this.onEditContract,
    this.onPresentationModeChanged,
    this.detailTopInset,
    this.onDisplayedContractChanged,
    this.onDetailSectionChanged,
  });

  @override
  ConsumerState<ContractsListInlineDetailView> createState() =>
      _ContractsListInlineDetailViewState();
}

class _ContractsListInlineDetailViewState
    extends ConsumerState<ContractsListInlineDetailView> {
  String? _selectedContractId;
  ContractDetailNavigationSection _detailNavSection =
      ContractDetailNavigationSection.general;

  void _applySelection(String? id) {
    final before = _selectedContractId != null;

    Contract? sidebarContext;
    if (id != null) {
      for (final c in widget.filteredContracts) {
        if (c.id == id) {
          sidebarContext = c;
          break;
        }
      }
    }

    setState(() {
      _selectedContractId = id;
      if (id != null) {
        _detailNavSection = ContractDetailNavigationSection.general;
        widget.onDetailSectionChanged
            ?.call(ContractDetailNavigationSection.general);
      }
    });
    final after = _selectedContractId != null;
    if (before != after) {
      widget.onPresentationModeChanged?.call(after);
    }
    widget.onDisplayedContractChanged?.call(sidebarContext);
  }

  @override
  void didUpdateWidget(ContractsListInlineDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedContractId != null) {
      final containsSelected = widget.filteredContracts.any(
        (c) => c.id == _selectedContractId,
      );
      if (!containsSelected) {
        _applySelection(null);
      }
    }
  }

  Contract? get _selectedContract {
    final id = _selectedContractId;
    if (id == null) return null;
    for (final c in widget.filteredContracts) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = MobileAtmosphereAppearance.of(context);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.isError) {
      return Center(child: Text(widget.errorMessage ?? 'Ошибка'));
    }
    if (widget.filteredContracts.isEmpty) {
      return Center(
        child: Text(
          widget.hasActiveSearch
              ? 'По вашему запросу ничего не найдено'
              : 'Список договоров пуст',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final selected = _selectedContract;
    if (selected != null) {
      final detailTopInset =
          widget.detailTopInset ??
          ContractsListInlineDetailLayout.sidebarTopAlignInset;
      final toolbarBottomSpacing =
          (detailTopInset - ContractsListInlineDetailLayout.toolbarRowHeight)
              .clamp(0.0, double.infinity)
              .toDouble();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: toolbarBottomSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MobileAtmosphereChromeCircleButton(
                  appearance: appearance,
                  tooltip: 'К списку договоров',
                  icon: Icons.arrow_back_rounded,
                  onTap: () => _applySelection(null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ContractDetailsPanel.toolbarTitle(selected),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ContractDetailSectionNavLinks(
                  selected: _detailNavSection,
                  onSelected: (section) {
                    setState(() => _detailNavSection = section);
                    widget.onDetailSectionChanged?.call(section);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.14),
                  ),
                  color: theme.colorScheme.surfaceContainerLowest,
                ),
                child: LayoutBuilder(
                  builder: (innerContext, constraints) {
                    final expandEstimates = _detailNavSection ==
                        ContractDetailNavigationSection.estimates;

                    if (expandEstimates) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ContractDetailsPanel(
                              contract: selected,
                              onEdit: () => widget.onEditContract(selected),
                              detailSectionFilter: _detailNavSection,
                              expandEstimatesBodyToViewport: true,
                            ),
                          ),
                        ],
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: ContractDetailsPanel(
                            contract: selected,
                            onEdit: () => widget.onEditContract(selected),
                            detailSectionFilter: _detailNavSection,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ContractTableView(
      contracts: widget.filteredContracts,
      selectedId: _selectedContractId,
      onSelect: (contract) => _applySelection(contract.id),
    );
  }
}
