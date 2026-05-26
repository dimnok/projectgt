import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_estimate_linked_estimate_file_picker.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';

/// Выгружает Excel: договорная смета с колонками выполнения (кол-во и сумма).
///
/// Содержимое и оформление книги формируются Edge Function
/// `export-contract-estimate-execution`. Сохранение на диск — как у
/// [openContractEstimateWithAddendaExportFlow].
Future<void> openContractEstimateWithExecutionExportFlow({
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
      AppSnackBar.show(
        context: context,
        message:
            'Нет смет по договору с привязкой к договору — выгрузка недоступна',
        kind: AppSnackBarKind.warning,
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
        dialogTitle: 'Смета для выгрузки с выполнением',
        objectNamesById: objectNamesById,
        showNewEstimateButton: false,
      );
      if (!context.mounted) return;
      if (pick == null || pick.isCanceled || pick.createNewEstimate) return;
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

    final repository = ref.read(estimateRepositoryProvider);
    final result = await repository.exportContractEstimateWithExecutionExcel(
      estimateTitle: target.estimateTitle,
      contractId: contractId,
      objectId: target.objectId,
    );

    final bytes = result['bytes'] as Uint8List;
    final fileName = result['filename'] as String;

    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: fileName.replaceAll('.xlsx', ''),
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } else {
      await FilePicker.saveFile(
        dialogTitle: 'Сохранить смету с выполнением',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
    }

    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Excel со сметой и выполнением сохранён',
      kind: AppSnackBarKind.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Не удалось выгрузить смету с выполнением: $e',
      kind: AppSnackBarKind.error,
    );
  }
}
