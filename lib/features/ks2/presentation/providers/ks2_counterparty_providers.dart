import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';

/// Профиль компании и список контрагентов для шапки КС-2.
///
/// Ошибка загрузки профиля не блокирует контрагентов: [CompanyProfile] будет `null`.
final ks2PartiesContextProvider = FutureProvider.autoDispose
    .family<({CompanyProfile? profile, List<Contractor> contractors}), String>((ref, companyId) async {
  final repository = ref.watch(companyRepositoryProvider);
  final useCase = ref.watch(getContractorsUseCaseProvider);

  CompanyProfile? profile;
  try {
    profile = await repository.getCompanyProfile(companyId: companyId);
  } catch (_) {
    profile = null;
  }

  final contractors = await useCase.execute(companyId);
  return (profile: profile, contractors: contractors);
});
