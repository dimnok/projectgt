import 'dart:math' show min;

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee_blocking_shift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Преобразование ошибок Supabase при удалении строки из `employees` в текст для пользователя.
///
/// При нарушении внешнего ключа (код `23503`) формируется список причин на русском.
abstract final class EmployeeDeleteErrorMapper {
  /// Первая строка сообщения при блокировке удаления по связям.
  static const String structuredBlockPrefix = 'Удаление сотрудника невозможно.';

  /// Текст причины для связи с таблицей `work_hours` (без префикса «•»).
  static const String workHoursForeignKeyReasonText =
      'в системе есть учёт часов этого сотрудника в сменах';

  /// Максимум строк в перечне смен в сообщении (остальные суммируются одной строкой).
  static const int maxShiftLinesInMessage = 80;

  /// `true`, если [message] сформировано [formatUserMessage] при обнаружении FK.
  static bool isStructuredBlock(String message) {
    return message.startsWith(structuredBlockPrefix);
  }

  /// `true`, если ошибка связана с таблицей `work_hours` (часы в сменах).
  static bool referencesWorkHoursTable(Object error) {
    return _rawMessage(error).toLowerCase().contains('work_hours');
  }

  /// Сообщение для UI с учётом перечня смен [workShifts], если удалось загрузить их из БД.
  static String formatDeleteBlockedForUi(
    Object error,
    List<EmployeeBlockingShift> workShifts,
  ) {
    final raw = _rawMessage(error);
    final reasons = _collectForeignKeyReasons(raw);
    if (reasons.isEmpty && !referencesWorkHoursTable(error)) {
      return formatUserMessage(error);
    }

    final otherReasons = reasons
        .where((r) => r != workHoursForeignKeyReasonText)
        .toList();
    final whFromReasons = reasons.contains(workHoursForeignKeyReasonText);
    final whFromMessage = referencesWorkHoursTable(error);
    final whBlocked = whFromReasons || whFromMessage;

    if (!whBlocked) {
      return formatUserMessage(error);
    }

    final buf = StringBuffer(structuredBlockPrefix);
    buf.writeln();

    if (otherReasons.isNotEmpty) {
      buf.writeln(otherReasons.length == 1 ? 'Причина:' : 'Причины:');
      for (final r in otherReasons) {
        buf.writeln('• $r');
      }
      if (whBlocked && workShifts.isNotEmpty) {
        buf.writeln();
      }
    }

    if (whBlocked && workShifts.isNotEmpty) {
      buf.writeln('Смены с учётом часов (дата и объект):');
      final cap = min(workShifts.length, maxShiftLinesInMessage);
      for (var i = 0; i < cap; i++) {
        final s = workShifts[i];
        buf.writeln('• ${formatRuDate(s.date)} — ${s.objectName}');
      }
      if (workShifts.length > maxShiftLinesInMessage) {
        buf.writeln(
          '… и ещё ${workShifts.length - maxShiftLinesInMessage} смен.',
        );
      }
      return buf.toString().trimRight();
    }

    if (otherReasons.isEmpty) {
      buf.writeln('Причина:');
      buf.writeln('• $workHoursForeignKeyReasonText');
    } else {
      buf.writeln('• $workHoursForeignKeyReasonText');
    }
    return buf.toString().trimRight();
  }

  /// Человекочитаемое сообщение для UI и [EmployeeNotifier.errorMessage].
  static String formatUserMessage(Object error) {
    final raw = _rawMessage(error);
    final reasons = _collectForeignKeyReasons(raw);
    if (reasons.isEmpty) {
      if (error is PostgrestException) {
        return error.message;
      }
      return raw;
    }
    if (reasons.length == 1) {
      return '$structuredBlockPrefix\n\nПричина:\n• ${reasons.first}';
    }
    final bullets = reasons.map((r) => '• $r').join('\n');
    return '$structuredBlockPrefix\n\nПричины:\n$bullets';
  }

  static String _rawMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }
    return error.toString();
  }

  /// Разбор текста ошибки Postgres/PostgREST: `... on table "work_hours"`.
  static List<String> _collectForeignKeyReasons(String message) {
    final out = <String>[];
    final seen = <String>{};
    void add(String line) {
      if (seen.add(line)) {
        out.add(line);
      }
    }

    final re = RegExp(
      r'foreign key constraint\s+"([^"]+)"\s+on table\s+"([^"]+)"',
      caseSensitive: false,
    );
    for (final m in re.allMatches(message)) {
      final table = (m.group(2) ?? '').toLowerCase();
      final line = _reasonForReferencedTable(table);
      if (line != null) {
        add(line);
      }
    }

    // Доп. эвристики, если формулировка сервера отличается от шаблона выше.
    final lower = message.toLowerCase();
    for (final entry in _substringTableHints.entries) {
      if (lower.contains(entry.key)) {
        final line = _reasonForReferencedTable(entry.value);
        if (line != null) {
          add(line);
        }
      }
    }

    return out;
  }

  static const Map<String, String> _substringTableHints = {
    'work_hours': 'work_hours',
    'employee_rates': 'employee_rates',
    'employee_attendance': 'employee_attendance',
    'profiles': 'profiles',
    'payroll_payout': 'payroll_payout',
    'payroll_bonus': 'payroll_bonus',
    'payroll_penalty': 'payroll_penalty',
    'payroll_calculation': 'payroll_calculation',
    'work_plans': 'work_plans',
  };

  /// Краткое описание причины по имени дочерней таблицы FK.
  static String? _reasonForReferencedTable(String table) {
    switch (table) {
      case 'work_hours':
        return workHoursForeignKeyReasonText;
      case 'employee_rates':
        return 'есть история ставок по сотруднику';
      case 'employee_attendance':
        return 'есть записи посещаемости / табеля';
      case 'profiles':
        return 'учётная запись пользователя привязана к этому сотруднику';
      case 'payroll_payout':
        return 'есть выплаты в расчётах ФОТ';
      case 'payroll_bonus':
        return 'есть премии в расчётах ФОТ';
      case 'payroll_penalty':
        return 'есть штрафы в расчётах ФОТ';
      case 'payroll_calculation':
        return 'есть расчёты зарплаты, связанные с сотрудником';
      case 'work_plans':
        return 'сотрудник указан в планах работ (ответственный)';
      default:
        if (table.isEmpty) {
          return null;
        }
        return 'есть связанные данные в таблице «$table»';
    }
  }
}
