import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';

part 'splash_controller.g.dart';

/// Контроллер экрана заставки (Splash Screen).
///
/// Отвечает за инициализацию приложения, проверку авторизации
/// и предварительную загрузку необходимых данных.
@riverpod
class SplashController extends _$SplashController {
  @override
  String build() {
    return "Инициализация...";
  }

  /// Запускает процесс инициализации приложения.
  ///
  /// [navigate] - функция обратного вызова для навигации после завершения инициализации.
  Future<void> initApp(void Function(String route) navigate) async {
    // Хелпер для гарантированной задержки
    // Запускает работу work() и ждет минимум duration времени
    Future<void> step(String text, Future<void> Function() work,
        {int ms = 1000}) async {
      state = text;
      // Запускаем таймер
      final minWait = Future.delayed(Duration(milliseconds: ms));
      // Запускаем работу (безопасно)
      final workTask = _safeRun(work);

      // Ждем завершения ОБОИХ процессов
      await Future.wait([minWait, workTask]);
    }

    try {
      // 1. Старт (визуальная пауза)
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Авторизация
      await step("Проверка авторизации...", () async {
        // Инициируем проверку (на случай если она не запустилась сама)
        ref.read(authProvider.notifier).checkAuthStatus();

        // Ждем РЕАЛЬНОГО завершения проверки
        // Цикл проверяет статус каждые 100мс
        for (int i = 0; i < 100; i++) {
          // Ждем до 10 секунд (на случай очень медленного интернета)
          final s = ref.read(authProvider).status;
          // Если статус изменился с начальных на конкретный - выходим
          if (s != AuthStatus.initial && s != AuthStatus.loading) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
      });

      final authState = ref.read(authProvider);
      // Если после ожидания всё еще не авторизован или ошибка - идем на логин
      if (authState.status != AuthStatus.authenticated ||
          authState.user == null) {
        navigate('/login');
        return;
      }

      // 3. Профиль
      await step("Загрузка профиля...", () async {
        await ref
            .read(currentUserProfileProvider.notifier)
            .getCurrentUserProfile(authState.user!.id);
      });

      // 4. Фоновые загрузки справочников (без блокировки UI)
      state = "Подготовка данных...";
      unawaited(_prefetchData());

      // 5. Финал
      await Future.delayed(const Duration(milliseconds: 300));
      navigate('/home');
    } catch (e) {
      state = "Ошибка: $e";
      debugPrint("Splash Error: $e");
      // В случае критической ошибки безопаснее отправить на логин
      // navigate('/login');
    }
  }

  // Фоновая предзагрузка справочников без блокировки основного потока навигации.
  Future<void> _prefetchData() async {
    try {
      await Future.wait([
        ref.read(employeeProvider.notifier).getEmployees(
              includeResponsibilityMap: false,
            ),
        ref.read(estimateNotifierProvider.notifier).loadEstimates(),
        ref.read(workPlanNotifierProvider.notifier).loadWorkPlans(),
        ref.read(contractorProvider.notifier).loadContractors(),
        ref.read(contractProvider.notifier).loadContracts(),
      ]);
    } catch (e) {
      // Проглатываем, чтобы не мешать запуску; ошибки будут обработаны при явной загрузке экранов
      debugPrint("Splash prefetch warning: $e");
    }
  }

  // Обертка, чтобы ошибка в загрузке не ломала весь процесс
  Future<void> _safeRun(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint("Splash load warning: $e");
    }
  }
}
