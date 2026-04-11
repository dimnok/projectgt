import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Адаптивная раскладка модуля «Сотрудники».
///
/// Ширина окна в альбоме на телефоне часто превышает пороги [ResponsiveUtils],
/// из‑за чего ошибочно выбирались таблица и центрированные диалоги. Здесь
/// дополнительно учитывается [Size.shortestSide], чтобы «телефон в любом
/// положении» оставался компактным.
class EmployeesLayoutUtils {
  EmployeesLayoutUtils._();

  /// Мобильный список ([EmployeesListMobileScreen]) вместо таблицы.
  ///
  /// `true`, если короткая сторона окна меньше [ResponsiveUtils.tabletBreakpoint]
  /// (типичный телефон в портрете и в альбоме).
  static bool useEmployeesMobileList(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide <
        ResponsiveUtils.tabletBreakpoint;
  }

  /// Центрированный диалог вместо bottom sheet для форм модуля.
  ///
  /// Требуется и «не телефон по [shortestSide]», и достаточная ширина
  /// ([ResponsiveUtils.desktopBreakpoint]), чтобы на планшете в портрете
  /// по‑прежнему открывался лист снизу при узкой ширине.
  static bool useEmployeesDesktopModal(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < ResponsiveUtils.tabletBreakpoint) {
      return false;
    }
    return size.width >= ResponsiveUtils.desktopBreakpoint;
  }
}
