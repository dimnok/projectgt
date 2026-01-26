import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/ks6a_period.dart' as entity;
import 'estimate_sorter.dart';

/// Тип строки в журнале КС-6а.
enum Ks6aRowType {
  /// Заголовок группы (название сметы).
  groupHeader,

  /// Обычная строка позиции.
  item,

  /// Итоговая строка по группе.
  groupTotal,
}

/// Модель данных для одной строки в таблице КС-6а.
/// Используется для плоского отображения сгруппированных данных.
class Ks6aRowViewModel {
  /// Тип строки (заголовок, позиция, итог).
  final Ks6aRowType type;

  /// Номер позиции по смете.
  final String? number;

  /// Наименование работы или группы.
  final String label;

  /// Единица измерения.
  final String? unit;

  /// Общее количество по смете.
  final double quantity;

  /// Цена за единицу.
  final double price;

  /// Общая стоимость по смете.
  final double total;

  /// Ссылка на сущность сметы (только для типа item).
  final Estimate? estimate;

  /// Данные по периодам: список кортежей {quantity, amount}.
  /// Соответствует порядку периодов в `ks6aData.periods`.
  final List<({double quantity, double amount})> periodValues;

  /// Создает экземпляр [Ks6aRowViewModel].
  const Ks6aRowViewModel({
    required this.type,
    this.number,
    required this.label,
    this.unit,
    this.quantity = 0,
    this.price = 0,
    this.total = 0,
    this.periodValues = const [],
    this.estimate,
  });
}

/// Утилита для подготовки и трансформации данных Журнала КС-6а для UI.
class Ks6aTableProcessor {
  /// Преобразует список смет и данные по периодам в плоский список моделей строк.
  /// 
  /// Группирует позиции по `estimateTitle`, сортирует их по номеру
  /// и рассчитывает промежуточные итоги по каждой группе.
  static List<Ks6aRowViewModel> process({
    required List<Estimate> estimates,
    required entity.Ks6aContractData ks6aData,
  }) {
    final rows = <Ks6aRowViewModel>[];
    final periods = ks6aData.periods;
    final periodItems = ks6aData.items;

    // 1. Сортируем все позиции
    final sortedEstimates = [...estimates]..sort(EstimateSorter.compareByNumber);

    // 2. Группируем по заголовку
    final grouped = <String, List<Estimate>>{};
    for (final e in sortedEstimates) {
      final title = e.estimateTitle ?? 'Основная смета';
      grouped.putIfAbsent(title, () => []).add(e);
    }

    // 3. Сортируем заголовки
    final sortedTitles = grouped.keys.toList()..sort();

    for (final title in sortedTitles) {
      final items = grouped[title]!;
      
      // Итоги по группе
      final groupTotalAmount = items.fold(0.0, (sum, e) => sum + e.total);
      final groupPeriodTotals = List.generate(
        periods.length, 
        (_) => (quantity: 0.0, amount: 0.0),
      );

      // Добавляем заголовок группы
      rows.add(Ks6aRowViewModel(
        type: Ks6aRowType.groupHeader,
        label: title.toUpperCase(),
      ));

      // Добавляем строки позиций
      for (final estimate in items) {
        final itemPeriodValues = <({double quantity, double amount})>[];
        
        for (int i = 0; i < periods.length; i++) {
          final period = periods[i];
          final periodItem = periodItems.where((pi) => pi.periodId == period.id && pi.estimateId == estimate.id).firstOrNull;

          final qty = periodItem?.quantity ?? 0.0;
          final amt = periodItem?.amount ?? 0.0;

          itemPeriodValues.add((quantity: qty, amount: amt));
          
          final currentTotal = groupPeriodTotals[i];
          groupPeriodTotals[i] = (
            quantity: currentTotal.quantity + qty,
            amount: currentTotal.amount + amt,
          );
        }

        rows.add(Ks6aRowViewModel(
          type: Ks6aRowType.item,
          number: estimate.number,
          label: estimate.name,
          unit: estimate.unit,
          quantity: estimate.quantity,
          price: estimate.price,
          total: estimate.total,
          periodValues: itemPeriodValues,
          estimate: estimate,
        ));
      }

      // Добавляем итог по группе
      rows.add(Ks6aRowViewModel(
        type: Ks6aRowType.groupTotal,
        label: 'ИТОГО ПО СМЕТЕ:',
        total: groupTotalAmount,
        periodValues: groupPeriodTotals,
      ));
    }

    return rows;
  }
}
