import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/profile/presentation/screens/pdf_preview_screen.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/services/settlement_invoice_pdf_data.dart';
import 'package:projectgt/features/settlements/presentation/services/settlement_invoice_pdf_service.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_files_state.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_invoice_pdf_persist.dart';

/// Проверяет, достаточно ли данных для формирования PDF счёта.
List<String> validateSettlementInvoicePdfData({
  CompanyProfile? company,
  CompanyBankAccount? bankAccount,
  Contractor? contractor,
}) {
  final missing = <String>[];

  if (company == null) {
    missing.add('профиль компании');
    return missing;
  }

  if (company.nameFull.trim().isEmpty) {
    missing.add('полное наименование компании');
  }
  if (company.inn == null || company.inn!.trim().isEmpty) {
    missing.add('ИНН компании');
  }
  if (bankAccount == null) {
    missing.add('банковский счёт компании');
  } else {
    if (bankAccount.accountNumber.trim().isEmpty) {
      missing.add('расчётный счёт');
    }
    if (bankAccount.bankName.trim().isEmpty) {
      missing.add('наименование банка');
    }
  }
  if (contractor == null) {
    missing.add('контрагент');
  } else {
    if (contractor.fullName.trim().isEmpty) {
      missing.add('наименование контрагента');
    }
    if (contractor.inn.trim().isEmpty) {
      missing.add('ИНН контрагента');
    }
  }

  return missing;
}

/// Результат подготовки байтов PDF счёта.
typedef SettlementInvoicePdfPrepareResult = ({
  Uint8List? bytes,
  List<String> missing,
});

/// Загружает реквизиты, проверяет данные и формирует байты PDF.
Future<SettlementInvoicePdfPrepareResult> prepareSettlementInvoicePdfBytes({
  required WidgetRef ref,
  required SettlementOperation operation,
}) async {
  final company = await ref.read(companyProfileProvider.future);
  final bankAccounts = await ref.read(companyBankAccountsProvider.future);
  final contractor = await ref
      .read(getContractorUseCaseProvider)
      .execute(operation.contractorId);

  final bankAccount = _resolvePrimaryBankAccount(bankAccounts);
  final missing = validateSettlementInvoicePdfData(
    company: company,
    bankAccount: bankAccount,
    contractor: contractor,
  );

  if (missing.isNotEmpty) {
    return (bytes: null, missing: missing);
  }

  final pdfData = SettlementInvoicePdfData(
    operation: operation,
    company: company!,
    bankAccount: bankAccount!,
    contractor: contractor!,
  );

  final bytes = await SettlementInvoicePdfService.build(
    format: PdfPageFormat.a4,
    data: pdfData,
  );

  return (bytes: bytes, missing: const <String>[]);
}

/// Сохраняет PDF в документы счёта, если есть право `settlements` / `update`.
Future<PersistGeneratedInvoicePdfResult?> persistSettlementInvoicePdfIfAllowed({
  required WidgetRef ref,
  required SettlementOperation operation,
  required List<int> bytes,
}) async {
  final canPersist =
      ref.read(permissionServiceProvider).can('settlements', 'update');
  if (!canPersist) return null;

  return persistSettlementInvoicePdf(
    ref: ref,
    settlementOperationId: operation.id,
    bytes: bytes,
    fileName: buildSettlementInvoicePdfFileName(operation),
  );
}

/// Формирует PDF при сохранении счёта и сохраняет в «Документы» (без предпросмотра).
///
/// [isCreate] — влияет только на текст уведомления.
/// Возвращает текст для snackbar или `null`, если достаточно стандартного сообщения.
Future<String?> generateAndPersistSettlementInvoicePdfOnSave({
  required WidgetRef ref,
  required SettlementOperation operation,
  required bool isCreate,
}) async {
  try {
    final prepared = await prepareSettlementInvoicePdfBytes(
      ref: ref,
      operation: operation,
    );

    final savedLabel = isCreate ? 'Счёт создан' : 'Счёт обновлён';

    if (prepared.missing.isNotEmpty) {
      return '$savedLabel. Для PDF не хватает данных: '
          '${prepared.missing.join(', ')}';
    }

    final persistResult = await persistSettlementInvoicePdfIfAllowed(
      ref: ref,
      operation: operation,
      bytes: prepared.bytes!,
    );

    if (persistResult == null) {
      return null;
    }

    if (persistResult.file != null) {
      if (isCreate) {
        return '$savedLabel, PDF сохранён в документы';
      }
      return persistResult.replaced
          ? '$savedLabel, PDF пересобран в документах'
          : '$savedLabel, PDF сохранён в документы';
    }

    return '$savedLabel. Не удалось сохранить PDF в документы';
  } catch (_) {
    final savedLabel = isCreate ? 'Счёт создан' : 'Счёт обновлён';
    return '$savedLabel. Не удалось сформировать PDF';
  }
}

/// Загружает данные и открывает предпросмотр PDF счёта на оплату.
Future<void> openSettlementInvoicePdfPreview({
  required BuildContext context,
  required WidgetRef ref,
  required SettlementOperation operation,
}) async {
  var loadingDialogOpen = false;

  void dismissLoadingDialog() {
    if (!loadingDialogOpen || !context.mounted) return;
    Navigator.of(context).pop();
    loadingDialogOpen = false;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CupertinoActivityIndicator(radius: 14)),
  );
  loadingDialogOpen = true;

  try {
    final prepared = await prepareSettlementInvoicePdfBytes(
      ref: ref,
      operation: operation,
    );

    dismissLoadingDialog();
    if (!context.mounted) return;

    if (prepared.missing.isNotEmpty) {
      AppSnackBar.show(
        context: context,
        message:
            'Не хватает данных для счёта: ${prepared.missing.join(', ')}. '
            'Заполните реквизиты в карточке компании и контрагента.',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    final fileName = buildSettlementInvoicePdfBaseName(operation);
    final pdfBytes = prepared.bytes!;

    final persistResult = await persistSettlementInvoicePdfIfAllowed(
      ref: ref,
      operation: operation,
      bytes: pdfBytes,
    );

    if (!context.mounted) return;

    if (persistResult != null) {
      if (persistResult.file != null) {
        AppSnackBar.show(
          context: context,
          message: persistResult.replaced
              ? 'Счёт пересобран и сохранён в документы'
              : 'Счёт сохранён в документы',
          kind: AppSnackBarKind.success,
        );
      } else {
        AppSnackBar.show(
          context: context,
          message:
              'Не удалось сохранить в документы. Предпросмотр доступен.',
          kind: AppSnackBarKind.warning,
        );
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          fileName: fileName,
          buildPdf: (_) async => pdfBytes,
        ),
      ),
    );
  } catch (e) {
    dismissLoadingDialog();
    if (context.mounted) {
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сформировать счёт: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }
}

CompanyBankAccount? _resolvePrimaryBankAccount(
  List<CompanyBankAccount> accounts,
) {
  if (accounts.isEmpty) return null;
  return accounts.firstWhere(
    (a) => a.isPrimary,
    orElse: () => accounts.first,
  );
}
