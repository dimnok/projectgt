/// Строка шаблона для выгрузки LC / ДС по текущей смете.
///
/// `positionId` является сквозным идентификатором позиции и нужен для того,
/// чтобы при повторной загрузке Excel отличать существующие строки от новых.
class EstimateAddendumTemplateRow {
  /// Сквозной идентификатор позиции сметы.
  final String positionId;

  /// Система.
  final String system;

  /// Подсистема.
  final String subsystem;

  /// Номер позиции.
  final String number;

  /// Наименование позиции.
  final String name;

  /// Артикул.
  final String article;

  /// Производитель.
  final String manufacturer;

  /// Единица измерения.
  final String unit;

  /// Количество.
  final double quantity;

  /// Цена.
  final double price;

  /// Сумма.
  final double total;

  /// Создаёт строку шаблона для LC / ДС.
  const EstimateAddendumTemplateRow({
    required this.positionId,
    required this.system,
    required this.subsystem,
    required this.number,
    required this.name,
    required this.article,
    required this.manufacturer,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

/// Строка из импортируемого Excel-файла LC / ДС.
class EstimateAddendumImportRow {
  /// Сквозной идентификатор позиции.
  ///
  /// Пустое значение означает, что строка новая и должна получить новый ID.
  final String? positionId;

  /// Порядок строки в файле.
  final int rowNo;

  /// Система.
  final String system;

  /// Подсистема.
  final String subsystem;

  /// Номер позиции.
  final String number;

  /// Наименование позиции.
  final String name;

  /// Артикул.
  final String article;

  /// Производитель.
  final String manufacturer;

  /// Единица измерения.
  final String unit;

  /// Количество.
  final double quantity;

  /// Цена.
  final double price;

  /// Сумма.
  final double total;

  /// Создаёт строку импорта LC / ДС.
  const EstimateAddendumImportRow({
    required this.positionId,
    required this.rowNo,
    required this.system,
    required this.subsystem,
    required this.number,
    required this.name,
    required this.article,
    required this.manufacturer,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

/// Результат создания черновика LC / ДС.
class EstimateRevisionDraftResult {
  /// Идентификатор ревизии.
  final String revisionId;

  /// Номер ревизии внутри сметы.
  final int revisionNo;

  /// Текстовая метка ревизии.
  final String revisionLabel;

  /// Количество сохранённых строк.
  final int itemsCount;

  /// Признак того, что базовая ревизия "Основная" была создана автоматически.
  final bool baseRevisionCreated;

  /// Создаёт результат импорта черновика LC / ДС.
  const EstimateRevisionDraftResult({
    required this.revisionId,
    required this.revisionNo,
    required this.revisionLabel,
    required this.itemsCount,
    required this.baseRevisionCreated,
  });
}
