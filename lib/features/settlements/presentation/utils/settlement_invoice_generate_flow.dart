import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/profile/presentation/screens/pdf_preview_screen.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/services/settlement_invoice_pdf_data.dart';
import 'package:projectgt/features/settlements/presentation/services/settlement_invoice_pdf_service.dart';

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

/// Загружает данные и открывает предпросмотр PDF счёта на оплату.
Future<void> openSettlementInvoicePdfPreview({
  required BuildContext context,
  required WidgetRef ref,
  required SettlementOperation operation,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CupertinoActivityIndicator(radius: 14)),
  );

  try {
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

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (missing.isNotEmpty) {
      AppSnackBar.show(
        context: context,
        message:
            'Не хватает данных для счёта: ${missing.join(', ')}. '
            'Заполните реквизиты в карточке компании и контрагента.',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    final pdfData = SettlementInvoicePdfData(
      operation: operation,
      company: company!,
      bankAccount: bankAccount!,
      contractor: contractor!,
    );

    final safeNumber = operation.invoiceNumber.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final fileName =
        'Счёт_${safeNumber}_${formatRuDate(operation.invoiceDate).replaceAll('.', '-')}';

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          fileName: fileName,
          buildPdf: (format) => SettlementInvoicePdfService.build(
            format: format,
            data: pdfData,
          ),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
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
