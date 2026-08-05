import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

void main() {
  group('computeSettlementPaymentStatus', () {
    test('unpaid when nothing paid', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 100_000, paidAmount: 0),
        SettlementPaymentStatus.unpaid,
      );
    });

    test('partial when paid below total', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 100_000, paidAmount: 40_000),
        SettlementPaymentStatus.partial,
      );
    });

    test('paid when amounts match', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 100_000, paidAmount: 100_000),
        SettlementPaymentStatus.paid,
      );
    });

    test('paid within epsilon tolerance', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 100, paidAmount: 100.004),
        SettlementPaymentStatus.paid,
      );
    });

    test('overpaid when paid exceeds total', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 100_000, paidAmount: 105_000),
        SettlementPaymentStatus.overpaid,
      );
    });

    test('paid when total is zero and nothing paid', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 0, paidAmount: 0),
        SettlementPaymentStatus.paid,
      );
    });

    test('overpaid when total is zero but paid', () {
      expect(
        computeSettlementPaymentStatus(totalToPay: 0, paidAmount: 1),
        SettlementPaymentStatus.overpaid,
      );
    });
  });

  group('SettlementOperation resolvedPaymentStatus', () {
    test('matches computeSettlementPaymentStatus from stored amounts', () {
      final op = SettlementOperation(
        id: '1',
        companyId: 'c',
        operationType: SettlementOperationType.act,
        objectId: 'o',
        contractorId: 'k',
        contractId: 'd',
        invoiceNumber: '1',
        invoiceDate: DateTime(2026, 1, 1),
        amount: 100,
        totalToPay: 120,
        paidAmount: 50,
      );

      expect(op.resolvedPaymentStatus, SettlementPaymentStatus.partial);
      expect(op.positiveDebt, 70);
      expect(op.hasOutstandingDebt, isTrue);
      expect(op.hasOverpayment, isFalse);
    });
  });
}
