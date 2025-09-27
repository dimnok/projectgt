import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/usecases/contract/get_contracts_usecase.dart';
import 'package:projectgt/domain/usecases/contract/get_contract_usecase.dart';
import 'package:projectgt/domain/usecases/contract/create_contract_usecase.dart';
import 'package:projectgt/domain/usecases/contract/update_contract_usecase.dart';
import 'package:projectgt/domain/usecases/contract/delete_contract_usecase.dart';

/// Перечисление возможных статусов загрузки и обработки договоров.
///
/// Используется для управления состоянием экрана и логики работы с договорами.
enum ContractStatusState {
  /// Начальное состояние (ничего не загружено).
  initial,

  /// Выполняется загрузка или операция.
  loading,

  /// Операция завершена успешно.
  success,

  /// Произошла ошибка при выполнении операции.
  error,
}

/// Состояние для работы с договорами.
///
/// Хранит список договоров, выбранный договор, статус загрузки, ошибку и поисковый запрос.
class ContractState {
  /// Текущий статус загрузки/операции ([ContractStatusState]).
  final ContractStatusState status;

  /// Список всех договоров.
  final List<Contract> contracts;

  /// Текущий выбранный договор (если есть).
  final Contract? contract;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Поисковый запрос для фильтрации договоров.
  final String searchQuery;

  /// Создаёт новое состояние для работы с договорами.
  ///
  /// [status] — статус загрузки/операции.
  /// [contracts] — список договоров (по умолчанию пустой).
  /// [contract] — выбранный договор (опционально).
  /// [errorMessage] — сообщение об ошибке (опционально).
  /// [searchQuery] — поисковый запрос (по умолчанию пустая строка).
  ContractState({
    required this.status,
    this.contracts = const [],
    this.contract,
    this.errorMessage,
    this.searchQuery = '',
  });

  /// Возвращает начальное состояние ([ContractStatusState.initial]).
  factory ContractState.initial() =>
      ContractState(status: ContractStatusState.initial);

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [contracts] — новый список договоров (опционально).
  /// [contract] — новый выбранный договор (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  /// [searchQuery] — новый поисковый запрос (опционально).
  ContractState copyWith({
    ContractStatusState? status,
    List<Contract>? contracts,
    Contract? contract,
    String? errorMessage,
    String? searchQuery,
  }) {
    return ContractState(
      status: status ?? this.status,
      contracts: contracts ?? this.contracts,
      contract: contract ?? this.contract,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Возвращает отфильтрованный список договоров по поисковому запросу [searchQuery].
  ///
  /// Если запрос пустой — возвращает все договоры.
  List<Contract> get filteredContracts {
    if (searchQuery.isEmpty) return contracts;
    final query = searchQuery.toLowerCase();
    return contracts
        .where((c) =>
            c.number.toLowerCase().contains(query) ||
            (c.contractorName?.toLowerCase().contains(query) ?? false) ||
            (c.objectName?.toLowerCase().contains(query) ?? false))
        .toList();
  }
}

/// StateNotifier для управления состоянием и операциями с договорами.
///
/// Позволяет загружать, создавать, обновлять, удалять и искать договоры, а также получать отдельный договор по id.
class ContractNotifier extends StateNotifier<ContractState> {
  /// Use case для получения всех договоров.
  final GetContractsUseCase getContractsUseCase;

  /// Use case для получения одного договора.
  final GetContractUseCase getContractUseCase;

  /// Use case для создания договора.
  final CreateContractUseCase createContractUseCase;

  /// Use case для обновления договора.
  final UpdateContractUseCase updateContractUseCase;

  /// Use case для удаления договора.
  final DeleteContractUseCase deleteContractUseCase;

  /// Создаёт [ContractNotifier] с необходимыми use case-ами.
  ContractNotifier({
    required this.getContractsUseCase,
    required this.getContractUseCase,
    required this.createContractUseCase,
    required this.updateContractUseCase,
    required this.deleteContractUseCase,
  }) : super(ContractState.initial());

  /// Загружает список всех договоров.
  ///
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> loadContracts() async {
    state = state.copyWith(status: ContractStatusState.loading);
    try {
      final contracts = await getContractsUseCase.execute();
      state = state.copyWith(
          status: ContractStatusState.success, contracts: contracts);
    } catch (e) {
      state = state.copyWith(
          status: ContractStatusState.error, errorMessage: e.toString());
    }
  }

  /// Добавляет новый договор.
  ///
  /// После успешного добавления — перезагружает список договоров.
  Future<void> addContract(Contract contract) async {
    state = state.copyWith(status: ContractStatusState.loading);
    try {
      await createContractUseCase.execute(contract);
      await loadContracts();
    } catch (e) {
      state = state.copyWith(
          status: ContractStatusState.error, errorMessage: e.toString());
    }
  }

  /// Обновляет существующий договор.
  ///
  /// После успешного обновления — перезагружает список договоров.
  Future<void> updateContract(Contract contract) async {
    state = state.copyWith(status: ContractStatusState.loading);
    try {
      await updateContractUseCase.execute(contract);
      await loadContracts();
    } catch (e) {
      state = state.copyWith(
          status: ContractStatusState.error, errorMessage: e.toString());
    }
  }

  /// Удаляет договор по [id].
  ///
  /// После успешного удаления — перезагружает список договоров.
  Future<void> deleteContract(String id) async {
    state = state.copyWith(status: ContractStatusState.loading);
    try {
      await deleteContractUseCase.execute(id);
      await loadContracts();
    } catch (e) {
      state = state.copyWith(
          status: ContractStatusState.error, errorMessage: e.toString());
    }
  }

  /// Устанавливает поисковый запрос для фильтрации договоров.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Загружает отдельный договор по [id].
  ///
  /// Если договор уже загружен и статус success — повторная загрузка не выполняется.
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getContract(String id) async {
    if (state.contract != null &&
        state.contract!.id == id &&
        state.status == ContractStatusState.success) {
      return;
    }
    state = state.copyWith(status: ContractStatusState.loading);
    try {
      final contract = await getContractUseCase.execute(id);
      if (contract != null) {
        state = state.copyWith(
            status: ContractStatusState.success, contract: contract);
      } else {
        state = state.copyWith(
            status: ContractStatusState.error,
            errorMessage: 'Договор не найден');
      }
    } catch (e) {
      state = state.copyWith(
          status: ContractStatusState.error, errorMessage: e.toString());
    }
  }
}
