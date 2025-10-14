import '../entities/work.dart';
import '../../data/models/month_group.dart';

/// Абстрактный репозиторий для работы со сменами.
///
/// Определяет методы для получения, создания, обновления и удаления смен.
abstract class WorkRepository {
  /// Возвращает список всех смен.
  Future<List<Work>> getWorks();

  /// Возвращает смену по идентификатору [id].
  Future<Work?> getWork(String id);

  /// Добавляет новую смену [work] и возвращает созданную сущность.
  Future<Work> addWork(Work work);

  /// Обновляет данные смены [work] и возвращает обновлённую сущность.
  Future<Work> updateWork(Work work);

  /// Удаляет смену по идентификатору [id].
  Future<void> deleteWork(String id);

  /// Возвращает заголовки групп месяцев с агрегированными данными.
  ///
  /// Используется для оптимизации отображения списка смен с группировкой по месяцам.
  Future<List<MonthGroup>> getMonthsHeaders();

  /// Возвращает смены конкретного месяца с пагинацией.
  ///
  /// [month] — дата начала месяца
  /// [offset] — смещение для пагинации (по умолчанию 0)
  /// [limit] — лимит записей (по умолчанию 30)
  Future<List<Work>> getMonthWorks(
    DateTime month, {
    int offset = 0,
    int limit = 30,
  });
}
