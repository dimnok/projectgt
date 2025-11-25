import '../../domain/entities/work.dart';
import '../../domain/entities/light_work.dart';
import '../../domain/entities/work_summaries.dart';
import '../../domain/repositories/work_repository.dart';
import '../datasources/work_data_source.dart';
import '../models/work_model.dart';
import '../models/month_group.dart';
import '../models/light_work_model.dart';
import 'package:projectgt/core/services/photo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Реализация репозитория для работы со сменами через источник данных [WorkDataSource].
class WorkRepositoryImpl implements WorkRepository {
  /// Источник данных для смен.
  final WorkDataSource dataSource;

  /// Сервис для работы с фото.
  late final PhotoService _photoService;

  /// Создаёт репозиторий для работы со сменами.
  WorkRepositoryImpl(this.dataSource) {
    _photoService = PhotoService(Supabase.instance.client);
  }

  /// Возвращает список всех смен.
  @override
  Future<List<Work>> getWorks() async {
    final models = await dataSource.getWorks();
    return models.map(_mapToEntity).toList();
  }

  /// Возвращает смену по идентификатору [id].
  @override
  Future<Work?> getWork(String id) async {
    final model = await dataSource.getWork(id);
    return model != null ? _mapToEntity(model) : null;
  }

  /// Добавляет новую смену [work] и возвращает созданную сущность.
  @override
  Future<Work> addWork(Work work) async {
    final model = WorkModel(
      id: null,
      date: work.date,
      objectId: work.objectId,
      openedBy: work.openedBy,
      status: work.status,
      photoUrl: work.photoUrl,
      eveningPhotoUrl: work.eveningPhotoUrl,
      createdAt: work.createdAt,
      updatedAt: work.updatedAt,
      // Агрегатные поля инициализируются нулями
      totalAmount: work.totalAmount ?? 0,
      itemsCount: work.itemsCount ?? 0,
      employeesCount: work.employeesCount ?? 0,
    );
    final result = await dataSource.addWork(model);
    return _mapToEntity(result);
  }

  /// Обновляет данные смены [work] и возвращает обновлённую сущность.
  @override
  Future<Work> updateWork(Work work) async {
    final model = WorkModel(
      id: work.id,
      date: work.date,
      objectId: work.objectId,
      openedBy: work.openedBy,
      status: work.status,
      photoUrl: work.photoUrl,
      eveningPhotoUrl: work.eveningPhotoUrl,
      createdAt: work.createdAt,
      updatedAt: work.updatedAt,
      // Агрегатные поля (триггеры могут пересчитать, но передаём текущие значения)
      totalAmount: work.totalAmount,
      itemsCount: work.itemsCount,
      employeesCount: work.employeesCount,
      telegramMessageId: work.telegramMessageId,
    );
    final result = await dataSource.updateWork(model);
    return _mapToEntity(result);
  }

  /// Удаляет смену по идентификатору [id].
  @override
  Future<void> deleteWork(String id) async {
    // Сначала получаем данные смены для удаления связанных фото
    final work = await dataSource.getWork(id);
    if (work != null) {
      // Удаляем утреннее фото (если есть)
      if (work.photoUrl != null && work.photoUrl!.isNotEmpty) {
        await _photoService.deleteWorkPhotoByUrl(work.photoUrl!);
      }

      // Удаляем вечернее фото (если есть)
      if (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty) {
        await _photoService.deleteWorkPhotoByUrl(work.eveningPhotoUrl!);
      }
    }

    // Удаляем саму смену из БД
    await dataSource.deleteWork(id);
  }

  /// Возвращает заголовки групп месяцев с агрегированными данными.
  @override
  Future<List<MonthGroup>> getMonthsHeaders() async {
    return await dataSource.getMonthsHeaders();
  }

  /// Возвращает смены конкретного месяца с пагинацией.
  @override
  Future<List<Work>> getMonthWorks(
    DateTime month, {
    int offset = 0,
    int limit = 30,
  }) async {
    final models = await dataSource.getMonthWorks(
      month,
      offset: offset,
      limit: limit,
    );
    return models.map(_mapToEntity).toList();
  }

  /// Возвращает полные данные по выработке за месяц для графика.
  @override
  Future<List<LightWork>> getMonthWorksForChart(DateTime month) async {
    final models = await dataSource.getMonthWorksForChart(month);
    return models.map(_mapToLightEntity).toList();
  }

  /// Возвращает полную статистику по объектам за месяц.
  @override
  Future<List<ObjectSummary>> getObjectsSummary(DateTime month) async {
    return await dataSource.getObjectsSummary(month);
  }

  /// Возвращает полную статистику по системам за месяц.
  @override
  Future<List<SystemSummary>> getSystemsSummary(DateTime month) async {
    return await dataSource.getSystemsSummary(month);
  }

  /// Возвращает общее количество часов за месяц.
  @override
  Future<MonthHoursSummary> getTotalHours(DateTime month) async {
    return await dataSource.getTotalHours(month);
  }

  /// Возвращает количество уникальных сотрудников за месяц.
  @override
  Future<MonthEmployeesSummary> getTotalEmployees(DateTime month) async {
    return await dataSource.getTotalEmployees(month);
  }

  /// Преобразует модель смены [WorkModel] в доменную сущность [Work].
  Work _mapToEntity(WorkModel model) {
    return Work(
      id: model.id,
      date: model.date,
      objectId: model.objectId,
      openedBy: model.openedBy,
      status: model.status,
      photoUrl: model.photoUrl,
      eveningPhotoUrl: model.eveningPhotoUrl,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      totalAmount: model.totalAmount,
      itemsCount: model.itemsCount,
      employeesCount: model.employeesCount,
      telegramMessageId: model.telegramMessageId,
    );
  }

  /// Преобразует облегченную модель [LightWorkModel] в доменную сущность [LightWork].
  LightWork _mapToLightEntity(LightWorkModel model) {
    return LightWork(
      id: model.id,
      date: model.date,
      totalAmount: model.totalAmount,
      employeesCount: model.employeesCount,
    );
  }
}
