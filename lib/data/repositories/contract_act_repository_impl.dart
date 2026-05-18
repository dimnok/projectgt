import 'package:projectgt/data/datasources/contract_act_data_source.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/domain/repositories/contract_act_repository.dart';

/// Реализация [ContractActRepository].
class ContractActRepositoryImpl implements ContractActRepository {
  /// Источник данных.
  final ContractActDataSource _dataSource;

  /// Активная компания (изоляция данных).
  final String _activeCompanyId;

  /// Создаёт репозиторий.
  ContractActRepositoryImpl(this._dataSource, this._activeCompanyId);

  @override
  Future<List<ContractAct>> listByContract(String contractId) async {
    final rows = await _dataSource.listByContract(
      contractId: contractId,
      companyId: _activeCompanyId,
    );
    return rows.map((e) => e.toEntity()).toList();
  }

  @override
  Future<ContractAct> create({
    required String companyId,
    required String contractId,
    required String title,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required double amount,
    required double vatAmount,
    required double advanceRetention,
    required double warrantyRetention,
    required double otherRetentions,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    if (companyId != _activeCompanyId) {
      throw ArgumentError('companyId не совпадает с активной компанией');
    }
    final model = await _dataSource.insert(
      companyId: companyId,
      contractId: contractId,
      title: title,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      amount: amount,
      vatAmount: vatAmount,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
      note: note,
      workflowStatus: workflowStatus,
      paymentStatus: paymentStatus,
    );
    return model.toEntity();
  }

  @override
  Future<ContractAct> update({
    required String id,
    required String companyId,
    required String contractId,
    required String title,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required double amount,
    required double vatAmount,
    required double advanceRetention,
    required double warrantyRetention,
    required double otherRetentions,
    String? note,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    if (companyId != _activeCompanyId) {
      throw ArgumentError('companyId не совпадает с активной компанией');
    }
    final model = await _dataSource.updateRow(
      id: id,
      companyId: companyId,
      contractId: contractId,
      title: title,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      amount: amount,
      vatAmount: vatAmount,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
      note: note,
      workflowStatus: workflowStatus,
      paymentStatus: paymentStatus,
    );
    return model.toEntity();
  }

  @override
  Future<void> delete({
    required String id,
    required String companyId,
    required String contractId,
  }) async {
    if (companyId != _activeCompanyId) {
      throw ArgumentError('companyId не совпадает с активной компанией');
    }
    await _dataSource.deleteRow(
      id: id,
      companyId: companyId,
      contractId: contractId,
    );
  }
}
