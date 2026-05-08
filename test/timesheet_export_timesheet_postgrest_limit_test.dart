import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Регрессия по табелю Excel (Edge Function `export-timesheet`):
/// PostgREST режет ответ по max-rows (~1000) без постраничной загрузки.
void main() {
  test(
    'export-timesheet: loadTimesheetEntries использует fetchAllPages + .range()',
    () {
      final file = File('supabase/functions/export-timesheet/index.ts');
      expect(file.existsSync(), isTrue, reason: 'Нужен файл Edge Function');
      final src = file.readAsStringSync();

      expect(
        src.contains('async function loadTimesheetEntries'),
        isTrue,
        reason: 'Ожидается функция loadTimesheetEntries',
      );

      expect(
        src.contains('fetchAllPages'),
        isTrue,
        reason: 'Нужна постраничная загрузка fetchAllPages',
      );

      expect(
        src.contains('POSTGREST_PAGE_SIZE'),
        isTrue,
        reason: 'Ожидается константа размера страницы PostgREST',
      );

      final loadBlock = RegExp(
        r'async function loadTimesheetEntries[\s\S]*?return results;',
      ).firstMatch(src)?.group(0);
      expect(loadBlock, isNotNull);
      expect(
        loadBlock!.split('.range(').length - 1,
        greaterThanOrEqualTo(2),
        reason:
            'Ожидаются минимум два запроса с .range (work_hours + employee_attendance)',
      );
    },
  );
}
