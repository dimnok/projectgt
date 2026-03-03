import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'refresh_models.freezed.dart';

/// Описание цели для автоматического обновления данных.
class RefreshTarget {
  /// Уникальный идентификатор цели.
  final String id;

  /// Интервал обновления (Time To Live). 
  /// Если с последнего обновления прошло больше времени, чем [ttl], 
  /// при возврате в приложение будет запущен [callback].
  final Duration ttl;

  /// Флаг, разрешающий обновление для данной цели.
  final bool enabled;

  /// Если true, обновление будет запускаться только если цель помечена как видимая.
  /// Полезно для тяжелых экранов, которые не нужно обновлять в фоне.
  final bool visibleOnly;

  /// Функция обратного вызова для выполнения обновления.
  final Future<void> Function(Ref ref) callback;

  /// Создает описание цели обновления.
  const RefreshTarget({
    required this.id,
    required this.callback,
    this.ttl = const Duration(minutes: 5),
    this.enabled = true,
    this.visibleOnly = false,
  });
}

/// Состояние системы глобального обновления данных.
@freezed
abstract class RefreshState with _$RefreshState {
  /// Создает состояние обновления.
  const factory RefreshState({
    /// Карта времени последнего успешного запуска обновления для каждой цели (UTC).
    @Default({}) Map<String, DateTime> lastRunByTargetUtc,

    /// Флаг, указывающий на выполнение процесса обновления в данный момент.
    @Default(false) bool isRefreshing,

    /// Время последнего возврата приложения из фонового режима (UTC).
    DateTime? lastAppResumeAtUtc,

    /// Набор ID активных целей, которые считаются видимыми.
    @Default({}) Set<String> visibleTargetIds,

    /// Длительность последнего цикла обновления.
    Duration? lastRefreshDuration,

    /// Количество обновленных целей в последнем цикле.
    @Default(0) int lastRefreshedCount,
  }) = _RefreshState;
}
