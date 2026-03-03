import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет для отображения реестра актов КС-2.
///
/// Позволяет отслеживать финансовое актирование работ, привязанных к смете.
class ActsTableView extends ConsumerWidget {
  /// Идентификатор договора.
  final String contractId;

  /// Поисковый запрос.
  final String searchQuery;

  /// Создает экземпляр [ActsTableView].
  const ActsTableView({
    super.key,
    required this.contractId,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Реестр актов КС-2',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Раздел находится в разработке. Здесь будет отображаться список финансовых актов.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
