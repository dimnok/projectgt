import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_selected_contractor_provider.dart';

/// Данные из `estimate_contractor_prices` для строки сметы при выбранном подрядчике.
@immutable
class SubcontractorPricingForEstimate {
  /// Создаёт значения для отображения в таблице.
  const SubcontractorPricingForEstimate({
    this.unitPrice,
    this.contractorQuantity,
  });

  /// Цена подрядчика за ед.
  final double? unitPrice;

  /// Объём, отнесённый подрядчику.
  final double? contractorQuantity;
}

/// Строки `estimate_contractor_prices` для выбранного подрядчика и компании.
///
/// Ключ — `estimate_id`. Пустая карта, если подрядчик не выбран.
final subcontractorsContractorUnitPricesProvider =
    FutureProvider.autoDispose<Map<String, SubcontractorPricingForEstimate>>((
      ref,
    ) async {
      final companyId = ref.watch(activeCompanyIdProvider);
      final contractorId = ref.watch(
        subcontractorsSelectedContractorIdProvider,
      );
      if (companyId == null || contractorId == null || contractorId.isEmpty) {
        return {};
      }

      final client = ref.watch(supabaseClientProvider);
      final response = await client
          .from('estimate_contractor_prices')
          .select('estimate_id, unit_price, contractor_quantity')
          .eq('company_id', companyId)
          .eq('contractor_id', contractorId);

      final map = <String, SubcontractorPricingForEstimate>{};
      for (final row in response as List<dynamic>) {
        final id = row['estimate_id'] as String?;
        if (id == null) continue;
        final up = row['unit_price'];
        final cq = row['contractor_quantity'];
        map[id] = SubcontractorPricingForEstimate(
          unitPrice: up == null ? null : (up as num).toDouble(),
          contractorQuantity: cq == null ? null : (cq as num).toDouble(),
        );
      }
      return map;
    });
