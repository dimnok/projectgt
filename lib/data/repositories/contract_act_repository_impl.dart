import 'package:projectgt/data/datasources/contract_act_data_source.dart';
import 'package:projectgt/data/datasources/contract_act_ks2_remote_data_source.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_line.dart';
import 'package:projectgt/domain/entities/contract_act_kind.dart';
import 'package:projectgt/domain/entities/contract_act_ks2_preview.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/domain/repositories/contract_act_repository.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';

/// Реализация [ContractActRepository].
class ContractActRepositoryImpl implements ContractActRepository {
  /// Создаёт репозиторий.
  ContractActRepositoryImpl(
    this._dataSource,
    this._ks2Remote,
    this._activeCompanyId,
  );

  final ContractActDataSource _dataSource;
  final ContractActKs2RemoteDataSource _ks2Remote;
  final String _activeCompanyId;

  void _assertCompany(String companyId) {
    if (companyId != _activeCompanyId) {
      throw ArgumentError('companyId не совпадает с активной компанией');
    }
  }

  @override
  Future<List<ContractAct>> listByContract(String contractId) async {
    final rows = await _dataSource.listByContract(
      contractId: contractId,
      companyId: _activeCompanyId,
    );
    return rows.map((e) => e.toEntity()).toList();
  }

  @override
  Future<ContractAct> createManual({
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
    _assertCompany(companyId);
    final model = await _dataSource.insert(
      companyId: companyId,
      contractId: contractId,
      actKind: ContractActKind.manual,
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
      amountSource: ContractActAmountSource.manual,
      note: note,
      workflowStatus: workflowStatus,
      paymentStatus: paymentStatus,
    );
    return model.toEntity();
  }

  @override
  Future<ContractAct> updateStatuses({
    required String id,
    required String companyId,
    required String contractId,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    _assertCompany(companyId);
    final model = await _dataSource.updateStatusesRow(
      id: id,
      companyId: companyId,
      contractId: contractId,
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
    ContractActAmountSource? amountSource,
  }) async {
    _assertCompany(companyId);
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
      amountSource: amountSource ?? ContractActAmountSource.manual,
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
    _assertCompany(companyId);
    final excelPath = await _dataSource.fetchExcelPath(
      actId: id,
      companyId: companyId,
    );
    await _dataSource.unlinkWorkItems(actId: id, companyId: companyId);
    await _dataSource.deleteRow(
      id: id,
      companyId: companyId,
      contractId: contractId,
    );
    await _ks2Remote.removeExcelIfExists(excelPath);
  }

  @override
  Future<ContractActKs2Preview> previewKs2({
    required String contractId,
    required String vorId,
  }) async {
    return _ks2Remote.preview(contractId: contractId, vorId: vorId);
  }

  @override
  Future<ContractActKs2Preview> previewKs2ByActId({
    required String contractId,
    required String actId,
  }) async {
    return _ks2Remote.previewByAct(
      contractId: contractId,
      actId: actId,
    );
  }

  @override
  Future<List<ContractActLine>> listActLines(String actId) async {
    final rows = await _dataSource.listLinesByActId(
      actId: actId,
      companyId: _activeCompanyId,
    );
    return rows.map((e) => e.toEntity()).toList();
  }

  @override
  Future<String> createKs2Act({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    double advanceRetention = 0,
    double warrantyRetention = 0,
    double otherRetentions = 0,
  }) async {
    return _ks2Remote.createAct(
      contractId: contractId,
      vorId: vorId,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
    );
  }

  @override
  Future<void> attachKs2Excel({
    required String actId,
    required String contractId,
    required List<int> bytes,
    required String displayFileName,
  }) async {
    final previousPath = await _dataSource.fetchExcelPath(
      actId: actId,
      companyId: _activeCompanyId,
    );
    final path = await _ks2Remote.uploadExcel(
      actId: actId,
      contractId: contractId,
      bytes: bytes,
      displayFileName: displayFileName,
    );
    await _dataSource.updateExcelPath(
      actId: actId,
      companyId: _activeCompanyId,
      excelPath: path,
    );
    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != path) {
      await _ks2Remote.removeExcelIfExists(previousPath);
    }
  }

  @override
  Future<ContractAct> saveKs2HeaderAndRetentions({
    required ContractAct act,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required double advanceRetention,
    required double warrantyRetention,
    required double otherRetentions,
    required ContractActWorkflowStatus workflowStatus,
    required ContractActPaymentStatus paymentStatus,
  }) async {
    _assertCompany(act.companyId);
    if (!act.isKs2) {
      throw ArgumentError('saveKs2HeaderAndRetentions только для актов КС-2');
    }

    final title = act.title.trim().isNotEmpty
        ? act.title.trim()
        : 'Акт КС-2 № $number';

    return update(
      id: act.id,
      companyId: act.companyId,
      contractId: act.contractId,
      title: title,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      amount: act.amount,
      vatAmount: act.vatAmount,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
      note: act.note,
      workflowStatus: workflowStatus,
      paymentStatus: paymentStatus,
      amountSource: act.amountSource,
    );
  }

  @override
  Future<ContractAct> saveKs2ActEdits({
    required ContractAct act,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    required Map<String, double> quantitiesByLineId,
    Set<String> deletedLineIds = const {},
    double advanceRetention = 0,
    double warrantyRetention = 0,
    double otherRetentions = 0,
  }) async {
    _assertCompany(act.companyId);
    if (!act.isKs2) {
      throw ArgumentError('saveKs2ActEdits только для актов КС-2');
    }

    for (final lineId in deletedLineIds) {
      await _dataSource.deleteActLine(
        lineId: lineId,
        companyId: act.companyId,
      );
    }

    final lines = await _dataSource.listLinesByActId(
      actId: act.id,
      companyId: act.companyId,
    );

    var totalAmount = 0.0;
    for (final line in lines) {
      if (deletedLineIds.contains(line.id)) continue;
      final rawQty = quantitiesByLineId[line.id] ?? line.quantity;
      if (rawQty.isNaN || rawQty < 0) {
        throw ArgumentError('Некорректное количество: ${line.name}');
      }
      final backlog = line.backlogQuantity;
      final current = backlog > 0
          ? (rawQty - backlog).clamp(0.0, double.infinity)
          : rawQty;
      final amount = rawQty * line.price;

      final changed = rawQty != line.quantity ||
          amount != line.amount ||
          current != line.currentPeriodQuantity;

      if (changed) {
        await _dataSource.updateActLineQuantities(
          lineId: line.id,
          companyId: act.companyId,
          quantity: rawQty,
          amount: amount,
          backlogQuantity: backlog,
          currentPeriodQuantity: current,
        );
      }
      totalAmount += amount;
    }

    await _dataSource.clearActExcelPath(
      actId: act.id,
      companyId: act.companyId,
    );

    final vatTerms = await _dataSource.fetchContractVatTerms(
      contractId: act.contractId,
      companyId: act.companyId,
    );
    final split = splitActAmountForStorage(
      lineTotal: totalAmount,
      vatTerms: vatTerms,
    );

    final title = act.title.trim().isNotEmpty
        ? act.title.trim()
        : 'Акт КС-2 № $number';

    return update(
      id: act.id,
      companyId: act.companyId,
      contractId: act.contractId,
      title: title,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      amount: split.amount,
      vatAmount: split.vatAmount,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
      note: act.note,
      workflowStatus: act.workflowStatus,
      paymentStatus: act.paymentStatus,
      amountSource: act.amountSource,
    );
  }

  @override
  Future<List<int>> downloadKs2Excel(String actId) async {
    final path = await _dataSource.fetchExcelPath(
      actId: actId,
      companyId: _activeCompanyId,
    );
    if (path == null || path.isEmpty) {
      throw Exception('Файл акта ещё не сохранён');
    }
    return _ks2Remote.downloadExcel(path);
  }
}
