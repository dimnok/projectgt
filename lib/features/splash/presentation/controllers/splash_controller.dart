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

      // 4. Сотрудники
      await step("Загрузка сотрудников...", () async {
        await ref.read(employeeProvider.notifier).getEmployees();
      });

      // 5. Планы и Сметы
      await step("Загрузка планов и смет...", () async {
        await Future.wait([
          ref.read(estimateNotifierProvider.notifier).loadEstimates(),
          ref.read(workPlanNotifierProvider.notifier).loadWorkPlans(),
        ]);
      });

      // 6. Справочники
      await step("Загрузка материалов...", () async {
        await Future.wait([
          ref.read(contractorProvider.notifier).loadContractors(),
          ref.read(contractProvider.notifier).loadContracts(),
        ]);
      });

      // 7. Финал
      state = "Загрузка главной...";
      await Future.delayed(const Duration(milliseconds: 500));

      navigate('/home');
    } catch (e) {
      state = "Ошибка: $e";
      debugPrint("Splash Error: $e");
      // В случае критической ошибки безопаснее отправить на логин
      // navigate('/login');
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
