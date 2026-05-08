import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_linked_estimate_file_picker.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_addenda_from_revisions_section.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/estimates/presentation/screens/import_estimate_addendum_modal.dart';

/// Открывает сценарий LC/ДС: при необходимости выбор сметы по договору,
/// затем модальное окно импорта. Если привязанных смет нет, модалка всё равно
/// открывается — смету можно создать кнопкой «Новая смета».
///
/// [contract] задаёт договор; сметы берутся из [contractEstimateFilesProvider].
Future<void> openContractEstimateAddendumFlow({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
}) async {
  try {
    final files = await ref.read(
      contractEstimateFilesProvider(contract.id).future,
    );
    final withContract = files
        .where((f) => f.contractId != null && f.contractId!.isNotEmpty)
        .toList();

    if (!context.mounted) return;

    if (withContract.isEmpty) {
      if (!context.mounted) return;
      ImportEstimateAddendumModal.show(
        context,
        estimateTitle: '',
        contractId: contract.id,
        objectId: contract.objectId,
        onSuccess: () {
          if (context.mounted) {
            Navigator.of(context).maybePop();
          }
          ref.invalidate(contractEstimateFilesProvider(contract.id));
          ref.invalidate(contractEstimatesProvider(contract.id));
          ref.invalidate(estimateGroupsProvider);
          ref.invalidate(contractAddendumRowsProvider(contract.id));
          ref.invalidate(contractVorCompletionProvider(contract.id));
        },
      );
      return;
    }

    final EstimateFile target;
    if (withContract.length == 1) {
      target = withContract.single;
    } else {
      final objectNamesById = {
        for (final o in ref.read(objectProvider).objects) o.id: o.name,
      };
      final pick = await pickContractLinkedEstimateFile(
        context,
        withContract,
        objectNamesById: objectNamesById,
      );
      if (!context.mounted) return;
      if (pick == null || pick.isCanceled) return;
      if (pick.createNewEstimate) {
        ImportEstimateAddendumModal.show(
          context,
          estimateTitle: '',
          contractId: contract.id,
          objectId: contract.objectId,
          onSuccess: () {
            if (context.mounted) {
              Navigator.of(context).maybePop();
            }
            ref.invalidate(contractEstimateFilesProvider(contract.id));
            ref.invalidate(contractEstimatesProvider(contract.id));
            ref.invalidate(estimateGroupsProvider);
            ref.invalidate(contractAddendumRowsProvider(contract.id));
            ref.invalidate(contractVorCompletionProvider(contract.id));
          },
        );
        return;
      }
      target = pick.selectedFile!;
    }

    final contractId = target.contractId;
    if (contractId == null || contractId.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'У выбранной сметы нет привязки к договору',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    ImportEstimateAddendumModal.show(
      context,
      estimateTitle: target.estimateTitle,
      contractId: contractId,
      objectId: target.objectId,
      onSuccess: () {
        if (context.mounted) {
          Navigator.of(context).maybePop();
        }
        ref.invalidate(contractEstimateFilesProvider(contract.id));
        ref.invalidate(contractEstimatesProvider(contract.id));
        ref.invalidate(estimateGroupsProvider);
        ref.invalidate(contractAddendumRowsProvider(contract.id));
        ref.invalidate(contractVorCompletionProvider(contract.id));
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Не удалось подготовить доп. соглашение: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
