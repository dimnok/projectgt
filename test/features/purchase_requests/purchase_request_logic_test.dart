import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/core/utils/user_display_utils.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_file.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_invoice_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_module_utils.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_actions_bar.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

void main() {
  group('PurchaseRequestStatusX', () {
    test('fromDb maps all workflow statuses', () {
      for (final status in PurchaseRequestStatus.values) {
        if (status == PurchaseRequestStatus.unknown) continue;
        expect(PurchaseRequestStatusX.fromDb(status.dbValue), status);
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
      expect(PurchaseRequestStatus.unknown.displayName, 'Неизвестный статус');
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
    }) {
      return PurchaseRequest(
        id: 'req-1',
        companyId: 'company-1',
        number: 'ЗП-2026-00001',
        objectId: 'obj-1',
        createdBy: createdBy,
        status: status,
      );
    }

    PurchaseRequestSettings routeSettings({
      List<String> firstApprovers = const [userId],
      List<String> invoicePreparers = const [userId],
      List<String> invoiceApprovers = const [userId],
      List<String> accountants = const [userId],
      PurchaseRequestReceiverMode receiverMode =
          PurchaseRequestReceiverMode.initiator,
      List<String> receivers = const [],
    }) {
      return PurchaseRequestSettings(
        companyId: 'company-1',
        firstApproverIds: firstApprovers,
        invoicePreparerIds: invoicePreparers,
        invoiceApproverIds: invoiceApprovers,
        accountantIds: accountants,
        receiverMode: receiverMode,
        fixedReceiverIds: receivers,
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
      expect(actions.canEditDraft, isTrue);
      expect(actions.canDeleteDraft, isTrue);
      expect(actions.canReturn, isFalse);
    });

    test('other user cannot edit or delete someone else draft', () {
      final actions = resolvePurchaseRequestActions(
        request: request(
          status: PurchaseRequestStatus.draft,
          createdBy: otherId,
        ),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true, 'view_all': true},
          },
        ),
      );

      expect(actions.canEditDraft, isFalse);
      expect(actions.canDeleteDraft, isFalse);
      expect(actions.canEditItems, isFalse);
    });

    test('creator cannot edit or delete after draft', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.revision),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true},
          },
        ),
      );

      expect(actions.canEditItems, isTrue);
      expect(actions.canEditDraft, isFalse);
      expect(actions.canDeleteDraft, isFalse);
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
        settings: routeSettings(),
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
        settings: routeSettings(),
      );

      expect(actions.canApprove, isTrue);
      expect(actions.canReturn, isTrue);
    });

    test('second route member can approve', () {
      final actions = resolvePurchaseRequestActions(
        request: request(
          status: PurchaseRequestStatus.approval,
          createdBy: otherId,
        ),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'approve': true},
          },
        ),
        settings: routeSettings(firstApprovers: [otherId, userId]),
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
      expect(actions.canReturn, isFalse);
    });

    test('view_all cannot return submitted request to draft', () {
      final actions = resolvePurchaseRequestActions(
        request: request(
          status: PurchaseRequestStatus.approval,
          createdBy: otherId,
        ),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'view_all': true},
          },
        ),
      );

      expect(actions.canReturn, isFalse);
      expect(actions.canApprove, isFalse);
      expect(actions.hasAny, isFalse);
    });

    test('creator cannot return own submitted request', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.approval),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true, 'approve': true},
          },
        ),
      );

      expect(actions.canReturn, isFalse);
      expect(actions.canApprove, isFalse);
      expect(actions.canEditDraft, isFalse);
    });

    test('non-assignee with approve cannot return', () {
      final actions = resolvePurchaseRequestActions(
        request: request(
          status: PurchaseRequestStatus.approval,
          createdBy: otherId,
        ),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'approve': true},
          },
        ),
        settings: routeSettings(firstApprovers: [otherId]),
      );

      expect(actions.canReturn, isFalse);
      expect(actions.canApprove, isFalse);
    });

    test('creator on revision can edit items and resubmit', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.revision),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true},
          },
        ),
      );

      expect(actions.canEditItems, isTrue);
      expect(actions.canSubmit, isTrue);
      expect(actions.canReturn, isFalse);
      expect(actions.canEditDraft, isFalse);
    });

    test('paid request has no return for creator', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.paid),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true, 'view_all': true},
          },
        ),
      );

      expect(actions.canReturn, isFalse);
      expect(actions.hasAny, isFalse);
    });

    test('received request has no actions for creator', () {
      final actions = resolvePurchaseRequestActions(
        request: request(status: PurchaseRequestStatus.received),
        currentUserId: userId,
        permissions: permissions(
          grants: const {
            'purchase_requests': {'create': true, 'view_all': true},
          },
        ),
      );

      expect(actions.hasAny, isFalse);
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
      expect(purchaseRequestInvoicesReadyForSubmit([invoiceWithFile]), isTrue);
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

  group('isPurchaseRequestInvoiceFilePreviewable', () {
    PurchaseRequestFile file({required String name, String? mimeType}) {
      return PurchaseRequestFile(
        id: 'f1',
        requestId: 'r1',
        type: 'invoice',
        storagePath: 'path',
        fileName: name,
        mimeType: mimeType,
      );
    }

    test('allows pdf and images', () {
      expect(
        isPurchaseRequestInvoiceFilePreviewable(file(name: 'a.pdf')),
        isTrue,
      );
      expect(
        isPurchaseRequestInvoiceFilePreviewable(file(name: 'a.PNG')),
        isTrue,
      );
      expect(
        isPurchaseRequestInvoiceFilePreviewable(
          file(name: 'scan.bin', mimeType: 'image/jpeg'),
        ),
        isTrue,
      );
    });

    test('rejects unknown formats', () {
      expect(
        isPurchaseRequestInvoiceFilePreviewable(file(name: 'a.xlsx')),
        isFalse,
      );
    });
  });

  group('PurchaseRequestUiLabels.idleActionsMessage', () {
    test('describes terminal statuses', () {
      expect(
        PurchaseRequestUiLabels.idleActionsMessage(
          PurchaseRequestStatus.received,
        ),
        'Заявка получена',
      );
      expect(
        PurchaseRequestUiLabels.idleActionsMessage(
          PurchaseRequestStatus.cancelled,
        ),
        'Заявка возвращена в черновик',
      );
      expect(
        PurchaseRequestUiLabels.idleActionsMessage(
          PurchaseRequestStatus.approval,
        ),
        'Ожидает действия ответственного',
      );
    });
  });

  group('PurchaseRequestHistoryEntry.fromJson', () {
    test('keeps null from_status on created action', () {
      final entry = PurchaseRequestHistoryEntry.fromJson({
        'id': 'h1',
        'request_id': 'r1',
        'user_id': 'u1',
        'action': 'created',
        'from_status': null,
        'to_status': 'draft',
        'created_at': '2026-08-16T10:00:00Z',
      });

      expect(entry.fromStatus, isNull);
      expect(entry.toStatus, PurchaseRequestStatus.draft);
    });

    test('maps invalid status to unknown', () {
      final entry = PurchaseRequestHistoryEntry.fromJson({
        'id': 'h2',
        'request_id': 'r1',
        'user_id': 'u1',
        'action': 'submitted',
        'from_status': 'broken',
        'to_status': 'approval',
        'created_at': '2026-08-16T10:00:00Z',
      });

      expect(entry.fromStatus, PurchaseRequestStatus.unknown);
      expect(entry.toStatus, PurchaseRequestStatus.approval);
    });
  });

  group('latestPurchaseRequestReworkComment', () {
    PurchaseRequestHistoryEntry entry({
      required String id,
      required String action,
      String? comment,
      required DateTime createdAt,
    }) {
      return PurchaseRequestHistoryEntry(
        id: id,
        requestId: 'r1',
        userId: 'u1',
        action: action,
        comment: comment,
        createdAt: createdAt,
      );
    }

    test('returns latest non-empty return comment', () {
      final note = latestPurchaseRequestReworkComment([
        entry(
          id: '1',
          action: 'cancelled',
          comment: 'старая',
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        entry(
          id: '2',
          action: 'submitted',
          createdAt: DateTime.utc(2026, 8, 2),
        ),
        entry(
          id: '3',
          action: 'returned',
          comment: 'исправить объект',
          createdAt: DateTime.utc(2026, 8, 3),
        ),
      ]);

      expect(note, 'исправить объект');
    });

    test('returns null when rework comments are empty', () {
      expect(
        latestPurchaseRequestReworkComment([
          entry(
            id: '1',
            action: 'returned',
            comment: '  ',
            createdAt: DateTime.utc(2026, 8, 1),
          ),
        ]),
        isNull,
      );
    });
  });

  group('isPurchaseRequestSettingsConfigured', () {
    test('requires all four route roles', () {
      expect(
        isPurchaseRequestSettingsConfigured(
          const PurchaseRequestSettings(
            companyId: 'c1',
            firstApproverIds: ['u1'],
            invoicePreparerIds: ['u1'],
            invoiceApproverIds: ['u1'],
            accountantIds: ['u1'],
          ),
        ),
        isTrue,
      );
      expect(
        isPurchaseRequestSettingsConfigured(
          const PurchaseRequestSettings(
            companyId: 'c1',
            firstApproverIds: ['u1'],
            invoicePreparerIds: ['u1'],
            invoiceApproverIds: ['u1'],
          ),
        ),
        isFalse,
      );
    });

    test('fixed receiver requires at least one user', () {
      expect(
        isPurchaseRequestSettingsConfigured(
          const PurchaseRequestSettings(
            companyId: 'c1',
            firstApproverIds: ['u1'],
            invoicePreparerIds: ['u1'],
            invoiceApproverIds: ['u1'],
            accountantIds: ['u1'],
            receiverMode: PurchaseRequestReceiverMode.fixedUser,
          ),
        ),
        isFalse,
      );
      expect(
        isPurchaseRequestSettingsConfigured(
          const PurchaseRequestSettings(
            companyId: 'c1',
            firstApproverIds: ['u1'],
            invoicePreparerIds: ['u1'],
            invoiceApproverIds: ['u1'],
            accountantIds: ['u1'],
            receiverMode: PurchaseRequestReceiverMode.fixedUser,
            fixedReceiverIds: ['u2'],
          ),
        ),
        isTrue,
      );
    });
  });

  group('isPurchaseRequestAwaitingUserApproval', () {
    const userId = 'user-1';
    const otherId = 'user-2';

    PurchaseRequestSettings settings({
      List<String> firstApprovers = const [userId],
      List<String> invoiceApprovers = const [userId],
    }) {
      return PurchaseRequestSettings(
        companyId: 'company-1',
        firstApproverIds: firstApprovers,
        invoicePreparerIds: const [userId],
        invoiceApproverIds: invoiceApprovers,
        accountantIds: const [userId],
      );
    }

    test('true for first approver on approval status', () {
      expect(
        isPurchaseRequestAwaitingUserApproval(
          status: PurchaseRequestStatus.approval,
          settings: settings(),
          userId: userId,
        ),
        isTrue,
      );
    });

    test('true for invoice approver on invoice_approval', () {
      expect(
        isPurchaseRequestAwaitingUserApproval(
          status: PurchaseRequestStatus.invoiceApproval,
          settings: settings(invoiceApprovers: [otherId, userId]),
          userId: userId,
        ),
        isTrue,
      );
    });

    test('false for other statuses', () {
      expect(
        isPurchaseRequestAwaitingUserApproval(
          status: PurchaseRequestStatus.invoicePreparation,
          settings: settings(),
          userId: userId,
        ),
        isFalse,
      );
    });

    test('false if user is not in the role', () {
      expect(
        isPurchaseRequestAwaitingUserApproval(
          status: PurchaseRequestStatus.approval,
          settings: settings(firstApprovers: [otherId]),
          userId: userId,
        ),
        isFalse,
      );
    });

    test('false without settings or user', () {
      expect(
        isPurchaseRequestAwaitingUserApproval(
          status: PurchaseRequestStatus.approval,
          settings: null,
          userId: userId,
        ),
        isFalse,
      );
      expect(
        isPurchaseRequestAwaitingUserApproval(
          status: PurchaseRequestStatus.approval,
          settings: settings(),
          userId: '',
        ),
        isFalse,
      );
    });
  });
}
