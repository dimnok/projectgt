import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/data/subcontractor_margin_dashboard_data_source.dart';
import 'package:projectgt/features/contractors/domain/entities/subcontractor_margin_dashboard_row.dart';

/// Плановая сводка по сметам и расценкам суб (RPC [get_subcontractor_margin_dashboard]).
final subcontractorMarginDashboardProvider =
    FutureProvider.autoDispose<List<SubcontractorMarginDashboardRow>>((
      ref,
    ) async {
      final companyId = ref.watch(activeCompanyIdProvider);
      if (companyId == null || companyId.isEmpty) {
        return const [];
      }
      final client = ref.watch(supabaseClientProvider);
      final dataSource = SubcontractorMarginDashboardDataSource(client);
      return dataSource.fetchRows(companyId);
    });
