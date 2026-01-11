import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/core/common/models/base_month_group.dart';

/// Модель группы смен, сгруппированных по месяцу.
///
/// Используется для оптимизации отображения списка смен с группировкой по месяцам.
/// Смены загружаются лениво при раскрытии группы.
class MonthGroup extends BaseMonthGroup<Work> {
  /// Количество смен в этом месяце.
  int get worksCount => count;

  /// Общая сумма всех смен в месяце.
  double get totalAmount => total;

  /// Список смен месяца.
  List<Work>? get works => items;
  set works(List<Work>? value) => items = value;

  /// Создаёт группу смен по месяцу.
  MonthGroup({
    required super.month,
    required int worksCount,
    required double totalAmount,
    super.isExpanded,
    List<Work>? works,
  }) : super(count: worksCount, total: totalAmount, items: works);

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
