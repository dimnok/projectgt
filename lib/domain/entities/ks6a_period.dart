import '../../../data/models/ks6a_model.dart';

/// Сущность заголовка периода КС-6а.
class Ks6aPeriod {
  /// Идентификатор периода.
  final String id;

  /// Дата начала периода.
  final DateTime startDate;

  /// Дата окончания периода.
  final DateTime endDate;

  /// Статус периода (черновик/согласовано).
  final Ks6aStatus status;

  /// Название периода (например, "Январь 2026").
  final String? title;

  /// Итоговая сумма по периоду.
  final double totalAmount;

  /// Создает экземпляр [Ks6aPeriod].
  const Ks6aPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.title,
    this.totalAmount = 0.0,
  });
}

/// Сущность строки периода КС-6а.
class Ks6aPeriodItem {
  /// Идентификатор записи.
  final String id;

  /// Идентификатор периода.
  final String periodId;

  /// Идентификатор сметной позиции.
  final String estimateId;

  /// Количество выполнения за этот период.
  final double quantity;

  /// Цена позиции на момент фиксации периода.
  final double priceSnapshot;

  /// Сумма (quantity * priceSnapshot).
  final double amount;

  /// Создает экземпляр [Ks6aPeriodItem].
  const Ks6aPeriodItem({
    required this.id,
    required this.periodId,
    required this.estimateId,
    required this.quantity,
    required this.priceSnapshot,
    required this.amount,
  });
}

/// Агрегированная сущность всех данных КС-6а по договору.
class Ks6aContractData {
  /// Список всех периодов договора.
  final List<Ks6aPeriod> periods;

  /// Список всех детальных строк по всем периодам.
  final List<Ks6aPeriodItem> items;

  /// Создает экземпляр [Ks6aContractData].
  const Ks6aContractData({
    required this.periods,
    required this.items,
  });
}
