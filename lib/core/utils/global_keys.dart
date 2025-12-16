import 'package:flutter/material.dart';

/// Глобальный ключ для корневого ScaffoldMessenger, чтобы показывать SnackBar
/// поверх любых Hero/модалок и избежать вложенности Hero.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
