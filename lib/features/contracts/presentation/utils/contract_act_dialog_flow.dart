import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/features/contracts/presentation/constants/contract_act_desktop_dialog_width.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_add_dialog.dart';

/// Открывает диалог создания акта по [contract].
Future<void> openContractActAddDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
}) async {
  if (!context.mounted) return;
  await DesktopDialogContent.show<void>(
    context,
    title: 'Новый акт',
    width: kContractActDesktopDialogWidth,
    scrollable: true,
    child: ContractActAddDialog(contract: contract),
  );
}

/// Открывает диалог редактирования [act] по [contract].
Future<void> openContractActEditDialog({
  required BuildContext context,
  required Contract contract,
  required ContractAct act,
}) async {
  if (!context.mounted) return;
  await DesktopDialogContent.show<void>(
    context,
    title: 'Редактировать акт',
    width: kContractActDesktopDialogWidth,
    scrollable: true,
    child: ContractActAddDialog(contract: contract, existingAct: act),
  );
}
