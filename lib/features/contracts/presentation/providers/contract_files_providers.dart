import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/domain/usecases/contract/bulk_update_contract_files_document_status_usecase.dart';
import 'package:projectgt/domain/usecases/contract/get_contract_files_usecase.dart';
import 'package:projectgt/domain/usecases/contract/upload_contract_file_usecase.dart';
import 'package:projectgt/domain/usecases/contract/delete_contract_file_usecase.dart';
import 'package:projectgt/domain/usecases/contract/update_contract_file_metadata_usecase.dart';
import 'package:projectgt/domain/usecases/contract/reorder_contract_files_usecase.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Режим упорядочивания документов на вкладке «Документы» (десктоп).
final contractDocumentsReorderModeProvider =
    StateProvider.family<bool, String>((ref, contractId) => false);

/// Сигнал сохранения порядка документов для [contractId].
///
/// Инкрементируется из UI (кнопка «Готово» в быстрых действиях); виджет
/// [ContractDocumentsSection] подписан и вызывает сохранение черновика порядка.
final contractDocumentsReorderSaveRequestProvider =
    StateProvider.family<int, String>((ref, contractId) => 0);

/// Показ примечаний (описаний) к файлам во вкладке «Документы».
///
/// Управляется из панели быстрых действий на широкой вёрстке и из шапки
/// карточки договора на узкой (где сайдбар скрыт).
final contractDocumentDescriptionsVisibleProvider =
    StateProvider.family<bool, String>((ref, contractId) => false);

/// Идентификаторы файлов договора [contractId], для которых сейчас идёт скачивание.
///
/// Используется для индикации на кнопке «Скачать» при долгой загрузке с Storage.
final contractFileDownloadingIdsProvider =
    StateProvider.family<Set<String>, String>((ref, contractId) => {});

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

  /// Use case для обновления метаданных файла.
  final UpdateContractFileMetadataUseCase updateContractFileMetadataUseCase;

  /// Use case для сохранения порядка файлов.
  final ReorderContractFilesUseCase reorderContractFilesUseCase;

  /// Use case для массовой смены статуса документооборота.
  final BulkUpdateContractFilesDocumentStatusUseCase
      bulkUpdateContractFilesDocumentStatusUseCase;

  /// Репозиторий для работы с файлами.
  final ContractFileRepository repository;

  /// Идентификатор контракта.
  final String contractId;

  /// Конструктор нотификатора. Запускает начальную загрузку файлов.
  ContractFilesNotifier({
    required this.getContractFilesUseCase,
    required this.uploadContractFileUseCase,
    required this.deleteContractFileUseCase,
    required this.updateContractFileMetadataUseCase,
    required this.bulkUpdateContractFilesDocumentStatusUseCase,
    required this.reorderContractFilesUseCase,
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
  Future<void> uploadFile(File file, String fileName, {String? description}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await uploadContractFileUseCase.execute(
        contractId: contractId,
        file: file,
        fileName: fileName,
        description: description,
      );
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow; // Пробрасываем ошибку дальше, чтобы UI мог ее обработать
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

  /// Скачивает файл и возвращает его содержимое в виде списка байтов.
  Future<List<int>> downloadFile(String filePath) async {
    return await repository.downloadFile(filePath);
  }

  /// Обновляет отображаемое имя, примечание и поля документооборота.
  Future<void> updateFileMetadata({
    required String fileId,
    required String name,
    String? description,
    ContractDocumentStatus? documentStatus,
    int? documentVersion,
    bool? isAmendment,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await updateContractFileMetadataUseCase.execute(
        fileId: fileId,
        name: name,
        description: description,
        documentStatus: documentStatus,
        documentVersion: documentVersion,
        isAmendment: isAmendment,
      );
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Массово выставляет статус выбранным файлам.
  Future<void> bulkUpdateDocumentStatus({
    required List<String> fileIds,
    required ContractDocumentStatus status,
  }) async {
    if (fileIds.isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await bulkUpdateContractFilesDocumentStatusUseCase.execute(
        fileIds: fileIds,
        status: status,
      );
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Удаляет несколько файлов подряд (после подтверждения в UI).
  Future<void> bulkDeleteFiles(List<ContractFile> files) async {
    if (files.isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      for (final f in files) {
        await deleteContractFileUseCase.execute(f.id, f.filePath);
      }
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Сохраняет порядок отображения файлов (сверху вниз).
  Future<void> saveFilesDisplayOrder(List<String> orderedFileIds) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await reorderContractFilesUseCase.execute(
        contractId: contractId,
        orderedFileIds: orderedFileIds,
      );
      await loadFiles();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
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
        updateContractFileMetadataUseCase:
            ref.watch(updateContractFileMetadataUseCaseProvider),
        bulkUpdateContractFilesDocumentStatusUseCase:
            ref.watch(bulkUpdateContractFilesDocumentStatusUseCaseProvider),
        reorderContractFilesUseCase:
            ref.watch(reorderContractFilesUseCaseProvider),
        repository: ref.watch(contractFileRepositoryProvider),
        contractId: contractId,
      );
    });
