import 'package:projectgt/features/works/domain/entities/work.dart';

/// Модель группы смен, сгруппированных по месяцу.
///
/// Используется для оптимизации отображения списка смен с группировкой по месяцам.
/// Смены загружаются лениво при раскрытии группы.
class MonthGroup {
  /// Дата начала месяца (первое число).
  ///
  /// Например: DateTime(2025, 10, 1) для октября 2025.
  final DateTime month;

  /// Количество смен в этом месяце.
  final int worksCount;

  /// Общая сумма всех смен в месяце.
  final double totalAmount;

  /// Флаг, показывающий развёрнута ли группа (отображаются ли смены).
  bool isExpanded;

  /// Список смен месяца.
  ///
  /// null - смены ещё не загружены (группа не раскрывалась).
  /// [] - смены загружены, но список пустой.
  /// [Work, ...] - загруженные смены.
  List<Work>? works;

  /// Создаёт группу смен по месяцу.
  ///
  /// [month] — дата начала месяца
  /// [worksCount] — количество смен в месяце
  /// [totalAmount] — общая сумма смен в месяце
  /// [isExpanded] — развёрнута ли группа (по умолчанию false)
  /// [works] — список смен (по умолчанию null, загружаются лениво)
  MonthGroup({
    required this.month,
    required this.worksCount,
    required this.totalAmount,
    this.isExpanded = false,
    this.works,
  });

  /// Создаёт копию группы с изменёнными полями.
  MonthGroup copyWith({
    DateTime? month,
    int? worksCount,
    double? totalAmount,
    bool? isExpanded,
    List<Work>? works,
  }) {
    return MonthGroup(
      month: month ?? this.month,
      worksCount: worksCount ?? this.worksCount,
      totalAmount: totalAmount ?? this.totalAmount,
      isExpanded: isExpanded ?? this.isExpanded,
      works: works ?? this.works,
    );
  }

  /// Возвращает название месяца в формате "Октябрь 2025".
  String get monthName {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  /// Возвращает true, если это текущий месяц.
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  @override
  String toString() {
    return 'MonthGroup(month: $month, worksCount: $worksCount, totalAmount: $totalAmount, isExpanded: $isExpanded, works: ${works?.length ?? 'null'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MonthGroup && other.month == month;
  }

  @override
  int get hashCode => month.hashCode;
}
