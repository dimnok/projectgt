import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/domain/repositories/settlement_file_repository.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_files_state.dart';

/// Описание автосгенерированного PDF счёта в [settlement_files].
///
/// Используется для поиска и перезаписи предыдущей версии при повторном формировании.
const kSettlementInvoicePdfDescription =
    'Счёт на оплату (сформирован автоматически)';

/// Базовое имя PDF без расширения: `Счёт на оплату № {номер} от {дата}`.
String buildSettlementInvoicePdfBaseName(SettlementOperation operation) {
  final number = _sanitizeSettlementInvoiceFileNameSegment(
    operation.invoiceNumber.trim(),
  );
  final date = formatRuDate(operation.invoiceDate);
  return 'Счёт на оплату № $number от $date';
}

/// Убирает символы, недопустимые в имени файла на Windows/macOS.
String _sanitizeSettlementInvoiceFileNameSegment(String value) {
  return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
}

/// Полное имя файла PDF счёта.
String buildSettlementInvoicePdfFileName(SettlementOperation operation) {
  return '${buildSettlementInvoicePdfBaseName(operation)}.pdf';
}

/// Сохраняет PDF через репозиторий, перезаписывая предыдущую автоверсию.
///
/// Сначала загружает новый файл, затем удаляет старые — чтобы не потерять PDF при сбое upload.
Future<PersistGeneratedInvoicePdfResult> persistGeneratedInvoicePdfToStorage({
  required SettlementFileRepository repository,
  required String settlementOperationId,
  required List<int> bytes,
  required String fileName,
  required String description,
}) async {
  try {
    final allFiles = await repository.getFiles(settlementOperationId);
    final existing =
        allFiles.where((f) => f.description == description).toList();
    final replaced = existing.isNotEmpty;

    final created = await repository.uploadFileBytes(
      settlementOperationId: settlementOperationId,
      bytes: bytes,
      fileName: fileName,
      description: description,
    );

    for (final old in existing) {
      await repository.deleteFile(old.id, old.filePath);
    }

    return (file: created, replaced: replaced);
  } catch (_) {
    return (file: null, replaced: false);
  }
}

/// Сохраняет байты PDF в Storage и [settlement_files], перезаписывая предыдущую версию.
///
/// Не использует [settlementFilesProvider], чтобы не создавать autoDispose-notifier
/// без подписчиков (например, при сохранении нового счёта из формы).
Future<PersistGeneratedInvoicePdfResult> persistSettlementInvoicePdf({
  required WidgetRef ref,
  required String settlementOperationId,
  required List<int> bytes,
  required String fileName,
}) async {
  final repository = ref.read(settlementFileRepositoryProvider);
  final result = await persistGeneratedInvoicePdfToStorage(
    repository: repository,
    settlementOperationId: settlementOperationId,
    bytes: bytes,
    fileName: fileName,
    description: kSettlementInvoicePdfDescription,
  );

  ref.invalidate(settlementFilesProvider(settlementOperationId));
  return result;
}
