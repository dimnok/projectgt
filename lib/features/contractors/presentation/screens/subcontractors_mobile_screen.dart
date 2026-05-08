import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractor_margin_dashboard_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_contractor_unit_prices_provider.dart'
    show
        SubcontractorPricingForEstimate,
        subcontractorsContractorUnitPricesProvider;
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_estimate_name_search_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_execution_progress_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_filtered_estimates_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contract_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contractor_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_object_provider.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractor_form_screen.dart';
import 'package:projectgt/features/contractors/presentation/services/subcontractor_rates_excel_export_service.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/contractors/presentation/subcontractors_presentation_mode.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_contract_filter_field.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_contractor_filter_field.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_name_search_field.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_margin_dashboard_view.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_object_filter_field.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_rates_import_sheet.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Экран раздела «Подрядчики»: расценки, выполнение и сводка маржи.
class SubcontractorsMobileScreen extends ConsumerStatefulWidget {
  /// Создаёт экран подрядчиков.
  const SubcontractorsMobileScreen({super.key});

  @override
  ConsumerState<SubcontractorsMobileScreen> createState() =>
      _SubcontractorsMobileScreenState();
}

class _SubcontractorsMobileScreenState
    extends ConsumerState<SubcontractorsMobileScreen> {
  bool _isExportingSubcontractorRates = false;
  bool _isExportingSubcontractorExecution = false;
  final Set<String> _selectedEstimateIds = <String>{};
  SubcontractorsPresentationMode _mode =
      SubcontractorsPresentationMode.ratesTable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(estimateNotifierProvider.notifier).loadEstimates();
      ref.read(contractorNotifierProvider.notifier).loadContractors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionServiceProvider);
    if (!permissions.can('contractors', 'read')) {
      return const Scaffold(
        body: Center(child: Text('У вас нет прав для просмотра этой страницы')),
      );
    }

    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final selectedObjectId = ref.watch(subcontractorsSelectedObjectIdProvider);
    final selectedContractId = ref.watch(
      subcontractorsSelectedContractIdProvider,
    );
    final selectedContractorId = ref.watch(
      subcontractorsSelectedContractorIdProvider,
    );
    final estimatesState = ref.watch(estimateNotifierProvider);
    final filteredItems = ref.watch(subcontractorsFilteredEstimatesProvider);
    final isRates = _mode == SubcontractorsPresentationMode.ratesTable;
    final isExecution = _mode == SubcontractorsPresentationMode.executionTable;
    final isDetailedTable = isRates || isExecution;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? appearance.atmosphereBase
            : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.subcontractors),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (ctx) => _ToolbarIconButton(
                            appearance: appearance,
                            icon: Icons.menu_rounded,
                            tooltip: 'Меню',
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        if (isDetailedTable && isDesktop) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 420,
                            child: SubcontractorsEstimateNameSearchField(),
                          ),
                        ],
                        if (isDetailedTable) ...[
                          const Spacer(),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 120,
                              maxWidth: 200,
                            ),
                            child: SubcontractorsObjectFilterField(
                              compact: true,
                              borderSide: BorderSide(
                                color: appearance.chromeBorder,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 120,
                              maxWidth: 200,
                            ),
                            child: SubcontractorsContractFilterField(
                              compact: true,
                              borderSide: BorderSide(
                                color: appearance.chromeBorder,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 100,
                              maxWidth: 180,
                            ),
                            child: SubcontractorsContractorFilterField(
                              compact: true,
                              borderSide: BorderSide(
                                color: appearance.chromeBorder,
                                width: 1,
                              ),
                            ),
                          ),
                        ],
                        if (isRates &&
                            selectedObjectId != null &&
                            selectedObjectId.isNotEmpty &&
                            selectedContractId != null &&
                            selectedContractId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _ToolbarIconButton(
                            appearance: appearance,
                            icon: Icons.file_download_outlined,
                            tooltip: 'Скачать Excel для расценок',
                            isLoading: _isExportingSubcontractorRates,
                            onTap: _isExportingSubcontractorRates
                                ? null
                                : () => _exportSubcontractorRatesExcel(context),
                          ),
                        ],
                        if (isExecution &&
                            selectedObjectId != null &&
                            selectedObjectId.isNotEmpty &&
                            selectedContractId != null &&
                            selectedContractId.isNotEmpty &&
                            selectedContractorId != null &&
                            selectedContractorId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _ToolbarIconButton(
                            appearance: appearance,
                            icon: Icons.file_download_outlined,
                            tooltip: 'Скачать Excel выполнения',
                            isLoading: _isExportingSubcontractorExecution,
                            onTap: _isExportingSubcontractorExecution
                                ? null
                                : () => _exportSubcontractorExecutionExcel(
                                    context,
                                  ),
                          ),
                        ],
                        if (isRates &&
                            permissions.can('contractors', 'update') &&
                            permissions.can('contractors', 'create')) ...[
                          const SizedBox(width: 8),
                          _ToolbarIconButton(
                            appearance: appearance,
                            icon: Icons.file_upload_outlined,
                            tooltip: 'Загрузить Excel расценок',
                            onTap: () =>
                                _openSubcontractorRatesImportSheet(context),
                          ),
                        ],
                        if (isRates &&
                            permissions.can('contractors', 'create')) ...[
                          const SizedBox(width: 8),
                          _ToolbarIconButton(
                            appearance: appearance,
                            icon: Icons.add_rounded,
                            tooltip: 'Добавить контрагента',
                            iconColor: scheme.primary,
                            onTap: _showContractorForm,
                          ),
                        ],
                        if (!isDetailedTable) const Spacer(),
                      ],
                    ),
                  ),
                  if (isDetailedTable && !isDesktop)
                    const SubcontractorsEstimateNameSearchField(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 8),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        0,
                        10,
                        isDetailedTable ? 8 : 6,
                      ),
                      child: _SubcontractorsModeSwitch(
                        appearance: appearance,
                        value: _mode,
                        onChanged: _setMode,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                      child: isRates
                          ? _buildRatesTableBody(
                              context,
                              appearance: appearance,
                              isEstimatesInitialLoading:
                                  estimatesState.isLoading &&
                                  estimatesState.estimates.isEmpty,
                              selectedObjectId: selectedObjectId,
                              selectedContractId: selectedContractId,
                              filteredItems: filteredItems,
                            )
                          : isExecution
                          ? _buildExecutionTableBody(
                              context,
                              appearance: appearance,
                              isEstimatesInitialLoading:
                                  estimatesState.isLoading &&
                                  estimatesState.estimates.isEmpty,
                              selectedObjectId: selectedObjectId,
                              selectedContractId: selectedContractId,
                              filteredItems: filteredItems,
                            )
                          : const SubcontractorsMarginDashboardView(),
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

  void _setMode(SubcontractorsPresentationMode mode) {
    setState(() {
      _mode = mode;
    });
    if (mode == SubcontractorsPresentationMode.marginDashboard) {
      ref.invalidate(subcontractorMarginDashboardProvider);
    } else if (mode == SubcontractorsPresentationMode.executionTable) {
      ref.invalidate(subcontractorsExecutionProgressProvider);
    }
  }

  void _setSelectedEstimateIds(Set<String> ids) {
    setState(() {
      _selectedEstimateIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _showContractorForm() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContractorFormScreen(),
    );
  }

  Widget _buildRatesTableBody(
    BuildContext context, {
    required MobileAtmosphereAppearance appearance,
    required bool isEstimatesInitialLoading,
    required String? selectedObjectId,
    required String? selectedContractId,
    required List<Estimate> filteredItems,
  }) {
    if (isEstimatesInitialLoading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: appearance.scheme.primary,
          ),
        ),
      );
    }

    if (selectedObjectId == null || selectedObjectId.isEmpty) {
      return _EmptyStateText(text: 'Выберите объект', appearance: appearance);
    }

    if (selectedContractId == null || selectedContractId.isEmpty) {
      return _EmptyStateText(text: 'Выберите договор', appearance: appearance);
    }

    final contractorId = ref.watch(subcontractorsSelectedContractorIdProvider);
    final pricesAsync = ref.watch(subcontractorsContractorUnitPricesProvider);
    final searchQuery = ref.watch(subcontractorsEstimateNameSearchProvider);
    final Map<String, SubcontractorPricingForEstimate>? subcontractorPricing;

    if (contractorId == null || contractorId.isEmpty) {
      subcontractorPricing = null;
    } else {
      subcontractorPricing = pricesAsync.when(
        data: (m) => m,
        loading: () => <String, SubcontractorPricingForEstimate>{},
        error: (_, __) => <String, SubcontractorPricingForEstimate>{},
      );
    }

    return SubcontractorsEstimateTable(
      items: filteredItems,
      subcontractorPricingByEstimateId: subcontractorPricing,
      expandSections: searchQuery.trim().isNotEmpty,
      selectedEstimateIds: _selectedEstimateIds,
      onSelectedEstimateIdsChanged: _setSelectedEstimateIds,
    );
  }

  Widget _buildExecutionTableBody(
    BuildContext context, {
    required MobileAtmosphereAppearance appearance,
    required bool isEstimatesInitialLoading,
    required String? selectedObjectId,
    required String? selectedContractId,
    required List<Estimate> filteredItems,
  }) {
    if (isEstimatesInitialLoading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: appearance.scheme.primary,
          ),
        ),
      );
    }

    if (selectedObjectId == null || selectedObjectId.isEmpty) {
      return _EmptyStateText(text: 'Выберите объект', appearance: appearance);
    }

    if (selectedContractId == null || selectedContractId.isEmpty) {
      return _EmptyStateText(text: 'Выберите договор', appearance: appearance);
    }

    final contractorId = ref.watch(subcontractorsSelectedContractorIdProvider);
    if (contractorId == null || contractorId.isEmpty) {
      return _EmptyStateText(
        text: 'Выберите подрядчика',
        appearance: appearance,
      );
    }

    final pricesAsync = ref.watch(subcontractorsContractorUnitPricesProvider);
    final executionAsync = ref.watch(subcontractorsExecutionProgressProvider);
    final searchQuery = ref.watch(subcontractorsEstimateNameSearchProvider);

    return pricesAsync.when(
      data: (pricing) => executionAsync.when(
        data: (execution) => SubcontractorsEstimateTable(
          items: filteredItems,
          subcontractorPricingByEstimateId: pricing,
          executionByEstimateId: execution,
          mode: SubcontractorsEstimateTableMode.execution,
          expandSections: searchQuery.trim().isNotEmpty,
          selectedEstimateIds: _selectedEstimateIds,
          onSelectedEstimateIdsChanged: _setSelectedEstimateIds,
        ),
        loading: () => _LoadingIndicator(appearance: appearance),
        error: (e, _) => _EmptyStateText(
          text: 'Ошибка загрузки выполнения: $e',
          appearance: appearance,
        ),
      ),
      loading: () => _LoadingIndicator(appearance: appearance),
      error: (e, _) => _EmptyStateText(
        text: 'Ошибка загрузки расценок: $e',
        appearance: appearance,
      ),
    );
  }

  Future<void> _openSubcontractorRatesImportSheet(BuildContext context) async {
    final contractId = ref.read(subcontractorsSelectedContractIdProvider);
    final objectId = ref.read(subcontractorsSelectedObjectIdProvider);
    final companyId = ref.read(activeCompanyIdProvider);
    if (contractId == null ||
        objectId == null ||
        companyId == null ||
        contractId.isEmpty ||
        objectId.isEmpty) {
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Выберите объект и договор',
          kind: AppSnackBarKind.error,
        );
      }
      return;
    }

    final int? count;
    if (ResponsiveUtils.isDesktop(context)) {
      count = await showDialog<int>(
        context: context,
        builder: (ctx) => SubcontractorsRatesImportSheet(
          companyId: companyId,
          contractId: contractId,
          objectId: objectId,
        ),
      );
    } else {
      final screenWidth = MediaQuery.sizeOf(context).width;
      count = await showModalBottomSheet<int>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(maxWidth: screenWidth),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SubcontractorsRatesImportSheet(
          companyId: companyId,
          contractId: contractId,
          objectId: objectId,
        ),
      );
    }

    if (!context.mounted) return;
    if (count != null && count > 0) {
      AppSnackBar.show(
        context: context,
        message: 'Загружено строк: $count',
        kind: AppSnackBarKind.success,
      );
    }
  }

  Future<void> _exportSubcontractorRatesExcel(BuildContext context) async {
    if (_isExportingSubcontractorRates) return;
    setState(() => _isExportingSubcontractorRates = true);
    final contractId = ref.read(subcontractorsSelectedContractIdProvider);
    final objectId = ref.read(subcontractorsSelectedObjectIdProvider);
    final companyId = ref.read(activeCompanyIdProvider);
    final contractorForExport = ref.read(
      subcontractorsSelectedContractorIdProvider,
    );
    final visibleEstimateIds = ref
        .read(subcontractorsFilteredEstimatesProvider)
        .map((estimate) => estimate.id)
        .toSet();
    final selectedEstimateIdsForExport = _selectedEstimateIds
        .where(visibleEstimateIds.contains)
        .toList(growable: false);
    final client = ref.read(supabaseClientProvider);
    try {
      if (contractId == null || objectId == null || companyId == null) {
        throw Exception('Выберите компанию, объект и договор');
      }
      final path =
          await SubcontractorRatesExcelExportService.requestServerExportAndSaveToDevice(
            client,
            companyId: companyId,
            contractId: contractId,
            objectId: objectId,
            contractorId: contractorForExport,
            estimateIds: selectedEstimateIdsForExport,
          );
      if (!context.mounted) return;
      if (path != null) {
        AppSnackBar.show(
          context: context,
          message: 'Файл сформирован',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: e.toString(),
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingSubcontractorRates = false);
      }
    }
  }

  Future<void> _exportSubcontractorExecutionExcel(BuildContext context) async {
    if (_isExportingSubcontractorExecution) return;
    setState(() => _isExportingSubcontractorExecution = true);
    final contractId = ref.read(subcontractorsSelectedContractIdProvider);
    final objectId = ref.read(subcontractorsSelectedObjectIdProvider);
    final companyId = ref.read(activeCompanyIdProvider);
    final contractorId = ref.read(subcontractorsSelectedContractorIdProvider);
    final visibleEstimateIds = ref
        .read(subcontractorsFilteredEstimatesProvider)
        .map((estimate) => estimate.id)
        .toSet();
    final selectedEstimateIdsForExport = _selectedEstimateIds
        .where(visibleEstimateIds.contains)
        .toList(growable: false);
    final client = ref.read(supabaseClientProvider);
    try {
      if (contractId == null || objectId == null || companyId == null) {
        throw Exception('Выберите компанию, объект и договор');
      }
      if (contractorId == null || contractorId.isEmpty) {
        throw Exception('Выберите подрядчика');
      }
      final path =
          await SubcontractorRatesExcelExportService.requestServerExecutionExportAndSaveToDevice(
            client,
            companyId: companyId,
            contractId: contractId,
            objectId: objectId,
            contractorId: contractorId,
            estimateIds: selectedEstimateIdsForExport,
          );
      if (!context.mounted) return;
      if (path != null) {
        AppSnackBar.show(
          context: context,
          message: 'Файл сформирован',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: e.toString(),
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingSubcontractorExecution = false);
      }
    }
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.appearance,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
    this.isLoading = false,
  });

  final MobileAtmosphereAppearance appearance;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: appearance.chromeFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: appearance.chromeBorder),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: appearance.scheme.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: icon == Icons.add_rounded ? 26 : 24,
                    color: iconColor ?? appearance.scheme.onSurface,
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText({required this.text, required this.appearance});

  final String text;
  final MobileAtmosphereAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: appearance.scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.appearance});

  final MobileAtmosphereAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: appearance.scheme.primary,
        ),
      ),
    );
  }
}

class _SubcontractorsModeSwitch extends StatelessWidget {
  const _SubcontractorsModeSwitch({
    required this.appearance,
    required this.value,
    required this.onChanged,
  });

  final MobileAtmosphereAppearance appearance;
  final SubcontractorsPresentationMode value;
  final ValueChanged<SubcontractorsPresentationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = appearance.scheme;

    return Semantics(
      label: 'Режим отображения подрядчиков',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SubcontractorsModeSwitchButton(
            label: 'Расценки',
            selected: value == SubcontractorsPresentationMode.ratesTable,
            textColor: scheme.onSurfaceVariant,
            selectedTextColor: scheme.primary,
            onTap: () => onChanged(SubcontractorsPresentationMode.ratesTable),
          ),
          _ModeSeparator(color: scheme.onSurfaceVariant),
          _SubcontractorsModeSwitchButton(
            label: 'Выполнение',
            selected: value == SubcontractorsPresentationMode.executionTable,
            textColor: scheme.onSurfaceVariant,
            selectedTextColor: scheme.primary,
            onTap: () =>
                onChanged(SubcontractorsPresentationMode.executionTable),
          ),
          _ModeSeparator(color: scheme.onSurfaceVariant),
          _SubcontractorsModeSwitchButton(
            label: 'Сводка',
            selected: value == SubcontractorsPresentationMode.marginDashboard,
            textColor: scheme.onSurfaceVariant,
            selectedTextColor: scheme.primary,
            onTap: () =>
                onChanged(SubcontractorsPresentationMode.marginDashboard),
          ),
        ],
      ),
    );
  }
}

class _ModeSeparator extends StatelessWidget {
  const _ModeSeparator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '/',
        style: TextStyle(
          color: color.withValues(alpha: 0.45),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SubcontractorsModeSwitchButton extends StatelessWidget {
  const _SubcontractorsModeSwitchButton({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.selectedTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color textColor;
  final Color selectedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = selected ? selectedTextColor : textColor;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.08,
                decoration: selected ? TextDecoration.underline : null,
                decorationColor: selectedTextColor.withValues(alpha: 0.65),
                decorationThickness: 1.4,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
