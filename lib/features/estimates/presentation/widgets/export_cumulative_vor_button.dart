import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../providers/estimate_providers.dart';

/// Кнопка скачивания накопительной ведомости ВОР (Excel) по договору.
///
/// Файл содержит листы «Свод», «Накопительная ВОР (объемы)» и «Накопительная ВОР (финансы)».
class ExportCumulativeVorButton extends ConsumerStatefulWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Подпись на кнопке.
  final String label;

  /// Создаёт [ExportCumulativeVorButton].
  const ExportCumulativeVorButton({
    super.key,
    required this.contractId,
    this.label = 'Экспорт (накопительная)',
  });

  @override
  ConsumerState<ExportCumulativeVorButton> createState() =>
      _ExportCumulativeVorButtonState();
}

class _ExportCumulativeVorButtonState
    extends ConsumerState<ExportCumulativeVorButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: _isLoading ? null : _handleExport,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CupertinoActivityIndicator(radius: 7),
                )
              else
                Icon(
                  CupertinoIcons.arrow_down_doc,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) {
      AppSnackBar.show(
        context: context,
        message: 'Ошибка: компания не выбрана',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(vorCumulativeExportServiceProvider).exportCumulativeVorToExcel(
            contractId: widget.contractId,
            companyId: companyId,
          );
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Файл успешно сформирован',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка экспорта: $e',
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
