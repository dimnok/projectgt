import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Утилиты для работы с UI элементами
class UIUtils {
  /// Запускает URL во внешнем приложении (браузер, почта, телефон)
  static Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Создает стандартную декорацию для полей ввода
  static InputDecoration createInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffix,
    String? errorText,
    BorderRadius? borderRadius,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffix: suffix,
      border: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.black,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  /// Создает стандартную кнопку для приложения
  static ButtonStyle createButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.withValues(alpha: 0.3);
        }
        return backgroundColor ?? Colors.black;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        }
        return foregroundColor ?? Colors.white;
      }),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      padding: WidgetStateProperty.all<EdgeInsets>(
        padding ??
            const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
      ),
    );
  }
}
