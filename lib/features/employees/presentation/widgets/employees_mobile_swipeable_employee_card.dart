import 'package:flutter/material.dart';
import 'package:projectgt/core/navigation/app_route_observer.dart';

/// Обёртка над карточкой сотрудника: свайп влево — «Объекты», вправо — «Статус».
///
/// Подложка и боковые панели — [ColorScheme.surfaceContainerHigh]; панели расширены
/// на [cornerRadius] к центру карточки со скруглением к внешнему краю — без щелей
/// у углов карточки.
///
/// Смещение сбрасывается при перекрытии страницы другим маршрутом или модалкой
/// ([RouteAware]), при изменении [listSwipeResetEpoch] (например, начало скролла списка),
/// при паузе приложения и при отключении [enabled].
class EmployeesMobileSwipeableEmployeeCard extends StatefulWidget {
  /// Создаёт свайп-карточку.
  const EmployeesMobileSwipeableEmployeeCard({
    super.key,
    required this.child,
    this.enabled = true,
    required this.onObjectsPressed,
    this.onStatusPressed,
    this.actionExtent = 76,
    this.cornerRadius = 16,
    this.listSwipeResetEpoch = 0,
  });

  /// Карточка сотрудника (содержимое, которое сдвигается).
  final Widget child;

  /// Если `false`, жесты отключены (карточка ведёт себя как обычный [child]).
  final bool enabled;

  /// Вызывается при нажатии на действие «Объекты» (панель предварительно закрывается).
  final VoidCallback onObjectsPressed;

  /// Выбор статуса; если `null`, свайп вправо отключён.
  final VoidCallback? onStatusPressed;

  /// Ширина выезжающей панели действий (с каждой стороны).
  final double actionExtent;

  /// Скругление общего клипа (как у карточки).
  final double cornerRadius;

  /// Счётчик из родителя: при увеличении панель свайпа закрывается (скролл списка и т.п.).
  final int listSwipeResetEpoch;

  @override
  State<EmployeesMobileSwipeableEmployeeCard> createState() =>
      _EmployeesMobileSwipeableEmployeeCardState();
}

class _EmployeesMobileSwipeableEmployeeCardState
    extends State<EmployeesMobileSwipeableEmployeeCard>
    with RouteAware, WidgetsBindingObserver {
  /// Смещение foreground: отрицательное — «Объекты», положительное — «Статус».
  double _offset = 0;

  PageRoute<dynamic>? _subscribedPageRoute;

  double get _maxLeft => -widget.actionExtent;

  double get _maxRight =>
      widget.onStatusPressed != null ? widget.actionExtent : 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      if (_subscribedPageRoute != route) {
        if (_subscribedPageRoute != null) {
          appRouteObserver.unsubscribe(this);
        }
        _subscribedPageRoute = route;
        appRouteObserver.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    if (_subscribedPageRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _closePanel();
    }
  }

  @override
  void didPushNext() {
    _closePanel();
  }

  @override
  void didPopNext() {
    _closePanel();
  }

  @override
  void didUpdateWidget(
    covariant EmployeesMobileSwipeableEmployeeCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.listSwipeResetEpoch != oldWidget.listSwipeResetEpoch) {
      _offset = 0;
    }
    if (!widget.enabled && oldWidget.enabled) {
      _offset = 0;
    } else if (widget.onStatusPressed == null &&
        oldWidget.onStatusPressed != null &&
        _offset > 0) {
      _offset = 0;
    }
  }

  void _setOffset(double value) {
    if (!widget.enabled) return;
    setState(() {
      _offset = value.clamp(_maxLeft, _maxRight);
    });
  }

  void _closePanel() {
    if (_offset == 0) return;
    setState(() => _offset = 0);
  }

  void _onObjectsTap() {
    _closePanel();
    widget.onObjectsPressed();
  }

  void _onStatusTap() {
    _closePanel();
    widget.onStatusPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final panelColor = scheme.surfaceContainerHigh;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(child: ColoredBox(color: panelColor)),
          if (widget.onStatusPressed != null)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: widget.actionExtent + widget.cornerRadius,
              child: Material(
                color: panelColor,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(widget.cornerRadius),
                    bottomRight: Radius.circular(widget.cornerRadius),
                  ),
                ),
                child: InkWell(
                  onTap: _onStatusTap,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(widget.cornerRadius),
                    bottomRight: Radius.circular(widget.cornerRadius),
                  ),
                  child: Semantics(
                    button: true,
                    label: 'Статус сотрудника',
                    child: Row(
                      children: [
                        SizedBox(
                          width: widget.actionExtent,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 22,
                                  color: scheme.onSurface,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Статус',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: widget.cornerRadius),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: widget.actionExtent + widget.cornerRadius,
            child: Material(
              color: panelColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.cornerRadius),
                  bottomLeft: Radius.circular(widget.cornerRadius),
                ),
              ),
              child: InkWell(
                onTap: _onObjectsTap,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.cornerRadius),
                  bottomLeft: Radius.circular(widget.cornerRadius),
                ),
                child: Semantics(
                  button: true,
                  label: 'Объекты сотрудника',
                  child: Row(
                    children: [
                      SizedBox(width: widget.cornerRadius),
                      SizedBox(
                        width: widget.actionExtent,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment_outlined,
                                size: 22,
                                color: scheme.onSurface,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Объекты',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              _setOffset(_offset + details.delta.dx);
            },
            onHorizontalDragEnd: (details) {
              final vx = details.velocity.pixelsPerSecond.dx;
              final extent = widget.actionExtent;
              final hasStatus = widget.onStatusPressed != null;

              if (vx < -300) {
                _setOffset(_maxLeft);
                return;
              }
              if (vx > 300) {
                if (hasStatus) {
                  _setOffset(_maxRight);
                } else {
                  _setOffset(0);
                }
                return;
              }

              if (_offset <= -extent / 2) {
                _setOffset(_maxLeft);
              } else if (hasStatus && _offset >= extent / 2) {
                _setOffset(_maxRight);
              } else {
                _setOffset(0);
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
