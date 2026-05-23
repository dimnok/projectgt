import 'package:flutter/material.dart';

/// Отступы и сетка экрана «Материалы» (согласованы с модулем «Договоры»).
abstract final class MaterialsListScreenChrome {
  /// Единый горизонтальный шаг экрана.
  static const double gridGutter = 16;

  /// Шапка: меню, заголовок, действия.
  static const EdgeInsets headerOuterPadding = EdgeInsets.fromLTRB(
    gridGutter,
    20,
    gridGutter,
    8,
  );

  /// Тело: таблица материалов.
  static const EdgeInsets bodyOuterPadding = EdgeInsets.fromLTRB(
    gridGutter,
    0,
    gridGutter,
    10,
  );

  /// Ширина полей фильтров «Объект» / «Договор».
  static const double filterFieldWidth = 232;
}
