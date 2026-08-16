import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/core/utils/user_display_utils.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_file.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_invoice_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_actions_bar.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

void main() {
  group('PurchaseRequestStatusX', () {
    test('fromDb maps all workflow statuses', () {
      for (final status in PurchaseRequestStatus.values) {
        if (status == PurchaseRequestStatus.unknown) continue;
        expect(
          PurchaseRequestStatusX.fromDb(status.dbValue),
          status,
        );
      }
    });

    test('parseFromDb returns unknown for invalid value', () {
      expect(
        PurchaseRequestStatusX.parseFromDb('not_a_status'),
        PurchaseRequestStatus.unknown,
      );
    });

    test('parseFromDb returns draft for valid value', () {
      expect(
        PurchaseRequestStatusX.parseFromDb('draft'),
        PurchaseRequestStatus.draft,
      );
    });

    test('unknown status has display name', () {
      expect(
        PurchaseRequestStatus.unknown.displayName,
        'Неизвестный статус',
      );
    });
  });

  group('user_display_utils', () {
    test('pickUserDisplayName prefers short name', () {
      expect(
        pickUserDisplayName(
          shortName: 'Иван',
          fullName: 'Иванов Иван',
          email: 'a@b.c',
        ),
        'Иван',
      );
    });

    test('formatUserDisplayLabel uses fallback', () {
      expect(formatUserDisplayLabel(null), '—');
      expect(formatUserDisplayLabel('  '), '—');
      expect(formatUserDisplayLabel(' Петр '), 'Петр');
    });
  });

  group('resolvePurchaseRequestActions', () {
    const userId = 'user-1';
    const otherId = 'user-2';

    PurchaseRequest request({
      required PurchaseRequestStatus status,
      String createdBy = userId,
      String? assigneeId,
    }) {
      return PurchaseRequest(
        id: 'req-1',
        companyId: 'company-1',
        number: 'ЗП-2026-00001',
        objectId: 'obj-1',
        createdBy: createdBy,
        currentAssigneeId: assigneeId ?? userId,
        status: status,
      );
    }

    PermissionService permissions({Map<String, Map<String, bool>>? grants}) {
      return PermissionService(
        grants ?? const {},
        const User(
          id: userId,
          email: 'user@test.com',
          roleId: 'role-1',
          systemRole: 'user',
        ),
      );
    }

    test('creator can submit draft with create permission', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.draft),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true},
          },
        ),
      );

      expect(actions.canSubmit, isTrue);
      expect(actions.canEditItems, isTrue);
    });

    test('assignee can submit invoices at invoice preparation', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.invoicePreparation),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'prepare_invoice': true},
          },
        ),
      );

      expect(actions.canSubmitInvoices, isTrue);
    });

    test('assignee can approve at approval stage', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.approval),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'approve': true},
          },
        ),
      );

      expect(actions.canApprove, isTrue);
      expect(actions.canReturn, isTrue);
    });

    test('unknown user gets no actions', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.draft),
        currentUserId: null,
        permissions: permissions(),
      );

      expect(actions.canSubmit, isFalse);
      expect(actions.canCancel, isFalse);
    });

    test('creator cannot cancel received request', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.received),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true, 'view_all': true},
          },
        ),
      );

      expect(actions.canCancel, isFalse);
    });

    test('view_all allows cancel by non-creator', () {
      final actions = resolvePurchaseRequestActions(
        request: request(
          status: PurchaseRequestStatus.approval,
          createdBy: otherId,
          assigneeId: otherId,
        ),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'view_all': true},
          },
        ),
      );

      expect(actions.canCancel, isTrue);
      expect(actions.canApprove, isFalse);
    });
  });

  group('purchaseRequestInvoicesReadyForSubmit', () {
    const file = PurchaseRequestFile(
      id: 'f1',
      requestId: 'r1',
      type: 'invoice',
      storagePath: 'path',
      fileName: 'invoice.pdf',
    );

    const invoiceWithFile = PurchaseRequestInvoice(
      id: 'i1',
      requestId: 'r1',
      companyId: 'c1',
      supplierId: 's1',
      amount: 100,
      invoiceFile: file,
    );

    const invoiceWithoutFile = PurchaseRequestInvoice(
      id: 'i2',
      requestId: 'r1',
      companyId: 'c1',
      supplierId: 's1',
      amount: 200,
    );

    test('returns false when list is empty', () {
      expect(purchaseRequestInvoicesReadyForSubmit([]), isFalse);
    });

    test('returns true when every invoice has file', () {
      expect(
        purchaseRequestInvoicesReadyForSubmit([invoiceWithFile]),
        isTrue,
      );
    });

    test('returns false when any invoice lacks file', () {
      expect(
        purchaseRequestInvoicesReadyForSubmit([
          invoiceWithFile,
          invoiceWithoutFile,
        ]),
        isFalse,
      );
    });
  });
}
