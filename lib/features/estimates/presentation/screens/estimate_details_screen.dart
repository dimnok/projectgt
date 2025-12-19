import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'estimate_desktop_view.dart';
import 'estimate_mobile_view.dart';

/// Экран для отображения детальной информации о смете.
class EstimateDetailsScreen extends ConsumerWidget {
  /// Название сметы для отображения (используется в мобильном режиме).
  final String? estimateTitle;

  /// ID объекта (для корректной работы фильтров и создания позиций).
  final String? objectId;

  /// ID договора (для корректной работы фильтров и создания позиций).
  final String? contractId;

  /// Флаг отображения AppBar (зарезервирован для будущих сценариев).
  final bool showAppBar;

  const EstimateDetailsScreen({
    super.key,
    this.estimateTitle,
    this.objectId,
    this.contractId,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    if (isLargeScreen) {
      return const EstimateDesktopView();
    }
    return EstimateMobileView(
      estimateTitle: estimateTitle,
      objectId: objectId,
      contractId: contractId,
      showAppBar: showAppBar,
    );
  }
}
