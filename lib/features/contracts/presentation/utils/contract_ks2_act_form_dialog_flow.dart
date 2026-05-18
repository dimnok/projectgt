import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_ks2_vor_positions_section.dart';
import 'package:projectgt/features/ks2/presentation/constants/ks2_act_form_dialog_width.dart';
import 'package:projectgt/features/ks2/presentation/widgets/ks2_act_form_template.dart';

/// Открывает диалог унифицированной формы КС-2: шапка + таблица позиций по ВОР.
///
/// Реализация в модуле «Договоры»; данные позиций — превью `ks2_operations` без
/// провайдеров модуля «Сметы».
Future<void> openContractKs2ActFormDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
}) async {
  if (!context.mounted) return;
  final formKey = GlobalKey<Ks2ActFormTemplateState>();

  await DesktopDialogContent.show<void>(
    context,
    title: 'Акт КС-2',
    width: kKs2ActFormDialogWidth,
    scrollable: true,
    footer: Row(
      children: [
        GTSecondaryButton(
          text: 'Скачать Excel',
          onPressed: () {
            final state = formKey.currentState;
            if (state == null) {
              AppSnackBar.show(
                context: context,
                message: 'Форма ещё не готова — подождите и повторите.',
                kind: AppSnackBarKind.error,
              );
              return;
            }
            unawaited(state.exportHeaderDraftToDevice(context, ref));
          },
        ),
        const Spacer(),
        GTPrimaryButton(
          text: 'Закрыть',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
    child: Ks2ActFormTemplate(
      key: formKey,
      contract: contract,
      positionsSection: ContractKs2VorPositionsSection(contractId: contract.id),
    ),
  );
}
