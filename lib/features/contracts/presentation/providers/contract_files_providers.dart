import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/domain/usecases/contract/get_contract_files_usecase.dart';
import 'package:projectgt/domain/usecases/contract/upload_contract_file_usecase.dart';
import 'package:projectgt/domain/usecases/contract/delete_contract_file_usecase.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Состояние файлов контракта.
class ContractFilesState {
  /// Список файлов.
  final List<ContractFile> files;

  /// Статус загрузки.
  final bool isLoading;

  /// Сообщение об ошибке, если есть.
  final String? errorMessage;

  /// Конструктор состояния файлов контракта.
  ContractFilesState({
    this.files = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Создает копию состояния с измененными полями.
  ContractFilesState copyWith({
    List<ContractFile>? files,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ContractFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Нотификатор для управления файлами контракта.
class ContractFilesNotifier extends StateNotifier<ContractFilesState> {
  /// Use case для получения списка файлов.
  final GetContractFilesUseCase getContractFilesUseCase;

  /// Use case для загрузки файла.
  final UploadContractFileUseCase uploadContractFileUseCase;

  /// Use case для удаления файла.
  final DeleteContractFileUseCase deleteContractFileUseCase;

  /// Репозиторий для работы с файлами.
  final ContractFileRepository repository;

  /// Идентификатор контракта.
  final String contractId;

  /// Конструктор нотификатора. Запускает начальную загрузку файлов.
  ContractFilesNotifier({
    required this.getContractFilesUseCase,
    required this.uploadContractFileUseCase,
    required this.deleteContractFileUseCase,
    required this.repository,
    required this.contractId,
  }) : super(ContractFilesState()) {
    loadFiles();
  }

  /// Загружает список файлов контракта.
  Future<void> loadFiles() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final files = await getContractFilesUseCase.execute(contractId);
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Загружает новый файл для контракта.
  Future<void> uploadFile(File file, String fileName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await uploadContractFileUseCase.execute(
        contractId: contractId,
        file: file,
        fileName: fileName,
      );
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Удаляет файл по его ID и пути.
  Future<void> deleteFile(String fileId, String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await deleteContractFileUseCase.execute(fileId, filePath);
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Получает URL для скачивания файла.
  Future<String> getDownloadUrl(String filePath, String originalName) async {
    return await repository.getDownloadUrl(filePath, originalName);
  }

  /// Скачивает файл и возвращает его содержимое в виде списка байтов.
  Future<List<int>> downloadFile(String filePath) async {
    return await repository.downloadFile(filePath);
  }
}

/// Провайдер для управления файлами конкретного контракта.
final contractFilesProvider =
    StateNotifierProvider.family<
      ContractFilesNotifier,
      ContractFilesState,
      String
    >((ref, contractId) {
      return ContractFilesNotifier(
        getContractFilesUseCase: ref.watch(getContractFilesUseCaseProvider),
        uploadContractFileUseCase: ref.watch(uploadContractFileUseCaseProvider),
        deleteContractFileUseCase: ref.watch(deleteContractFileUseCaseProvider),
        repository: ref.watch(contractFileRepositoryProvider),
        contractId: contractId,
      );
    });
