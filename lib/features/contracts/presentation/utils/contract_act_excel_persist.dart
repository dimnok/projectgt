import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/ks2/presentation/services/ks2_form_header_export_service.dart';

/// Генерирует Excel на сервере и сохраняет в Storage для акта [actId].
///
/// Таблица работ берётся из `contract_act_lines` ([actId]); [vorId] — fallback на сервере.
Future<void> persistContractActExcel({
  required WidgetRef ref,
  required String companyId,
  required String contractId,
  required String actId,
  required String vorId,
  String? actNumber,
  DateTime? actDocDate,
  DateTime? reportingPeriodFrom,
  DateTime? reportingPeriodTo,
  List<Ks2HeaderAddendumInput> addenda = const [],
}) async {
  final client = ref.read(supabaseClientProvider);
  final repository = ref.read(contractActRepositoryProvider);

  final generated = await Ks2FormHeaderExportService.generateDraftHeaderExcel(
    client: client,
    companyId: companyId,
    contractId: contractId,
    actNumber: actNumber,
    actDocDate: actDocDate,
    reportingPeriodFrom: reportingPeriodFrom,
    reportingPeriodTo: reportingPeriodTo,
    addenda: addenda,
    actId: actId,
    vorId: vorId,
  );

  await repository.attachKs2Excel(
    actId: actId,
    contractId: contractId,
    bytes: generated.bytes,
    displayFileName: generated.fileName,
  );
}

/// То же, что [persistContractActExcel], с сообщением об ошибке для только что созданного акта.
Future<void> persistContractActExcelAfterCreate({
  required WidgetRef ref,
  required String companyId,
  required String contractId,
  required String actId,
  required String vorId,
  String? actNumber,
  DateTime? actDocDate,
  DateTime? reportingPeriodFrom,
  DateTime? reportingPeriodTo,
  List<Ks2HeaderAddendumInput> addenda = const [],
}) async {
  try {
    await persistContractActExcel(
      ref: ref,
      companyId: companyId,
      contractId: contractId,
      actId: actId,
      vorId: vorId,
      actNumber: actNumber,
      actDocDate: actDocDate,
      reportingPeriodFrom: reportingPeriodFrom,
      reportingPeriodTo: reportingPeriodTo,
      addenda: addenda,
    );
  } catch (e) {
    throw Exception(
      'Акт сохранён (id: $actId), но не удалось сформировать Excel: $e',
    );
  }
}
