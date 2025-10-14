import '../models/work_model.dart';
import '../models/month_group.dart';

/// Абстрактный источник данных для работы со сменами.
///
/// Определяет методы для получения, создания, обновления и удаления смен.
abstract class WorkDataSource {
  /// Возвращает список всех смен.
  Future<List<WorkModel>> getWorks();

  /// Возвращает смену по идентификатору [id].
  Future<WorkModel?> getWork(String id);

  /// Добавляет новую смену [work] и возвращает созданную модель.
  Future<WorkModel> addWork(WorkModel work);

  /// Обновляет данные смены [work] и возвращает обновлённую модель.
  Future<WorkModel> updateWork(WorkModel work);

  /// Удаляет смену по идентификатору [id].
  Future<void> deleteWork(String id);

  /// Возвращает заголовки групп месяцев с агрегированными данными.
  ///
  /// Загружает все смены с полями date, total_amount, items_count, employees_count
  /// и группирует их по месяцам на клиенте.
  ///
  /// Возвращает список [MonthGroup] с заполненными worksCount и totalAmount,
  /// но works = null (загружаются лениво через getMonthWorks).
  Future<List<MonthGroup>> getMonthsHeaders();

  /// Возвращает смены конкретного месяца с пагинацией.
  ///
  /// [month] — дата начала месяца (например, DateTime(2025, 10, 1))
  /// [offset] — смещение для пагинации (по умолчанию 0)
  /// [limit] — лимит записей (по умолчанию 30)
  ///
  /// Загружает смены где date >= month AND date < month+1месяц,
  /// отсортированные по дате (от новых к старым).
  Future<List<WorkModel>> getMonthWorks(
    DateTime month, {
    int offset = 0,
    int limit = 30,
  });
}
