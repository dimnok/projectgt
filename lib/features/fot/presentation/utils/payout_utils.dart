/// Утилиты для работы с выплатами в модуле ФОТ.
///
/// Предоставляет единые методы для преобразования значений способов и типов выплат
/// в человекочитаемые названия для отображения в UI.
class PayoutUtils {
  /// Получает отображаемое название способа выплаты.
  ///
  /// Преобразует технические значения (`card`, `cash`, `bank_transfer`)
  /// в человекочитаемые названия для UI.
  ///
  /// Примеры:
  /// ```dart
  /// PayoutUtils.getMethodDisplayName('card');          // 'Карта'
  /// PayoutUtils.getMethodDisplayName('cash');          // 'Наличные'
  /// PayoutUtils.getMethodDisplayName('bank_transfer'); // 'Банковский перевод'
  /// ```
  ///
  /// [method] — технический код способа выплаты.
  /// Возвращает отображаемое название или 'Неизвестный способ' для неизвестных значений.
  static String getMethodDisplayName(String method) {
    switch (method) {
      case 'card':
        return 'Карта';
      case 'cash':
        return 'Наличные';
      case 'bank_transfer':
        return 'Банковский перевод';
      default:
        return 'Неизвестный способ';
    }
  }

  /// Получает отображаемое название типа выплаты.
  ///
  /// Преобразует технические значения (`salary`, `advance`)
  /// в человекочитаемые названия для UI.
  ///
  /// Примеры:
  /// ```dart
  /// PayoutUtils.getTypeDisplayName('salary');  // 'Зарплата'
  /// PayoutUtils.getTypeDisplayName('advance'); // 'Аванс'
  /// ```
  ///
  /// [type] — технический код типа выплаты.
  /// Возвращает отображаемое название или 'Неизвестный тип' для неизвестных значений.
  static String getTypeDisplayName(String type) {
    switch (type) {
      case 'salary':
        return 'Зарплата';
      case 'advance':
        return 'Аванс';
      default:
        return 'Неизвестный тип';
    }
  }
}
