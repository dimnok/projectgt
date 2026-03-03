import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'refresh_models.dart';

/// Координатор автоматического обновления данных при возврате приложения в фокус.
/// 
/// Позволяет регистрировать цели [RefreshTarget], которые будут автоматически 
/// обновляться (через callback) при возврате пользователя в приложение, 
/// если истекло время TTL (по умолчанию 5 минут).
class AppFocusRefreshCoordinator extends StateNotifier<RefreshState> {
  final Ref _ref;
  final Map<String, RefreshTarget> _targets = {};

  /// Создает координатор обновления.
  AppFocusRefreshCoordinator(this._ref) : super(const RefreshState());

  /// Регистрирует новую цель для обновления.
  /// 
  /// Если цель с таким [target.id] уже существует, она будет перезаписана.
  void registerTarget(RefreshTarget target) {
    _targets[target.id] = target;
  }

  /// Удаляет регистрацию цели по её [id].
  void unregisterTarget(String id) {
    if (!_targets.containsKey(id)) return;
    
    _targets.remove(id);
    
    // Обновляем состояние асинхронно, чтобы избежать ошибок при вызове из dispose()
    Future.microtask(() {
      if (!mounted) return;

      final newLastRun = Map<String, DateTime>.from(state.lastRunByTargetUtc);
      newLastRun.remove(id);
      
      final newVisibleIds = Set<String>.from(state.visibleTargetIds);
      newVisibleIds.remove(id);

      state = state.copyWith(
        lastRunByTargetUtc: newLastRun,
        visibleTargetIds: newVisibleIds,
      );
    });
  }

  /// Помечает цель как видимую или скрытую.
  /// 
  /// Используется для целей с флагом `visibleOnly: true`. 
  /// Обновление таких целей будет запущено только если они помечены как видимые.
  void markTargetVisible(String id, bool visible) {
    // Обновляем состояние асинхронно, так как это может вызываться во время сборки кадра
    Future.microtask(() {
      if (!mounted) return;
      
      final newVisibleIds = Set<String>.from(state.visibleTargetIds);
      if (visible) {
        newVisibleIds.add(id);
      } else {
        newVisibleIds.remove(id);
      }
      state = state.copyWith(visibleTargetIds: newVisibleIds);
    });
  }

  /// Обрабатывает событие возврата приложения из фонового режима (или перехода в фокус).
  /// 
  /// Проверяет все зарегистрированные цели, соблюдает их TTL и visibleOnly ограничения.
  /// Предотвращает параллельный запуск нескольких циклов обновления.
  Future<void> handleAppResumed() async {
    // Защита от параллельного запуска
    if (state.isRefreshing) return;

    final nowUtc = DateTime.now().toUtc();
    state = state.copyWith(
      isRefreshing: true,
      lastAppResumeAtUtc: nowUtc,
    );

    try {
      final startTime = DateTime.now();
      
      // Отбираем цели, которые требуют обновления
      final targetsToRefresh = _targets.values.where((target) {
        if (!target.enabled) return false;
        
        // Если цель требует видимости, проверяем, помечена ли она как видимая
        if (target.visibleOnly && !state.visibleTargetIds.contains(target.id)) {
          return false;
        }

        final lastRun = state.lastRunByTargetUtc[target.id];
        // Если еще ни разу не запускалось, значит нужно запустить
        if (lastRun == null) return true;

        // Проверяем, прошло ли достаточно времени (TTL)
        return nowUtc.difference(lastRun) >= target.ttl;
      }).toList();

      // Сортируем цели: сначала те, что сейчас видимы (priority)
      targetsToRefresh.sort((a, b) {
        final aVisible = state.visibleTargetIds.contains(a.id) ? 1 : 0;
        final bVisible = state.visibleTargetIds.contains(b.id) ? 1 : 0;
        return bVisible.compareTo(aVisible);
      });

      final newLastRun = Map<String, DateTime>.from(state.lastRunByTargetUtc);
      int refreshedCount = 0;

      // Последовательно запускаем callback для каждой цели
      for (final target in targetsToRefresh) {
        // Проверяем, не была ли цель удалена во время выполнения предыдущих callback-ов
        if (!_targets.containsKey(target.id)) continue;

        try {
          // Выполняем обновление через предоставленный callback
          await target.callback(_ref);
          
          // Проверяем еще раз после await
          if (!_targets.containsKey(target.id)) continue;

          // Обновляем время последнего успешного запуска
          newLastRun[target.id] = nowUtc;
          refreshedCount++;
        } catch (e) {
          // Ошибка в одной цели не должна прерывать обновление остальных
          // В продакшене здесь можно добавить логирование в Sentry/Firebase
        }
      }

      final endTime = DateTime.now();
      state = state.copyWith(
        lastRunByTargetUtc: newLastRun,
        isRefreshing: false,
        lastRefreshDuration: endTime.difference(startTime),
        lastRefreshedCount: refreshedCount,
      );
    } finally {
      // Гарантированно сбрасываем флаг refreshing
      if (mounted) {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }
}

/// Провайдер координатора обновления данных при фокусе.
final appFocusRefreshProvider =
    StateNotifierProvider<AppFocusRefreshCoordinator, RefreshState>((ref) {
  return AppFocusRefreshCoordinator(ref);
});
