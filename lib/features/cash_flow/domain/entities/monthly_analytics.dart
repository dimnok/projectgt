/// Модель аналитики за конкретный месяц.
class MonthlyAnalytics {
  /// Название месяца и года (например, "Янв 2025").
  final String monthYear;

  /// Общая сумма прихода за месяц.
  final double income;

  /// Общая сумма расхода за месяц.
  final double expense;

  /// Расшифровка приходов по статьям (Название статьи -> Сумма).
  final Map<String, double> categoryIncomes;

  /// Расшифровка расходов по статьям (Название статьи -> Сумма).
  final Map<String, double> categoryExpenses;

  /// Создаёт экземпляр [MonthlyAnalytics].
  const MonthlyAnalytics({
    required this.monthYear,
    required this.income,
    required this.expense,
    this.categoryIncomes = const {},
    this.categoryExpenses = const {},
  });

  /// Итоговая разница (приход - расход).
  double get total => income - expense;
}

