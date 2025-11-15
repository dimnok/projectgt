import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран инвентаризации ТМЦ.
class InventoryInventoryScreen extends ConsumerWidget {
  /// Создаёт экран инвентаризации.
  const InventoryInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: AppBarWidget(
        title: 'Инвентаризация',
        leading: BackButton(),
        showThemeSwitch: false,
      ),
      body: Center(
        child: Text('Инвентаризация'),
      ),
    );
  }
}
