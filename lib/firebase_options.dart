// GENERATED via MCP (not using flutterfire CLI)
// Provides FirebaseOptions for all supported platforms.

// ignore_for_file: constant_identifier_names

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

/// Конфигурационные опции Firebase для разных платформ.
///
/// Предоставляет настройки Firebase для Web, Android и iOS платформ.
/// Автоматически выбирает подходящую конфигурацию в зависимости от текущей платформы.
class DefaultFirebaseOptions {
  /// Приватный конструктор для предотвращения создания экземпляров.
  const DefaultFirebaseOptions._();

  /// Возвращает конфигурацию Firebase для текущей платформы.
  ///
  /// Автоматически определяет платформу (Web, iOS, Android)
  /// и возвращает соответствующую конфигурацию.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (Platform.isIOS) return ios;
    if (Platform.isAndroid) return android;
    throw UnsupportedError('Unsupported platform for Firebase initialization');
  }

  /// Конфигурация Firebase для Web платформы.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCopDZnRXf5E4WrIqBAWtQnYcj5Ky3ETpc',
    appId: '1:229844296884:web:758b5f5eaf1738ca8923e1',
    messagingSenderId: '229844296884',
    projectId: 'pgtmess',
    authDomain: 'pgtmess.firebaseapp.com',
    storageBucket: 'pgtmess.firebasestorage.app',
    measurementId: 'G-HER9D5YNCF',
  );

  /// Конфигурация Firebase для Android платформы.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDy4uLoVMBu5lNL5wrcAx3msPJ9WI0ZYRQ',
    appId: '1:229844296884:android:d810cb7e64189b228923e1',
    messagingSenderId: '229844296884',
    projectId: 'pgtmess',
    storageBucket: 'pgtmess.firebasestorage.app',
  );

  /// Конфигурация Firebase для iOS платформы.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAK6AuAPqzsg9lb_0ROfgiPiyj5fxQCCjc',
    appId: '1:229844296884:ios:a40f894d9e8335ca8923e1',
    messagingSenderId: '229844296884',
    projectId: 'pgtmess',
    storageBucket: 'pgtmess.firebasestorage.app',
    iosBundleId: 'dev.projectgt.projectgt',
  );
}
