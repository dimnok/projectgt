import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/timesheet/presentation/widgets/timesheet_filter_widget.dart';

void main() {
  group('timesheetListFilterTriggerLabel', () {
    test('по умолчанию — Состав', () {
      expect(
        timesheetListFilterTriggerLabel(
          hoursScope: TimesheetEmployeeListScope.all,
          shiftScope: TimesheetOpenShiftFilterScope.all,
          periodContainsToday: true,
        ),
        'Состав',
      );
    });

    test('комбинирует часы и смену', () {
      expect(
        timesheetListFilterTriggerLabel(
          hoursScope: TimesheetEmployeeListScope.withHours,
          shiftScope: TimesheetOpenShiftFilterScope.inOpenShift,
          periodContainsToday: true,
        ),
        'С часами · В смене',
      );
    });

    test('смена скрыта вне текущего месяца', () {
      expect(
        timesheetListFilterTriggerLabel(
          hoursScope: TimesheetEmployeeListScope.all,
          shiftScope: TimesheetOpenShiftFilterScope.inOpenShift,
          periodContainsToday: false,
        ),
        'Состав',
      );
    });
  });

  group('hasActiveTimesheetListFilters', () {
    test('активен при любом не-all фильтре', () {
      expect(
        hasActiveTimesheetListFilters(
          hoursScope: TimesheetEmployeeListScope.withoutHours,
          shiftScope: TimesheetOpenShiftFilterScope.all,
          periodContainsToday: true,
        ),
        isTrue,
      );
    });
  });
}
