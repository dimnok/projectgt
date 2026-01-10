import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/domain/usecases/get_objects_usecase.dart';
import 'package:projectgt/features/objects/domain/usecases/create_object_usecase.dart';
import 'package:projectgt/features/objects/domain/usecases/update_object_usecase.dart';
import 'package:projectgt/features/objects/domain/usecases/delete_object_usecase.dart';

part 'object_state.freezed.dart';

/// Перечисление возможных статусов загрузки и обработки объектов.
///
/// Используется для управления состоянием экрана и логики работы с объектами недвижимости.
enum ObjectStatus {
  /// Начальное состояние (ничего не загружено).
  initial,

  /// Выполняется загрузка или операция.
  loading,

  /// Операция завершена успешно.
  success,

  /// Произошла ошибка при выполнении операции.
  error,
}

/// Состояние для работы с объектами недвижимости.
///
/// Хранит список объектов, статус загрузки и сообщение об ошибке.
@freezed
abstract class ObjectState with _$ObjectState {
  /// Создаёт новое состояние для работы с объектами.
  ///
  /// [status] — статус загрузки/операции.
  /// [objects] — список объектов (по умолчанию пустой).
  /// [errorMessage] — сообщение об ошибке (опционально).
  const factory ObjectState({
    required ObjectStatus status,
    @Default([]) List<ObjectEntity> objects,
    String? errorMessage,
  }) = _ObjectState;

  /// Возвращает начальное состояние ([ObjectStatus.initial]).
  factory ObjectState.initial() => const ObjectState(status: ObjectStatus.initial);
}

/// StateNotifier для управления состоянием и операциями с объектами недвижимости.
///
/// Позволяет загружать, создавать, обновлять и удалять объекты, а также обрабатывать ошибки.
class ObjectNotifier extends StateNotifier<ObjectState> {
  /// Use case для получения всех объектов.
  final GetObjectsUseCase getObjectsUseCase;

  /// Use case для создания объекта.
  final CreateObjectUseCase createObjectUseCase;

  /// Use case для обновления объекта.
  final UpdateObjectUseCase updateObjectUseCase;

  /// Use case для удаления объекта.
  final DeleteObjectUseCase deleteObjectUseCase;

  /// Создаёт [ObjectNotifier] с необходимыми use case-ами.
  ObjectNotifier({
    required this.getObjectsUseCase,
    required this.createObjectUseCase,
    required this.updateObjectUseCase,
    required this.deleteObjectUseCase,
  }) : super(ObjectState.initial());

  /// Загружает список всех объектов недвижимости.
  ///
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> loadObjects() async {
    state = state.copyWith(status: ObjectStatus.loading);
    try {
      final objects = await getObjectsUseCase.execute();
      state = state.copyWith(status: ObjectStatus.success, objects: objects);
    } catch (e) {
      state = state.copyWith(
          status: ObjectStatus.error, errorMessage: e.toString());
    }
  }

  /// Добавляет новый объект недвижимости.
  ///
  /// После успешного добавления — перезагружает список объектов.
  Future<void> addObject(ObjectEntity object) async {
    state = state.copyWith(status: ObjectStatus.loading);
    try {
      await createObjectUseCase.execute(object);
      await loadObjects();
    } catch (e) {
      state = state.copyWith(
          status: ObjectStatus.error, errorMessage: e.toString());
    }
  }

  /// Обновляет существующий объект недвижимости.
  ///
  /// После успешного обновления — перезагружает список объектов.
  Future<void> updateObject(ObjectEntity object) async {
    state = state.copyWith(status: ObjectStatus.loading);
    try {
      await updateObjectUseCase.execute(object);
      await loadObjects();
    } catch (e) {
      state = state.copyWith(
          status: ObjectStatus.error, errorMessage: e.toString());
    }
  }

  /// Удаляет объект недвижимости по [id].
  ///
  /// После успешного удаления — перезагружает список объектов.
  Future<void> deleteObject(String id) async {
    state = state.copyWith(status: ObjectStatus.loading);
    try {
      await deleteObjectUseCase.execute(id);
      await loadObjects();
    } catch (e) {
      state = state.copyWith(
          status: ObjectStatus.error, errorMessage: e.toString());
    }
  }
}
