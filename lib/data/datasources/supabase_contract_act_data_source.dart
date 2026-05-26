import 'package:projectgt/data/datasources/contract_act_data_source.dart';
import 'package:projectgt/data/models/contract_act_line_model.dart';
import 'package:projectgt/data/models/contract_act_model.dart';
import 'package:projectgt/domain/entities/contract_act_kind.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Реализация [ContractActDataSource] через Supabase.
class SupabaseContractActDataSource implements ContractActDataSource {
  /// Клиент Supabase.
  final SupabaseClient _client;

  /// Создаёт источник данных.
  const SupabaseContractActDataSource(this._client);

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
        .select('*, vors(number)')
        .eq('contract_id', contractId)
        .eq('company_id', companyId)
        .order('act_date', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (e) => ContractActModel.fromJsonWithVorJoin(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  @override
  Future<ContractActModel> insert({
    required String companyId,
    required String contractId,
    required ContractActKind actKind,
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
    required ContractActAmountSource amountSource,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
    String? vorId,
    String? excelPath,
  }) async {
    final uid = _client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      'company_id': companyId,
      'contract_id': contractId,
      'act_kind': actKind.apiValue,
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
      'amount_source': amountSource.apiValue,
      'note': note,
      'workflow_status': workflowStatus.apiValue,
      'payment_status': paymentStatus.apiValue,
      if (vorId != null) 'vor_id': vorId,
      if (excelPath != null) 'excel_path': excelPath,
      if (uid != null) 'created_by': uid,
    };

    final inserted = await _client
        .from('contract_acts')
        .insert(payload)
        .select('*, vors(number)')
        .single();

    return ContractActModel.fromJsonWithVorJoin(
      Map<String, dynamic>.from(inserted),
    );
  }

  @override
  Future<ContractActModel> updateStatusesRow({
    required String id,
    required String companyId,
    required String contractId,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    final payload = <String, dynamic>{
      'workflow_status': workflowStatus.apiValue,
      'payment_status': paymentStatus.apiValue,
    };

    final updated = await _client
        .from('contract_acts')
        .update(payload)
        .eq('id', id)
        .eq('company_id', companyId)
        .eq('contract_id', contractId)
        .select('*, vors(number)')
        .single();

    return ContractActModel.fromJsonWithVorJoin(
      Map<String, dynamic>.from(updated),
    );
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
    required ContractActAmountSource amountSource,
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
      'amount_source': amountSource.apiValue,
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
        .select('*, vors(number)')
        .single();

    return ContractActModel.fromJsonWithVorJoin(
      Map<String, dynamic>.from(updated),
    );
  }

  @override
  Future<void> updateExcelPath({
    required String actId,
    required String companyId,
    required String excelPath,
  }) async {
    await _client
        .from('contract_acts')
        .update({'excel_path': excelPath})
        .eq('id', actId)
        .eq('company_id', companyId);
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

  @override
  Future<void> unlinkWorkItems({
    required String actId,
    required String companyId,
  }) async {
    await _client
        .from('work_items')
        .update({'contract_act_id': null})
        .eq('contract_act_id', actId)
        .eq('company_id', companyId);
  }

  @override
  Future<String?> fetchExcelPath({
    required String actId,
    required String companyId,
  }) async {
    final row = await _client
        .from('contract_acts')
        .select('excel_path')
        .eq('id', actId)
        .eq('company_id', companyId)
        .maybeSingle();

    if (row == null) return null;
    return row['excel_path'] as String?;
  }

  @override
  Future<List<ContractActLineModel>> listLinesByActId({
    required String actId,
    required String companyId,
  }) async {
    final rows = await _client
        .from('contract_act_lines')
        .select()
        .eq('contract_act_id', actId)
        .eq('company_id', companyId)
        .order('sort_order');

    return (rows as List<dynamic>)
        .map(
          (e) => ContractActLineModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> updateActLineQuantities({
    required String lineId,
    required String companyId,
    required double quantity,
    required double amount,
    required double backlogQuantity,
    required double currentPeriodQuantity,
  }) async {
    await _client
        .from('contract_act_lines')
        .update({
          'quantity': quantity,
          'amount': amount,
          'backlog_quantity': backlogQuantity,
          'current_period_quantity': currentPeriodQuantity,
        })
        .eq('id', lineId)
        .eq('company_id', companyId);
  }

  @override
  Future<void> clearActExcelPath({
    required String actId,
    required String companyId,
  }) async {
    await _client
        .from('contract_acts')
        .update({'excel_path': null})
        .eq('id', actId)
        .eq('company_id', companyId);
  }

  @override
  Future<void> deleteActLine({
    required String lineId,
    required String companyId,
  }) async {
    await _client
        .from('contract_act_lines')
        .delete()
        .eq('id', lineId)
        .eq('company_id', companyId);
  }

  @override
  Future<ContractVatTerms> fetchContractVatTerms({
    required String contractId,
    required String companyId,
  }) async {
    final row = await _client
        .from('contracts')
        .select('vat_rate, is_vat_included')
        .eq('id', contractId)
        .eq('company_id', companyId)
        .maybeSingle();

    if (row == null) {
      throw Exception('Договор не найден');
    }

    final map = Map<String, dynamic>.from(row as Map);
    final rate = (map['vat_rate'] as num?)?.toDouble() ?? 0.0;
    return ContractVatTerms(
      vatRate: rate,
      isVatIncluded: map['is_vat_included'] as bool? ?? true,
    );
  }
}
