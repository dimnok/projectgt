import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// Use case для получения командировочных выплат по ID сотрудника.
///
/// Возвращает список всех настроенных командировочных для конкретного сотрудника,
/// отсортированных по дате создания (новые сначала).
class GetBusinessTripRatesByEmployeeUseCase {
  /// Репозиторий для работы с командировочными выплатами.
  final BusinessTripRateRepository _repository;

  /// Конструктор [GetBusinessTripRatesByEmployeeUseCase].
  const GetBusinessTripRatesByEmployeeUseCase(this._repository);

  /// Выполняет получение командировочных выплат для сотрудника.
  ///
  /// [employeeId] — ID сотрудника для поиска командировочных.
  /// Возвращает [Future<List<BusinessTripRate>>] со списком командировочных.
  ///
  /// Пример использования:
  /// ```dart
  /// final useCase = GetBusinessTripRatesByEmployeeUseCase(repository);
  /// final rates = await useCase('employee-id-123');
  /// ```
  Future<List<BusinessTripRate>> call(String employeeId) async {
    final allRates = await _repository.getAllRates();

    // Фильтруем по employee_id и сортируем по дате создания
    final employeeRates =
        allRates.where((rate) => rate.employeeId == employeeId).toList();

    // Сортируем по дате создания (новые сначала), затем по дате начала действия
    employeeRates.sort((a, b) {
      // Сначала по дате создания (если есть)
      if (a.createdAt != null && b.createdAt != null) {
        final createdComparison = b.createdAt!.compareTo(a.createdAt!);
        if (createdComparison != 0) return createdComparison;
      }

      // Затем по дате начала действия (новые сначала)
      return b.validFrom.compareTo(a.validFrom);
    });

    return employeeRates;
  }
}
