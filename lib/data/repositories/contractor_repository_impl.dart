import 'package:projectgt/data/datasources/contractor_data_source.dart';
import 'package:projectgt/data/models/contractor_model.dart';
import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/domain/repositories/contractor_repository.dart';

/// Имплементация [ContractorRepository] для работы с контрагентами через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class ContractorRepositoryImpl implements ContractorRepository {
  /// Data source для работы с контрагентами.
  final ContractorDataSource dataSource;

  /// Создаёт [ContractorRepositoryImpl] с указанным [dataSource].
  ContractorRepositoryImpl(this.dataSource);

  @override
  Future<List<Contractor>> getContractors() async {
    final models = await dataSource.getContractors();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<Contractor?> getContractor(String id) async {
    final model = await dataSource.getContractor(id);
    return model?.toDomain();
  }

  @override
  Future<Contractor> createContractor(Contractor contractor) async {
    final model = await dataSource.createContractor(ContractorModel.fromDomain(contractor));
    return model.toDomain();
  }

  @override
  Future<Contractor> updateContractor(Contractor contractor) async {
    final model = await dataSource.updateContractor(ContractorModel.fromDomain(contractor));
    return model.toDomain();
  }

  @override
  Future<void> deleteContractor(String id) async {
    await dataSource.deleteContractor(id);
  }
} 