/// Строка сводки по одной накладной в контексте договора.
class MaterialsReceiptSummaryItem {
  /// Создаёт строку сводки.
  const MaterialsReceiptSummaryItem({
    required this.receiptNumber,
    this.receiptDate,
    required this.positionCount,
    required this.totalAmount,
  });

  /// Номер накладной.
  final String receiptNumber;

  /// Дата накладной.
  final DateTime? receiptDate;

  /// Количество позиций (строк материалов).
  final int positionCount;

  /// Сумма по позициям накладной.
  final double totalAmount;
}

/// Агрегированная сводка по накладным договора.
class MaterialsReceiptsSummary {
  /// Создаёт сводку.
  const MaterialsReceiptsSummary({
    required this.receiptCount,
    required this.grandTotal,
    required this.items,
  });

  /// Число уникальных накладных.
  final int receiptCount;

  /// Сумма по всем накладным.
  final double grandTotal;

  /// Строки по накладным, отсортированы по дате (новые сверху).
  final List<MaterialsReceiptSummaryItem> items;
}
