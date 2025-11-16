import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/datasources/auth_data_source.dart';
import 'package:projectgt/data/datasources/telegram_auth_data_source.dart';
// Telegram data source удалён
import 'package:projectgt/data/datasources/profile_data_source.dart';
import 'package:projectgt/data/datasources/employee_data_source.dart';
import 'package:projectgt/data/models/estimate_completion_model.dart';
import 'package:projectgt/data/repositories/auth_repository_impl.dart';
import 'package:projectgt/data/repositories/profile_repository_impl.dart';
import 'package:projectgt/data/repositories/employee_repository_impl.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';
import 'package:projectgt/domain/repositories/profile_repository.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:projectgt/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:projectgt/domain/usecases/auth/login_usecase.dart';
import 'package:projectgt/domain/usecases/auth/logout_usecase.dart';
import 'package:projectgt/domain/usecases/auth/register_usecase.dart';
import 'package:projectgt/domain/usecases/auth/request_email_otp_usecase.dart';
import 'package:projectgt/domain/usecases/auth/verify_email_otp_usecase.dart';
import 'package:projectgt/domain/usecases/auth/complete_user_profile_usecase.dart';
import 'package:projectgt/domain/usecases/auth/telegram_authenticate_usecase.dart';
// Telegram auth usecases удалены

// Telegram moderation слои удалены
import 'package:projectgt/domain/usecases/profile/get_profile_usecase.dart';
import 'package:projectgt/domain/usecases/profile/get_profiles_usecase.dart';
import 'package:projectgt/domain/usecases/profile/update_profile_usecase.dart';
import 'package:projectgt/domain/usecases/employee/get_employee_usecase.dart';
import 'package:projectgt/domain/usecases/employee/get_employees_usecase.dart';
import 'package:projectgt/domain/usecases/employee/create_employee_usecase.dart';
import 'package:projectgt/domain/usecases/employee/update_employee_usecase.dart';
import 'package:projectgt/domain/usecases/employee/delete_employee_usecase.dart';
import 'package:projectgt/core/services/photo_service.dart';
import 'package:projectgt/data/datasources/object_data_source.dart';
import 'package:projectgt/data/repositories/object_repository_impl.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';
import 'package:projectgt/domain/usecases/object/get_objects_usecase.dart';
import 'package:projectgt/domain/usecases/object/create_object_usecase.dart';
import 'package:projectgt/domain/usecases/object/update_object_usecase.dart';
import 'package:projectgt/domain/usecases/object/delete_object_usecase.dart';
import 'package:projectgt/presentation/state/object_state.dart';
import 'package:projectgt/data/datasources/contractor_data_source.dart';
import 'package:projectgt/data/repositories/contractor_repository_impl.dart';
import 'package:projectgt/domain/repositories/contractor_repository.dart';
import 'package:projectgt/domain/usecases/contractor/get_contractors_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/get_contractor_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/create_contractor_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/update_contractor_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/delete_contractor_usecase.dart';
import 'package:projectgt/presentation/state/contractor_state.dart';
import 'package:projectgt/data/datasources/contract_data_source.dart';
import 'package:projectgt/data/repositories/contract_repository_impl.dart';
import 'package:projectgt/domain/repositories/contract_repository.dart';
import 'package:projectgt/domain/usecases/contract/get_contracts_usecase.dart';
import 'package:projectgt/domain/usecases/contract/get_contract_usecase.dart';
import 'package:projectgt/domain/usecases/contract/create_contract_usecase.dart';
import 'package:projectgt/domain/usecases/contract/update_contract_usecase.dart';
import 'package:projectgt/domain/usecases/contract/delete_contract_usecase.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/data/datasources/estimate_data_source.dart';
import 'package:projectgt/data/repositories/estimate_repository_impl.dart';
import 'package:projectgt/domain/repositories/estimate_repository.dart';
import 'package:projectgt/data/datasources/work_plan_data_source.dart';
import 'package:projectgt/data/repositories/work_plan_repository_impl.dart';
import 'package:projectgt/domain/repositories/work_plan_repository.dart';
import 'package:projectgt/domain/usecases/estimate/get_estimates_usecase.dart';
import 'package:projectgt/domain/usecases/estimate/get_estimate_usecase.dart';
import 'package:projectgt/domain/usecases/estimate/create_estimate_usecase.dart';
import 'package:projectgt/domain/usecases/estimate/update_estimate_usecase.dart';
import 'package:projectgt/domain/usecases/estimate/delete_estimate_usecase.dart';
import 'package:projectgt/domain/usecases/work_plan/get_work_plans_usecase.dart';
import 'package:projectgt/domain/usecases/work_plan/get_work_plan_usecase.dart';
import 'package:projectgt/domain/usecases/work_plan/create_work_plan_usecase.dart';
import 'package:projectgt/domain/usecases/work_plan/update_work_plan_usecase.dart';
import 'package:projectgt/domain/usecases/work_plan/delete_work_plan_usecase.dart';
// Удалён неиспользуемый use-case get_user_work_plans_usecase
import 'package:projectgt/presentation/state/estimate_state.dart';
import 'package:projectgt/presentation/state/work_plan_state.dart';
import 'package:projectgt/features/works/domain/repositories/work_hour_repository.dart';
import 'package:projectgt/features/works/data/datasources/work_hour_data_source.dart';
import 'package:projectgt/features/works/data/datasources/work_hour_data_source_impl.dart';
import 'package:projectgt/features/works/data/repositories/work_hour_repository_impl.dart';
import 'package:projectgt/data/datasources/employee_rate_data_source.dart';

// Business Trip Rates imports
import 'package:projectgt/data/datasources/business_trip_rate_data_source.dart';
import 'package:projectgt/data/repositories/business_trip_rate_repository_impl.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/get_business_trip_rates_usecase.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/get_business_trip_rates_by_object_usecase.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/get_active_business_trip_rate_usecase.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/create_business_trip_rate_usecase.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/update_business_trip_rate_usecase.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/delete_business_trip_rate_usecase.dart';
import 'package:projectgt/domain/usecases/business_trip_rate/get_business_trip_rates_by_employee_usecase.dart';
import 'package:projectgt/data/repositories/employee_rate_repository_impl.dart';
import 'package:projectgt/domain/repositories/employee_rate_repository.dart';
import 'package:projectgt/domain/usecases/employee_rate/get_employee_rate_for_date_usecase.dart';
import 'package:projectgt/domain/usecases/employee_rate/set_employee_rate_usecase.dart';
import 'package:projectgt/domain/usecases/employee_rate/get_employee_rates_usecase.dart';

/// Провайдер Supabase клиента для доступа к базе данных.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// DataSources
/// Провайдер для AuthDataSource (Supabase).
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthDataSource(client);
});

/// Провайдер для TelegramAuthDataSource (Edge Function).
final telegramAuthDataSourceProvider = Provider<TelegramAuthDataSource>((ref) {
  return TelegramAuthDataSource();
});

// TelegramModerationDataSource удалён

/// Провайдер для ProfileDataSource (Supabase).
final profileDataSourceProvider = Provider<ProfileDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileDataSource(client);
});

/// Провайдер для EmployeeDataSource (Supabase).
final employeeDataSourceProvider = Provider<EmployeeDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseEmployeeDataSource(client);
});

/// Провайдер для ObjectDataSource (Supabase).
final objectDataSourceProvider = Provider<ObjectDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseObjectDataSource(client);
});

/// Провайдер для ContractorDataSource (Supabase).
final contractorDataSourceProvider = Provider<ContractorDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseContractorDataSource(client);
});

/// Провайдер для ContractDataSource (Supabase).
final contractDataSourceProvider = Provider<ContractDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseContractDataSource(client);
});

/// Провайдер для EstimateDataSource (Supabase).
final estimateDataSourceProvider = Provider<EstimateDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseEstimateDataSource(client);
});

/// Провайдер для WorkPlanDataSource (Supabase).
final workPlanDataSourceProvider = Provider<WorkPlanDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseWorkPlanDataSource(client);
});

// Repositories
// TelegramModerationRepository удалён

/// Провайдер репозитория аутентификации.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authDataSource = ref.watch(authDataSourceProvider);
  final telegramAuthDataSource = ref.watch(telegramAuthDataSourceProvider);
  return AuthRepositoryImpl(
    authDataSource: authDataSource,
    telegramAuthDataSource: telegramAuthDataSource,
  );
});

/// Провайдер репозитория профилей.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dataSource = ref.watch(profileDataSourceProvider);
  return ProfileRepositoryImpl(dataSource);
});

/// Провайдер репозитория сотрудников.
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final dataSource = ref.watch(employeeDataSourceProvider);
  return EmployeeRepositoryImpl(dataSource);
});

/// Провайдер репозитория объектов.
final objectRepositoryProvider = Provider<ObjectRepository>((ref) {
  final dataSource = ref.watch(objectDataSourceProvider);
  return ObjectRepositoryImpl(dataSource);
});

/// Провайдер репозитория подрядчиков.
final contractorRepositoryProvider = Provider<ContractorRepository>((ref) {
  final dataSource = ref.watch(contractorDataSourceProvider);
  return ContractorRepositoryImpl(dataSource);
});

/// Провайдер репозитория договоров.
final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final dataSource = ref.watch(contractDataSourceProvider);
  return ContractRepositoryImpl(dataSource);
});

/// Провайдер репозитория смет.
final estimateRepositoryProvider = Provider<EstimateRepository>((ref) {
  final dataSource = ref.watch(estimateDataSourceProvider);
  return EstimateRepositoryImpl(dataSource);
});

/// Провайдер репозитория планов работ.
final workPlanRepositoryProvider = Provider<WorkPlanRepository>((ref) {
  final dataSource = ref.watch(workPlanDataSourceProvider);
  return WorkPlanRepositoryImpl(dataSource);
});

// UseCases - Auth
/// Провайдер use-case для логина пользователя.
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Провайдер use-case для регистрации пользователя.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

/// Провайдер use-case для отправки OTP на email
final requestEmailOtpUseCaseProvider = Provider<RequestEmailOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RequestEmailOtpUseCase(repository);
});

/// Провайдер use-case для подтверждения OTP и входа
final verifyEmailOtpUseCaseProvider = Provider<VerifyEmailOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyEmailOtpUseCase(repository);
});

/// Провайдер use-case для завершения заполнения профиля пользователя
final completeUserProfileUseCaseProvider =
    Provider<CompleteUserProfileUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CompleteUserProfileUseCase(repository);
});

/// Провайдер use-case для выхода пользователя.
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

/// Провайдер use-case для аутентификации через Telegram.
final telegramAuthenticateUseCaseProvider =
    Provider<TelegramAuthenticateUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return TelegramAuthenticateUseCase(repository);
});

/// Провайдер use-case для получения текущего пользователя.
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

// UseCases Telegram удалены

// UseCases Telegram moderation удалены

// UseCases - Profile
/// Провайдер use-case для получения профиля.
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return GetProfileUseCase(repository);
});

/// Провайдер use-case для получения списка профилей.
final getProfilesUseCaseProvider = Provider<GetProfilesUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return GetProfilesUseCase(repository);
});

/// Провайдер use-case для обновления профиля.
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

// UseCases - Employee
/// Провайдер use-case для получения сотрудника.
final getEmployeeUseCaseProvider = Provider<GetEmployeeUseCase>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return GetEmployeeUseCase(repository);
});

/// Провайдер use-case для получения списка сотрудников.
final getEmployeesUseCaseProvider = Provider<GetEmployeesUseCase>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return GetEmployeesUseCase(repository);
});

/// Провайдер use-case для создания сотрудника.
final createEmployeeUseCaseProvider = Provider<CreateEmployeeUseCase>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return CreateEmployeeUseCase(repository);
});

/// Провайдер use-case для обновления сотрудника.
final updateEmployeeUseCaseProvider = Provider<UpdateEmployeeUseCase>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return UpdateEmployeeUseCase(repository);
});

/// Провайдер use-case для удаления сотрудника.
final deleteEmployeeUseCaseProvider = Provider<DeleteEmployeeUseCase>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return DeleteEmployeeUseCase(repository);
});

/// Провайдер сервиса работы с фото (Supabase Storage).
final photoServiceProvider = Provider<PhotoService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PhotoService(supabase);
});

// UseCases - Object
/// Провайдер use-case для получения объектов.
final getObjectsUseCaseProvider = Provider<GetObjectsUseCase>((ref) {
  final repository = ref.watch(objectRepositoryProvider);
  return GetObjectsUseCase(repository);
});

/// Провайдер use-case для создания объекта.
final createObjectUseCaseProvider = Provider<CreateObjectUseCase>((ref) {
  final repository = ref.watch(objectRepositoryProvider);
  return CreateObjectUseCase(repository);
});

/// Провайдер use-case для обновления объекта.
final updateObjectUseCaseProvider = Provider<UpdateObjectUseCase>((ref) {
  final repository = ref.watch(objectRepositoryProvider);
  return UpdateObjectUseCase(repository);
});

/// Провайдер use-case для удаления объекта.
final deleteObjectUseCaseProvider = Provider<DeleteObjectUseCase>((ref) {
  final repository = ref.watch(objectRepositoryProvider);
  return DeleteObjectUseCase(repository);
});

// UseCases - Contractor
/// Провайдер use-case для получения списка подрядчиков.
final getContractorsUseCaseProvider = Provider<GetContractorsUseCase>((ref) {
  final repository = ref.watch(contractorRepositoryProvider);
  return GetContractorsUseCase(repository);
});

/// Провайдер use-case для получения подрядчика.
final getContractorUseCaseProvider = Provider<GetContractorUseCase>((ref) {
  final repository = ref.watch(contractorRepositoryProvider);
  return GetContractorUseCase(repository);
});

/// Провайдер use-case для создания подрядчика.
final createContractorUseCaseProvider =
    Provider<CreateContractorUseCase>((ref) {
  final repository = ref.watch(contractorRepositoryProvider);
  return CreateContractorUseCase(repository);
});

/// Провайдер use-case для обновления подрядчика.
final updateContractorUseCaseProvider =
    Provider<UpdateContractorUseCase>((ref) {
  final repository = ref.watch(contractorRepositoryProvider);
  return UpdateContractorUseCase(repository);
});

/// Провайдер use-case для удаления подрядчика.
final deleteContractorUseCaseProvider =
    Provider<DeleteContractorUseCase>((ref) {
  final repository = ref.watch(contractorRepositoryProvider);
  return DeleteContractorUseCase(repository);
});

// UseCases - Contract
/// Провайдер use-case для получения списка договоров.
final getContractsUseCaseProvider = Provider<GetContractsUseCase>((ref) {
  final repository = ref.watch(contractRepositoryProvider);
  return GetContractsUseCase(repository);
});

/// Провайдер use-case для получения договора.
final getContractUseCaseProvider = Provider<GetContractUseCase>((ref) {
  final repository = ref.watch(contractRepositoryProvider);
  return GetContractUseCase(repository);
});

/// Провайдер use-case для создания договора.
final createContractUseCaseProvider = Provider<CreateContractUseCase>((ref) {
  final repository = ref.watch(contractRepositoryProvider);
  return CreateContractUseCase(repository);
});

/// Провайдер use-case для обновления договора.
final updateContractUseCaseProvider = Provider<UpdateContractUseCase>((ref) {
  final repository = ref.watch(contractRepositoryProvider);
  return UpdateContractUseCase(repository);
});

/// Провайдер use-case для удаления договора.
final deleteContractUseCaseProvider = Provider<DeleteContractUseCase>((ref) {
  final repository = ref.watch(contractRepositoryProvider);
  return DeleteContractUseCase(repository);
});

// UseCases - Estimate
/// Провайдер use-case для получения списка смет.
final getEstimatesUseCaseProvider = Provider<GetEstimatesUseCase>((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  return GetEstimatesUseCase(repository);
});

/// Провайдер use-case для получения одной сметы.
final getEstimateUseCaseProvider = Provider<GetEstimateUseCase>((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  return GetEstimateUseCase(repository);
});

/// Провайдер use-case для создания сметы.
final createEstimateUseCaseProvider = Provider<CreateEstimateUseCase>((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  return CreateEstimateUseCase(repository);
});

/// Провайдер use-case для обновления сметы.
final updateEstimateUseCaseProvider = Provider<UpdateEstimateUseCase>((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  return UpdateEstimateUseCase(repository);
});

/// Провайдер use-case для удаления сметы.
final deleteEstimateUseCaseProvider = Provider<DeleteEstimateUseCase>((ref) {
  final repository = ref.watch(estimateRepositoryProvider);
  return DeleteEstimateUseCase(repository);
});

// UseCases - WorkPlan
/// Провайдер use-case для получения списка планов работ.
final getWorkPlansUseCaseProvider = Provider<GetWorkPlansUseCase>((ref) {
  final repository = ref.watch(workPlanRepositoryProvider);
  return GetWorkPlansUseCase(repository);
});

/// Провайдер use-case для получения одного плана работ.
final getWorkPlanUseCaseProvider = Provider<GetWorkPlanUseCase>((ref) {
  final repository = ref.watch(workPlanRepositoryProvider);
  return GetWorkPlanUseCase(repository);
});

/// Провайдер use-case для создания плана работ.
final createWorkPlanUseCaseProvider = Provider<CreateWorkPlanUseCase>((ref) {
  final repository = ref.watch(workPlanRepositoryProvider);
  return CreateWorkPlanUseCase(repository);
});

/// Провайдер use-case для обновления плана работ.
final updateWorkPlanUseCaseProvider = Provider<UpdateWorkPlanUseCase>((ref) {
  final repository = ref.watch(workPlanRepositoryProvider);
  return UpdateWorkPlanUseCase(repository);
});

/// Провайдер use-case для удаления плана работ.
final deleteWorkPlanUseCaseProvider = Provider<DeleteWorkPlanUseCase>((ref) {
  final repository = ref.watch(workPlanRepositoryProvider);
  return DeleteWorkPlanUseCase(repository);
});

// Employee Rate providers
/// Провайдер для EmployeeRateDataSource.
final employeeRateDataSourceProvider = Provider<EmployeeRateDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmployeeRateDataSourceImpl(client);
});

/// Провайдер для EmployeeRateRepository.
final employeeRateRepositoryProvider = Provider<EmployeeRateRepository>((ref) {
  final dataSource = ref.watch(employeeRateDataSourceProvider);
  return EmployeeRateRepositoryImpl(dataSource);
});

/// Провайдер use-case для получения ставки на дату.
final getEmployeeRateForDateUseCaseProvider =
    Provider<GetEmployeeRateForDateUseCase>((ref) {
  final repository = ref.watch(employeeRateRepositoryProvider);
  return GetEmployeeRateForDateUseCase(repository);
});

/// Провайдер use-case для установки новой ставки.
final setEmployeeRateUseCaseProvider = Provider<SetEmployeeRateUseCase>((ref) {
  final repository = ref.watch(employeeRateRepositoryProvider);
  return SetEmployeeRateUseCase(repository);
});

/// Провайдер use-case для получения истории ставок.
final getEmployeeRatesUseCaseProvider =
    Provider<GetEmployeeRatesUseCase>((ref) {
  final repository = ref.watch(employeeRateRepositoryProvider);
  return GetEmployeeRatesUseCase(repository);
});

/// Провайдер use-case для получения пользовательских планов работ.
// Удалён провайдер getUserWorkPlansUseCaseProvider как неиспользуемый

// ObjectNotifier provider
/// StateNotifierProvider для управления состоянием объектов (ObjectState).
final objectProvider =
    StateNotifierProvider<ObjectNotifier, ObjectState>((ref) {
  return ObjectNotifier(
    getObjectsUseCase: ref.watch(getObjectsUseCaseProvider),
    createObjectUseCase: ref.watch(createObjectUseCaseProvider),
    updateObjectUseCase: ref.watch(updateObjectUseCaseProvider),
    deleteObjectUseCase: ref.watch(deleteObjectUseCaseProvider),
  )..loadObjects();
});

// ContractorNotifier provider
/// StateNotifierProvider для управления состоянием подрядчиков (ContractorState).
final contractorProvider =
    StateNotifierProvider<ContractorNotifier, ContractorState>((ref) {
  return ContractorNotifier(
    getContractorsUseCase: ref.watch(getContractorsUseCaseProvider),
    getContractorUseCase: ref.watch(getContractorUseCaseProvider),
    createContractorUseCase: ref.watch(createContractorUseCaseProvider),
    updateContractorUseCase: ref.watch(updateContractorUseCaseProvider),
    deleteContractorUseCase: ref.watch(deleteContractorUseCaseProvider),
    ref: ref,
  )..loadContractors();
});

// ContractNotifier provider
/// StateNotifierProvider для управления состоянием договоров (ContractState).
final contractProvider =
    StateNotifierProvider<ContractNotifier, ContractState>((ref) {
  return ContractNotifier(
    getContractsUseCase: ref.watch(getContractsUseCaseProvider),
    getContractUseCase: ref.watch(getContractUseCaseProvider),
    createContractUseCase: ref.watch(createContractUseCaseProvider),
    updateContractUseCase: ref.watch(updateContractUseCaseProvider),
    deleteContractUseCase: ref.watch(deleteContractUseCaseProvider),
  )..loadContracts();
});

/// Провайдер состояния и логики EstimateNotifier.
final estimateNotifierProvider =
    StateNotifierProvider<EstimateNotifier, EstimateState>((ref) {
  return EstimateNotifier(
    getEstimatesUseCase: ref.watch(getEstimatesUseCaseProvider),
    getEstimateUseCase: ref.watch(getEstimateUseCaseProvider),
    createEstimateUseCase: ref.watch(createEstimateUseCaseProvider),
    updateEstimateUseCase: ref.watch(updateEstimateUseCaseProvider),
    deleteEstimateUseCase: ref.watch(deleteEstimateUseCaseProvider),
  );
});

/// Провайдер состояния и логики WorkPlanNotifier.
final workPlanNotifierProvider =
    StateNotifierProvider<WorkPlanNotifier, WorkPlanState>((ref) {
  return WorkPlanNotifier(
    getWorkPlansUseCase: ref.watch(getWorkPlansUseCaseProvider),
    getWorkPlanUseCase: ref.watch(getWorkPlanUseCaseProvider),
    createWorkPlanUseCase: ref.watch(createWorkPlanUseCaseProvider),
    updateWorkPlanUseCase: ref.watch(updateWorkPlanUseCaseProvider),
    deleteWorkPlanUseCase: ref.watch(deleteWorkPlanUseCaseProvider),
  );
});

/// Провайдер источника данных для работы с табелем (work_hours) через Supabase.
///
/// Используется для внедрения зависимости WorkHourDataSourceImpl во все репозитории и use-case, связанные с табелем учёта рабочего времени.
/// @returns WorkHourDataSource — реализация источника данных для работы с таблицей work_hours.
final workHourDataSourceProvider = Provider<WorkHourDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WorkHourDataSourceImpl(client);
});

/// Провайдер репозитория для работы с табелем (work_hours).
///
/// Инкапсулирует логику доступа к данным табеля через WorkHourDataSource.
/// Используется для внедрения в use-case и сервисы, связанные с учётом рабочего времени.
/// @returns WorkHourRepository — репозиторий для работы с табелем.
final workHourRepositoryProvider = Provider<WorkHourRepository>((ref) {
  final dataSource = ref.watch(workHourDataSourceProvider);
  return WorkHourRepositoryImpl(dataSource);
});

// ФОТ теперь рассчитывается динамически и не требует предварительного создания

// === BUSINESS TRIP RATES ===

/// Провайдер для DataSource командировочных ставок
final businessTripRateDataSourceProvider =
    Provider<BusinessTripRateDataSource>((ref) {
  return BusinessTripRateDataSource();
});

/// Провайдер для Repository командировочных ставок
final businessTripRateRepositoryProvider =
    Provider<BusinessTripRateRepository>((ref) {
  final dataSource = ref.watch(businessTripRateDataSourceProvider);
  return BusinessTripRateRepositoryImpl(dataSource);
});

/// Провайдер для UseCase получения всех ставок командировочных
final getBusinessTripRatesUseCaseProvider =
    Provider<GetBusinessTripRatesUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return GetBusinessTripRatesUseCase(repository);
});

/// Провайдер для UseCase получения ставок по объекту
final getBusinessTripRatesByObjectUseCaseProvider =
    Provider<GetBusinessTripRatesByObjectUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return GetBusinessTripRatesByObjectUseCase(repository);
});

/// Провайдер для UseCase получения активной ставки
final getActiveBusinessTripRateUseCaseProvider =
    Provider<GetActiveBusinessTripRateUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return GetActiveBusinessTripRateUseCase(repository);
});

/// Провайдер для UseCase создания ставки
final createBusinessTripRateUseCaseProvider =
    Provider<CreateBusinessTripRateUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return CreateBusinessTripRateUseCase(repository);
});

/// Провайдер для UseCase обновления ставки
final updateBusinessTripRateUseCaseProvider =
    Provider<UpdateBusinessTripRateUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return UpdateBusinessTripRateUseCase(repository);
});

/// Провайдер для UseCase удаления ставки
final deleteBusinessTripRateUseCaseProvider =
    Provider<DeleteBusinessTripRateUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return DeleteBusinessTripRateUseCase(repository);
});

/// Провайдер для UseCase получения ставок по сотруднику
final getBusinessTripRatesByEmployeeUseCaseProvider =
    Provider<GetBusinessTripRatesByEmployeeUseCase>((ref) {
  final repository = ref.watch(businessTripRateRepositoryProvider);
  return GetBusinessTripRatesByEmployeeUseCase(repository);
});

/// Провайдер для получения отчёта о выполнении смет.
final estimateCompletionProvider =
    FutureProvider<List<EstimateCompletionModel>>((ref) async {
  final dataSource = ref.watch(estimateDataSourceProvider);
  return dataSource.getEstimateCompletion();
});
