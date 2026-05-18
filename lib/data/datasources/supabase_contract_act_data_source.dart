import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/datasources/contract_act_data_source.dart';
import 'package:projectgt/data/models/contract_act_model.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

/// Реализация [ContractActDataSource] через Supabase.
class SupabaseContractActDataSource implements ContractActDataSource {
  /// Клиент Supabase.
  final SupabaseClient _client;

  /// Создаёт источник данных.
  SupabaseContractActDataSource(this._client);

  String _dateOnly(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Future<List<ContractActModel>> listByContract({
    required String contractId,
    required String companyId,
  }) async {
    final rows = await _client
        .from('contract_acts')
        .select()
        .eq('contract_id', contractId)
        .eq('company_id', companyId)
        .order('act_date', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => ContractActModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<ContractActModel> insert({
    required String companyId,
    required String contractId,
    required String title,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required double amount,
    required double vatAmount,
    required double advanceRetention,
    required double warrantyRetention,
    required double otherRetentions,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    final uid = _client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      'company_id': companyId,
      'contract_id': contractId,
      'title': title,
      'number': number,
      'act_date': _dateOnly(actDate),
      'period_from': _dateOnly(periodFrom),
      'period_to': _dateOnly(periodTo),
      'amount': amount,
      'vat_amount': vatAmount,
      'advance_retention': advanceRetention,
      'warranty_retention': warrantyRetention,
      'other_retentions': otherRetentions,
      'note': note,
      'workflow_status': workflowStatus.apiValue,
      'payment_status': paymentStatus.apiValue,
      if (uid != null) 'created_by': uid,
    };

    final inserted = await _client
        .from('contract_acts')
        .insert(payload)
        .select()
        .single();

    return ContractActModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<ContractActModel> updateRow({
    required String id,
    required String companyId,
    required String contractId,
    required String title,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required double amount,
    required double vatAmount,
    required double advanceRetention,
    required double warrantyRetention,
    required double otherRetentions,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'number': number,
      'act_date': _dateOnly(actDate),
      'period_from': _dateOnly(periodFrom),
      'period_to': _dateOnly(periodTo),
      'amount': amount,
      'vat_amount': vatAmount,
      'advance_retention': advanceRetention,
      'warranty_retention': warrantyRetention,
      'other_retentions': otherRetentions,
      'note': note,
      'workflow_status': workflowStatus.apiValue,
      'payment_status': paymentStatus.apiValue,
    };

    final updated = await _client
        .from('contract_acts')
        .update(payload)
        .eq('id', id)
        .eq('company_id', companyId)
        .eq('contract_id', contractId)
        .select()
        .single();

    return ContractActModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> deleteRow({
    required String id,
    required String companyId,
    required String contractId,
  }) async {
    await _client
        .from('contract_acts')
        .delete()
        .eq('id', id)
        .eq('company_id', companyId)
        .eq('contract_id', contractId);
  }
}
