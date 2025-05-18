import 'package:projectgt/data/datasources/contract_data_source.dart';
import 'package:projectgt/data/models/contract_model.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/repositories/contract_repository.dart';

/// Имплементация [ContractRepository] для работы с договорами через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class ContractRepositoryImpl implements ContractRepository {
  /// Data source для работы с договорами.
  final ContractDataSource dataSource;

  /// Создаёт [ContractRepositoryImpl] с указанным [dataSource].
  ContractRepositoryImpl(this.dataSource);

  @override
  Future<List<Contract>> getContracts() async {
    final models = await dataSource.getContracts();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<Contract?> getContract(String id) async {
    final model = await dataSource.getContract(id);
    return model?.toDomain();
  }

  @override
  Future<Contract> createContract(Contract contract) async {
    final model = await dataSource.createContract(contract);
    return model.toDomain();
  }

  @override
  Future<Contract> updateContract(Contract contract) async {
    final model = await dataSource.updateContract(ContractModel.fromDomain(contract));
    return model.toDomain();
  }

  @override
  Future<void> deleteContract(String id) async {
    await dataSource.deleteContract(id);
  }
} 