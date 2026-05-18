import 'package:projectgt/domain/entities/ks2_act.dart';

/// Интерфейс репозитория для работы с актами КС-2.
abstract class Ks2Repository {
  /// Получает список актов КС-2 по договору.
  Future<List<Ks2Act>> getActs(String contractId);

  /// Предварительный расчёт акта КС-2 по утверждённой ВОР (только строки без превышения сметы).
  Future<Ks2PreviewData> previewAct({
    required String contractId,
    required String vorId,
  });

  /// Создаёт акт КС-2 и привязывает его к ВОР (один акт на одну ВОР).
  Future<void> createAct({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime date,
  });

  /// Удаляет акт КС-2 (только если черновик) и отвязывает работы.
  Future<void> deleteAct(String actId);
}

/// Данные предпросмотра акта КС-2.
class Ks2PreviewData {
  /// Общая сумма акта.
  final double totalAmount;

  /// Количество позиций (строк ВОР), попадающих в акт.
  final int itemsCount;

  /// Количество строк ВОР, не попавших в акт (превышение сметы и т.п.).
  final int skippedCount;

  /// Список кандидатов (работ) для включения в акт.
  final List<dynamic> candidates;

  /// Создает данные предпросмотра.
  const Ks2PreviewData({
    required this.totalAmount,
    required this.itemsCount,
    required this.skippedCount,
    required this.candidates,
  });

  /// Создает экземпляр из JSON.
  factory Ks2PreviewData.fromJson(Map<String, dynamic> json) {
    return Ks2PreviewData(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      itemsCount: json['stats']?['candidatesCount'] ?? 0,
      skippedCount: json['stats']?['skippedCount'] ?? 0,
      candidates: json['candidates'] as List<dynamic>? ?? [],
    );
  }
}
