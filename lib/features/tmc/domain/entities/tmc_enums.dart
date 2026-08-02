import 'package:json_annotation/json_annotation.dart';

/// Тип учёта позиции ТМЦ.
enum TmcAccountingType {
  /// Поштучный (индивидуальный) учёт.
  @JsonValue('individual')
  individual,

  /// Количественный учёт.
  @JsonValue('quantitative')
  quantitative,
}

/// Расширения для [TmcAccountingType].
extension TmcAccountingTypeX on TmcAccountingType {
  /// Значение для БД / JSON.
  String get dbValue => switch (this) {
        TmcAccountingType.individual => 'individual',
        TmcAccountingType.quantitative => 'quantitative',
      };

  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcAccountingType.individual => 'Индивидуальный',
        TmcAccountingType.quantitative => 'Количественный',
      };
}

/// Статус позиции каталога ТМЦ.
enum TmcItemStatus {
  /// Активная позиция.
  @JsonValue('active')
  active,

  /// Архивная позиция.
  @JsonValue('archived')
  archived,
}

/// Расширения для [TmcItemStatus].
extension TmcItemStatusX on TmcItemStatus {
  /// Значение для БД / JSON.
  String get dbValue => switch (this) {
        TmcItemStatus.active => 'active',
        TmcItemStatus.archived => 'archived',
      };

  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcItemStatus.active => 'Активна',
        TmcItemStatus.archived => 'В архиве',
      };
}

/// Статус единицы ТМЦ (индивидуальный учёт).
enum TmcUnitStatus {
  /// На складе.
  @JsonValue('in_stock')
  inStock,

  /// На объекте.
  @JsonValue('on_object')
  onObject,

  /// Выдано сотруднику.
  @JsonValue('issued')
  issued,

  /// Временно передано.
  @JsonValue('temporarily_transferred')
  temporarilyTransferred,

  /// В ремонте.
  @JsonValue('in_repair')
  inRepair,

  /// На обслуживании.
  @JsonValue('in_service')
  inService,

  /// Зарезервировано.
  @JsonValue('reserved')
  reserved,

  /// Утеряно.
  @JsonValue('lost')
  lost,

  /// Списано.
  @JsonValue('written_off')
  writtenOff,
}

/// Расширения для [TmcUnitStatus].
extension TmcUnitStatusX on TmcUnitStatus {
  /// Значение для БД / JSON.
  String get dbValue => switch (this) {
        TmcUnitStatus.inStock => 'in_stock',
        TmcUnitStatus.onObject => 'on_object',
        TmcUnitStatus.issued => 'issued',
        TmcUnitStatus.temporarilyTransferred => 'temporarily_transferred',
        TmcUnitStatus.inRepair => 'in_repair',
        TmcUnitStatus.inService => 'in_service',
        TmcUnitStatus.reserved => 'reserved',
        TmcUnitStatus.lost => 'lost',
        TmcUnitStatus.writtenOff => 'written_off',
      };

  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcUnitStatus.inStock => 'На складе',
        TmcUnitStatus.onObject => 'На объекте',
        TmcUnitStatus.issued => 'Выдано',
        TmcUnitStatus.temporarilyTransferred => 'Временно передано',
        TmcUnitStatus.inRepair => 'В ремонте',
        TmcUnitStatus.inService => 'На обслуживании',
        TmcUnitStatus.reserved => 'Зарезервировано',
        TmcUnitStatus.lost => 'Утеряно',
        TmcUnitStatus.writtenOff => 'Списано',
      };
}

/// Тип местоположения ТМЦ.
enum TmcLocationType {
  /// Склад.
  @JsonValue('warehouse')
  warehouse,

  /// Объект строительства.
  @JsonValue('object')
  object,

  /// Сотрудник.
  @JsonValue('employee')
  employee,

  /// Офис.
  @JsonValue('office')
  office,

  /// Ремонтная организация.
  @JsonValue('repair_org')
  repairOrg,

  /// Прочее.
  @JsonValue('other')
  other,
}

/// Расширения для [TmcLocationType].
extension TmcLocationTypeX on TmcLocationType {
  /// Значение для БД / JSON.
  String get dbValue => switch (this) {
        TmcLocationType.warehouse => 'warehouse',
        TmcLocationType.object => 'object',
        TmcLocationType.employee => 'employee',
        TmcLocationType.office => 'office',
        TmcLocationType.repairOrg => 'repair_org',
        TmcLocationType.other => 'other',
      };

  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcLocationType.warehouse => 'Склад',
        TmcLocationType.object => 'Объект',
        TmcLocationType.employee => 'Сотрудник',
        TmcLocationType.office => 'Офис',
        TmcLocationType.repairOrg => 'Ремонтная организация',
        TmcLocationType.other => 'Прочее',
      };
}

/// Тип складской операции ТМЦ.
enum TmcOperationType {
  /// Поступление.
  @JsonValue('receipt')
  receipt,

  /// Выдача сотруднику.
  @JsonValue('issue')
  issue,

  /// Возврат от сотрудника.
  @JsonValue('return_from_employee')
  returnFromEmployee,

  /// Перемещение на объект.
  @JsonValue('transfer_to_object')
  transferToObject,

  /// Возврат с объекта.
  @JsonValue('return_from_object')
  returnFromObject,

  /// Перемещение между объектами.
  @JsonValue('move_between_objects')
  moveBetweenObjects,

  /// Перемещение между складами.
  @JsonValue('move_between_warehouses')
  moveBetweenWarehouses,

  /// Передача между сотрудниками.
  @JsonValue('transfer_between_employees')
  transferBetweenEmployees,

  /// Резервирование.
  @JsonValue('reserve')
  reserve,

  /// Снятие резерва.
  @JsonValue('unreserve')
  unreserve,

  /// Отправка в ремонт.
  @JsonValue('send_to_repair')
  sendToRepair,

  /// Возврат из ремонта.
  @JsonValue('return_from_repair')
  returnFromRepair,

  /// Изменение состояния.
  @JsonValue('change_condition')
  changeCondition,

  /// Корректировка по инвентаризации.
  @JsonValue('inventory_adjust')
  inventoryAdjust,

  /// Списание.
  @JsonValue('write_off')
  writeOff,

  /// Недостача.
  @JsonValue('shortage')
  shortage,

  /// Корректировка.
  @JsonValue('correction')
  correction,
}

/// Расширения для [TmcOperationType].
extension TmcOperationTypeX on TmcOperationType {
  /// Значение для БД / JSON.
  String get dbValue => switch (this) {
        TmcOperationType.receipt => 'receipt',
        TmcOperationType.issue => 'issue',
        TmcOperationType.returnFromEmployee => 'return_from_employee',
        TmcOperationType.transferToObject => 'transfer_to_object',
        TmcOperationType.returnFromObject => 'return_from_object',
        TmcOperationType.moveBetweenObjects => 'move_between_objects',
        TmcOperationType.moveBetweenWarehouses => 'move_between_warehouses',
        TmcOperationType.transferBetweenEmployees =>
          'transfer_between_employees',
        TmcOperationType.reserve => 'reserve',
        TmcOperationType.unreserve => 'unreserve',
        TmcOperationType.sendToRepair => 'send_to_repair',
        TmcOperationType.returnFromRepair => 'return_from_repair',
        TmcOperationType.changeCondition => 'change_condition',
        TmcOperationType.inventoryAdjust => 'inventory_adjust',
        TmcOperationType.writeOff => 'write_off',
        TmcOperationType.shortage => 'shortage',
        TmcOperationType.correction => 'correction',
      };

  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcOperationType.receipt => 'Поступление',
        TmcOperationType.issue => 'Выдача',
        TmcOperationType.returnFromEmployee => 'Возврат от сотрудника',
        TmcOperationType.transferToObject => 'Перемещение на объект',
        TmcOperationType.returnFromObject => 'Возврат с объекта',
        TmcOperationType.moveBetweenObjects => 'Перемещение между объектами',
        TmcOperationType.moveBetweenWarehouses => 'Перемещение между складами',
        TmcOperationType.transferBetweenEmployees => 'Передача между сотрудниками',
        TmcOperationType.reserve => 'Резервирование',
        TmcOperationType.unreserve => 'Снятие резерва',
        TmcOperationType.sendToRepair => 'Отправка в ремонт',
        TmcOperationType.returnFromRepair => 'Возврат из ремонта',
        TmcOperationType.changeCondition => 'Изменение состояния',
        TmcOperationType.inventoryAdjust => 'Корректировка по инвентаризации',
        TmcOperationType.writeOff => 'Списание',
        TmcOperationType.shortage => 'Недостача',
        TmcOperationType.correction => 'Корректировка',
      };
}

/// Причина списания ТМЦ.
enum TmcWriteOffReason {
  /// Износ.
  @JsonValue('wear')
  wear,

  /// Поломка.
  @JsonValue('breakdown')
  breakdown,

  /// Утеря.
  @JsonValue('loss')
  loss,

  /// Недостача.
  @JsonValue('shortage')
  shortage,

  /// Моральный износ.
  @JsonValue('obsolescence')
  obsolescence,

  /// Окончание срока службы.
  @JsonValue('end_of_life')
  endOfLife,

  /// Прочее.
  @JsonValue('other')
  other,
}

/// Расширения для [TmcWriteOffReason].
extension TmcWriteOffReasonX on TmcWriteOffReason {
  /// Значение для БД / JSON.
  String get dbValue => switch (this) {
        TmcWriteOffReason.wear => 'wear',
        TmcWriteOffReason.breakdown => 'breakdown',
        TmcWriteOffReason.loss => 'loss',
        TmcWriteOffReason.shortage => 'shortage',
        TmcWriteOffReason.obsolescence => 'obsolescence',
        TmcWriteOffReason.endOfLife => 'end_of_life',
        TmcWriteOffReason.other => 'other',
      };

  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcWriteOffReason.wear => 'Износ',
        TmcWriteOffReason.breakdown => 'Поломка',
        TmcWriteOffReason.loss => 'Утеря',
        TmcWriteOffReason.shortage => 'Недостача',
        TmcWriteOffReason.obsolescence => 'Моральный износ',
        TmcWriteOffReason.endOfLife => 'Окончание срока службы',
        TmcWriteOffReason.other => 'Прочее',
      };
}
