import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// imports of specific screens are not needed here because we use AuthGate
import 'package:projectgt/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/profile_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/financial_info_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/property_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/users_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
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
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/presentation/screens/month_details_mobile_screen.dart';
import 'package:projectgt/features/timesheet/presentation/screens/timesheet_screen.dart';
import 'package:projectgt/features/fot/presentation/screens/payroll_list_screen.dart';
import 'package:projectgt/features/export/presentation/screens/export_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plans_list_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_edit_screen.dart';
import 'package:projectgt/features/materials/presentation/screens/material_screen.dart';
import 'package:projectgt/features/materials/presentation/screens/materials_mapping_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_receipt_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_item_details_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_transfer_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_breakdowns_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_inventory_screen.dart';
import 'package:projectgt/features/inventory/presentation/screens/inventory_categories_reference_screen.dart';
// Telegram moderation экраны удалены
import 'package:projectgt/core/widgets/auth_gate.dart';
import 'package:projectgt/features/version_control/presentation/force_update_screen.dart';
import 'package:projectgt/features/version_control/presentation/version_management_screen.dart';

/// Проверяет, является ли текущий пользователь администратором.
///
/// Используется для защиты маршрутов, доступных только админам.
bool _isAdmin(WidgetRef ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.role == 'admin';
}

/// Проверяет, может ли пользователь просматривать информацию о конкретном сотруднике.
///
/// Админы могут просматривать всех сотрудников.
/// Обычные пользователи могут просматривать только своего привязанного сотрудника.
bool _canViewEmployee(WidgetRef ref, String employeeId) {
  final authState = ref.watch(authProvider);

  // Админы могут просматривать всех
  if (authState.user?.role == 'admin') {
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
    appBar: AppBar(
      title: const Text('Доступ запрещён'),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey,
          ),
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
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      // Защищаемся от случая, когда hash-токен попадает в path и роутер
      // пытается интерпретировать его как маршрут
      final loc = state.matchedLocation;
      if (loc.startsWith('access_token') || loc.startsWith('/access_token')) {
        // fix bad path
        return AppRoutes.home;
      }

      // Обработка Telegram Mini App параметров (tgWebAppData, и др.)
      // Telegram добавляет параметры в URL, которые Go Router не может маршрутизировать
      // Перенаправляем на главную страницу, если в URL есть Telegram параметры
      if (state.uri.queryParameters.containsKey('tgWebAppData')) {
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
        builder: (context, state) => const UsersListScreen(),
      ),
      // Маршрут для списка сотрудников - только для админов
      GoRoute(
        path: AppRoutes.employees,
        name: 'employees',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const EmployeesListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового сотрудника - только для админов
      GoRoute(
        path: '${AppRoutes.employees}/create',
        name: 'employee_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const EmployeeFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования существующего сотрудника - только для админов
      GoRoute(
        path: '${AppRoutes.employees}/:employeeId/edit',
        name: 'employee_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                final employeeId = state.pathParameters['employeeId']!;
                return EmployeeFormScreen(employeeId: employeeId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра конкретного сотрудника - админы или просмотр своей карточки
      GoRoute(
        path: '${AppRoutes.employees}/:employeeId',
        name: 'employee_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final employeeId = state.pathParameters['employeeId']!;

              if (_canViewEmployee(ref, employeeId)) {
                return EmployeeDetailsScreen(employeeId: employeeId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для объектов - только для админов
      GoRoute(
        path: AppRoutes.objects,
        name: 'objects',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const ObjectsListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового объекта - только для админов
      GoRoute(
        path: '${AppRoutes.objects}/create',
        name: 'object_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const ObjectFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для контрагентов - только для админов
      GoRoute(
        path: AppRoutes.contractors,
        name: 'contractors',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const ContractorsListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового контрагента - только для админов
      GoRoute(
        path: '${AppRoutes.contractors}/create',
        name: 'contractor_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const ContractorFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования контрагента - только для админов
      GoRoute(
        path: '${AppRoutes.contractors}/:contractorId/edit',
        name: 'contractor_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                final contractorId = state.pathParameters['contractorId']!;
                return ContractorFormScreen(contractorId: contractorId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра контрагента - только для админов
      GoRoute(
        path: '${AppRoutes.contractors}/:contractorId',
        name: 'contractor_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                final contractorId = state.pathParameters['contractorId']!;
                return ContractorDetailsScreen(contractorId: contractorId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для договоров - только для админов
      GoRoute(
        path: AppRoutes.contracts,
        name: 'contracts',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const ContractsListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания нового договора - только для админов
      GoRoute(
        path: '${AppRoutes.contracts}/create',
        name: 'contract_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const ContractFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования договора - только для админов
      GoRoute(
        path: '${AppRoutes.contracts}/:contractId/edit',
        name: 'contract_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                // Передаем contractId, ContractFormScreen сам найдет контракт по id
                // (или можно доработать для передачи объекта)
                return const ContractFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра договора - только для админов
      GoRoute(
        path: '${AppRoutes.contracts}/:contractId',
        name: 'contract_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                final contractId = state.pathParameters['contractId']!;
                return ContractDetailsScreen(contractId: contractId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для смет - только для админов
      GoRoute(
        path: AppRoutes.estimates,
        name: 'estimates',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const EstimatesListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для создания сметы - только для админов
      GoRoute(
        path: '${AppRoutes.estimates}/create',
        name: 'estimate_new',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const EstimateFormScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для редактирования сметы - только для админов
      GoRoute(
        path: '${AppRoutes.estimates}/:estimateId/edit',
        name: 'estimate_edit',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                final estimateId = state.pathParameters['estimateId']!;
                return EstimateFormScreen(estimateId: estimateId);
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для просмотра сметы - только для админов
      GoRoute(
        path: '${AppRoutes.estimates}/:estimateTitle',
        name: 'estimate_details',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
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
      // Маршрут для расчётов ФОТ - только для админов
      GoRoute(
        path: AppRoutes.payrolls,
        name: 'payrolls',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const PayrollListScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
      ),
      // Маршрут для экспорта - доступен всем пользователям
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

      // Маршрут для складского учёта
      GoRoute(
        path: AppRoutes.inventory,
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
        routes: [
          // Маршрут для прихода ТМЦ
          GoRoute(
            path: 'receipt',
            name: 'inventory_receipt',
            builder: (context, state) => const InventoryReceiptScreen(),
          ),
          // Маршрут для добавления ТМЦ без накладной (редирект на receipt с переключателем)
          GoRoute(
            path: 'add',
            name: 'inventory_item_add',
            builder: (context, state) =>
                const InventoryReceiptScreen(hasReceipt: false),
          ),
          // Маршрут для карточки ТМЦ
          GoRoute(
            path: 'item/:itemId',
            name: 'inventory_item_details',
            builder: (context, state) {
              final itemId = state.pathParameters['itemId']!;
              return InventoryItemDetailsScreen(itemId: itemId);
            },
          ),
          // Маршрут для передачи/выдачи ТМЦ
          GoRoute(
            path: 'transfer',
            name: 'inventory_transfer',
            builder: (context, state) => const InventoryTransferScreen(),
          ),
          // Маршрут для поломок/утрат
          GoRoute(
            path: 'breakdowns',
            name: 'inventory_breakdowns',
            builder: (context, state) => const InventoryBreakdownsScreen(),
          ),
          // Маршрут для инвентаризации
          GoRoute(
            path: 'check',
            name: 'inventory_inventory',
            builder: (context, state) => const InventoryInventoryScreen(),
          ),
          // Маршрут для справочника категорий ТМЦ
          GoRoute(
            path: 'categories',
            name: 'inventory_categories_reference',
            builder: (context, state) =>
                const InventoryCategoriesReferenceScreen(),
          ),
        ],
      ),

      // Маршрут для экрана принудительного обновления
      GoRoute(
        path: AppRoutes.forceUpdate,
        name: 'force_update',
        builder: (context, state) => const ForceUpdateScreen(),
      ),

      // Маршрут для управления версиями - только для админов
      GoRoute(
        path: AppRoutes.versionManagement,
        name: 'version_management',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              if (_isAdmin(ref)) {
                return const VersionManagementScreen();
              }
              return _buildAccessDeniedScreen();
            },
          );
        },
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

  /// Маршрут для складского учёта
  static const String inventory = '/inventory';

  /// Маршрут для экрана принудительного обновления
  static const String forceUpdate = '/force-update';

  /// Маршрут для управления версиями (админ)
  static const String versionManagement = '/version-management';

  // Telegram маршруты удалены

  // Специальный маршрут удалён
}
