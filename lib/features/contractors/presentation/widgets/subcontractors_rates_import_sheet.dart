import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_contractor_unit_prices_provider.dart';
import 'package:projectgt/features/contractors/presentation/services/subcontractor_rates_excel_import_service.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';

/// Импорт расценок: тот же каркас, что у «Открытия смены» ([MobileBottomSheetContent] + [MobileAtmosphereBackdrop] / [DesktopDialogContent]).
///
/// В списке только контрагенты с типом [ContractorType.contractor].
class SubcontractorsRatesImportSheet extends ConsumerStatefulWidget {
  /// Создаёт лист импорта.
  const SubcontractorsRatesImportSheet({
    super.key,
    required this.companyId,
    required this.contractId,
    required this.objectId,
  });

  /// Текущая компания.
  final String companyId;

  /// Выбранный договор (должен совпадать с выгрузкой).
  final String contractId;

  /// Выбранный объект.
  final String objectId;

  @override
  ConsumerState<SubcontractorsRatesImportSheet> createState() =>
      _SubcontractorsRatesImportSheetState();
}

class _SubcontractorsRatesImportSheetState
    extends ConsumerState<SubcontractorsRatesImportSheet> {
  Contractor? _selectedContractor;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(contractorNotifierProvider.notifier).loadContractors();
    });
  }

  Future<void> _pickAndImport() async {
    if (_selectedContractor == null || _isImporting) return;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
    } on PlatformException {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message:
              'Не удалось открыть выбор файла. Проверьте доступ приложения к файлам.',
          kind: AppSnackBarKind.error,
        );
      }
      return;
    }

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Не удалось прочитать файл',
          kind: AppSnackBarKind.error,
        );
      }
      return;
    }

    setState(() => _isImporting = true);
    try {
      final rows = SubcontractorRatesExcelImportService.parseImportRows(bytes);
      final count =
          await SubcontractorRatesExcelImportService.validateAndUpsert(
            ref.read(supabaseClientProvider),
            companyId: widget.companyId,
            contractId: widget.contractId,
            objectId: widget.objectId,
            contractorId: _selectedContractor!.id,
            contributionsByEstimateId: rows,
          );
      if (!mounted) return;
      ref.invalidate(subcontractorsContractorUnitPricesProvider);
      Navigator.of(context).pop(count);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: e.toString(),
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractorState = ref.watch(contractorNotifierProvider);
    final contractors =
        contractorState.contractors
            .where((c) => c.type == ContractorType.contractor)
            .toList()
          ..sort(
            (a, b) =>
                a.shortName.toLowerCase().compareTo(b.shortName.toLowerCase()),
          );

    if (_selectedContractor != null &&
        !contractors.any((c) => c.id == _selectedContractor!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedContractor = null);
      });
    }

    final isMobile = ResponsiveUtils.isMobile(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Выберите подрядчика, затем укажите Excel той же выгрузки (объект и договор должны совпадать).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (contractors.isEmpty &&
            contractorState.status != ContractorStatus.loading)
          Text(
            'В справочнике нет контрагентов с типом «Подрядчик». Добавьте запись в разделе контрагентов.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          GTDropdown<Contractor>(
            labelText: 'Подрядчик',
            hintText: 'Выберите подрядчика',
            items: contractors,
            selectedItem: _selectedContractor,
            itemDisplayBuilder: (c) =>
                c.shortName.trim().isNotEmpty ? c.shortName : c.fullName,
            readOnly: _isImporting,
            onSelectionChanged: (c) => setState(() => _selectedContractor = c),
            isLoading: contractorState.status == ContractorStatus.loading,
            allowMultipleSelection: false,
            allowCustomInput: false,
            showAddNewOption: false,
          ),
      ],
    );

    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: _isImporting ? null : () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: 'Выбрать файл',
            icon: Icons.upload_file_outlined,
            onPressed:
                _selectedContractor == null ||
                    _isImporting ||
                    contractors.isEmpty
                ? null
                : _pickAndImport,
            isLoading: _isImporting,
          ),
        ),
      ],
    );

    if (isMobile) {
      return MobileBottomSheetContent(
        title: 'Импорт расценок',
        sheetBackdrop: const MobileAtmosphereBackdrop(),
        footer: footer,
        child: content,
      );
    }

    return Center(
      child: DesktopDialogContent(
        title: 'Импорт расценок',
        width: 480,
        footer: footer,
        child: content,
      ),
    );
  }
}
