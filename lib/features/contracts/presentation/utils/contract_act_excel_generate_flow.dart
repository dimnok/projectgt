import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_excel_persist.dart';

/// Формирует Excel КС-2 по сохранённому акту и записывает в Storage.
Future<void> generateContractActExcelForUser({
  required BuildContext context,
  required WidgetRef ref,
  required ContractAct act,
}) async {
  if (!act.isKs2) return;

  final vorId = act.vorId?.trim();
  if (vorId == null || vorId.isEmpty) {
    AppSnackBar.show(
      context: context,
      message: 'У акта нет привязанной ВОР — Excel сформировать нельзя',
      kind: AppSnackBarKind.warning,
    );
    return;
  }

  try {
    await persistContractActExcel(
      ref: ref,
      companyId: act.companyId,
      contractId: act.contractId,
      actId: act.id,
      vorId: vorId,
      actNumber: act.number,
      actDocDate: act.actDate,
      reportingPeriodFrom: act.periodFrom,
      reportingPeriodTo: act.periodTo,
    );

    ref.invalidate(contractActsProvider(act.contractId));

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: act.hasExcel
          ? 'Файл КС-2 пересобран и сохранён'
          : 'Файл КС-2 сформирован и сохранён',
      kind: AppSnackBarKind.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Не удалось сформировать Excel: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
