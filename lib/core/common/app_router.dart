import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/auth/presentation/screens/login_screen.dart';
import 'package:projectgt/features/auth/presentation/screens/register_screen.dart';
import 'package:projectgt/features/home/presentation/screens/home_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/profile_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/users_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
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

/// Провайдер маршрутизатора приложения на базе GoRouter.
/// 
/// Управляет навигацией, авторизацией, доступом к защищённым и административным маршрутам.
/// Использует Riverpod для внедрения зависимостей и состояния авторизации.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: authState.status == AuthStatus.authenticated 
      ? AppRoutes.home
      : AppRoutes.login,
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isRegisterRoute = state.matchedLocation == AppRoutes.register;
      final isAdminRoute = state.matchedLocation == AppRoutes.users;
      
      // Если пользователь не аутентифицирован и пытается получить доступ к защищенному маршруту
      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        return AppRoutes.login;
      }
      
      // Если пользователь аутентифицирован и пытается получить доступ к маршруту логина
      if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
        return AppRoutes.home;
      }
      
      // Если пользователь не админ и пытается получить доступ к админ-странице
      if (isAuthenticated && isAdminRoute && authState.user?.role != 'admin') {
        return AppRoutes.home;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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
  /// Маршрут для экрана регистрации
  static const String register = '/register';
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
} 