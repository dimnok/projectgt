import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:projectgt/features/settlements/data/models/settlement_operation_model.dart';
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
    final response = await client
        .from(_table)
        .select('invoice_number')
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .order('invoice_date', ascending: false)
        .limit(500);

    int max = 0;
    String? prefix;
    for (final row in response as List) {
      final raw = row['invoice_number'];
      if (raw is! String) continue;
      final parsed = _trailingNumber(raw);
      if (parsed == null) continue;
      final n = parsed.value;
      if (n > max) {
        max = n;
        prefix = parsed.prefix;
      }
    }
    return '${prefix ?? ''}${max + 1}';
  }

  /// Разбивает номер на префикс и завершающую группу цифр.
  /// 'сч-13' → (prefix='сч-', 13), '217-3' → (prefix='217-', 3), '2' → ('', 2).
  static _ParsedNumber? _trailingNumber(String value) {
    final match = RegExp(r'(\d+)\s*$').firstMatch(value);
    if (match == null) return null;
    final n = int.tryParse(match.group(1)!);
    if (n == null) return null;
    final prefix = value.substring(0, match.start);
    return _ParsedNumber(prefix, n);
  }
}

class _ParsedNumber {
  final String prefix;
  final int value;

  const _ParsedNumber(this.prefix, this.value);
}
