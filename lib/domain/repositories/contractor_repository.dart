import 'package:projectgt/domain/entities/contractor.dart';

/// Абстракция репозитория для работы с подрядчиками.
abstract class ContractorRepository {
  /// Получи список всех подрядчиков.
  ///
  /// Возвращает список [Contractor]. Бросает [Exception] при ошибке.
  Future<List<Contractor>> getContractors();

  /// Получи подрядчика по [id].
  ///
  /// Возвращает [Contractor] или null, если не найден. Бросает [Exception] при ошибке.
  Future<Contractor?> getContractor(String id);

  /// Создай нового подрядчика [contractor] в источнике данных.
  ///
  /// Возвращает созданного [Contractor]. Бросает [Exception] при ошибке.
  Future<Contractor> createContractor(Contractor contractor);

  /// Обнови подрядчика [contractor] в источнике данных.
  ///
  /// Возвращает обновлённого [Contractor]. Бросает [Exception] при ошибке.
  Future<Contractor> updateContractor(Contractor contractor);

  /// Удали подрядчика по [id].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> deleteContractor(String id);
} 