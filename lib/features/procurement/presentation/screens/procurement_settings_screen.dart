import 'package:flutter/material.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/procurement/presentation/widgets/procurement_settings_panel.dart';

/// Экран настроек согласования заявок на закупку.
///
/// Позволяет настроить ответственных лиц для каждого этапа согласования.
/// Использует [ProcurementSettingsPanel] для отображения контента.
class ProcurementSettingsScreen extends StatelessWidget {
  /// Создаёт экран настроек согласования заявок.
  const ProcurementSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(title: 'Настройки согласования заявок'),
      body: ProcurementSettingsPanel(
        styleAsPanel: false,
        showTitle: false,
      ),
    );
  }
}
