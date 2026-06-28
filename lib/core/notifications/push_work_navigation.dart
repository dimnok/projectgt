/// Имя query-параметра с ID смены в URL push-уведомления.
const pushWorkIdQueryParam = 'work_id';

/// URL для клика по push на Web/PWA: всегда открывает главную страницу приложения.
String buildPushWorkLaunchUrl(String workId) {
  return '/?$pushWorkIdQueryParam=$workId';
}

/// Извлекает ID смены из URL, открытого по push (query или legacy `/works/:id`).
String? extractWorkIdFromPushUri(Uri uri) {
  final fromQuery = uri.queryParameters[pushWorkIdQueryParam];
  if (fromQuery != null && fromQuery.isNotEmpty) {
    return fromQuery;
  }

  final segments = uri.pathSegments;
  if (segments.length >= 2 && segments.first == 'works') {
    return segments[1];
  }

  return null;
}
