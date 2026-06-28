import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_today_open_shift.dart';

void main() {
  group('parseTodayOpenShiftWorksResponse', () {
    test('собирает employee_id и подсказки по объектам', () {
      final index = parseTodayOpenShiftWorksResponse([
        {
          'object_id': 'obj-a',
          'objects': {'name': 'Объект А'},
          'work_hours': [
            {'employee_id': 'e1'},
            {'employee_id': 'e2'},
          ],
        },
        {
          'object_id': 'obj-b',
          'objects': {'name': 'Объект Б'},
          'work_hours': [
            {'employee_id': 'e1'},
          ],
        },
      ]);

      expect(index.employeeIds, {'e1', 'e2'});
      expect(index.objectIdsFor('e1'), {'obj-a', 'obj-b'});
      expect(index.objectIdsFor('e2'), {'obj-a'});
      expect(index.hintFor('e1'), 'В смене сегодня: Объект А, Объект Б');
      expect(index.hintFor('e2'), 'В смене сегодня: Объект А');
    });

    test('пустой ответ', () {
      expect(
        parseTodayOpenShiftWorksResponse(const []).employeeIds,
        isEmpty,
      );
    });
  });

  group('timesheetPeriodContainsToday', () {
    test('текущий месяц содержит сегодня', () {
      final now = DateTime(2026, 6, 28);
      expect(
        timesheetPeriodContainsToday(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
          now: now,
        ),
        isTrue,
      );
    });

    test('прошлый месяц не содержит сегодня', () {
      final now = DateTime(2026, 6, 28);
      expect(
        timesheetPeriodContainsToday(
          start: DateTime(2026, 5, 1),
          end: DateTime(2026, 5, 31),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
