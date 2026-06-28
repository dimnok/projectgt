import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_html/html.dart' as html;

import 'package:projectgt/data/services/fcm_device_info.dart';

/// Собирает метаданные браузера / PWA для Web.
Future<FcmDeviceMetadata> collectFcmDeviceMetadata() async {
  final ua = html.window.navigator.userAgent;
  final standalone = _isStandalonePwa();
  final appVersion = await _readAppVersion();

  return FcmDeviceMetadata(
    deviceModel: _webDeviceLabel(ua, standalone: standalone),
    osVersion: _webOsVersion(ua),
    appVersion: appVersion,
  );
}

bool _isStandalonePwa() {
  return html.window.matchMedia('(display-mode: standalone)').matches ||
      html.window.matchMedia('(display-mode: fullscreen)').matches;
}

Future<String?> _readAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  } catch (_) {
    return null;
  }
}

/// Человекочитаемая подпись: «Safari PWA (iPhone)», «Chrome (Windows)».
String _webDeviceLabel(String userAgent, {required bool standalone}) {
  final browser = _detectBrowser(userAgent);
  final formFactor = _detectFormFactor(userAgent);
  final pwa = standalone ? ' PWA' : '';

  if (formFactor != null) {
    return '$browser$pwa ($formFactor)';
  }
  return '$browser$pwa';
}

String _detectBrowser(String ua) {
  final lower = ua.toLowerCase();
  if (lower.contains('edg/')) return 'Edge';
  if (lower.contains('opr/') || lower.contains('opera')) return 'Opera';
  if (lower.contains('firefox/')) return 'Firefox';
  if (lower.contains('crios/')) return 'Chrome';
  if (lower.contains('chrome/') && !lower.contains('edg/')) return 'Chrome';
  if (lower.contains('safari/') && !lower.contains('chrome/')) return 'Safari';
  return 'Browser';
}

String? _detectFormFactor(String ua) {
  final lower = ua.toLowerCase();
  if (lower.contains('iphone')) return 'iPhone';
  if (lower.contains('ipad')) return 'iPad';
  if (lower.contains('android') && lower.contains('mobile')) return 'Android';
  if (lower.contains('android')) return 'Android tablet';
  if (lower.contains('windows')) return 'Windows';
  if (lower.contains('mac os x') || lower.contains('macintosh')) {
    return 'macOS';
  }
  if (lower.contains('linux')) return 'Linux';
  return null;
}

String? _webOsVersion(String ua) {
  final formFactor = _detectFormFactor(ua);
  if (formFactor == 'iPhone' || formFactor == 'iPad') {
    final match = RegExp(r'OS (\d+[._]\d+(?:[._]\d+)?)').firstMatch(ua);
    if (match != null) {
      return 'iOS ${match.group(1)!.replaceAll('_', '.')}';
    }
    return 'iOS';
  }
  if (formFactor != null && formFactor.startsWith('Android')) {
    final match = RegExp(r'Android (\d+(?:\.\d+)*)').firstMatch(ua);
    if (match != null) return 'Android ${match.group(1)}';
    return 'Android';
  }
  if (formFactor == 'Windows') {
    final match = RegExp(r'Windows NT (\d+\.\d+)').firstMatch(ua);
    if (match != null) return 'Windows NT ${match.group(1)}';
    return 'Windows';
  }
  if (formFactor == 'macOS') {
    final match = RegExp(r'Mac OS X (\d+[._]\d+(?:[._]\d+)?)').firstMatch(ua);
    if (match != null) {
      return 'macOS ${match.group(1)!.replaceAll('_', '.')}';
    }
    return 'macOS';
  }
  return formFactor;
}
