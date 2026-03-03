import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../../../estimates/presentation/providers/estimate_providers.dart';
import '../providers/materials_providers.dart';

/// Кнопка экспорта отчета по списанию материалов на основании ВОР.
class MaterialsVorExportAction extends ConsumerWidget {
  /// Создает экземпляр [MaterialsVorExportAction].
  const MaterialsVorExportAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Экспорт отчета по списанию (ВОР)',
      icon: const Icon(Icons.description_outlined),
      onPressed: () => _showVorSelectionDialog(context, ref),
    );
  }

  Future<void> _showVorSelectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final contractNumber = ref.read(selectedContractNumberProvider);
    final contracts = ref.read(contractProvider).contracts;

    // Пытаемся найти ID контракта по номеру из фильтра
    final selectedContract = contracts
        .where((c) => c.number == contractNumber)
        .firstOrNull;

    if (selectedContract == null) {
      AppSnackBar.show(
        context: context,
        message: 'Выберите договор в фильтре',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _VorPickerLoader(
        contractId: selectedContract.id,
        contractNumber: selectedContract.number,
      ),
    );
  }
}

class _VorPickerLoader extends ConsumerWidget {
  final String contractId;
  final String contractNumber;

  const _VorPickerLoader({
    required this.contractId,
    required this.contractNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vorsAsync = ref.watch(vorsProvider(contractId));

    return Dialog(
      backgroundColor: Colors.transparent,
      child: DesktopDialogContent(
        title: 'Выбор ВОР для отчета (Договор $contractNumber)',
        width: 500,
        child: vorsAsync.when(
          data: (vors) {
            if (vors.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('Ведомости ВОР не найдены')),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: vors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final vor = vors[index];
                return ListTile(
                  title: Text(vor.number),
                  subtitle: Text(
                    '${vor.startDate.toLocal().toString().split(' ')[0]} - ${vor.endDate.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () async {
                    final companyId = ref.read(activeCompanyIdProvider);
                    if (companyId == null) return;

                    Navigator.of(context).pop();

                    try {
                      AppSnackBar.show(
                        context: context,
                        message: 'Генерация отчета...',
                        kind: AppSnackBarKind.info,
                      );

                      await ref
                          .read(vorExportServiceProvider)
                          .exportVorMaterialsReport(
                            vorId: vor.id,
                            companyId: companyId,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.show(
                          context: context,
                          message: 'Ошибка при экспорте: $e',
                          kind: AppSnackBarKind.error,
                        );
                      }
                    }
                  },
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (e, __) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Ошибка: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
