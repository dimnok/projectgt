import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Позиция отображения минималистичного снекбара.
enum AppSnackBarPosition {
  /// Сверху экрана.
  top,

  /// Снизу экрана.
  bottom,
}

/// Тип сообщения для цветовых схем.
enum AppSnackBarKind {
  /// Нейтральное сообщение (по умолчанию).
  neutral,

  /// Успешная операция.
  success,

  /// Ошибка.
  error,

  /// Предупреждение.
  warning,

  /// Информационное сообщение.
  info,
}

/// Минималистичный снекбар через Overlay.
///
/// Теперь каждый вызов создаёт отдельный блок (как тост); несколько вызовов
/// подряд выстраиваются столбцом и исчезают по таймеру по очереди.
class AppSnackBar {
  static final Map<AppSnackBarPosition, _OverlayBucket> _buckets = {};
  static final Map<String, Timer> _timers = {};

  /// Показывает снекбар/тост.
  static void show({
    required BuildContext context,
    required String message,
    AppSnackBarPosition position = AppSnackBarPosition.bottom,
    Duration duration = const Duration(milliseconds: 2400),
    double borderRadius = 22,
    Color? backgroundColor,
    Color? foregroundColor,
    AppSnackBarKind kind = AppSnackBarKind.neutral,
    IconData? icon,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  }) {
    final bucket = _ensureOverlay(context, position);
    if (bucket == null) return;

    final (bg, fg) = _resolveColors(
      Theme.of(context).colorScheme,
      kind,
      backgroundColor,
      foregroundColor,
    );

    final resolvedIcon = icon ?? _resolveIcon(kind);

    final id = UniqueKey().toString();
    final data = _ToastData(
      id: id,
      message: message,
      borderRadius: borderRadius,
      backgroundColor: bg,
      foregroundColor: fg,
      padding: padding,
      icon: resolvedIcon,
    );

    bucket.items.value = [...bucket.items.value, data];

    _timers[id]?.cancel();
    _timers[id] = Timer(duration, () => _removeById(position, id));
  }

  /// Принудительно скрывает все снекбары.
  static void hide() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final bucket in _buckets.values) {
      bucket.entry.remove();
      bucket.items.dispose();
    }
    _buckets.clear();
  }

  static void _removeById(AppSnackBarPosition position, String id) {
    final bucket = _buckets[position];
    if (bucket == null) return;
    _timers.remove(id)?.cancel();
    final updated = bucket.items.value.where((e) => e.id != id).toList();
    if (updated.isEmpty) {
      bucket.entry.remove();
      bucket.items.dispose();
      _buckets.remove(position);
    } else {
      bucket.items.value = updated;
    }
  }

  static _OverlayBucket? _ensureOverlay(
    BuildContext context,
    AppSnackBarPosition position,
  ) {
    final existing = _buckets[position];
    if (existing != null) return existing;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final items = ValueNotifier<List<_ToastData>>([]);
    final entry = OverlayEntry(
      builder: (ctx) => _ToastStack(
        items: items,
        position: position,
      ),
    );

    overlay.insert(entry);
    final bucket = _OverlayBucket(entry: entry, items: items);
    _buckets[position] = bucket;
    return bucket;
  }

  static (Color, Color) _resolveColors(
    ColorScheme scheme,
    AppSnackBarKind kind,
    Color? bgOverride,
    Color? fgOverride,
  ) {
    // Цвета фиксированы: успех-зелёный, ошибка-красный, предупреждение-жёлтый, инфо-синий.
    Color bg;
    Color fg;
    switch (kind) {
      case AppSnackBarKind.success:
        bg = const Color(0xFF1B5E20); // deep green
        fg = Colors.white;
      case AppSnackBarKind.error:
        bg = const Color(0xFFB71C1C); // deep red
        fg = Colors.white;
      case AppSnackBarKind.warning:
        bg = const Color(0xFFF9A825); // amber/yellow
        fg = Colors.black;
      case AppSnackBarKind.info:
        bg = const Color(0xFF1565C0); // blue
        fg = Colors.white;
      case AppSnackBarKind.neutral:
        bg = scheme.inverseSurface.withValues(alpha: 0.94);
        fg = scheme.onInverseSurface;
    }

    if (bgOverride != null) bg = bgOverride;
    if (fgOverride != null) fg = fgOverride;
    return (bg, fg);
  }

  static IconData? _resolveIcon(AppSnackBarKind kind) {
    switch (kind) {
      case AppSnackBarKind.success:
        return CupertinoIcons.checkmark_circle;
      case AppSnackBarKind.error:
        return CupertinoIcons.xmark_octagon;
      case AppSnackBarKind.warning:
        return CupertinoIcons.exclamationmark_triangle;
      case AppSnackBarKind.info:
        return CupertinoIcons.info_circle;
      case AppSnackBarKind.neutral:
        return null;
    }
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack({
    required this.items,
    required this.position,
  });

  final ValueNotifier<List<_ToastData>> items;
  final AppSnackBarPosition position;

  @override
  Widget build(BuildContext context) {
    final isTop = position == AppSnackBarPosition.top;
    final alignment = isTop ? Alignment.topCenter : Alignment.bottomCenter;
    return IgnorePointer(
      child: SafeArea(
        top: isTop,
        bottom: !isTop,
        minimum: const EdgeInsets.symmetric(vertical: 12),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ValueListenableBuilder<List<_ToastData>>(
                valueListenable: items,
                builder: (context, list, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        _ToastCard(
                          key: ValueKey(list[i].id),
                          data: list[i],
                          isTop: isTop,
                        ),
                        if (i != list.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    super.key,
    required this.data,
    required this.isTop,
  });

  final _ToastData data;
  final bool isTop;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    final beginOffset =
        widget.isTop ? const Offset(0, -1.1) : const Offset(0, 1.1);
    _offset = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = widget.data.backgroundColor ??
        colorScheme.inverseSurface.withValues(alpha: 0.94);
    final textColor =
        widget.data.foregroundColor ?? colorScheme.onInverseSurface;

    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(widget.data.borderRadius),
              border: Border.all(
                color: colorScheme.onInverseSurface.withValues(alpha: 0.08),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: widget.data.padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.data.icon != null) ...[
                    Icon(
                      widget.data.icon,
                      color: textColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.data.message,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayBucket {
  _OverlayBucket({required this.entry, required this.items});

  final OverlayEntry entry;
  final ValueNotifier<List<_ToastData>> items;
}

class _ToastData {
  _ToastData({
    required this.id,
    required this.message,
    required this.borderRadius,
    required this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  });

  final String id;
  final String message;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
}
