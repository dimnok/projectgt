/// Утилиты для преобразования данных модуля выплат (ФОТ).
///
/// Содержит функции-конвертеры для преобразования кодов методов и типов
/// выплат в читаемые названия на русском языке.

/// Получает человекочитаемое название способа выплаты.
///
/// Примеры:
/// - `'cash'` → `'Наличные'`
/// - `'bank_transfer'` → `'Банковский перевод'`
/// - `'card'` → `'Карта'`
String getPayoutMethodName(String method) {
  switch (method) {
    case 'cash':
      return 'Наличные';
    case 'bank_transfer':
      return 'Банковский перевод';
    case 'card':
      return 'Карта';
    default:
      return method;
  }
}

/// Получает человекочитаемое название типа выплаты.
///
/// Примеры:
/// - `'salary'` → `'Зарплата'`
/// - `'advance'` → `'Аванс'`
String getPayoutTypeName(String type) {
  switch (type) {
    case 'salary':
      return 'Зарплата';
    case 'advance':
      return 'Аванс';
    default:
      return type;
  }
}
