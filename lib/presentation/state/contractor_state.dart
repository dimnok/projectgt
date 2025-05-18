import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/domain/usecases/contractor/get_contractors_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/get_contractor_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/create_contractor_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/update_contractor_usecase.dart';
import 'package:projectgt/domain/usecases/contractor/delete_contractor_usecase.dart';
import 'package:projectgt/core/di/providers.dart';

/// Перечисление возможных статусов загрузки и обработки контрагентов.
///
/// Используется для управления состоянием экрана и логики работы с контрагентами.
enum ContractorStatus {
  /// Начальное состояние (ничего не загружено).
  initial,
  /// Выполняется загрузка или операция.
  loading,
  /// Операция завершена успешно.
  success,
  /// Произошла ошибка при выполнении операции.
  error,
}

/// Состояние для работы с контрагентами.
///
/// Хранит список контрагентов, выбранного контрагента, статус загрузки, ошибку и поисковый запрос.
class ContractorState {
  /// Текущий статус загрузки/операции ([ContractorStatus]).
  final ContractorStatus status;
  /// Список всех контрагентов.
  final List<Contractor> contractors;
  /// Текущий выбранный контрагент (если есть).
  final Contractor? contractor;
  /// Сообщение об ошибке (если есть).
  final String? errorMessage;
  /// Поисковый запрос для фильтрации контрагентов.
  final String searchQuery;

  /// Создаёт новое состояние для работы с контрагентами.
  ///
  /// [status] — статус загрузки/операции.
  /// [contractors] — список контрагентов (по умолчанию пустой).
  /// [contractor] — выбранный контрагент (опционально).
  /// [errorMessage] — сообщение об ошибке (опционально).
  /// [searchQuery] — поисковый запрос (по умолчанию пустая строка).
  ContractorState({
    required this.status,
    this.contractors = const [],
    this.contractor,
    this.errorMessage,
    this.searchQuery = '',
  });

  /// Возвращает начальное состояние ([ContractorStatus.initial]).
  factory ContractorState.initial() => ContractorState(status: ContractorStatus.initial);

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [contractors] — новый список контрагентов (опционально).
  /// [contractor] — новый выбранный контрагент (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  /// [searchQuery] — новый поисковый запрос (опционально).
  ContractorState copyWith({
    ContractorStatus? status,
    List<Contractor>? contractors,
    Contractor? contractor,
    String? errorMessage,
    String? searchQuery,
  }) {
    return ContractorState(
      status: status ?? this.status,
      contractors: contractors ?? this.contractors,
      contractor: contractor ?? this.contractor,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Возвращает отфильтрованный список контрагентов по поисковому запросу [searchQuery].
  ///
  /// Если запрос пустой — возвращает всех контрагентов.
  List<Contractor> get filteredContractors {
    if (searchQuery.isEmpty) return contractors;
    final query = searchQuery.toLowerCase();
    return contractors.where((c) =>
      c.fullName.toLowerCase().contains(query) ||
      c.shortName.toLowerCase().contains(query) ||
      c.inn.toLowerCase().contains(query) ||
      c.director.toLowerCase().contains(query) ||
      c.phone.toLowerCase().contains(query) ||
      c.email.toLowerCase().contains(query)
    ).toList();
  }
}

/// StateNotifier для управления состоянием и операциями с контрагентами.
///
/// Позволяет загружать, создавать, обновлять, удалять и искать контрагентов, а также получать отдельного контрагента по id.
class ContractorNotifier extends StateNotifier<ContractorState> {
  /// Use case для получения списка контрагентов.
  final GetContractorsUseCase getContractorsUseCase;
  /// Use case для получения одного контрагента по id.
  final GetContractorUseCase getContractorUseCase;
  /// Use case для создания нового контрагента.
  final CreateContractorUseCase createContractorUseCase;
  /// Use case для обновления существующего контрагента.
  final UpdateContractorUseCase updateContractorUseCase;
  /// Use case для удаления контрагента.
  final DeleteContractorUseCase deleteContractorUseCase;
  /// Riverpod Ref для доступа к провайдерам зависимостей.
  final Ref _ref;

  /// Создаёт [ContractorNotifier] с необходимыми use case-ами.
  ContractorNotifier({
    required this.getContractorsUseCase,
    required this.getContractorUseCase,
    required this.createContractorUseCase,
    required this.updateContractorUseCase,
    required this.deleteContractorUseCase,
    required Ref ref,
  })  : _ref = ref,
        super(ContractorState.initial());

  /// Загружает список всех контрагентов.
  ///
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> loadContractors() async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      final contractors = await getContractorsUseCase.execute();
      state = state.copyWith(status: ContractorStatus.success, contractors: contractors);
    } catch (e) {
      state = state.copyWith(status: ContractorStatus.error, errorMessage: e.toString());
    }
  }

  /// Добавляет нового контрагента.
  ///
  /// После успешного добавления — перезагружает список контрагентов.
  Future<void> addContractor(Contractor contractor) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      await createContractorUseCase.execute(contractor);
      await loadContractors();
    } catch (e) {
      state = state.copyWith(status: ContractorStatus.error, errorMessage: e.toString());
    }
  }

  /// Обновляет существующего контрагента.
  ///
  /// После успешного обновления — перезагружает список контрагентов.
  Future<void> updateContractor(Contractor contractor) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      await updateContractorUseCase.execute(contractor);
      await loadContractors();
    } catch (e) {
      state = state.copyWith(status: ContractorStatus.error, errorMessage: e.toString());
    }
  }

  /// Удаляет контрагента по [id].
  ///
  /// После успешного удаления — перезагружает список контрагентов.
  /// Также удаляет фото контрагента из Supabase Storage.
  Future<void> deleteContractor(String id) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      Contractor? contractor = state.contractor;
      if (contractor == null) {
        try {
          contractor = state.contractors.firstWhere((c) => c.id == id);
        } catch (_) {
          contractor = null;
        }
      }
      await _ref.read(photoServiceProvider).deletePhoto(
        entity: 'contractor',
        id: id,
        displayName: contractor?.shortName ?? '',
      );
      await deleteContractorUseCase.execute(id);
      await loadContractors();
    } catch (e) {
      state = state.copyWith(status: ContractorStatus.error, errorMessage: e.toString());
    }
  }

  /// Устанавливает поисковый запрос для фильтрации контрагентов.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Загружает отдельного контрагента по [id].
  ///
  /// Если контрагент уже загружен и статус success — повторная загрузка не выполняется.
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getContractor(String id) async {
    if (state.contractor != null && state.contractor!.id == id && state.status == ContractorStatus.success) {
      return;
    }
    final idx = state.contractors.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final local = state.contractors[idx];
      state = state.copyWith(status: ContractorStatus.success, contractor: local);
      return;
    }
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      final contractor = await getContractorUseCase.execute(id);
      if (contractor != null) {
        state = state.copyWith(status: ContractorStatus.success, contractor: contractor);
      } else {
        state = state.copyWith(status: ContractorStatus.error, errorMessage: 'Контрагент не найден');
      }
    } catch (e) {
      state = state.copyWith(status: ContractorStatus.error, errorMessage: e.toString());
    }
  }
} 