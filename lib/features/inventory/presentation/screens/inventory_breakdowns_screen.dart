import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран поломок, утрат и ремонта ТМЦ.
class InventoryBreakdownsScreen extends ConsumerWidget {
  /// Создаёт экран поломок/утрат.
  const InventoryBreakdownsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: AppBarWidget(
        title: 'Поломки / Утраты / Ремонт',
        leading: BackButton(),
        showThemeSwitch: false,
      ),
      body: Center(
        child: Text('Поломки / Утраты / Ремонт'),
      ),
    );
  }
}
