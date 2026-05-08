import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/contractors/domain/entities/subcontractor_margin_dashboard_row.dart';

/// Загрузка сводки маржи подрядчиков (RPC [get_subcontractor_margin_dashboard]).
class SubcontractorMarginDashboardDataSource {
  /// Создаёт источник.
  SubcontractorMarginDashboardDataSource(this._client);

  final SupabaseClient _client;

  /// Возвращает строки плановой сводки по сметам для компании.
  Future<List<SubcontractorMarginDashboardRow>> fetchRows(
    String companyId,
  ) async {
    final response =
        await _client.rpc(
              'get_subcontractor_margin_dashboard',
              params: <String, dynamic>{'p_company_id': companyId},
            )
            as List<dynamic>;

    final out = <SubcontractorMarginDashboardRow>[];
    for (final raw in response) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final objectId = raw['object_id'] as String?;
      if (objectId == null) {
        continue;
      }
      final contractorId = raw['contractor_id'] as String?;
      final contractId = raw['contract_id'] as String?;
      final title = raw['estimate_title'] as String? ?? 'Без названия';
      final our = _toDouble(raw['our_amount']);
      final sub = _toDouble(raw['subcontractor_planned_amount']);
      final factOwn = _toDouble(raw['fact_own_amount']);
      final factSubRev = _toDouble(raw['fact_subcontractor_revenue_amount']);
      final factSubCost = _toDouble(raw['fact_subcontractor_cost_amount']);
      final unpriced = raw['unpriced_lines'];
      final unpricedLines = unpriced is int
          ? unpriced
          : (unpriced is num
                ? unpriced.toInt()
                : int.tryParse('$unpriced') ?? 0);
      out.add(
        SubcontractorMarginDashboardRow(
          objectId: objectId,
          contractId: contractId,
          estimateTitle: title,
          contractorId: contractorId,
          ourAmount: our,
          subcontractorPlannedAmount: sub,
          unpricedLines: unpricedLines,
          factOwnAmount: factOwn,
          factSubcontractorRevenueAmount: factSubRev,
          factSubcontractorCostAmount: factSubCost,
        ),
      );
    }
    return out;
  }

  static double _toDouble(Object? v) {
    if (v == null) {
      return 0;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}
