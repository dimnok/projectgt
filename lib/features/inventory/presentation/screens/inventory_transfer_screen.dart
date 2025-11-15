import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран передачи/выдачи ТМЦ.
class InventoryTransferScreen extends ConsumerWidget {
  /// Создаёт экран передачи/выдачи ТМЦ.
  const InventoryTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: AppBarWidget(
        title: 'Передача / Выдача ТМЦ',
        leading: BackButton(),
        showThemeSwitch: false,
      ),
      body: Center(
        child: Text('Передача / Выдача ТМЦ'),
      ),
    );
  }
}
