import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Типы окна подтверждения.
enum GTConfirmationType {
  /// Информационное сообщение.
  info,

  /// Предупреждение.
  warning,

  /// Опасное действие (например, удаление).
  danger,
}

/// Универсальный виджет окна подтверждения для всего проекта.
///
/// Адаптируется под десктоп (диалог по центру) и мобильные устройства (bottom sheet).
/// Использует системные кастомные виджеты [DesktopDialogContent] и [MobileBottomSheetContent].
///
/// Если заданы [emphasisText] и/или [detail], текст вопроса ([message]) отделяется от
/// выделенного блока (имя файла, примечание) — так проще различить смысл и детали.
class GTConfirmationDialog extends StatelessWidget {
  /// Заголовок окна.
  final String title;

  /// Основной текст сообщения.
  final String message;

  /// Строка для выделенного блока (например имя файла). Не смешивается с [message].
  final String? emphasisText;

  /// Дополнительный текст (например примечание к документу), показывается под именем.
  final String? detail;

  /// Текст кнопки подтверждения.
  final String confirmText;

  /// Текст кнопки отмены.
  final String cancelText;

  /// Тип окна, влияющий на акцентный цвет.
  final GTConfirmationType type;

  /// Создаёт виджет окна подтверждения в строгом минималистичном стиле.
  const GTConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.emphasisText,
    this.detail,
    this.confirmText = 'Подтвердить',
    this.cancelText = 'Отмена',
    this.type = GTConfirmationType.info,
  });

  /// Показывает окно подтверждения.
  ///
  /// Возвращает [true], если нажата кнопка подтверждения, и [false] (или null), если отмена.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? emphasisText,
    String? detail,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    GTConfirmationType type = GTConfirmationType.info,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GTConfirmationDialog(
            title: title,
            message: message,
            emphasisText: emphasisText,
            detail: detail,
            confirmText: confirmText,
            cancelText: cancelText,
            type: type,
          ),
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (context) => GTConfirmationDialog(
          title: title,
          message: message,
          emphasisText: emphasisText,
          detail: detail,
          confirmText: confirmText,
          cancelText: cancelText,
          type: type,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final Color accentColor;
    switch (type) {
      case GTConfirmationType.danger:
        accentColor = theme.colorScheme.error;
        break;
      case GTConfirmationType.warning:
        accentColor = Colors.orange.shade700;
        break;
      case GTConfirmationType.info:
        accentColor = theme.colorScheme.primary;
        break;
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildBody(theme),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        width: 500,
        scrollable: false,
        showDividers: false,
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: cancelText,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 12),
            GTPrimaryButton(
              text: confirmText,
              backgroundColor: type == GTConfirmationType.danger
                  ? accentColor
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: title,
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        footer: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: GTPrimaryButton(
                text: confirmText,
                backgroundColor: type == GTConfirmationType.danger
                    ? accentColor
                    : null,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GTSecondaryButton(
                text: cancelText,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
        child: content,
      );
    }
  }

  /// Тело диалога: либо один абзац [message], либо вопрос + карточка с файлом и примечанием.
  Widget _buildBody(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.55,
      letterSpacing: 0.15,
      color: colorScheme.onSurface.withValues(alpha: 0.88),
    );
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    final trimmedEmphasis = emphasisText?.trim();
    final hasEmphasis = trimmedEmphasis != null && trimmedEmphasis.isNotEmpty;
    final trimmedDetail = detail?.trim();
    final hasDetail = trimmedDetail != null && trimmedDetail.isNotEmpty;

    if (!hasEmphasis && !hasDetail) {
      return Text(message, style: bodyStyle);
    }

    BoxDecoration cardDecoration() => BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
        );

    if (!hasEmphasis && hasDetail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: bodyStyle),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Примечание', style: labelStyle),
                const SizedBox(height: 6),
                Text(
                  trimmedDetail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: bodyStyle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Файл', style: labelStyle),
              const SizedBox(height: 6),
              SelectableText(
                trimmedEmphasis!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: colorScheme.onSurface,
                ),
              ),
              if (hasDetail) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                Text('Примечание', style: labelStyle),
                const SizedBox(height: 6),
                Text(
                  trimmedDetail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
