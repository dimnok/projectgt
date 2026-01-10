import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/cash_flow/domain/entities/monthly_analytics.dart';
import 'package:projectgt/features/cash_flow/domain/entities/available_filters.dart';
import 'package:projectgt/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';
import 'package:projectgt/features/cash_flow/application/bank_import_service.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';

part 'cash_flow_state.freezed.dart';

/// Статусы состояния модуля Cash Flow.
enum CashFlowStatus {
  /// Начальное состояние.
  initial,

  /// Загрузка данных.
  loading,

  /// Данные успешно загружены.
  success,

  /// Ошибка при загрузке или операции.
  error,
}

/// Виды отображения в модуле Cash Flow.
enum CashFlowView {
  /// Основной список транзакций и аналитика.
  transactions,

  /// Банковская выписка.
  bankStatement,
}

/// Состояние модуля Cash Flow.
@freezed
abstract class CashFlowState with _$CashFlowState {
  /// Создаёт экземпляр [CashFlowState].
  const factory CashFlowState({
    /// Текущий статус состояния.
    required CashFlowStatus status,

    /// Текущий вид отображения.
    @Default(CashFlowView.transactions) CashFlowView currentView,

    /// Список финансовых операций.
    @Default([]) List<CashFlowTransaction> transactions,

    /// Список категорий ДДС.
    @Default([]) List<CashFlowCategory> categories,

    /// Список шаблонов импорта банковских выписок.
    @Default([]) List<BankImportTemplate> bankImportTemplates,

    /// Список записей из текущей загруженной выписки.
    @Default([]) List<BankStatementEntry> bankStatementEntries,

    /// Данные аналитики по месяцам за весь год.
    @Default([]) List<MonthlyAnalytics> yearlyAnalytics,

    /// Доступные ID для фильтрации ( Option B ).
    @Default(AvailableFilters()) AvailableFilters availableFilters,

    /// Сообщение об ошибке.
    String? errorMessage,

    /// Поисковый запрос.
    @Default('') String searchQuery,

    /// Выбранный год для фильтрации.
    required int selectedYear,

    /// Выбранный объект для фильтрации.
    String? selectedObjectId,

    /// Выбранный контрагент для фильтрации.
    String? selectedContractorId,

    /// Выбранные договоры для фильтрации.
    @Default([]) List<String> selectedContractIds,

    /// Выбранные типы операций (income/expense).
    @Default([]) List<String> selectedOperationTypes,

    /// Выбранный банковский счет (для выписок).
    String? selectedBankAccountId,

    /// Есть ли ещё данные для загрузки (пагинация).
    @Default(true) bool hasMore,

    /// Загружаются ли сейчас дополнительные данные.
    @Default(false) bool isLoadingMore,

    /// Отображать ли детальную аналитику по статьям.
    @Default(false) bool isDetailedAnalytics,
  }) = _CashFlowState;

  const CashFlowState._();

  /// Начальное состояние.
  factory CashFlowState.initial() => CashFlowState(
    status: CashFlowStatus.initial,
    selectedYear: DateTime.now().year,
    bankStatementEntries: [],
  );
}

/// Notifier для управления состоянием Cash Flow.
class CashFlowNotifier extends StateNotifier<CashFlowState> {
  final ICashFlowRepository _repository;
  final BankImportService _importService;
  static const int _pageSize = 50;
  int _currentPage = 0;

  /// Создаёт [CashFlowNotifier].
  CashFlowNotifier(this._repository, this._importService)
    : super(CashFlowState.initial());

  /// Загружает начальные данные модуля (первая страница транзакций и категории).
  Future<void> loadAllData({
    String? search,
    int? year,
    String? objectId,
    String? contractorId,
    List<String>? contractIds,
    List<String>? operationTypes,
  }) async {
    final effectiveYear = year ?? state.selectedYear;
    state = state.copyWith(
      status: CashFlowStatus.loading,
      searchQuery: search ?? state.searchQuery,
      selectedYear: effectiveYear,
      selectedObjectId: objectId,
      selectedContractorId: contractorId,
      selectedContractIds: contractIds ?? state.selectedContractIds,
      selectedOperationTypes: operationTypes ?? state.selectedOperationTypes,
    );
    _currentPage = 0;

    try {
      final fromDate = DateTime(effectiveYear, 1, 1);
      final toDate = DateTime(effectiveYear, 12, 31, 23, 59, 59);

      final results = await Future.wait([
        _repository.getTransactions(
          limit: _pageSize,
          offset: 0,
          search: state.searchQuery,
          fromDate: fromDate,
          toDate: toDate,
          objectId: state.selectedObjectId,
          contractorId: state.selectedContractorId,
          contractIds: state.selectedContractIds,
          types: state.selectedOperationTypes,
        ),
        _repository.getCategories(),
        _repository.getYearlyAnalytics(
          effectiveYear,
          objectId: state.selectedObjectId,
          contractorId: state.selectedContractorId,
          contractIds: state.selectedContractIds,
          types: state.selectedOperationTypes,
          search: state.searchQuery,
        ),
        _repository.getBankImportTemplates(),
        _repository.getAvailableFilters(fromDate: fromDate, toDate: toDate),
      ]);

      final transactions = results[0] as List<CashFlowTransaction>;
      final availableFilters = results[4] as AvailableFilters;

      // Проверка актуальности выбранных фильтров
      String? updatedObjectId = state.selectedObjectId;
      if (updatedObjectId != null &&
          !availableFilters.objectIds.contains(updatedObjectId)) {
        updatedObjectId = null;
      }

      String? updatedContractorId = state.selectedContractorId;
      if (updatedContractorId != null &&
          !availableFilters.contractorIds.contains(updatedContractorId)) {
        updatedContractorId = null;
      }

      List<String> updatedContractIds = state.selectedContractIds
          .where((id) => availableFilters.contractIds.contains(id))
          .toList();

      state = state.copyWith(
        status: CashFlowStatus.success,
        transactions: transactions,
        categories: results[1] as List<CashFlowCategory>,
        yearlyAnalytics: results[2] as List<MonthlyAnalytics>,
        bankImportTemplates: results[3] as List<BankImportTemplate>,
        availableFilters: availableFilters,
        selectedObjectId: updatedObjectId,
        selectedContractorId: updatedContractorId,
        selectedContractIds: updatedContractIds,
        hasMore: transactions.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Загружает следующую страницу транзакций.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    _currentPage++;

    try {
      final fromDate = DateTime(state.selectedYear, 1, 1);
      final toDate = DateTime(state.selectedYear, 12, 31, 23, 59, 59);

      final nextTransactions = await _repository.getTransactions(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        search: state.searchQuery,
        fromDate: fromDate,
        toDate: toDate,
        objectId: state.selectedObjectId,
        contractorId: state.selectedContractorId,
        contractIds: state.selectedContractIds,
        types: state.selectedOperationTypes,
      );

      state = state.copyWith(
        isLoadingMore: false,
        transactions: [...state.transactions, ...nextTransactions],
        hasMore: nextTransactions.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  /// Устанавливает выбранный год и перезагружает данные.
  void setSelectedYear(int year) {
    if (state.selectedYear == year) return;
    loadAllData(
      year: year,
      objectId: state.selectedObjectId,
      contractorId: state.selectedContractorId,
      contractIds: state.selectedContractIds,
      operationTypes: state.selectedOperationTypes,
    );
  }

  /// Устанавливает поисковый запрос и перезагружает данные.
  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    loadAllData(
      search: query,
      objectId: state.selectedObjectId,
      contractorId: state.selectedContractorId,
      contractIds: state.selectedContractIds,
      operationTypes: state.selectedOperationTypes,
    );
  }

  /// Устанавливает фильтр по объекту и перезагружает данные.
  void setSelectedObject(String? objectId) {
    if (state.selectedObjectId == objectId) return;
    loadAllData(
      objectId: objectId,
      contractorId: state.selectedContractorId,
      contractIds: state.selectedContractIds,
      operationTypes: state.selectedOperationTypes,
    );
  }

  /// Устанавливает фильтр по контрагенту и перезагружает данные.
  void setSelectedContractor(String? contractorId) {
    if (state.selectedContractorId == contractorId) return;
    loadAllData(
      objectId: state.selectedObjectId,
      contractorId: contractorId,
      contractIds: state.selectedContractIds,
      operationTypes: state.selectedOperationTypes,
    );
  }

  /// Устанавливает фильтр по договорам и перезагружает данные.
  void setSelectedContracts(List<String> contractIds) {
    loadAllData(
      objectId: state.selectedObjectId,
      contractorId: state.selectedContractorId,
      contractIds: contractIds,
      operationTypes: state.selectedOperationTypes,
    );
  }

  /// Устанавливает фильтр по типам операций и перезагружает данные.
  void setSelectedOperationTypes(List<String> operationTypes) {
    loadAllData(
      objectId: state.selectedObjectId,
      contractorId: state.selectedContractorId,
      contractIds: state.selectedContractIds,
      operationTypes: operationTypes,
    );
  }

  /// Сохраняет транзакцию (создание или обновление).
  Future<void> saveTransaction(CashFlowTransaction transaction) async {
    // При сохранении/изменении лучше перезагрузить всё с первой страницы,
    // чтобы данные были актуальны
    try {
      await _repository.saveTransaction(transaction);
      await loadAllData();
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Переносит запись из выписки в основную таблицу транзакций.
  Future<void> processBankStatementEntry({
    required String entryId,
    required CashFlowTransaction transaction,
  }) async {
    try {
      state = state.copyWith(status: CashFlowStatus.loading);
      await _repository.processBankStatementEntry(
        entryId: entryId,
        transaction: transaction,
      );

      // Если год транзакции отличается от выбранного, переключаем год
      if (transaction.date.year != state.selectedYear) {
        state = state.copyWith(selectedYear: transaction.date.year);
      }

      // После успешного переноса обновляем и транзакции, и записи выписки
      await loadAllData();
      if (state.selectedBankAccountId != null) {
        await loadBankStatementEntries(state.selectedBankAccountId!);
      }
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Удаляет транзакцию.
  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadAllData();

      // Если выбран банковский счет, обновляем и записи выписки,
      // так как триггер в БД мог вернуть запись в статус "не импортировано"
      if (state.selectedBankAccountId != null) {
        await loadBankStatementEntries(state.selectedBankAccountId!);
      }
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Сохраняет (создаёт или обновляет) статью ДДС.
  Future<void> saveCategory(CashFlowCategory category) async {
    state = state.copyWith(status: CashFlowStatus.loading);
    try {
      await _repository.saveCategory(category);
      await loadAllData();
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Удаляет статью ДДС (архивирует).
  Future<void> deleteCategory(String id) async {
    state = state.copyWith(status: CashFlowStatus.loading);
    try {
      await _repository.deleteCategory(id);
      await loadAllData();
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Сохраняет шаблон импорта банковской выписки.
  Future<void> saveBankImportTemplate(BankImportTemplate template) async {
    state = state.copyWith(status: CashFlowStatus.loading);
    try {
      await _repository.saveBankImportTemplate(template);
      await loadAllData();
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Удаляет шаблон импорта.
  Future<void> deleteBankImportTemplate(String id) async {
    state = state.copyWith(status: CashFlowStatus.loading);
    try {
      await _repository.deleteBankImportTemplate(id);
      await loadAllData();
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Переключает режим детальной аналитики.
  void toggleDetailedAnalytics() {
    state = state.copyWith(isDetailedAnalytics: !state.isDetailedAnalytics);
  }

  /// Устанавливает текущий вид отображения.
  void setView(CashFlowView view) {
    state = state.copyWith(currentView: view);
  }

  /// Устанавливает выбранный банковский счет.
  void setSelectedBankAccount(String? id) {
    if (state.selectedBankAccountId == id) return;
    state = state.copyWith(selectedBankAccountId: id);
    if (id != null) {
      loadBankStatementEntries(id);
    }
  }

  /// Загружает сохраненные записи выписки из БД для счета.
  Future<void> loadBankStatementEntries(String accountId) async {
    state = state.copyWith(status: CashFlowStatus.loading);
    try {
      final entries = await _repository.getBankStatementEntries(accountId);
      state = state.copyWith(
        status: CashFlowStatus.success,
        bankStatementEntries: entries,
      );
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Выбирает файл выписки и парсит его на основе подходящего шаблона.
  /// Возвращает статистику импорта.
  Future<BankImportStats?> pickAndParseBankStatement({
    required CompanyBankAccount account,
    String? targetInn,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw 'Не удалось прочитать данные файла';

      // Поиск подходящего шаблона по названию банка
      final template = state.bankImportTemplates.firstWhere(
        (t) =>
            t.bankName.toLowerCase().contains(account.bankName.toLowerCase()) ||
            account.bankName.toLowerCase().contains(t.bankName.toLowerCase()),
        orElse: () =>
            throw 'Шаблон для банка «${account.bankName}» не найден. Создайте его в настройках.',
      );

      state = state.copyWith(status: CashFlowStatus.loading);

      // Используем сервис для координации парсинга и проверки на дубликаты
      final importResult = await _importService.processStatement(
        bytes: bytes,
        template: template,
        account: account,
        targetInn: targetInn,
      );

      if (importResult.total == 0) {
        state = state.copyWith(status: CashFlowStatus.success);
        return const BankImportStats(total: 0, added: 0, skipped: 0);
      }

      // Сохраняем только новые записи в БД
      if (importResult.newEntries.isNotEmpty) {
        await _repository.saveBankStatementEntries(importResult.newEntries);
      }

      // Загружаем актуальный список из БД
      await loadBankStatementEntries(account.id);

      return BankImportStats(
        total: importResult.total,
        added: importResult.added,
        skipped: importResult.skipped,
      );
    } catch (e) {
      state = state.copyWith(
        status: CashFlowStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

/// Провайдер состояния Cash Flow.
final cashFlowProvider = StateNotifierProvider<CashFlowNotifier, CashFlowState>(
  (ref) {
    final repository = ref.watch(cashFlowRepositoryProvider);
    final importService = ref.watch(bankImportServiceProvider);
    return CashFlowNotifier(repository, importService)..loadAllData();
  },
);
