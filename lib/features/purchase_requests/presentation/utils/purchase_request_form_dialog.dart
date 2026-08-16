import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Показывает компактную форму модуля заявок: диалог на desktop, лист на mobile.
///
/// [title] — заголовок окна.
/// [bodyBuilder] — содержимое формы.
/// [footerBuilder] — кнопки действий; [dialogContext] нужен для закрытия окна.
/// [width] — ширина desktop-диалога.
Future<T?> showPurchaseRequestFormDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext dialogContext) bodyBuilder,
  required Widget Function(BuildContext dialogContext) footerBuilder,
  double width = 480,
}) {
  if (ResponsiveUtils.isDesktop(context)) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: title,
          width: width,
          child: bodyBuilder(dialogContext),
          footer: footerBuilder(dialogContext),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) => MobileBottomSheetContent(
      title: title,
      child: bodyBuilder(dialogContext),
      footer: footerBuilder(dialogContext),
    ),
  );
}
