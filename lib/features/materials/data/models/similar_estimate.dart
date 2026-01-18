/// Модель похожей сметной позиции для автоматического поиска дублирующихся работ.
///
/// Используется в функции "Умная групповая привязка материалов".
class SimilarEstimate {
  /// UUID сметной позиции.
  final String id;

  /// Название сметной позиции.
  final String name;

  /// Единица измерения.
  final String unit;

  /// Система (например, "КМИ9").
  final String system;

  /// Подсистема (например, "Профиль").
  final String subsystem;

  /// Коэффициент схожести от 0 до 1 (1 = полное совпадение).
  final double similarityScore;

  /// Создаёт модель похожей сметной позиции.
  const SimilarEstimate({
    required this.id,
    required this.name,
    required this.unit,
    required this.system,
    required this.subsystem,
    required this.similarityScore,
  });

  /// Создаёт модель из JSON Map (результат PostgreSQL RPC).
  factory SimilarEstimate.fromMap(Map<String, dynamic> map) {
    return SimilarEstimate(
      id: map['estimate_id']?.toString() ?? '',
      name: map['estimate_name']?.toString() ?? '',
      unit: map['estimate_unit']?.toString() ?? '',
      system: map['system']?.toString() ?? '',
      subsystem: map['subsystem']?.toString() ?? '',
      similarityScore: double.tryParse(
            map['similarity_score']?.toString() ?? '0',
          ) ??
          0.0,
    );
  }

  @override
  String toString() {
    return 'SimilarEstimate(id: $id, name: $name, system: $system, subsystem: $subsystem, similarity: ${(similarityScore * 100).round()}%)';
  }
}
