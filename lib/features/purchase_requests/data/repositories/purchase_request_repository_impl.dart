import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/user_display_utils.dart';
import 'package:projectgt/features/purchase_requests/data/models/purchase_request_models.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_repository_exception.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_company_user.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_invoice.dart';
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

  void _requireCompany() {
    if (!_hasCompany) {
      throw const PurchaseRequestCompanyRequiredException();
    }
  }

  static const _requestsTable = 'purchase_requests';
  static const _itemsTable = 'purchase_request_items';
  static const _historyTable = 'purchase_request_history';
  static const _settingsTable = 'purchase_request_settings';
  static const _invoicesTable = 'purchase_request_invoices';
  static const _filesTable = 'purchase_request_files';

  static const _requestSelect = '*, objects:object_id(name)';

  PurchaseRequest _mapRequest(dynamic row) => PurchaseRequestModel.fromJson(
    Map<String, dynamic>.from(row as Map),
  ).toDomain();

  Future<String?> _fetchCreatedByName(String userId) async {
    final names = await _fetchUserNames({userId});
    return names[userId];
  }

  String? _pickProfileName(Map<String, dynamic> profile) =>
      pickProfileDisplayName(profile);

  Future<Map<String, String>> _fetchUserNames(Set<String> userIds) async {
    if (userIds.isEmpty) return {};

    final response = await client
        .from('profiles')
        .select('id, short_name, full_name, email')
        .inFilter('id', userIds.toList());

    final names = <String, String>{};
    for (final row in response as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id'] as String?;
      final name = _pickProfileName(map);
      if (id != null && name != null) {
        names[id] = name;
      }
    }
    return names;
  }

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

    final map = Map<String, dynamic>.from(row);
    final createdBy = map['created_by'] as String?;
    if (createdBy != null && createdBy.isNotEmpty) {
      final createdByName = await _fetchCreatedByName(createdBy);
      if (createdByName != null) {
        map['created_by_name'] = createdByName;
      }
    }

    return _mapRequest(map);
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

    final rows = (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    final userIds = rows
        .map((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet();
    final userNames = await _fetchUserNames(userIds);

    return rows.map((row) {
      final userId = row['user_id'] as String?;
      if (userId != null) {
        final name = userNames[userId];
        if (name != null) {
          row['user_name'] = name;
        }
      }
      return PurchaseRequestHistoryEntry.fromJson(row);
    }).toList();
  }

  @override
  Future<List<PurchaseRequestInvoice>> getInvoices(String requestId) async {
    if (!_hasCompany) return [];

    final invoiceRows = await client
        .from(_invoicesTable)
        .select('*, contractors:supplier_id(short_name, full_name)')
        .eq('company_id', activeCompanyId)
        .eq('request_id', requestId)
        .order('created_at');

    final fileRows = await client
        .from(_filesTable)
        .select()
        .eq('company_id', activeCompanyId)
        .eq('request_id', requestId)
        .eq('type', 'invoice');

    final filesByInvoice = <String, PurchaseRequestFileModel>{};
    for (final row in fileRows as List) {
      final model = PurchaseRequestFileModel.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      final invoiceId = model.invoiceId;
      if (invoiceId != null && !filesByInvoice.containsKey(invoiceId)) {
        filesByInvoice[invoiceId] = model;
      }
    }

    return (invoiceRows as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final invoice = PurchaseRequestInvoiceModel.fromJson(map);
      final file = filesByInvoice[invoice.id];
      return invoice.copyWithFile(file).toDomain();
    }).toList();
  }

  @override
  Future<PurchaseRequestInvoice> createInvoiceWithFile({
    required String requestId,
    required String supplierId,
    required double amount,
    required List<int> fileBytes,
    required String fileName,
    String? invoiceNumber,
    DateTime? invoiceDate,
    String? comment,
  }) async {
    _requireCompany();

    final userId = client.auth.currentUser?.id;
    final invoiceRow = await client
        .from(_invoicesTable)
        .insert({
          'company_id': activeCompanyId,
          'request_id': requestId,
          'supplier_id': supplierId,
          'amount': amount,
          'invoice_number': invoiceNumber,
          'invoice_date': invoiceDate != null
              ? dateOnlyToJson(invoiceDate)
              : null,
          'comment': comment,
          if (userId != null) 'created_by': userId,
        })
        .select('*, contractors:supplier_id(short_name, full_name)')
        .single();

    final invoiceMap = Map<String, dynamic>.from(invoiceRow);
    final invoiceId = invoiceMap['id'] as String;

    try {
      final fileModel = await _uploadInvoiceFile(
        requestId: requestId,
        invoiceId: invoiceId,
        bytes: fileBytes,
        fileName: fileName,
      );
      final invoice = PurchaseRequestInvoiceModel.fromJson(invoiceMap);
      return invoice.copyWithFile(fileModel).toDomain();
    } catch (_) {
      await client
          .from(_invoicesTable)
          .delete()
          .eq('company_id', activeCompanyId)
          .eq('id', invoiceId);
      rethrow;
    }
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    _requireCompany();

    final files = await client
        .from(_filesTable)
        .select('storage_path')
        .eq('company_id', activeCompanyId)
        .eq('invoice_id', invoiceId);

    final paths = (files as List)
        .map((row) => (row as Map)['storage_path'] as String?)
        .whereType<String>()
        .toList();

    await client
        .from(_invoicesTable)
        .delete()
        .eq('company_id', activeCompanyId)
        .eq('id', invoiceId);

    await _removeStoragePaths(paths);
  }

  @override
  Future<List<int>> downloadInvoiceFile(String storagePath) async {
    _requireCompany();
    if (!storagePath.startsWith('$activeCompanyId/')) {
      throw ArgumentError('Некорректный путь файла счёта');
    }

    final bytes = await client.storage
        .from(purchaseRequestsStorageBucket)
        .download(storagePath);
    return bytes;
  }

  Future<PurchaseRequestFileModel> _uploadInvoiceFile({
    required String requestId,
    required String invoiceId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _buildSafeStorageFileName(fileName);
    final storagePath =
        '$activeCompanyId/$requestId/invoices/$invoiceId/${timestamp}_$safeName';

    var uploaded = false;
    try {
      await client.storage
          .from(purchaseRequestsStorageBucket)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: _contentTypeForFileName(fileName),
            ),
          );
      uploaded = true;

      final userId = client.auth.currentUser?.id;
      final row = await client
          .from(_filesTable)
          .insert({
            'company_id': activeCompanyId,
            'request_id': requestId,
            'invoice_id': invoiceId,
            'type': 'invoice',
            'storage_path': storagePath,
            'file_name': fileName,
            'mime_type': _contentTypeForFileName(fileName),
            'size': bytes.length,
            if (userId != null) 'uploaded_by': userId,
          })
          .select()
          .single();

      return PurchaseRequestFileModel.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      if (uploaded) {
        await _removeStoragePaths([storagePath]);
      }
      rethrow;
    }
  }

  Future<void> _removeStoragePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await client.storage.from(purchaseRequestsStorageBucket).remove(paths);
    } catch (error, stackTrace) {
      developer.log(
        'Не удалось удалить файлы заявок из Storage: $paths',
        name: 'PurchaseRequestRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static String _buildSafeStorageFileName(String fileName) {
    return fileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
  }

  static String _contentTypeForFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/octet-stream',
    };
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
    _requireCompany();
    if (settings.companyId != activeCompanyId) {
      throw ArgumentError(
        'companyId настроек не совпадает с активной компанией',
      );
    }

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
    _requireCompany();
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
    _requireCompany();
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
    _requireCompany();
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
    String? article,
    String? comment,
  }) async {
    _requireCompany();
    final row = await client
        .from(_itemsTable)
        .insert({
          'company_id': activeCompanyId,
          'request_id': requestId,
          'name': name,
          'quantity': quantity,
          'unit': unit,
          'article': article,
          'comment': comment,
        })
        .select()
        .single();

    return PurchaseRequestItemModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<void> deleteItem(String itemId) async {
    _requireCompany();
    await client
        .from(_itemsTable)
        .delete()
        .eq('company_id', activeCompanyId)
        .eq('id', itemId);
  }

  @override
  Future<PurchaseRequestItem> updateItem(PurchaseRequestItem item) async {
    _requireCompany();
    final row = await client
        .from(_itemsTable)
        .update({
          'name': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'article': item.article,
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
  Future<PurchaseRequest> submit(String requestId, {String? comment}) async {
    _requireCompany();
    final row = await client.rpc(
      'purchase_request_submit',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> approve(String requestId, {String? comment}) async {
    _requireCompany();
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
    _requireCompany();
    final row = await client.rpc(
      'purchase_request_return',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }

  @override
  Future<PurchaseRequest> submitInvoices(String requestId) async {
    _requireCompany();
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
    _requireCompany();
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
    _requireCompany();
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
    _requireCompany();
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
    _requireCompany();
    final row = await client.rpc(
      'purchase_request_mark_paid',
      params: {
        'p_request_id': requestId,
        'p_payment_date': paymentDate != null
            ? dateOnlyToJson(paymentDate)
            : null,
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
    _requireCompany();
    final row = await client.rpc(
      'purchase_request_mark_received',
      params: {
        'p_request_id': requestId,
        'p_received_date': receivedDate != null
            ? dateOnlyToJson(receivedDate)
            : null,
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
    _requireCompany();
    final row = await client.rpc(
      'purchase_request_cancel',
      params: {'p_request_id': requestId, 'p_comment': comment},
    );
    return _mapRequest(row);
  }
}
