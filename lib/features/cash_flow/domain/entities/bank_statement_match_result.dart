import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_statement_match_result.freezed.dart';

/// Уровень уверенности автосопоставления строки выписки.
enum BankStatementMatchConfidence {
  /// Все обязательные поля определены — можно обработать автоматически.
  high,

  /// Частичное совпадение — нужна проверка человека.
  medium,

  /// Недостаточно данных для автоматической обработки.
  low,
}

/// Результат автосопоставления одной строки банковской выписки.
@freezed
abstract class BankStatementMatchResult with _$BankStatementMatchResult {
  /// Создаёт [BankStatementMatchResult].
  const factory BankStatementMatchResult({
    /// ID строки выписки.
    required String entryId,

    /// Уровень уверенности.
    required BankStatementMatchConfidence confidence,

    /// Подобранная статья ДДС.
    String? categoryId,

    /// Подобранный контрагент.
    String? contractorId,

    /// Подобранный договор.
    String? contractId,

    /// Подобранный объект (из договора).
    String? objectId,

    /// Подобранный счёт взаиморасчётов (опционально).
    String? settlementOperationId,

    /// Пояснения для UI (источник совпадения / причина низкой уверенности).
    @Default([]) List<String> matchReasons,
  }) = _BankStatementMatchResult;

  const BankStatementMatchResult._();

  /// Строка готова к пакетной обработке без ручной проверки.
  bool get isAutoProcessable => confidence == BankStatementMatchConfidence.high;
}

/// Результат пакетной обработки выписки.
class BankStatementBatchProcessResult {
  /// Количество успешно обработанных строк.
  final int processed;

  /// Ошибки по строкам.
  final List<BankStatementBatchFailure> failures;

  /// Создаёт [BankStatementBatchProcessResult].
  const BankStatementBatchProcessResult({
    required this.processed,
    required this.failures,
  });

  /// Общее число неуспешных строк.
  int get failedCount => failures.length;
}

/// Ошибка обработки одной строки выписки в пакете.
class BankStatementBatchFailure {
  /// ID строки выписки.
  final String entryId;

  /// Текст ошибки.
  final String error;

  /// Создаёт [BankStatementBatchFailure].
  const BankStatementBatchFailure({
    required this.entryId,
    required this.error,
  });
}
