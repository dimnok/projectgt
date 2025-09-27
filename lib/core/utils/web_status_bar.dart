// Платформо-специфичная реализация: для Web используем web-версию,
// для остальных платформ — пустые заглушки (no-op).
export 'web_status_bar_stub.dart'
    if (dart.library.html) 'web_status_bar_web.dart';
