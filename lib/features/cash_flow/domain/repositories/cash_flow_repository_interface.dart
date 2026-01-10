import 'package:projectgt/features/cash_flow/domain/entities/available_filters.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/cash_flow/domain/entities/monthly_analytics.dart';

/// Интерфейс репозитория для работы с модулем Cash Flow.
abstract class ICashFlowRepository {
  /// Получает список записей банковской выписки для конкретного счета.
  Future<List<BankStatementEntry>> getBankStatementEntries(String accountId);

  /// Сохраняет список записей банковской выписки.
  Future<void> saveBankStatementEntries(List<BankStatementEntry> entries);

  /// Получает набор всех существующих хешей операций для компании.
  /// Используется для дедупликации при импорте.
  Future<Set<String>> getExistingOperationHashes();

  /// Получает список финансовых операций с поддержкой пагинации и поиска.
  Future<List<CashFlowTransaction>> getTransactions({
    String? objectId,
    String? contractId,
    List<String>? contractIds,
    String? contractorId,
    List<String>? types,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    int? limit,
    int? offset,
  });

  /// Сохраняет новую или обновляет существующую операцию.
  Future<CashFlowTransaction> saveTransaction(CashFlowTransaction transaction);

  /// Переносит запись из выписки в основную таблицу транзакций.
  /// 
  /// Создает запись в [cash_flow] и помечает [BankStatementEntry] как импортированную.
  Future<void> processBankStatementEntry({
    required String entryId,
    required CashFlowTransaction transaction,
  });

  /// Удаляет операцию по её идентификатору.
  Future<void> deleteTransaction(String id);

  /// Получает список категорий (статей) ДДС.
  Future<List<CashFlowCategory>> getCategories();

  /// Сохраняет (создаёт или обновляет) статью ДДС.
  Future<void> saveCategory(CashFlowCategory category);

  /// Удаляет статью ДДС.
  Future<void> deleteCategory(String id);

  /// Получает список шаблонов импорта банковских выписок.
  Future<List<BankImportTemplate>> getBankImportTemplates();

  /// Сохраняет (создаёт или обновляет) шаблон импорта.
  Future<BankImportTemplate> saveBankImportTemplate(BankImportTemplate template);

  /// Удаляет шаблон импорта.
  Future<void> deleteBankImportTemplate(String id);

  /// Получает списки доступных ID для фильтрации (объекты, контрагенты, договоры) за период.
  Future<AvailableFilters> getAvailableFilters({
    required DateTime fromDate,
    required DateTime toDate,
  });

  /// Получает агрегированную аналитику по месяцам за указанный год.
  Future<List<MonthlyAnalytics>> getYearlyAnalytics(
    int year, {
    String? objectId,
    String? contractorId,
    List<String>? contractIds,
    List<String>? types,
    String? search,
  });
}
