/// Строка акта КС-2 (`contract_act_lines`): объём по позиции сметы.
class ContractActLine {
  /// Создаёт строку акта.
  const ContractActLine({
    required this.id,
    required this.companyId,
    required this.contractId,
    required this.contractActId,
    this.estimateItemId,
    this.vorItemId,
    required this.sortOrder,
    required this.estimateNumber,
    required this.sectionTitle,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.backlogQuantity,
    required this.currentPeriodQuantity,
  });

  /// Идентификатор строки.
  final String id;

  /// Компания.
  final String companyId;

  /// Договор.
  final String contractId;

  /// Акт.
  final String contractActId;

  /// Позиция сметы.
  final String? estimateItemId;

  /// Строка ВОР (если была при формировании).
  final String? vorItemId;

  /// Порядок в таблице акта.
  final int sortOrder;

  /// Номер позиции в смете.
  final String estimateNumber;

  /// Раздел сметы (`estimate_title`).
  final String sectionTitle;

  /// Наименование работ.
  final String name;

  /// Единица измерения.
  final String unit;

  /// Количество в акте.
  final double quantity;

  /// Цена за единицу.
  final double price;

  /// Сумма строки.
  final double amount;

  /// Перенос с прошлых ВОР.
  final double backlogQuantity;

  /// Объём за период текущей ВОР.
  final double currentPeriodQuantity;
}
