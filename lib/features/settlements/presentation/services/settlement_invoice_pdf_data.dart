import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

/// Данные для формирования PDF «Счёт на оплату».
class SettlementInvoicePdfData {
  /// Создаёт набор данных для генерации счёта.
  const SettlementInvoicePdfData({
    required this.operation,
    required this.company,
    required this.bankAccount,
    required this.contractor,
  });

  /// Операция взаиморасчётов (счёт).
  final SettlementOperation operation;

  /// Профиль компании-получателя платежа.
  final CompanyProfile company;

  /// Банковский счёт компании.
  final CompanyBankAccount bankAccount;

  /// Контрагент-плательщик.
  final Contractor contractor;

  /// Наименование позиции: примечание, иначе стандартная формулировка по типу счёта.
  String get lineItemName {
    final note = operation.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return _defaultLineItemName;
  }

  String get _defaultLineItemName {
    final contract = operation.contractNumber?.trim();
    final contractPart = (contract != null && contract.isNotEmpty)
        ? ' по договору № $contract'
        : '';

    return switch (operation.operationType) {
      SettlementOperationType.act => _joinNonEmpty([
          'Выполнение работ$contractPart',
          if (operation.actNumber != null && operation.actNumber!.isNotEmpty)
            '(акт № ${operation.actNumber})',
          if (operation.objectName != null && operation.objectName!.isNotEmpty)
            'объект: ${operation.objectName}',
        ]),
      SettlementOperationType.advance => 'Авансовый платёж$contractPart',
      SettlementOperationType.other =>
        operation.purpose?.trim().isNotEmpty == true
            ? operation.purpose!.trim()
            : 'Услуги$contractPart',
    };
  }

  String _joinNonEmpty(List<String> parts) =>
      parts.where((p) => p.trim().isNotEmpty).join(', ');

  /// Основание платежа для шапки счёта.
  String get basisText {
    final contract = operation.contractNumber?.trim();
    if (contract != null && contract.isNotEmpty) {
      return 'Договор № $contract';
    }
    return '—';
  }

  /// Назначение платежа для банковского блока.
  String get paymentPurposeText {
    final invoiceDate = formatRuDate(operation.invoiceDate);
    final base =
        'Оплата по счету № ${operation.invoiceNumber} от $invoiceDate';

    final hasVat = operation.vatRate != null && operation.vatRate! > 0;
    if (hasVat && operation.vatAmount > 0) {
      return '$base. В том числе НДС(${formatQuantity(operation.vatRate!)}%) '
          '${formatAmount(operation.vatAmount)} руб.';
    }
    return base;
  }
}
