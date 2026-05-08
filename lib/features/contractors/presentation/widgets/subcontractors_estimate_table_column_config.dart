import 'package:flutter/material.dart';

import 'package:projectgt/domain/entities/estimate.dart';

/// Границы визуального блока «подрядчик» (колонки кол-во / цена / сумма и план-факт).
enum SubcontractorTableBlockEdge {
  /// Вне блока подрядчика.
  none,

  /// Левая граница блока.
  start,

  /// Внутренняя часть блока.
  inner,

  /// Правая граница блока.
  end,
}

/// Описание одной колонки таблицы подрядчиков (заголовок, выравнивание, ячейка).
class SubcontractorColumnConfig {
  /// Создаёт конфигурацию колонки.
  const SubcontractorColumnConfig({
    required this.title,
    required this.builder,
    this.headerAlign = TextAlign.left,
    this.cellAlignment = Alignment.centerLeft,
    this.flex = 1,
    this.minWidth,
    this.isFlexible = false,
    this.measureText,
    this.headerBuilder,
    this.isSubcontractorBlock = false,
    this.subBlockEdge = SubcontractorTableBlockEdge.none,
  });

  /// Текст заголовка; совпадает с ключами в ячейках итогов (например «Сумма»).
  final String title;

  /// Если задан, подменяет текст заголовка (например иконка вместо [title]).
  final Widget Function(ThemeData theme)? headerBuilder;

  /// Содержимое ячейки строки данных.
  final Widget Function(Estimate estimate, ThemeData theme) builder;

  /// Выравнивание текста в заголовке.
  final TextAlign headerAlign;

  /// Выравнивание содержимого ячейки.
  final Alignment cellAlignment;

  /// Вес колонки среди гибких.
  final double flex;

  /// Минимальная ширина при расчёте [TableColumnWidth].
  final double? minWidth;

  /// Если true, колонка забирает остаток ширины таблицы.
  final bool isFlexible;

  /// Текст для замера ширины колонки (все строки [widget.items]).
  final String? Function(Estimate)? measureText;

  /// Колонка входит в визуальный блок подрядчика (заливка/рамка).
  final bool isSubcontractorBlock;

  /// Сторона рамки блока подрядчика в заголовке/ячейке.
  final SubcontractorTableBlockEdge subBlockEdge;
}
