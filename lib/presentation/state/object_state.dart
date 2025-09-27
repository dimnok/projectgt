import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/usecases/object/get_objects_usecase.dart';
import 'package:projectgt/domain/usecases/object/create_object_usecase.dart';
import 'package:projectgt/domain/usecases/object/update_object_usecase.dart';
import 'package:projectgt/domain/usecases/object/delete_object_usecase.dart';

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
class ObjectState {
  /// Текущий статус загрузки/операции ([ObjectStatus]).
  final ObjectStatus status;

  /// Список всех объектов недвижимости.
  final List<ObjectEntity> objects;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Создаёт новое состояние для работы с объектами.
  ///
  /// [status] — статус загрузки/операции.
  /// [objects] — список объектов (по умолчанию пустой).
  /// [errorMessage] — сообщение об ошибке (опционально).
  ObjectState({
    required this.status,
    this.objects = const [],
    this.errorMessage,
  });

  /// Возвращает начальное состояние ([ObjectStatus.initial]).
  factory ObjectState.initial() => ObjectState(status: ObjectStatus.initial);

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [objects] — новый список объектов (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  ObjectState copyWith({
    ObjectStatus? status,
    List<ObjectEntity>? objects,
    String? errorMessage,
  }) {
    return ObjectState(
      status: status ?? this.status,
      objects: objects ?? this.objects,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
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

// Удалено: objectProvider-заглушка, теперь используется DI-провайдер из core/di/providers.dart
// final objectProvider = StateNotifierProvider<ObjectNotifier, ObjectState>((ref) {
//   // Здесь должны быть переданы реальные usecase, внедрение зависит от DI в проекте
//   // Для примера — заглушки, заменить на реальные реализации
//   throw UnimplementedError('Передайте реальные usecase в ObjectNotifier');
// });
