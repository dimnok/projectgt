import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

part 'contractor_state.freezed.dart';
part 'contractor_state.g.dart';

/// Статус состояния контрагентов.
enum ContractorStatus {
  /// Начальное состояние.
  initial,

  /// Загрузка данных.
  loading,

  /// Данные успешно загружены.
  loaded,

  /// Ошибка при работе с данными.
  error,
}

/// Состояние модуля контрагентов.
@freezed
abstract class ContractorState with _$ContractorState {
  /// Создает состояние контрагентов.
  const factory ContractorState({
    @Default([]) List<Contractor> contractors,
    @Default(ContractorStatus.initial) ContractorStatus status,
    String? errorMessage,
    @Default('') String searchQuery,
    Contractor? contractor,
  }) = _ContractorState;
}

/// Нотификатор для управления состоянием контрагентов.
@riverpod
class ContractorNotifier extends _$ContractorNotifier {
  @override
  ContractorState build() {
    // Автоматическая загрузка при инициализации
    Future.microtask(() => loadContractors());
    return const ContractorState();
  }

  /// Загружает список всех контрагентов.
  Future<void> loadContractors() async {
    final activeCompanyId = ref.read(activeCompanyIdProvider);
    if (activeCompanyId == null) return;

    state = state.copyWith(status: ContractorStatus.loading);
    try {
      final useCase = ref.read(getContractorsUseCaseProvider);
      final contractors = await useCase.execute(activeCompanyId);
      state = state.copyWith(
        contractors: contractors,
        status: ContractorStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        status: ContractorStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Устанавливает поисковый запрос и фильтрует список.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Добавляет нового контрагента.
  Future<void> addContractor(Contractor contractor) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      final useCase = ref.read(createContractorUseCaseProvider);
      await useCase.execute(contractor);
      await loadContractors();
    } catch (e) {
      state = state.copyWith(
        status: ContractorStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Обновляет данные существующего контрагента.
  Future<void> updateContractor(Contractor contractor) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      final useCase = ref.read(updateContractorUseCaseProvider);
      await useCase.execute(contractor);
      if (state.contractor?.id == contractor.id) {
        state = state.copyWith(contractor: contractor);
      }
      await loadContractors();
    } catch (e) {
      state = state.copyWith(
        status: ContractorStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Удаляет контрагента по ID.
  Future<void> deleteContractor(String id) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      // Сначала удаляем логотип из хранилища, если он есть
      final contractor = state.contractors.firstWhere((c) => c.id == id);
      if (contractor.logoUrl != null && contractor.logoUrl!.isNotEmpty) {
        await ref
            .read(photoServiceProvider)
            .deletePhoto(
              entity: 'contractor',
              id: id,
              displayName: contractor.shortName,
            );
      }

      final useCase = ref.read(deleteContractorUseCaseProvider);
      await useCase.execute(id);
      if (state.contractor?.id == id) {
        state = state.copyWith(contractor: null);
      }
      await loadContractors();
    } catch (e) {
      state = state.copyWith(
        status: ContractorStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Загружает данные конкретного контрагента по ID.
  Future<void> getContractor(String id) async {
    state = state.copyWith(status: ContractorStatus.loading);
    try {
      final useCase = ref.read(getContractorUseCaseProvider);
      final contractor = await useCase.execute(id);
      state = state.copyWith(
        contractor: contractor,
        status: ContractorStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        status: ContractorStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Провайдер для отфильтрованного списка контрагентов.
@riverpod
List<Contractor> filteredContractors(Ref ref) {
  final state = ref.watch(contractorNotifierProvider);
  if (state.searchQuery.isEmpty) return state.contractors;

  final query = state.searchQuery.toLowerCase();
  return state.contractors.where((c) {
    return c.shortName.toLowerCase().contains(query) ||
        c.fullName.toLowerCase().contains(query) ||
        c.inn.contains(query) ||
        c.director.toLowerCase().contains(query) ||
        c.phone.contains(query) ||
        c.email.toLowerCase().contains(query);
  }).toList();
}
