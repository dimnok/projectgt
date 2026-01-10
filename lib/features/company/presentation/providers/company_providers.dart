import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/company/data/datasources/company_data_source.dart';
import 'package:projectgt/features/company/data/repositories/company_repository_impl.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';
import 'package:projectgt/features/company/domain/repositories/company_repository.dart';
import 'package:projectgt/features/company/domain/usecases/create_company_usecase.dart';
import 'package:projectgt/features/company/domain/usecases/join_company_usecase.dart';
import 'package:projectgt/features/company/domain/usecases/update_member_usecase.dart';

/// Провайдер источника данных Компании.
final companyDataSourceProvider = Provider<CompanyDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCompanyDataSource(client);
});

/// Провайдер репозитория Компании.
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final dataSource = ref.watch(companyDataSourceProvider);
  return CompanyRepositoryImpl(dataSource);
});

/// Провайдер UseCase создания компании.
final createCompanyUseCaseProvider = Provider<CreateCompanyUseCase>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return CreateCompanyUseCase(repository);
});

/// Провайдер UseCase вступления в компанию.
final joinCompanyUseCaseProvider = Provider<JoinCompanyUseCase>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return JoinCompanyUseCase(repository);
});

/// Провайдер UseCase обновления участника.
final updateMemberUseCaseProvider = Provider<UpdateMemberUseCase>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return UpdateMemberUseCase(repository);
});

/// Провайдер профиля компании.
final companyProfileProvider = FutureProvider<CompanyProfile?>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  if (activeCompanyId == null) return null;
  return repository.getCompanyProfile(companyId: activeCompanyId);
});

/// Провайдер банковских счетов компании.
final companyBankAccountsProvider = FutureProvider<List<CompanyBankAccount>>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  if (activeCompanyId == null) return [];
  return repository.getBankAccounts(companyId: activeCompanyId);
});

/// Провайдер документов компании.
final companyDocumentsProvider = FutureProvider<List<CompanyDocument>>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  final activeCompanyId = ref.watch(activeCompanyIdProvider);
  if (activeCompanyId == null) return [];
  return repository.getDocuments(companyId: activeCompanyId);
});

/// Провайдер ID активной компании текущего пользователя.
///
/// Извлекает [last_company_id] из профиля текущего пользователя.
final activeCompanyIdProvider = Provider<String?>((ref) {
  final profileState = ref.watch(currentUserProfileProvider);
  return profileState.profile?.lastCompanyId;
});

/// Провайдер списка компаний текущего пользователя.
final userCompaniesProvider = FutureProvider<List<CompanyProfile>>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getMyCompanies();
});
