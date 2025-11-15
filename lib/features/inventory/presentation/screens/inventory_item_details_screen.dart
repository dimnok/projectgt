import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран карточки ТМЦ.
class InventoryItemDetailsScreen extends ConsumerWidget {
  /// ID ТМЦ для отображения.
  final String itemId;

  /// Создаёт экран карточки ТМЦ.
  const InventoryItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Карточка ТМЦ',
        leading: BackButton(),
        showThemeSwitch: false,
      ),
      body: Center(
        child: Text('Карточка ТМЦ: $itemId'),
      ),
    );
  }
}

