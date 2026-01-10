import 'package:projectgt/data/datasources/profile_data_source.dart';
import 'package:projectgt/data/models/profile_model.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/repositories/profile_repository.dart';

/// Имплементация [ProfileRepository] для работы с профилями через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class ProfileRepositoryImpl implements ProfileRepository {
  /// Data source для работы с профилями.
  final ProfileDataSource dataSource;

  /// Создаёт [ProfileRepositoryImpl] с указанным [dataSource].
  ProfileRepositoryImpl(this.dataSource);

  @override
  Future<Profile?> getProfile(String userId, [String? companyId]) async {
    final profileModel = await dataSource.getProfile(userId, companyId);
    return profileModel?.toDomain();
  }

  @override
  Future<List<Profile>> getProfiles(String companyId) async {
    final profileModels = await dataSource.getProfiles(companyId);
    return profileModels.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final profileModel =
        await dataSource.updateProfile(ProfileModel.fromDomain(profile));
    return profileModel.toDomain();
  }

  @override
  Future<void> deleteProfile(String userId) async {
    await dataSource.deleteProfile(userId);
  }
}
