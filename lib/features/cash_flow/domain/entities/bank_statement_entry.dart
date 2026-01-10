import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';

part 'bank_statement_entry.freezed.dart';

/// Сущность "Запись банковской выписки".
/// 
/// Представляет собой одну строку из импортированного файла банка
/// до того, как она будет окончательно разнесена в Cash Flow.
@freezed
abstract class BankStatementEntry with _$BankStatementEntry {
  /// Создает экземпляр [BankStatementEntry].
  const factory BankStatementEntry({
    /// Уникальный ID записи.
    required String id,
    /// ID компании.
    required String companyId,
    /// ID банковского счета.
    required String bankAccountId,
    /// Дата операции из выписки.
    required DateTime date,
    /// Сумма операции.
    required double amount,
    /// Тип операции (приход/расход).
    required CashFlowType type,
    /// Название контрагента из выписки.
    String? contractorName,
    /// ИНН контрагента из выписки.
    String? contractorInn,
    /// Комментарий/назначение платежа.
    String? comment,
    /// Номер транзакции в банке.
    String? transactionNumber,
    /// Статус импорта (уже создана ли транзакция в системе).
    @Default(false) bool isImported,
    /// ID связанной транзакции (если уже импортировано).
    String? linkedTransactionId,
    /// Уникальный хеш операции для дедупликации.
    String? operationHash,
  }) = _BankStatementEntry;
}

/// Результат импорта банковской выписки со статистикой.
class BankImportStats {
  /// Общее количество записей в файле.
  final int total;
  /// Количество новых (добавленных) записей.
  final int added;
  /// Количество пропущенных дубликатов.
  final int skipped;

  /// Создает экземпляр [BankImportStats].
  const BankImportStats({
    required this.total,
    required this.added,
    required this.skipped,
  });

  /// Были ли добавлены новые записи.
  bool get hasNew => added > 0;
}

