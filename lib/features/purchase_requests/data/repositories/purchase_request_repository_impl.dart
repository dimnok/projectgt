import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/data/models/purchase_request_models.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_company_user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_list_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/domain/repositories/purchase_request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Реализация [PurchaseRequestRepository] через Supabase.
class PurchaseRequestRepositoryImpl implements PurchaseRequestRepository {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Активная компания.
  final String activeCompanyId;

  /// Создаёт репозиторий.
  PurchaseRequestRepositoryImpl(this.client, this.activeCompanyId);

  bool get _hasCompany => activeCompanyId.isNotEmpty;

  static const _requestsTable = 'purchase_requests';
  static const _itemsTable = 'purchase_request_items';
  static const _historyTable = 'purchase_request_history';
  static const _settingsTable = 'purchase_request_settings';

  static const _requestSelect = '*, objects:object_id(name)';

  PurchaseRequest _mapRequest(dynamic row) =>
      PurchaseRequestModel.fromJson(Map<String, dynamic>.from(row as Map))
          .toDomain();

  @override
  Future<List<PurchaseRequestListItem>> list({
    required PurchaseRequestListFilter filter,
    String? search,
    String? objectId,
    PurchaseRequestStatus? status,
    String? createdBy,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_hasCompany) return [];

    final response = await client.rpc(
      'purchase_request_list',
      params: {
        'p_company_id': activeCompanyId,
        'p_filter': filter.rpcValue,
        'p_search': search,
        'p_object_id': objectId,
        'p_status': status?.dbValue,
        'p_created_by': createdBy,
        'p_from_date': fromDate != null ? dateOnlyToJson(fromDate) : null,
        'p_to_date': toDate != null ? dateOnlyToJson(toDate) : null,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    final rows = response as List;
    return rows
        .map(
          (row) => PurchaseRequestListItem.fromRpcRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<PurchaseRequest?> getRequest(String id) async {
    if (!_hasCompany || id.isEmpty) return null;

    final row = await client
        .from(_requestsTable)
        .select(_requestSelect)
        .eq('company_id', activeCompanyId)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return _mapRequest(row);
  }

  @override
  Future<List<PurchaseRequestItem>> getItems(String requestId) async {
    if (!_hasCompany) return [];

    final response = await client
        .from(_itemsTable)
        .select()
        .eq('company_id', activeCompanyId)
        .eq('request_id', requestId)
        .order('sort_order')
        .order('created_at');

    return (response as List)
        .map(
          (row) => PurchaseRequestItemModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<List<PurchaseRequestHistoryEntry>> getHistory(String requestId) async {
    if (!_hasCompany) return [];

    final response = await client
        .from(_historyTable)
        .select()
        .eq('company_id', activeCompanyId)
        .eq('request_id', requestId)
        .order('created_at');

    return (response as List)
        .map(
          (row) => PurchaseRequestHistoryEntry.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<PurchaseRequestSettings?> getSettings() async {
    if (!_hasCompany) return null;

    final row = await client
        .from(_settingsTable)
        .select()
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (row == null) return null;
    return PurchaseRequestSettingsModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<List<PurchaseRequestCompanyUser>> getCompanyUsers() async {
    if (!_hasCompany) return [];

    final rows = await client.rpc(
      'purchase_request_company_users',
      params: {'p_company_id': activeCompanyId},
    );

    return (rows as List)
        .map(
          (row) => PurchaseRequestCompanyUser.fromRpcRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<PurchaseRequestSettings> upsertSettings(
    PurchaseRequestSettings settings,
  ) async {
    final response = await client.rpc(
      'purchase_request_upsert_settings',
      params: {
        'p_company_id': activeCompanyId,
        'p_first_approver_id': settings.firstApproverId,
        'p_invoice_preparer_id': settings.invoicePreparerId,
        'p_invoice_approver_id': settings.invoiceApproverId,
        'p_accountant_id': settings.accountantId,
        'p_receiver_mode': settings.receiverMode.dbValue,
        'p_fixed_receiver_id': settings.fixedReceiverId,
      },
    );

    return PurchaseRequestSettingsModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    ).toDomain();
  }

  @override
  Future<String> createDraft({
    required String objectId,
    String? comment,
  }) async {
    final id = await client.rpc(
      'purchase_request_create_draft',
      params: {
        'p_company_id': activeCompanyId,
        'p_object_id': objectId,
        'p_comment': comment,
      },
    );
    return id as String;
  }

  @override
  Future<void> updateHeader({
    required String requestId,
    required String objectId,
    String? comment,
  }) async {
    await client.rpc(
      'purchase_request_update_header',
      params: {
        'p_request_id': requestId,
        'p_object_id': objectId,
        'p_comment': comment,
      },
    );
  }

  @override
  Future<void> deleteDraft(String requestId) async {
    await client.rpc(
      'purchase_request_delete_draft',
      params: {'p_request_id': requestId},
    );
  }

  @override
  Future<PurchaseRequestItem> addItem({
    required String requestId,
    required String name,
    required double quantity,
    required String unit,
    String? comment,
  }) async {
    final row = await client
        .from(_itemsTable)
        .insert({
          'company_id': activeCompanyId,
          'request_id': requestId,
          'name': name,
          'quantity': quantity,
          'unit': unit,
          'comment': comment,
        })
        .select()
        .single();

    return PurchaseRequestItemModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<PurchaseRequestItem> updateItem(PurchaseRequestItem item) async {
    final row = await client
        .from(_itemsTable)
        .update({
          'name': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'comment': item.comment,
          'sort_order': item.sortOrder,
        })
        .eq('company_id', activeCompanyId)
        .eq('id', item.id)
        .select()
        .single();

    return PurchaseRequestItemModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await client
        .from(_itemsTable)
        .delete()
        .eq('company_id', activeCompanyId)
        .eq('id', itemId);
  }

  @override
  Future<PurchaseRequest> submit(String requestId, {String? comment}) async {
    final row = await client.rpc(
      'purchase_request_submit',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> approve(String requestId, {String? comment}) async {
    final row = await client.rpc(
      'purchase_request_approve',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> returnForRevision(
    String requestId, {
    required String comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_return',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> submitInvoices(String requestId) async {
    final row = await client.rpc(
      'purchase_request_submit_invoices',
      params: {'p_request_id': requestId},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> approveInvoice(
    String requestId, {
    String? comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_approve_invoice',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> returnInvoice(
    String requestId, {
    required String comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_return_invoice',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> queuePayment(
    String requestId, {
    String? comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_queue_payment',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> markPaid(
    String requestId, {
    DateTime? paymentDate,
    String? comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_mark_paid',
      params: {
        'p_request_id': requestId,
        'p_payment_date':
            paymentDate != null ? dateOnlyToJson(paymentDate) : null,
        'p_comment': comment,
      },
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> markReceived(
    String requestId, {
    DateTime? receivedDate,
    String? comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_mark_received',
      params: {
        'p_request_id': requestId,
        'p_received_date':
            receivedDate != null ? dateOnlyToJson(receivedDate) : null,
        'p_comment': comment,
      },
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> cancel(
    String requestId, {
    required String comment,
  }) async {
    final row = await client.rpc(
      'purchase_request_cancel',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }
}
