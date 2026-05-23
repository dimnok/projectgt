import '../../../../core/utils/contract_number_match.dart';

/// Результат сравнения договора в накладной с выбранным в приложении.
enum ReceiptContractMatchStatus {
  /// Договор в файле совпадает с выбранным.
  match,

  /// В файле указан другой договор.
  mismatch,

  /// В файле не распознан номер договора.
  missingInFile,

  /// Строка не участвует в сравнении (ошибка парсинга файла).
  skipped,
}

/// Сравнивает договор из Excel с выбранным в модуле «Материалы».
ReceiptContractMatchStatus evaluateReceiptContractMatch({
  required String? fileContractNumber,
  required String selectedContractNumber,
  required bool hasParseError,
}) {
  if (hasParseError) return ReceiptContractMatchStatus.skipped;
  final file = fileContractNumber?.trim() ?? '';
  final selected = selectedContractNumber.trim();
  if (selected.isEmpty) return ReceiptContractMatchStatus.skipped;
  if (file.isEmpty) return ReceiptContractMatchStatus.missingInFile;
  if (contractNumbersMatch(file, selected)) {
    return ReceiptContractMatchStatus.match;
  }
  return ReceiptContractMatchStatus.mismatch;
}

/// Накладные с расхождением договора (для предупреждения в предпросмотре).
bool isReceiptContractMismatch(ReceiptContractMatchStatus status) {
  return status == ReceiptContractMatchStatus.mismatch ||
      status == ReceiptContractMatchStatus.missingInFile;
}
