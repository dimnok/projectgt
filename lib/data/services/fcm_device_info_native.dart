import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:projectgt/data/services/fcm_device_info.dart';

/// Собирает метаданные устройства на iOS и Android.
Future<FcmDeviceMetadata> collectFcmDeviceMetadata() async {
  final plugin = DeviceInfoPlugin();
  final appVersion = await _readAppVersion();

  if (Platform.isIOS) {
    final ios = await plugin.iosInfo;
    final model = _iosDisplayName(ios.utsname.machine, ios.name);
    return FcmDeviceMetadata(
      deviceId: ios.identifierForVendor,
      deviceModel: model,
      osVersion: 'iOS ${ios.systemVersion}',
      appVersion: appVersion,
    );
  }

  if (Platform.isAndroid) {
    final android = await plugin.androidInfo;
    final model = _androidDisplayName(android);
    return FcmDeviceMetadata(
      deviceId: android.id,
      deviceModel: model,
      osVersion: 'Android ${android.version.release}',
      appVersion: appVersion,
    );
  }

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

String _iosDisplayName(String machine, String marketingName) {
  if (marketingName.trim().isNotEmpty && marketingName != 'iPhone') {
    return marketingName.trim();
  }
  return machine.trim().isEmpty ? 'iPhone' : machine;
}

String _androidDisplayName(AndroidDeviceInfo android) {
  final brand = android.brand.trim();
  final model = android.model.trim();
  if (brand.isEmpty && model.isEmpty) return 'Android';
  if (brand.isEmpty) return model;
  if (model.isEmpty) return brand;
  if (model.toLowerCase().startsWith(brand.toLowerCase())) return model;
  return '$brand $model';
}
