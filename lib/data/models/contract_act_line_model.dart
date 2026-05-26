import 'package:projectgt/domain/entities/contract_act_line.dart';

/// DTO строки акта КС-2 (`contract_act_lines`).
class ContractActLineModel {
  /// Создаёт модель из JSON PostgREST.
  const ContractActLineModel({
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

  /// Строка ВОР.
  final String? vorItemId;

  /// Порядок сортировки.
  final int sortOrder;

  /// Номер в смете.
  final String estimateNumber;

  /// Раздел сметы.
  final String sectionTitle;

  /// Наименование.
  final String name;

  /// Единица измерения.
  final String unit;

  /// Количество.
  final double quantity;

  /// Цена.
  final double price;

  /// Сумма.
  final double amount;

  /// Перенос с прошлых ВОР.
  final double backlogQuantity;

  /// Объём текущего периода ВОР.
  final double currentPeriodQuantity;

  /// Парсит строку из Supabase.
  factory ContractActLineModel.fromJson(Map<String, dynamic> json) {
    return ContractActLineModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      contractId: json['contract_id'] as String,
      contractActId: json['contract_act_id'] as String,
      estimateItemId: json['estimate_item_id'] as String?,
      vorItemId: json['vor_item_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      estimateNumber: json['estimate_number'] as String? ?? '',
      sectionTitle: json['section_title'] as String? ?? '',
      name: json['name'] as String? ?? '—',
      unit: json['unit'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      backlogQuantity: (json['backlog_quantity'] as num?)?.toDouble() ?? 0,
      currentPeriodQuantity:
          (json['current_period_quantity'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Преобразует в доменную сущность.
  ContractActLine toEntity() {
    return ContractActLine(
      id: id,
      companyId: companyId,
      contractId: contractId,
      contractActId: contractActId,
      estimateItemId: estimateItemId,
      vorItemId: vorItemId,
      sortOrder: sortOrder,
      estimateNumber: estimateNumber,
      sectionTitle: sectionTitle,
      name: name,
      unit: unit,
      quantity: quantity,
      price: price,
      amount: amount,
      backlogQuantity: backlogQuantity,
      currentPeriodQuantity: currentPeriodQuantity,
    );
  }
}
