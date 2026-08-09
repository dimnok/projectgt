import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/settlements/data/datasources/settlement_file_data_source.dart';
import 'package:projectgt/features/settlements/data/repositories/settlement_file_repository_impl.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_file.dart';
import 'package:projectgt/features/settlements/domain/repositories/settlement_file_repository.dart';

/// Провайдер репозитория файлов счетов.
final settlementFileRepositoryProvider = Provider<SettlementFileRepository>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    final companyId = ref.watch(activeCompanyIdProvider);
    final dataSource = SupabaseSettlementFileDataSource(
      client,
      companyId ?? '',
    );
    return SettlementFileRepositoryImpl(dataSource);
  },
);

/// Состояние списка файлов по счёту.
class SettlementFilesState {
  /// Файлы.
  final List<SettlementFile> files;

  /// Идёт загрузка.
  final bool isLoading;

  /// Ошибка.
  final String? error;

  /// Создаёт состояние.
  const SettlementFilesState({
    this.files = const [],
    this.isLoading = false,
    this.error,
  });

  /// Копия с изменениями.
  SettlementFilesState copyWith({
    List<SettlementFile>? files,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SettlementFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier файлов по счёту.
class SettlementFilesNotifier extends StateNotifier<SettlementFilesState> {
  final SettlementFileRepository _repository;
  final String _operationId;

  /// Создаёт notifier.
  SettlementFilesNotifier(this._repository, this._operationId)
      : super(const SettlementFilesState()) {
    load();
  }

  /// Загрузить список файлов.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final files = await _repository.getFiles(_operationId);
      state = state.copyWith(
        files: files,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить файл на сервер.
  Future<SettlementFile?> uploadFile(
    File file,
    String fileName, {
    String? description,
  }) async {
    try {
      final created = await _repository.uploadFile(
        settlementOperationId: _operationId,
        file: file,
        fileName: fileName,
        description: description,
      );
      state = state.copyWith(
        files: [created, ...state.files],
        clearError: true,
      );
      return created;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Удалить файл.
  Future<bool> deleteFile(String fileId, String filePath) async {
    try {
      await _repository.deleteFile(fileId, filePath);
      state = state.copyWith(
        files: state.files.where((f) => f.id != fileId).toList(),
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Скачать байты файла.
  Future<List<int>> downloadFile(String filePath) {
    return _repository.downloadFile(filePath);
  }
}

/// Провайдер файлов по счёту.
final settlementFilesProvider = StateNotifierProvider.autoDispose
    .family<SettlementFilesNotifier, SettlementFilesState, String>(
  (ref, operationId) {
    final repo = ref.watch(settlementFileRepositoryProvider);
    return SettlementFilesNotifier(repo, operationId);
  },
);

/// Идентификаторы файлов, для которых идёт скачивание.
final settlementFileDownloadingIdsProvider =
    StateProvider.autoDispose.family<Set<String>, String>(
  (ref, operationId) => {},
);
