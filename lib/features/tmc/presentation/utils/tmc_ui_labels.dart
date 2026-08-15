import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';

/// Русские подписи UI модуля ТМЦ.
abstract final class TmcUiLabels {
  /// Название модуля.
  static const moduleTitle = 'ТМЦ';

  /// Текущий раздел: реестр позиций.
  static const registry = 'Реестр';

  /// Подсказка поиска в реестре.
  static const searchHint = 'Поиск по названию…';

  /// Уведомления.
  static const notifications = 'Уведомления';

  /// Журнал операций.
  static const operationsJournal = 'Журнал операций';

  /// Отчёты.
  static const reports = 'Отчёты';

  /// Инвентаризация.
  static const inventory = 'Инвентаризация';

  /// Справочники.
  static const catalogs = 'Справочники';

  /// Остатки по складам.
  static const stockBalances = 'Остатки по складам';

  /// Пустые остатки.
  static const emptyStock = 'На выбранном складе остатков нет';

  /// Карточка позиции.
  static const itemCard = 'Карточка ТМЦ';

  /// Возврат из карточки к текущему разделу.
  static const backToRegistry = 'К реестру';

  /// Возврат назад.
  static const back = 'Назад';

  /// Новая позиция.
  static const newItem = 'Новая позиция';

  /// Редактирование позиции.
  static const editItem = 'Редактирование позиции';

  /// Операция.
  static const operation = 'Операция';

  /// Подпись типа учёта.
  static String accountingType(TmcAccountingType type) => type.displayName;

  /// Подпись статуса позиции.
  static String itemStatus(TmcItemStatus status) => status.displayName;

  /// Подпись статуса единицы.
  static String unitStatus(TmcUnitStatus status) => status.displayName;

  /// Подпись типа операции.
  static String operationType(TmcOperationType type) => type.displayName;

  /// Короткая подпись типа операции для фильтров журнала.
  static String operationTypeShort(TmcOperationType type) => switch (type) {
    TmcOperationType.receipt => 'Поступление',
    TmcOperationType.issue => 'Выдача',
    TmcOperationType.returnFromEmployee => 'Возврат',
    TmcOperationType.transferToObject => 'На объект',
    TmcOperationType.moveBetweenWarehouses => 'Между складами',
    TmcOperationType.sendToRepair => 'В ремонт',
    TmcOperationType.returnFromRepair => 'Из ремонта',
    TmcOperationType.writeOff => 'Списание',
    TmcOperationType.changeCondition => 'Состояние',
    TmcOperationType.correction => 'Корректировка',
    _ => type.displayName,
  };

  /// Фильтр журнала: все типы операций.
  static const operationsFilterAll = 'Все';

  /// Колонка журнала: дата.
  static const operationsColDate = 'Дата';

  /// Колонка журнала: тип операции.
  static const operationsColType = 'Тип';

  /// Колонка журнала: позиции.
  static const operationsColItems = 'Позиции';

  /// Колонка журнала: количество.
  static const operationsColQty = 'Кол-во';

  /// Подпись причины списания.
  static String writeOffReason(TmcWriteOffReason reason) => reason.displayName;

  /// KPI: позиций.
  static const kpiTotalItems = 'Позиций';

  /// KPI: единиц.
  static const kpiTotalUnits = 'Единиц';

  /// KPI: на складе.
  static const kpiInStock = 'На складе';

  /// KPI: на объекте.
  static const kpiOnObject = 'На объекте';

  /// KPI: выдано.
  static const kpiIssued = 'Выдано';

  /// KPI: в ремонте.
  static const kpiInRepair = 'В ремонте';

  /// KPI: требует ремонта.
  static const kpiNeedsRepair = 'Требует ремонта';

  /// KPI: утеряно.
  static const kpiLost = 'Утеряно';

  /// KPI: списано за месяц.
  static const kpiWrittenOff = 'Списано (мес.)';

  /// KPI: стоимость.
  static const kpiTotalCost = 'Стоимость';

  /// Отчёт: в ремонте.
  static const reportInRepair = 'В ремонте';

  /// Отчёт: списания.
  static const reportWriteOffs = 'Списания';

  /// Секция: основные.
  static const sectionMain = 'Основные';

  /// Секция: единицы.
  static const sectionUnits = 'Единицы / местоположение';

  /// Секция: поступление.
  static const sectionPurchase = 'Поступление';

  /// Секция: история.
  static const sectionHistory = 'История операций';

  /// Действие: выдать.
  static const actionIssue = 'Выдать';

  /// Действие: возврат.
  static const actionReturn = 'Возврат';

  /// Действие: переместить между складами.
  static const actionMove = 'Переместить';

  /// Действие: переместить на объект.
  static const actionMoveToObject = 'На объект';

  /// Действие: ремонт.
  static const actionRepair = 'В ремонт';

  /// Действие: возврат из ремонта.
  static const actionReturnFromRepair = 'Из ремонта';

  /// Действие: списать.
  static const actionWriteOff = 'Списать';

  /// Действие: состояние.
  static const actionChangeCondition = 'Состояние';

  /// Действие: поступление.
  static const actionReceipt = 'Поступление';

  /// Пустой реестр.
  static const emptyItems = 'Позиций пока нет — создайте первую';

  /// Пустой фильтр.
  static const emptyFiltered = 'Ничего не найдено по фильтрам';

  /// Подпись диапазона записей в реестре: «1–50 из 120».
  static String itemsPageRange(int from, int to, int total) =>
      '$from–$to из $total';

  /// Пустой журнал.
  static const emptyOperations = 'Операций пока нет';

  /// Максимум полей S/N в форме поступления (остальные единицы — без номера).
  static const maxSerialFields = 30;

  /// Разбор числа из поля ввода (`1,5` / `1.5`).
  static double? parseNumber(String text) =>
      double.tryParse(text.replaceAll(',', '.'));

  /// Разбор количества из поля ввода (`1,5` / `1.5`).
  static double? parseQuantity(String text) => parseNumber(text);

  /// Разбор цены из поля ввода (`1,5` / `1.5`).
  static double? parsePrice(String text) => parseNumber(text);

  /// Число экземпляров при поступлении (≥ 1). Не обрезает реальное количество.
  static int receiptUnitCount(String text) {
    final n = (parseQuantity(text) ?? 1).ceil();
    return n < 1 ? 1 : n;
  }

  /// Непустые серийные номера из формы.
  static List<String> nonEmptySerials(List<String>? values) {
    if (values == null) return const [];
    return [
      for (final s in values)
        if (s.trim().isNotEmpty) s.trim(),
    ];
  }

  /// Подпись склада в списках.
  static String warehouseLabel(TmcWarehouse warehouse) =>
      warehouse.isMain ? '${warehouse.name} (основной)' : warehouse.name;

  /// Подпись единицы: инв. №, опционально S/N, статус и место.
  static String unitLabel(
    TmcUnit unit, {
    bool includeStatus = true,
    bool includeLocation = true,
  }) {
    final parts = <String>['Инв. № ${unit.inventoryNumber}'];
    final sn = unit.serialNumber?.trim();
    if (sn != null && sn.isNotEmpty) {
      parts.add('S/N: $sn');
    }
    if (includeStatus) {
      parts.add(unit.status.displayName);
    }
    if (includeLocation) {
      final loc = unit.warehouseName ?? unit.objectName ?? unit.employeeName;
      if (loc != null && loc.isNotEmpty) {
        parts.add(loc);
      }
    }
    return parts.join(' · ');
  }
}
