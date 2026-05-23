import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Политика доступности модулей в зависимости от платформы и ширины экрана.
///
/// Модули с табличным UI ([desktopOnlyModuleIds]) недоступны на нативных
/// iOS/Android и на web/PWA при ширине меньше [ResponsiveUtils.desktopBreakpoint].
abstract final class AppModuleAvailability {
  /// Идентификаторы модулей (RBAC `module`), доступных только в «десктопной» оболочке.
  static const Set<String> desktopOnlyModuleIds = {
    'materials',
    'cash_flow',
    'export',
  };

  static const Map<String, String> _pathToModuleId = {
    '/material': 'materials',
    '/cash_flow': 'cash_flow',
    '/export': 'export',
  };

  static const Map<String, String> _moduleTitles = {
    'materials': 'Материалы',
    'cash_flow': 'Cash Flow',
    'export': 'Выгрузка',
  };

  /// Возвращает `true`, если модуль помечен как desktop-only.
  static bool isDesktopOnlyModule(String moduleId) =>
      desktopOnlyModuleIds.contains(moduleId);

  /// Человекочитаемое название модуля для экранов-заглушек.
  static String moduleTitle(String moduleId) =>
      _moduleTitles[moduleId] ?? moduleId;

  /// Определяет RBAC-модуль по пути маршрута ([GoRouter.matchedLocation]).
  static String? moduleIdForPath(String path) {
    final normalized = path.split('?').first;
    for (final entry in _pathToModuleId.entries) {
      if (normalized == entry.key ||
          normalized.startsWith('${entry.key}/')) {
        return entry.value;
      }
    }
    return null;
  }

  /// Можно ли открыть модуль на текущем устройстве и при текущей ширине.
  static bool canOpenModule(String moduleId, BuildContext context) {
    if (!isDesktopOnlyModule(moduleId)) return true;
    return hasDesktopModuleShell(context);
  }

  /// Достаточно ли «десктопной» оболочки для табличных модулей.
  static bool hasDesktopModuleShell(BuildContext context) {
    if (_isNativeHandheld) return false;
    return MediaQuery.sizeOf(context).width >=
        ResponsiveUtils.desktopBreakpoint;
  }

  static bool get _isNativeHandheld {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
