import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/features/contracts/presentation/constants/contract_act_form_dialog_width.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_manual_form.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_ks2_form_body.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_lines_editor_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_ks2_status_documents_section.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_ks2_vor_positions_section.dart';

/// Режим формы создания акта.
enum ContractActFormMode {
  /// Ручной ввод сумм и реквизитов.
  manual,

  /// КС-2 по утверждённой ВОР.
  ks2,
}

/// Открывает единую форму создания или редактирования акта по [contract].
Future<void> openContractActFormDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
  ContractAct? existingAct,
  ContractActFormMode initialMode = ContractActFormMode.ks2,
}) async {
  if (!context.mounted) return;

  final isKs2Existing = existingAct?.isKs2 ?? false;
  final isKs2Mode = existingAct != null ? isKs2Existing : initialMode == ContractActFormMode.ks2;

  if (isKs2Mode) {
    final formKey = GlobalKey<ContractActKs2FormBodyState>();
    final positionsKey = GlobalKey<ContractKs2VorPositionsSectionState>();
    final actLinesKey = GlobalKey<ContractActLinesEditorSectionState>();
    final statusKey = GlobalKey<ContractActKs2StatusDocumentsSectionState>();
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.92;
    final isCreate = existingAct == null;
    final canEditLines = existingAct?.canEditFull ?? false;

    final actTitle = isCreate
        ? 'Новый акт КС-2'
        : 'Акт КС-2 № ${existingAct.number} · '
            '${formatRuDate(existingAct.periodFrom)}—${formatRuDate(existingAct.periodTo)}';

    await DesktopDialogContent.show<void>(
      context,
      title: actTitle,
      width: kContractActFormDialogWidth,
      height: dialogHeight,
      scrollable: false,
      footer: isCreate
          ? Row(
              children: [
                GTTextButton(
                  text: 'Ручной ввод',
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(
                      openContractActFormDialog(
                        context: context,
                        ref: ref,
                        contract: contract,
                        initialMode: ContractActFormMode.manual,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 12),
                GTPrimaryButton(
                  text: 'Сохранить акт',
                  onPressed: () async {
                    final state = formKey.currentState;
                    if (state == null) {
                      AppSnackBar.show(
                        context: context,
                        message: 'Форма ещё не готова — подождите и повторите.',
                        kind: AppSnackBarKind.error,
                      );
                      return;
                    }
                    final saved = await state.saveAct(context, ref);
                    if (!context.mounted) return;
                    if (saved) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            )
          : Row(
              children: [
                if (canEditLines) ...[
                  GTSecondaryButton(
                    text: 'Скачать Excel',
                    onPressed: () {
                      final state = formKey.currentState;
                      if (state == null) {
                        AppSnackBar.show(
                          context: context,
                          message:
                              'Форма ещё не готова — подождите и повторите.',
                          kind: AppSnackBarKind.error,
                        );
                        return;
                      }
                      unawaited(state.exportHeaderDraftToDevice(context, ref));
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                GTPrimaryButton(
                  text: 'Сохранить',
                  onPressed: () async {
                    final state = formKey.currentState;
                    if (state == null) {
                      AppSnackBar.show(
                        context: context,
                        message:
                            'Форма ещё не готова — подождите и повторите.',
                        kind: AppSnackBarKind.error,
                      );
                      return;
                    }
                    final saved = await state.saveExistingAct(context, ref);
                    if (!context.mounted) return;
                    if (saved) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
      child: ContractActKs2FormBody(
        key: formKey,
        contract: contract,
        existingAct: existingAct,
        actLinesSectionKey: isCreate ? null : actLinesKey,
        statusDocumentsSectionKey: isCreate ? null : statusKey,
        getSelectedVorId: isCreate
            ? () => positionsKey.currentState?.selectedVorId
            : null,
        getPreviewLineTotal: isCreate
            ? () => positionsKey.currentState?.previewLineTotal
            : null,
        positionsSection: isCreate
            ? ContractKs2VorPositionsSection(
                key: positionsKey,
                contractId: contract.id,
                onPreviewUpdated: () =>
                    formKey.currentState?.onPreviewLineTotalUpdated(),
              )
            : ContractActLinesEditorSection(
                key: actLinesKey,
                actId: existingAct.id,
                editable: canEditLines,
              ),
      ),
    );
    return;
  }

  await DesktopDialogContent.show<void>(
    context,
    title: existingAct == null ? 'Новый акт' : 'Редактировать акт',
    width: kContractActFormDialogWidth,
    scrollable: true,
    child: ContractActManualForm(
      contract: contract,
      existingAct: existingAct,
    ),
  );
}

/// Открывает форму редактирования [act].
Future<void> openContractActEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
  required ContractAct act,
}) {
  return openContractActFormDialog(
    context: context,
    ref: ref,
    contract: contract,
    existingAct: act,
  );
}
