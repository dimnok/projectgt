import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/usecases/contract/get_contracts_usecase.dart';
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
/// Хранит список договоров, статус загрузки и сообщение об ошибке.
class ContractState {
  /// Текущий статус загрузки/операции ([ContractStatusState]).
  final ContractStatusState status;

  /// Список всех договоров.
  final List<Contract> contracts;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Создаёт новое состояние для работы с договорами.
  ///
  /// [status] — статус загрузки/операции.
  /// [contracts] — список договоров (по умолчанию пустой).
  /// [errorMessage] — сообщение об ошибке (опционально).
  ContractState({
    required this.status,
    this.contracts = const [],
    this.errorMessage,
  });

  /// Возвращает начальное состояние ([ContractStatusState.initial]).
  factory ContractState.initial() =>
      ContractState(status: ContractStatusState.initial);

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [contracts] — новый список договоров (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  ContractState copyWith({
    ContractStatusState? status,
    List<Contract>? contracts,
    String? errorMessage,
  }) {
    return ContractState(
      status: status ?? this.status,
      contracts: contracts ?? this.contracts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// StateNotifier для управления состоянием и операциями с договорами.
///
/// Позволяет загружать, создавать, обновлять и удалять договоры.
class ContractNotifier extends StateNotifier<ContractState> {
  /// Use case для получения всех договоров.
  final GetContractsUseCase getContractsUseCase;

  /// Use case для создания договора.
  final CreateContractUseCase createContractUseCase;

  /// Use case для обновления договора.
  final UpdateContractUseCase updateContractUseCase;

  /// Use case для удаления договора.
  final DeleteContractUseCase deleteContractUseCase;

  /// Создаёт [ContractNotifier] с необходимыми use case-ами.
  ContractNotifier({
    required this.getContractsUseCase,
    required this.createContractUseCase,
    required this.updateContractUseCase,
    required this.deleteContractUseCase,
  }) : super(ContractState.initial());

  /// Загружает список всех договоров.
  ///
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  /// [quiet] — если true, статус loading не устанавливается (для фонового обновления).
  Future<void> loadContracts({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(status: ContractStatusState.loading);
    }
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
}
