import 'package:flutter/material.dart';

/// Виджет для мастер-детейл представления на больших экранах.
///
/// Разделяет экран на две части: слева список (мастер), справа детали.
class MasterDetailLayout extends StatelessWidget {
  /// Ширина мастер-панели (левая часть).
  final double masterWidth;
  
  /// Виджет для отображения в мастер-панели (список).
  final Widget masterPanel;
  
  /// Виджет для отображения в детейл-панели (детали выбранного элемента).
  final Widget detailPanel;
  
  /// Создает мастер-детейл представление.
  ///
  /// [masterWidth] - ширина мастер-панели (по умолчанию 570).
  /// [masterPanel] - виджет для отображения в мастер-панели (список).
  /// [detailPanel] - виджет для отображения в детейл-панели (детали).
  const MasterDetailLayout({
    super.key,
    this.masterWidth = 570,
    required this.masterPanel,
    required this.detailPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Мастер-панель (список)
        SizedBox(
          width: masterWidth,
          child: masterPanel,
        ),
        // Детейл-панель (детали выбранного элемента)
        Expanded(
          child: detailPanel,
        ),
      ],
    );
  }
} 