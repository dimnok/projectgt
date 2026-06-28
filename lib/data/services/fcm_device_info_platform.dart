export 'fcm_device_info_stub.dart'
    if (dart.library.io) 'fcm_device_info_native.dart'
    if (dart.library.html) 'fcm_device_info_web.dart';
