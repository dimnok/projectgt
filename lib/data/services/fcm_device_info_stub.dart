import 'package:package_info_plus/package_info_plus.dart';

import 'package:projectgt/data/services/fcm_device_info.dart';

/// Заглушка для платформ без поддержки сбора метаданных устройства.
Future<FcmDeviceMetadata> collectFcmDeviceMetadata() async {
  final appVersion = await _readAppVersion();
  return FcmDeviceMetadata(appVersion: appVersion);
}

Future<String?> _readAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  } catch (_) {
    return null;
  }
}
