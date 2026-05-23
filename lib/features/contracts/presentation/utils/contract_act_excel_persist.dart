import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/ks2/presentation/services/ks2_form_header_export_service.dart';

/// Генерирует Excel по полям формы и сохраняет в Storage для акта [actId].
///
/// При ошибке загрузки файла удаляет созданную запись `contract_acts` (откат).
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
  final client = ref.read(supabaseClientProvider);
  final repository = ref.read(contractActRepositoryProvider);

  try {
    final generated = await Ks2FormHeaderExportService.generateDraftHeaderExcel(
      client: client,
      companyId: companyId,
      contractId: contractId,
      actNumber: actNumber,
      actDocDate: actDocDate,
      reportingPeriodFrom: reportingPeriodFrom,
      reportingPeriodTo: reportingPeriodTo,
      addenda: addenda,
      vorId: vorId,
    );

    await repository.attachKs2Excel(
      actId: actId,
      contractId: contractId,
      bytes: generated.bytes,
      displayFileName: generated.fileName,
    );
  } catch (e) {
    try {
      await repository.delete(
        id: actId,
        companyId: companyId,
        contractId: contractId,
      );
    } catch (_) {
      // Откат записи не удался.
    }
    rethrow;
  }
}
