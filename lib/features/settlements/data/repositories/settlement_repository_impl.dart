import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:projectgt/features/settlements/data/models/settlement_operation_model.dart';
import 'package:projectgt/features/settlements/data/models/settlement_payment_model.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Реализация [SettlementRepository] через Supabase.
class SettlementRepositoryImpl implements SettlementRepository {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Активная компания (пустая строка — запросы не выполняются).
  final String activeCompanyId;

  /// Создаёт репозиторий.
  SettlementRepositoryImpl(this.client, this.activeCompanyId);

  static const _table = 'settlement_operations';
  static const _paymentsTable = 'settlement_payments';

  static const _select = '''
    *,
    objects:object_id(name),
    contractors:contractor_id(short_name),
    contracts:contract_id(number)
  ''';

  @override
  Future<List<SettlementOperation>> getOperations({String? contractId}) async {
    if (activeCompanyId.isEmpty) return [];

    var query = client
        .from(_table)
        .select(_select)
        .eq('company_id', activeCompanyId);

    if (contractId != null && contractId.isNotEmpty) {
      query = query.eq('contract_id', contractId);
    }

    final response = await query.order('invoice_date', ascending: false);

    return (response as List)
        .map(
          (row) => SettlementOperationModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<SettlementOperation?> getOperation(String id) async {
    if (activeCompanyId.isEmpty || id.isEmpty) return null;

    final row = await client
        .from(_table)
        .select(_select)
        .eq('company_id', activeCompanyId)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;

    return SettlementOperationModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<SettlementOperation> createOperation(
    SettlementOperation operation,
  ) async {
    final model = SettlementOperationModel.fromDomain(operation);
    final payload = model.toWriteJson(includeId: false);
    payload['company_id'] = activeCompanyId;

    final row = await client
        .from(_table)
        .insert(payload)
        .select(_select)
        .single();

    return SettlementOperationModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<SettlementOperation> updateOperation(
    SettlementOperation operation,
  ) async {
    final model = SettlementOperationModel.fromDomain(operation);
    final payload = model.toWriteJson(includeId: false);

    final row = await client
        .from(_table)
        .update(payload)
        .eq('id', operation.id)
        .eq('company_id', activeCompanyId)
        .select(_select)
        .single();

    return SettlementOperationModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<void> deleteOperation(String id) async {
    await client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
  }

  @override
  Future<String> getNextInvoiceNumber(String contractId) async {
    if (activeCompanyId.isEmpty || contractId.isEmpty) return '1';

    final response = await client.rpc(
      'get_next_settlement_invoice_number',
      params: {
        'p_company_id': activeCompanyId,
        'p_contract_id': contractId,
      },
    );

    final next = response?.toString();
    if (next == null || next.isEmpty) return '1';
    return next;
  }

  @override
  Future<List<SettlementPayment>> getPayments(
    String settlementOperationId,
  ) async {
    if (activeCompanyId.isEmpty || settlementOperationId.isEmpty) {
      return [];
    }

    final response = await client
        .from(_paymentsTable)
        .select()
        .eq('company_id', activeCompanyId)
        .eq('settlement_operation_id', settlementOperationId)
        .order('payment_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => SettlementPaymentModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<SettlementPayment> createPayment(SettlementPayment payment) async {
    final model = SettlementPaymentModel.fromDomain(payment);
    final payload = model.toWriteJson(includeId: false);
    payload['company_id'] = activeCompanyId;

    final row = await client
        .from(_paymentsTable)
        .insert(payload)
        .select()
        .single();

    return SettlementPaymentModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<SettlementPayment> updatePayment(SettlementPayment payment) async {
    final model = SettlementPaymentModel.fromDomain(payment);
    final payload = model.toUpdateJson();

    final row = await client
        .from(_paymentsTable)
        .update(payload)
        .eq('id', payment.id)
        .eq('company_id', activeCompanyId)
        .select()
        .single();

    return SettlementPaymentModel.fromJson(
      Map<String, dynamic>.from(row),
    ).toDomain();
  }

  @override
  Future<void> deletePayment(String id) async {
    await client
        .from(_paymentsTable)
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
  }
}
