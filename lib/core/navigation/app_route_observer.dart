import 'package:flutter/material.dart';

/// Глобальный наблюдатель маршрутов для [RouteAware]-виджетов (например, сброс UI при перекрытии экрана модалкой).
///
/// Передаётся в `GoRouter(observers: …)`, чтобы [RouteAware.didPushNext] / [RouteAware.didPopNext]
/// вызывались для страниц, когда поверх открывают bottom sheet, диалог или другой маршрут.
///
/// Используется [PageRoute<dynamic>], а не [PageRoute<Object?>]: у страниц GoRouter часто
/// тип результата `void`, и проверка `is PageRoute<Object?>` не срабатывает — подписка
/// на [RouteAware] не выполнялась.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
