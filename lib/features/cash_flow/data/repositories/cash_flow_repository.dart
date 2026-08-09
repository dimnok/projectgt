import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/cash_flow/domain/entities/available_filters.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_match_result.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_matching_context.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category_rule.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/cash_flow/domain/entities/monthly_analytics.dart';
import 'package:projectgt/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';
import 'package:projectgt/features/cash_flow/data/models/cash_flow_transaction_model.dart';
import 'package:projectgt/features/cash_flow/data/models/cash_flow_category_model.dart';
import 'package:projectgt/features/cash_flow/data/models/bank_import_template_model.dart';
import 'package:projectgt/features/cash_flow/data/models/bank_statement_entry_model.dart';
import 'package:projectgt/features/cash_flow/data/models/cash_flow_category_rule_model.dart';

/// Реализация репозитория Cash Flow с использованием Supabase.
class CashFlowRepository implements ICashFlowRepository {
  final SupabaseClient _client;
  final String _activeCompanyId;

  /// Создаёт экземпляр [CashFlowRepository].
  CashFlowRepository(this._client, this._activeCompanyId);

  static const _tableName = 'cash_flow';
  static const _categoriesTable = 'cash_flow_categories';
  static const _bankTemplatesTable = 'bank_import_templates';
  static const _bankEntriesTable = 'bank_statement_entries';
  static const _categoryRulesTable = 'cash_flow_category_rules';

  @override
  Future<List<BankStatementEntry>> getBankStatementEntries(String accountId) async {
    final response = await _client
        .from(_bankEntriesTable)
        .select()
        .eq('company_id', _activeCompanyId)
        .eq('bank_account_id', accountId)
        .eq('is_imported', false)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => BankStatementEntryModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<void> saveBankStatementEntries(List<BankStatementEntry> entries) async {
    if (entries.isEmpty) return;

    final jsonList = entries.map((entry) {
      final json = BankStatementEntryModel.fromEntity(entry).toJson();
      json['company_id'] = _activeCompanyId;
      // Если ID временный, удаляем его, чтобы БД сгенерировала новый
      if (entry.id.startsWith('temp_') || entry.id.length < 30) {
        json.remove('id');
      }
      return json;
    }).toList();

    // Используем upsert для автоматической обработки дублей по operation_hash
    await _client.from(_bankEntriesTable).upsert(
          jsonList,
          onConflict: 'company_id, operation_hash',
        );
  }

  @override
  Future<Set<String>> getExistingOperationHashes() async {
    // Получаем хеши из обеих таблиц: буфера и финальных транзакций
    final results = await Future.wait([
      _client
          .from(_bankEntriesTable)
          .select('operation_hash')
          .eq('company_id', _activeCompanyId)
          .not('operation_hash', 'is', null),
      _client
          .from(_tableName)
          .select('operation_hash')
          .eq('company_id', _activeCompanyId)
          .not('operation_hash', 'is', null),
    ]);

    final hashes = <String>{};
    for (final result in results) {
      for (final row in result as List) {
        final hash = row['operation_hash'] as String?;
        if (hash != null) hashes.add(hash);
      }
    }
    return hashes;
  }

  /// Базовый select-запрос с join-ами для получения полной информации об операции.
  static const _transactionSelect = '''
    *,
    objects:object_id(name),
    contracts:contract_id(number),
    contractors:contractor_id(short_name),
    cash_flow_categories:category_id(name),
    profiles:created_by(short_name)
  ''';

  @override
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
  }) async {
    // Принудительная фильтрация по активной компании
    dynamic query = _client
        .from(_tableName)
        .select(_transactionSelect)
        .eq('company_id', _activeCompanyId);

    if (objectId != null) query = query.eq('object_id', objectId);
    if (contractId != null) query = query.eq('contract_id', contractId);
    if (contractIds != null && contractIds.isNotEmpty) {
      query = query.inFilter('contract_id', contractIds);
    }
    if (contractorId != null) query = query.eq('contractor_id', contractorId);
    if (types != null && types.isNotEmpty) {
      query = query.inFilter('type', types);
    }
    if (fromDate != null) query = query.gte('date', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('date', toDate.toIso8601String());

    if (search != null && search.isNotEmpty) {
      // Поиск по вычисляемой колонке (объект, договор, контрагент, категория, комментарий)
      query = query.ilike('cash_flow_search_text', '%$search%');
    }

    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + (limit ?? 50) - 1);

    final response = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => CashFlowTransactionModel.fromJson(json).toDomain())
        .toList();
  }

  @override
  Future<CashFlowTransaction> saveTransaction(CashFlowTransaction transaction) async {
    final model = CashFlowTransactionModel.fromDomain(transaction);
    final json = model.toJson();
    
    // Принудительно устанавливаем ID компании
    json['company_id'] = _activeCompanyId;

    // Удаляем ID если это новая запись
    if (transaction.id.isEmpty || transaction.id.startsWith('temp_')) {
      json.remove('id');
    }

    // Удаляем null-поля, для которых в БД есть default значения
    if (json['created_at'] == null) json.remove('created_at');
    if (json['date'] == null) json.remove('date');
    if (json['operation_hash'] == null) json.remove('operation_hash');

    // Устанавливаем текущего пользователя как создателя, если это новая запись
    if (json['created_by'] == null) {
      json['created_by'] = _client.auth.currentUser?.id;
    }

    final response = await _client
        .from(_tableName)
        .upsert(json)
        .select(_transactionSelect)
        .single();

    return CashFlowTransactionModel.fromJson(response).toDomain();
  }

  @override
  Future<void> processBankStatementEntry({
    required String entryId,
    required CashFlowTransaction transaction,
    String? settlementOperationId,
  }) async {
    final model = CashFlowTransactionModel.fromDomain(transaction);
    final json = model.toJson();

    final params = {
      'p_entry_id': entryId,
      'p_company_id': _activeCompanyId,
      'p_date': json['date'],
      'p_type': json['type'],
      'p_amount': json['amount'],
      'p_category_id': json['category_id'],
      'p_object_id': json['object_id'],
      'p_contract_id': json['contract_id'],
      'p_contractor_id': json['contractor_id'],
      'p_contractor_name': json['contractor_name'],
      'p_contractor_inn': json['contractor_inn'],
      'p_comment': json['comment'],
      'p_operation_hash': json['operation_hash'],
      'p_created_by': _client.auth.currentUser?.id,
      if (settlementOperationId != null)
        'p_settlement_operation_id': settlementOperationId,
    };

    await _client.rpc('process_bank_statement_entry', params: params);
  }

  @override
  Future<void> deleteBankStatementEntry(String id) async {
    await _client.from(_bankEntriesTable).delete().eq('id', id);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  @override
  Future<List<CashFlowCategory>> getCategories() async {
    final response = await _client
        .from(_categoriesTable)
        .select()
        .eq('company_id', _activeCompanyId)
        .order('name');

    return (response as List)
        .map((json) => CashFlowCategoryModel.fromJson(json).toDomain())
        .toList();
  }

  @override
  Future<void> saveCategory(CashFlowCategory category) async {
    final model = CashFlowCategoryModel.fromDomain(category);
    final json = model.toJson();

    // Принудительно устанавливаем ID компании
    json['company_id'] = _activeCompanyId;

    // Удаляем ID если это новая запись
    if (category.id.isEmpty || category.id == '') {
      json.remove('id');
    }

    // Удаляем null-поля, для которых в БД есть default значения (now())
    if (json['created_at'] == null) json.remove('created_at');

    await _client.from(_categoriesTable).upsert(json);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _client.from(_categoriesTable).delete().eq('id', id);
  }

  @override
  Future<List<BankImportTemplate>> getBankImportTemplates() async {
    final response = await _client
        .from(_bankTemplatesTable)
        .select()
        .eq('company_id', _activeCompanyId)
        .order('bank_name');

    return (response as List)
        .map((json) => BankImportTemplateModel.fromJson(json).toDomain())
        .toList();
  }

  @override
  Future<BankImportTemplate> saveBankImportTemplate(
      BankImportTemplate template) async {
    final model = BankImportTemplateModel.fromDomain(template);
    final json = model.toJson();

    // Принудительно устанавливаем ID компании
    json['company_id'] = _activeCompanyId;

    // Удаляем ID если это новая запись
    if (template.id.isEmpty || template.id == '') {
      json.remove('id');
    }

    final response = await _client
        .from(_bankTemplatesTable)
        .upsert(json)
        .select()
        .single();

    return BankImportTemplateModel.fromJson(response).toDomain();
  }

  @override
  Future<void> deleteBankImportTemplate(String id) async {
    await _client.from(_bankTemplatesTable).delete().eq('id', id);
  }

  @override
  Future<AvailableFilters> getAvailableFilters({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await _client.rpc('get_cash_flow_available_filters', params: {
      'p_company_id': _activeCompanyId,
      'p_start_date': fromDate.toIso8601String(),
      'p_end_date': toDate.toIso8601String(),
    });

    if (response == null || (response as List).isEmpty) {
      return const AvailableFilters();
    }

    final data = response[0] as Map<String, dynamic>;

    return AvailableFilters(
      objectIds: (data['object_ids'] as List?)?.map((e) => e.toString()).toSet() ?? {},
      contractorIds: (data['contractor_ids'] as List?)?.map((e) => e.toString()).toSet() ?? {},
      contractIds: (data['contract_ids'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    );
  }

  @override
  Future<List<MonthlyAnalytics>> getYearlyAnalytics(
    int year, {
    String? objectId,
    String? contractorId,
    List<String>? contractIds,
    List<String>? types,
    String? search,
  }) async {
    final fromDate = DateTime(year, 1, 1).toIso8601String();
    final toDate = DateTime(year, 12, 31, 23, 59, 59).toIso8601String();

    // Запрашиваем тип, дату, сумму и название категории через join
    // Принудительная фильтрация по активной компании
    dynamic query = _client
        .from(_tableName)
        .select('type, date, amount, cash_flow_categories(name)')
        .eq('company_id', _activeCompanyId);

    if (objectId != null) query = query.eq('object_id', objectId);
    if (contractIds != null && contractIds.isNotEmpty) {
      query = query.inFilter('contract_id', contractIds);
    }
    if (contractorId != null) query = query.eq('contractor_id', contractorId);
    if (types != null && types.isNotEmpty) {
      query = query.inFilter('type', types);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('cash_flow_search_text', '%$search%');
    }

    final response = await query.gte('date', fromDate).lte('date', toDate);

    final List<dynamic> data = response as List;
    // Ключ: year * 100 + month — хронологическая сортировка без парсинга локализованных строк.
    final Map<int, MonthlyAnalytics> grouped = {};

    for (final item in data) {
      final date = DateTime.parse(item['date']).toLocal();
      final type =
          item['type'] == 'income' ? CashFlowType.income : CashFlowType.expense;
      final amount = (item['amount'] as num).toDouble();
      final categoryName =
          item['cash_flow_categories']?['name'] ?? 'Без категории';

      final monthKey = date.year * 100 + date.month;
      final monthLabel = GtFormatters.formatCompactMonthYear(date);
      final current = grouped[monthKey] ??
          MonthlyAnalytics(
            monthYear: monthLabel,
            income: 0,
            expense: 0,
            categoryIncomes: {},
            categoryExpenses: {},
          );

      if (type == CashFlowType.income) {
        final newCategoryIncomes = Map<String, double>.from(current.categoryIncomes);
        newCategoryIncomes[categoryName] = (newCategoryIncomes[categoryName] ?? 0) + amount;
        
        grouped[monthKey] = MonthlyAnalytics(
          monthYear: monthLabel,
          income: current.income + amount,
          expense: current.expense,
          categoryIncomes: newCategoryIncomes,
          categoryExpenses: current.categoryExpenses,
        );
      } else {
        final newCategoryExpenses = Map<String, double>.from(current.categoryExpenses);
        newCategoryExpenses[categoryName] = (newCategoryExpenses[categoryName] ?? 0) + amount;

        grouped[monthKey] = MonthlyAnalytics(
          monthYear: monthLabel,
          income: current.income,
          expense: current.expense + amount,
          categoryIncomes: current.categoryIncomes,
          categoryExpenses: newCategoryExpenses,
        );
      }
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((key) => grouped[key]!).toList();
  }

  static const _categoryRuleSelect = '''
    *,
    cash_flow_categories:category_id(name)
  ''';

  @override
  Future<List<CashFlowCategoryRule>> getCategoryRules() async {
    final response = await _client
        .from(_categoryRulesTable)
        .select(_categoryRuleSelect)
        .eq('company_id', _activeCompanyId)
        .order('operation_type')
        .order('priority', ascending: false)
        .order('keyword');

    return (response as List)
        .map(
          (json) => CashFlowCategoryRuleModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ).toDomain(),
        )
        .toList();
  }

  @override
  Future<CashFlowCategoryRule> saveCategoryRule(CashFlowCategoryRule rule) async {
    final model = CashFlowCategoryRuleModel.fromDomain(rule);
    final json = model.toJson();
    json['company_id'] = _activeCompanyId;

    if (rule.id.isEmpty) {
      json.remove('id');
    }

    if (json['created_at'] == null) {
      json.remove('created_at');
    }

    final response = await _client
        .from(_categoryRulesTable)
        .upsert(json)
        .select(_categoryRuleSelect)
        .single();

    return CashFlowCategoryRuleModel.fromJson(
      Map<String, dynamic>.from(response),
    ).toDomain();
  }

  @override
  Future<void> deleteCategoryRule(String id) async {
    await _client
        .from(_categoryRulesTable)
        .delete()
        .eq('id', id)
        .eq('company_id', _activeCompanyId);
  }

  @override
  Future<BankStatementMatchingContext> getMatchingContext() async {
    if (_activeCompanyId.isEmpty) {
      return BankStatementMatchingContext.empty;
    }

    final response = await _client.rpc(
      'get_bank_statement_matching_context',
      params: {'p_company_id': _activeCompanyId},
    );

    if (response == null) {
      return BankStatementMatchingContext.empty;
    }

    final data = Map<String, dynamic>.from(response as Map);

    final hintsList = data['contractor_hints'] as List? ?? [];
    final hints = <String, ContractorCashFlowHint>{};
    for (final raw in hintsList) {
      final map = Map<String, dynamic>.from(raw as Map);
      final contractorId = map['contractor_id']?.toString();
      if (contractorId == null) continue;
      hints[contractorId] = ContractorCashFlowHint(
        contractorId: contractorId,
        contractId: map['contract_id']?.toString(),
        objectId: map['object_id']?.toString(),
        categoryId: map['category_id']?.toString(),
      );
    }

    final settlementsList = data['open_settlements'] as List? ?? [];
    final settlements = settlementsList.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return OpenSettlementCandidate(
        id: map['id'] as String,
        contractId: map['contract_id'] as String,
        contractorId: map['contractor_id'] as String,
        remainingAmount: (map['remaining_amount'] as num).toDouble(),
        invoiceNumber: map['invoice_number'] as String,
      );
    }).toList();

    return BankStatementMatchingContext(
      contractorHints: hints,
      openSettlements: settlements,
    );
  }

  @override
  Future<BankStatementBatchProcessResult> batchProcessBankStatementEntries({
    required String companyId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.rpc(
      'batch_process_bank_statement_entries',
      params: {
        'p_company_id': companyId,
        'p_items': items,
        'p_created_by': _client.auth.currentUser?.id,
      },
    );

    final data = Map<String, dynamic>.from(response as Map);
    final processed = (data['processed'] as num?)?.toInt() ?? 0;
    final failuresRaw = data['failed'] as List? ?? [];

    final failures = failuresRaw.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return BankStatementBatchFailure(
        entryId: map['entry_id']?.toString() ?? '',
        error: map['error']?.toString() ?? 'Неизвестная ошибка',
      );
    }).toList();

    return BankStatementBatchProcessResult(
      processed: processed,
      failures: failures,
    );
  }
}

