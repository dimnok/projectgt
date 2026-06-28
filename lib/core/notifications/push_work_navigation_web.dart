import 'package:universal_html/html.dart' as html;

import 'package:projectgt/core/notifications/push_work_navigation.dart';

/// Слушает сообщения service worker о клике по push-уведомлению.
void setupWebPushNavigationListener(void Function(String workId) onWorkId) {
  html.window.onMessage.listen((event) {
    final raw = event.data;
    if (raw is! Map) return;
    if (raw['type'] != 'notification_navigate') return;

    final url = raw['url'];
    if (url is! String || url.isEmpty) return;

    final workId = extractWorkIdFromPushUri(Uri.parse(url));
    if (workId != null && workId.isNotEmpty) {
      onWorkId(workId);
    }
  });
}

/// Убирает `?work_id=` из адресной строки после перехода в приложении.
void clearPushWorkQueryFromUrl() {
  final uri = Uri.base;
  if (!uri.queryParameters.containsKey(pushWorkIdQueryParam)) return;

  final cleanPath = uri.path.isEmpty ? '/' : uri.path;
  html.window.history.replaceState(null, '', cleanPath);
}
