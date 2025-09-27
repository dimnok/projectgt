import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// imports of specific screens are not needed here because we use AuthGate
import 'package:projectgt/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/profile_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/users_list_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/financial_info_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';
// import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/features/objects/presentation/screens/objects_list_screen.dart';
import 'package:projectgt/features/objects/presentation/screens/object_form_screen.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractors_list_screen.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractor_form_screen.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractor_details_screen.dart';
import 'package:projectgt/features/contracts/presentation/screens/contracts_list_screen.dart';
import 'package:projectgt/features/contracts/presentation/screens/contract_form_screen.dart';
import 'package:projectgt/features/contracts/presentation/screens/contract_details_screen.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimates_list_screen.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimate_form_screen.dart';
import 'package:projectgt/features/estimates/presentation/screens/estimate_details_screen.dart';
import 'package:projectgt/features/works/presentation/screens/works_master_detail_screen.dart';
import 'package:projectgt/features/works/presentation/screens/work_details_screen.dart';
import 'package:projectgt/features/timesheet/presentation/screens/timesheet_screen.dart';
import 'package:projectgt/features/fot/presentation/screens/payroll_list_screen.dart';
import 'package:projectgt/features/export/presentation/screens/export_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plans_list_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_edit_screen.dart';
import 'package:projectgt/features/materials/presentation/screens/material_screen.dart';
import 'package:projectgt/features/materials/presentation/screens/materials_mapping_screen.dart';
// Telegram moderation экраны удалены
import 'package:projectgt/core/widgets/auth_gate.dart';

/// Провайдер маршрутизатора приложения на базе GoRouter.
///
/// Управляет навигацией, авторизацией, доступом к защищённым и административным маршрутам.
/// Использует Riverpod для внедрения зависимостей и состояния авторизации.
final routerProvider = Provider<GoRouter>((ref) {
  // final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      // Защищаемся от случая, когда hash-токен попадает в path и роутер
      // пытается интерпретировать его как маршрут
      final loc = state.matchedLocation;
      if (loc.startsWith('access_token') || loc.startsWith('/access_token')) {
        // fix bad path
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
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
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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
        path: '${AppRoutes.profile}/financial',
        name: 'profile_financial',
        builder: (context, state) => const FinancialInfoScreen(),
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
        builder: (context, state) => const UsersListScreen(),
      ),
      // Маршрут для списка сотрудников
      GoRoute(
        path: AppRoutes.employees,
        name: 'employees',
        builder: (context, state) => const EmployeesListScreen(),
      ),
      // Маршрут для создания нового сотрудника
      GoRoute(
        path: '${AppRoutes.employees}/create',
        name: 'employee_new',
        builder: (context, state) => const EmployeeFormScreen(),
      ),
      // Маршрут для редактирования существующего сотрудника
      GoRoute(
        path: '${AppRoutes.employees}/:employeeId/edit',
        name: 'employee_edit',
        builder: (context, state) {
          final employeeId = state.pathParameters['employeeId']!;
          return EmployeeFormScreen(employeeId: employeeId);
        },
      ),
      // Маршрут для просмотра конкретного сотрудника
      GoRoute(
        path: '${AppRoutes.employees}/:employeeId',
        name: 'employee_details',
        builder: (context, state) {
          final employeeId = state.pathParameters['employeeId']!;
          return EmployeeDetailsScreen(employeeId: employeeId);
        },
      ),
      // Маршрут для объектов
      GoRoute(
        path: AppRoutes.objects,
        name: 'objects',
        builder: (context, state) => const ObjectsListScreen(),
      ),
      // Маршрут для создания нового объекта
      GoRoute(
        path: '${AppRoutes.objects}/create',
        name: 'object_new',
        builder: (context, state) => const ObjectFormScreen(),
      ),
      // Маршрут для контрагентов
      GoRoute(
        path: AppRoutes.contractors,
        name: 'contractors',
        builder: (context, state) => const ContractorsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.contractors}/create',
        name: 'contractor_new',
        builder: (context, state) => const ContractorFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.contractors}/:contractorId/edit',
        name: 'contractor_edit',
        builder: (context, state) {
          final contractorId = state.pathParameters['contractorId']!;
          return ContractorFormScreen(contractorId: contractorId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.contractors}/:contractorId',
        name: 'contractor_details',
        builder: (context, state) {
          final contractorId = state.pathParameters['contractorId']!;
          return ContractorDetailsScreen(contractorId: contractorId);
        },
      ),
      // Маршрут для договоров
      GoRoute(
        path: AppRoutes.contracts,
        name: 'contracts',
        builder: (context, state) => const ContractsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.contracts}/create',
        name: 'contract_new',
        builder: (context, state) => const ContractFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.contracts}/:contractId/edit',
        name: 'contract_edit',
        builder: (context, state) {
          // Передаем contractId, ContractFormScreen сам найдет контракт по id
          // (или можно доработать для передачи объекта)
          return const ContractFormScreen();
        },
      ),
      GoRoute(
        path: '${AppRoutes.contracts}/:contractId',
        name: 'contract_details',
        builder: (context, state) {
          final contractId = state.pathParameters['contractId']!;
          return ContractDetailsScreen(contractId: contractId);
        },
      ),
      // Маршрут для смет
      GoRoute(
        path: AppRoutes.estimates,
        name: 'estimates',
        builder: (context, state) => const EstimatesListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.estimates}/create',
        name: 'estimate_new',
        builder: (context, state) => const EstimateFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.estimates}/:estimateId/edit',
        name: 'estimate_edit',
        builder: (context, state) {
          final estimateId = state.pathParameters['estimateId']!;
          return EstimateFormScreen(estimateId: estimateId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.estimates}/:estimateTitle',
        name: 'estimate_details',
        builder: (context, state) {
          final estimateTitle = state.pathParameters['estimateTitle']!;
          return EstimateDetailsScreen(estimateTitle: estimateTitle);
        },
      ),
      // Маршрут для работ
      GoRoute(
        path: AppRoutes.works,
        name: 'works',
        builder: (context, state) => const WorksMasterDetailScreen(),
        routes: [
          GoRoute(
            path: ':workId',
            name: 'work_details',
            builder: (context, state) {
              final workId = state.pathParameters['workId']!;
              return WorkDetailsScreen(workId: workId);
            },
          ),
        ],
      ),
      // Маршрут для плана работ
      GoRoute(
        path: AppRoutes.workPlans,
        name: 'work_plans',
        builder: (context, state) => const WorkPlansListScreen(),
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
      // Маршрут для редактирования плана работ
      GoRoute(
        path: '${AppRoutes.workPlans}/:workPlanId/edit',
        name: 'work_plan_edit',
        builder: (context, state) {
          final workPlanId = state.pathParameters['workPlanId']!;
          return WorkPlanEditScreen(workPlanId: workPlanId);
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
        builder: (context, state) => const PayrollListScreen(),
      ),
      // Маршрут для экспорта
      GoRoute(
        path: AppRoutes.export,
        name: 'export',
        builder: (context, state) => const ExportScreen(),
      ),

      // Маршрут для материалов (чистая страница с AppBar)
      GoRoute(
        path: AppRoutes.material,
        name: 'material',
        builder: (context, state) => const MaterialScreen(),
      ),

      // Экран сопоставления материалов
      GoRoute(
        path: AppRoutes.materialMapping,
        name: 'material_mapping',
        builder: (context, state) => const MaterialsMappingScreen(),
      ),

      // Страницы статусов доступа управляются через AuthGate
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ошибка: ${state.error}'),
      ),
    ),
  );
});

/// Класс с константами маршрутов приложения.
///
/// Используется для унификации путей и предотвращения опечаток в строках маршрутов.
class AppRoutes {
  /// Маршрут для экрана логина
  static const String login = '/login';

  // Маршрут для экрана регистрации удалён

  /// Главная страница
  static const String home = '/';

  /// Профиль пользователя
  static const String profile = '/profile';

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

  /// Маршрут для экрана сопоставления материалов
  static const String materialMapping = '/material/mapping';

  // Telegram маршруты удалены

  // Специальный маршрут удалён
}
