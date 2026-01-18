import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// imports of specific screens are not needed here because we use AuthGate
import 'package:projectgt/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/profile_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/settings_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/financial_info_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/property_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/users_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/objects/presentation/screens/objects_list_screen.dart';
import 'package:projectgt/features/objects/presentation/screens/object_form_screen.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractors_list_screen.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractor_form_screen.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractor_details_screen.dart';
import 'package:projectgt/features/contracts/presentation/screens/contracts_list_screen.dart';
import 'package:projectgt/features/contracts/presentation/screens/contract_form_screen.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimates_list_screen.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimate_form_screen.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimate_details_screen.dart';
import 'package:projectgt/features/works/presentation/screens/works_master_detail_screen.dart';
import 'package:projectgt/features/works/presentation/screens/work_details_screen.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/presentation/screens/month_details_mobile_screen.dart';
import 'package:projectgt/features/timesheet/presentation/screens/timesheet_screen.dart';
import 'package:projectgt/features/fot/presentation/screens/payroll_list_screen.dart';
import 'package:projectgt/features/export/presentation/screens/export_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/features/materials/presentation/screens/material_screen.dart';
import 'package:projectgt/features/cash_flow/presentation/screens/cash_flow_list_screen.dart';
// Telegram moderation экраны удалены
import 'package:projectgt/core/widgets/auth_gate.dart';
import 'package:projectgt/features/version_control/presentation/force_update_screen.dart';
import 'package:projectgt/features/version_control/presentation/version_management_screen.dart';
import 'package:projectgt/features/roles/presentation/screens/roles_list_screen.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/splash/presentation/screens/splash_screen.dart';
import 'package:projectgt/features/company/presentation/screens/company_screen.dart';

/// Проверяет, может ли пользователь просматривать информацию о конкретном сотруднике.
///
/// Админы могут просматривать всех сотрудников.
/// Обычные пользователи могут просматривать только своего привязанного сотрудника.
bool _canViewEmployee(WidgetRef ref, String employeeId) {
  final service = ref.watch(permissionServiceProvider);

  // Админы (с правом чтения) могут просматривать всех
  if (service.can('employees', 'read')) {
    return true;
  }

  // Обычные пользователи могут просматривать только своего привязанного сотрудника
  final profileState = ref.watch(currentUserProfileProvider);
  final profile = profileState.profile;
  final linkedEmployeeId = profile?.object?['employee_id'] as String?;

  return linkedEmployeeId != null && linkedEmployeeId == employeeId;
}

/// Создаёт экран "Доступ запрещён" для неавторизованных пользователей.
Widget _buildAccessDeniedScreen() {
  return Scaffold(
    appBar: AppBar(title: const Text('Доступ запрещён')),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Недостаточно прав для доступа к данному разделу',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Обратитесь к администратору',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

/// Провайдер маршрутизатора приложения на базе GoRouter.
///
/// Управляет навигацией, авторизацией, доступом к защищённым и административным маршрутам.
/// Использует Riverpod для внедрения зависимостей и состояния авторизации.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Защищаемся от случая, когда hash-токен попадает в path и роутер
      // пытается интерпретировать его как маршрут
      if (loc.startsWith('access_token') || loc.startsWith('/access_token')) {
        // fix bad path
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const AuthGate(),
      ),
      // Маршрут регистрации удалён: используется только OTP-вход через AuthGate
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.company,
        name: 'company',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('company', 'read')) {
                return const CompanyScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final showLogout = extra?['showLogout'] ?? true;
          return OnboardingScreen(showLogout: showLogout);
        },
      ),
      GoRoute(
        path: '${AppRoutes.profile}/complete',
        name: 'profile_complete',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.profile}/notifications',
        name: 'profile_notifications',
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.profile}/settings',
        name: 'profile_settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.profile}/financial',
        name: 'profile_financial',
        builder: (context, state) => const FinancialInfoScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.profile}/property',
        name: 'profile_property',
        builder: (context, state) => const PropertyScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.profile}/:userId',
        name: 'user_profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.users,
        name: 'users',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('users', 'read')) {
                return const UsersListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для списка сотрудников
      GoRoute(
        path: AppRoutes.employees,
        name: 'employees',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('employees', 'read')) {
                return const EmployeesListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового сотрудника
      GoRoute(
        path: '${AppRoutes.employees}/create',
        name: 'employee_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('employees', 'create')) {
                return const EmployeeFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования существующего сотрудника
      GoRoute(
        path: '${AppRoutes.employees}/:employeeId/edit',
        name: 'employee_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('employees', 'update')) {
                final employeeId = state.pathParameters['employeeId']!;
                return EmployeeFormScreen(employeeId: employeeId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра конкретного сотрудника
      GoRoute(
        path: '${AppRoutes.employees}/:employeeId',
        name: 'employee_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final employeeId = state.pathParameters['employeeId']!;
              final service = ref.watch(permissionServiceProvider);

              // Если есть право на чтение сотрудников ИЛИ это свой профиль
              if (service.can('employees', 'read') ||
                  _canViewEmployee(ref, employeeId)) {
                return EmployeeDetailsScreen(employeeId: employeeId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для объектов - доступ по правам
      GoRoute(
        path: AppRoutes.objects,
        name: 'objects',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('objects', 'read')) {
                return const ObjectsListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового объекта - доступ по правам
      GoRoute(
        path: '${AppRoutes.objects}/create',
        name: 'object_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('objects', 'create')) {
                return const ObjectFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для контрагентов
      GoRoute(
        path: AppRoutes.contractors,
        name: 'contractors',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contractors', 'read')) {
                return const ContractorsListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового контрагента
      GoRoute(
        path: '${AppRoutes.contractors}/create',
        name: 'contractor_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contractors', 'create')) {
                return const ContractorFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования контрагента
      GoRoute(
        path: '${AppRoutes.contractors}/:contractorId/edit',
        name: 'contractor_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contractors', 'update')) {
                final contractorId = state.pathParameters['contractorId']!;
                return ContractorFormScreen(contractorId: contractorId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра контрагента
      GoRoute(
        path: '${AppRoutes.contractors}/:contractorId',
        name: 'contractor_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contractors', 'read')) {
                final contractorId = state.pathParameters['contractorId']!;
                return ContractorDetailsScreen(contractorId: contractorId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для договоров
      GoRoute(
        path: AppRoutes.contracts,
        name: 'contracts',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contracts', 'read')) {
                return const ContractsListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового договора
      GoRoute(
        path: '${AppRoutes.contracts}/create',
        name: 'contract_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contracts', 'create')) {
                return const ContractFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования договора
      GoRoute(
        path: '${AppRoutes.contracts}/:contractId/edit',
        name: 'contract_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('contracts', 'update')) {
                // Передаем contractId, ContractFormScreen сам найдет контракт по id
                // (или можно доработать для передачи объекта)
                return const ContractFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра договора удален

      // Маршрут для смет
      GoRoute(
        path: AppRoutes.estimates,
        name: 'estimates',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('estimates', 'read')) {
                return const EstimatesListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания сметы
      GoRoute(
        path: '${AppRoutes.estimates}/create',
        name: 'estimate_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('estimates', 'create')) {
                return const EstimateFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования сметы
      GoRoute(
        path: '${AppRoutes.estimates}/:estimateId/edit',
        name: 'estimate_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('estimates', 'update')) {
                final estimateId = state.pathParameters['estimateId']!;
                return EstimateFormScreen(estimateId: estimateId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра сметы
      GoRoute(
        path: '${AppRoutes.estimates}/:estimateTitle',
        name: 'estimate_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('estimates', 'read')) {
                final estimateTitle = state.pathParameters['estimateTitle']!;
                return EstimateDetailsScreen(estimateTitle: estimateTitle);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для работ
      GoRoute(
        path: AppRoutes.works,
        name: 'works',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('works', 'read')) {
                return const WorksMasterDetailScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
        routes: [
          GoRoute(
            path: ':workId',
            name: 'work_details',
            pageBuilder: (context, state) {
              final workId = state.pathParameters['workId']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: WorkDetailsScreen(workId: workId),
                transitionDuration: const Duration(milliseconds: 600),
                reverseTransitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // Возвращаем child без FadeTransition, чтобы фон нового экрана
                  // сразу перекрывал старый (по требованию пользователя).
                  // Hero-анимация при этом продолжит работать благодаря длительности перехода.
                  return child;
                },
              );
            },
          ),
          GoRoute(
            path: 'month/details',
            name: 'month_details_mobile',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! MonthGroup) {
                return const Scaffold(
                  body: Center(
                    child: Text('Ошибка: не переданы данные месяца'),
                  ),
                );
              }
              return MonthDetailsMobileScreen(initialGroup: extra);
            },
          ),
        ],
      ),
      // Маршрут для плана работ - перенаправляем в общий модуль работ
      GoRoute(
        path: AppRoutes.workPlans,
        name: 'work_plans',
        builder: (context, state) => const WorksMasterDetailScreen(),
      ),
      // Маршрут для деталей плана работ
      GoRoute(
        path: '${AppRoutes.workPlans}/:workPlanId',
        name: 'work_plan_details',
        builder: (context, state) {
          final workPlanId = state.pathParameters['workPlanId']!;
          return WorkPlanDetailsScreen(workPlanId: workPlanId);
        },
      ),
      // Маршрут для табеля рабочего времени
      GoRoute(
        path: AppRoutes.timesheet,
        name: 'timesheet',
        builder: (context, state) => const TimesheetScreen(),
      ),
      // Маршрут для расчётов ФОТ
      GoRoute(
        path: AppRoutes.payrolls,
        name: 'payrolls',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('payroll', 'read')) {
                return const PayrollListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для экспорта - доступ по правам
      GoRoute(
        path: AppRoutes.export,
        name: 'export',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('export', 'read')) {
                return const ExportScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),

      // Маршрут для материалов (чистая страница с AppBar)
      GoRoute(
        path: AppRoutes.material,
        name: 'material',
        builder: (context, state) => const MaterialScreen(),
      ),

      // Маршрут для экрана принудительного обновления
      GoRoute(
        path: AppRoutes.forceUpdate,
        name: 'force_update',
        builder: (context, state) => const ForceUpdateScreen(),
      ),

      // Маршрут для управления версиями
      GoRoute(
        path: AppRoutes.versionManagement,
        name: 'version_management',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('system', 'read')) {
                return const VersionManagementScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),

      // Маршрут для управления ролями
      GoRoute(
        path: AppRoutes.roles,
        name: 'roles',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('roles', 'read')) {
                final roleId = state.uri.queryParameters['roleId'];
                return RolesListScreen(initialRoleId: roleId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),

      GoRoute(
        path: AppRoutes.cashFlow,
        name: 'cash_flow',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final service = ref.watch(permissionServiceProvider);
              if (service.can('cash_flow', 'read')) {
                return const CashFlowListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),

      // Страницы статусов доступа управляются через AuthGate
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Ошибка: ${state.error}'))),
  );
});

/// Класс с константами маршрутов приложения.
///
/// Используется для унификации путей и предотвращения опечаток в строках маршрутов.
class AppRoutes {
  /// Маршрут сплэш-экрана
  static const String splash = '/';

  /// Маршрут для экрана логина
  static const String login = '/login';

  // Маршрут для экрана регистрации удалён

  /// Главная страница
  static const String home = '/home';

  /// Модуль Компания
  static const String company = '/company';

  /// Профиль пользователя
  static const String profile = '/profile';

  /// Экран выбора компании (Onboarding)
  static const String onboarding = '/onboarding';

  /// Список пользователей (админ)
  static const String users = '/users';

  /// Список сотрудников
  static const String employees = '/employees';

  /// Список объектов
  static const String objects = '/objects';

  /// Список контрагентов
  static const String contractors = '/contractors';

  /// Список договоров
  static const String contracts = '/contracts';

  /// Список смет
  static const String estimates = '/estimates';

  /// Список работ
  static const String works = '/works';

  /// Табель рабочего времени
  static const String timesheet = '/timesheet';

  /// Список расчётов ФОТ
  static const String payrolls = '/payrolls';

  /// Маршрут для экспорта
  static const String export = '/export';

  /// Маршрут для плана работ
  static const String workPlans = '/work_plans';

  /// Маршрут для страницы Материал
  static const String material = '/material';

  /// Маршрут для экрана принудительного обновления
  static const String forceUpdate = '/force-update';

  /// Маршрут для управления версиями (админ)
  static const String versionManagement = '/version-management';

  /// Маршрут для управления ролями (админ)
  static const String roles = '/roles';

  /// Маршрут для модуля Cash Flow (Движение денежных средств)
  static const String cashFlow = '/cash_flow';

  // Telegram маршруты удалены

  // Специальный маршрут удалён
}
