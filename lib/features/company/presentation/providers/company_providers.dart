import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/data/datasources/company_data_source.dart';
import 'package:projectgt/features/company/data/repositories/company_repository_impl.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/domain/entities/company_document.dart';
import 'package:projectgt/features/company/domain/repositories/company_repository.dart';

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

/// Провайдер профиля компании.
final companyProfileProvider = FutureProvider<CompanyProfile?>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getCompanyProfile();
});

/// Провайдер банковских счетов компании.
final companyBankAccountsProvider = FutureProvider<List<CompanyBankAccount>>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getBankAccounts();
});

/// Провайдер документов компании.
final companyDocumentsProvider = FutureProvider<List<CompanyDocument>>((ref) async {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getDocuments();
});

