import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_search_result.freezed.dart';

/// Результат поиска работ.
///
/// Объединяет данные из смены и работы для отображения в таблице поиска.
@freezed
abstract class WorkSearchResult with _$WorkSearchResult {
  /// Создаёт результат поиска работ.
  ///
  /// [workDate] — дата смены
  /// [objectName] — название объекта
  /// [system] — система
  /// [subsystem] — подсистема
  /// [section] — секция (модуль)
  /// [floor] — этаж
  /// [workName] — наименование работы
  /// [materialName] — наименование работы (дублирует workName для совместимости)
  /// [unit] — единица измерения
  /// [quantity] — количество
  const factory WorkSearchResult({
    /// Дата смены.
    required DateTime workDate,
    /// Название объекта.
    required String objectName,
    /// Система.
    required String system,
    /// Подсистема.
    required String subsystem,
    /// Секция (модуль).
    required String section,
    /// Этаж.
    required String floor,
    /// Наименование работы.
    required String workName,
    /// Наименование работы (для совместимости с интерфейсом).
    required String materialName,
    /// Единица измерения.
    required String unit,
    /// Количество.
    required num quantity,
  }) = _WorkSearchResult;
} 