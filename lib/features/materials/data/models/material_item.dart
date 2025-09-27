/// Модель материала из таблицы `public.materials` в Supabase.
///
/// Поля соответствуют колонкам БД. Все числовые значения
/// представлены как `double?` для удобства форматирования в UI.
class MaterialItem {
  /// Идентификатор записи (UUID)
  final String id;

  /// Наименование материала
  final String name;

  /// Единица измерения, например: шт, м, т, м³
  final String? unit;

  /// Количество
  final double? quantity;

  /// Цена за единицу
  final double? price;

  /// Итоговая стоимость (computed в БД)
  final double? total;

  /// Номер расходной накладной
  final String? receiptNumber;

  /// Дата расходной накладной (ISO-строка в БД)
  final DateTime? receiptDate;

  /// Использовано
  final double? used;

  /// Остаток
  final double? remaining;

  /// URL файла (накладная/скан)
  final String? fileUrl;

  /// Создаёт экземпляр материала из БД `public.materials`.
  const MaterialItem({
    required this.id,
    required this.name,
    this.unit,
    this.quantity,
    this.price,
    this.total,
    this.receiptNumber,
    this.receiptDate,
    this.used,
    this.remaining,
    this.fileUrl,
  });

  /// Создание модели из JSON-объекта Supabase.
  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    double? parseNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return MaterialItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      unit: map['unit']?.toString(),
      quantity: parseNum(map['quantity']),
      price: parseNum(map['price']),
      total: parseNum(map['total']),
      receiptNumber: map['receipt_number']?.toString(),
      receiptDate: parseDate(map['receipt_date']),
      used: parseNum(map['used']),
      remaining: parseNum(map['remaining']),
      fileUrl: map['file_url']?.toString(),
    );
  }
}
