import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:logger/logger.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';
import '../../domain/entities/timesheet_entry.dart';

/// Сервис для экспорта табеля рабочего времени в PDF.
///
/// Генерирует PDF-документ с таблицей часов сотрудников,
/// сгруппированных по датам и объектам.
/// Отображает всех активных сотрудников (статус != 'fired'),
/// а также уволенных сотрудников, у которых есть часы в выбранном периоде.
class TimesheetPdfService {
  /// Репозиторий сотрудников для получения данных
  final EmployeeRepository employeeRepository;

  /// Логгер для отслеживания операций экспорта.
  static final Logger _logger = Logger();

  /// Создает экземпляр [TimesheetPdfService]
  TimesheetPdfService(this.employeeRepository);

  /// Форматтер для отображения даты.
  static final DateFormat _dateFormatter = DateFormat('dd.MM.yyyy', 'ru_RU');

  /// Форматтер для отображения времени.
  static final DateFormat _timeFormatter =
      DateFormat('HH:mm dd.MM.yyyy', 'ru_RU');

  /// Экспортирует табель в PDF.
  ///
  /// [entries] — список записей табеля
  /// [fileName] — имя выходного файла
  /// [startDate] — дата начала периода
  /// [endDate] — дата окончания периода
  ///
  /// Возвращает путь к созданному файлу или null при ошибке.
  Future<String?> exportToPdf({
    required List<TimesheetEntry> entries,
    required String fileName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i('Начинаем экспорт ${entries.length} записей табеля в PDF');

      // Загружаем шрифт для поддержки кириллицы
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Создаем PDF документ
      final pdf = pw.Document();

      // Получаем список всех сотрудников
      final allEmployees = await employeeRepository.getEmployees();

      // Находим ID сотрудников, у которых есть часы в записях
      final employeeIdsWithHours =
          entries.map((entry) => entry.employeeId).toSet();

      // Фильтруем: активные сотрудники + уволенные с часами
      final filteredEmployees = allEmployees.where((e) {
        if (e.status != EmployeeStatus.fired) {
          return true; // Все активные
        }
        return employeeIdsWithHours.contains(e.id); // Уволенные с часами
      }).toList();

      // Сортируем по ФИО
      filteredEmployees.sort((a, b) {
        final nameA = '${a.lastName} ${a.firstName} ${a.middleName ?? ''}';
        final nameB = '${b.lastName} ${b.firstName} ${b.middleName ?? ''}';
        return nameA.compareTo(nameB);
      });

      // Группируем записи по сотрудникам и датам
      final employeeMap = <String, Map<DateTime, num>>{};
      final employeeNames = <String, String>{};

      // Инициализируем всех отфильтрованных сотрудников
      for (final employee in filteredEmployees) {
        final fullName = employee.middleName != null &&
                employee.middleName!.isNotEmpty
            ? '${employee.lastName} ${employee.firstName} ${employee.middleName}'
            : '${employee.lastName} ${employee.firstName}';

        employeeMap[employee.id] = {};
        employeeNames[employee.id] = fullName;
      }

      // Заполняем часы из записей
      for (final entry in entries) {
        final date =
            DateTime(entry.date.year, entry.date.month, entry.date.day);

        if (employeeMap.containsKey(entry.employeeId)) {
          employeeMap[entry.employeeId]![date] =
              (employeeMap[entry.employeeId]![date] ?? 0) + entry.hours;
        }
      }

      // Создаем список дат в диапазоне
      final daysInRange = <DateTime>[];
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        daysInRange.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Подсчитываем общую сумму часов
      final totalHours =
          entries.fold<num>(0, (sum, entry) => sum + entry.hours);

      // Заголовок периода
      final periodText =
          '${_dateFormatter.format(startDate)} - ${_dateFormatter.format(endDate)}';

      // Добавляем страницу
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(15),
          build: (context) {
            return [
              // Заголовок
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ТАБЕЛЬ РАБОЧЕГО ВРЕМЕНИ',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Период: $periodText',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Дата формирования: ${_timeFormatter.format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Таблица в календарном виде (как в приложении)
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(140), // ФИО (расширенная)
                  // Остальные колонки для дат - динамические
                  ...Map.fromEntries(
                    List.generate(daysInRange.length, (i) {
                      return MapEntry(
                        i + 1,
                        const pw.FixedColumnWidth(28),
                      );
                    }),
                  ),
                  daysInRange.length + 1:
                      const pw.FixedColumnWidth(35), // Итого
                },
                children: [
                  // Шапка таблицы - первая строка (день месяца)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildHeaderCell('ФИО', font: fontBold, fontSize: 7),
                      ...daysInRange.map((date) => _buildHeaderCell(
                            '${date.day}',
                            font: fontBold,
                            fontSize: 7,
                          )),
                      _buildHeaderCell('Итого', font: fontBold, fontSize: 7),
                    ],
                  ),

                  // Шапка таблицы - вторая строка (день недели)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildHeaderCell('', font: font, fontSize: 6),
                      ...daysInRange.map((date) => _buildHeaderCell(
                            _getDayAbbreviation(date.weekday),
                            font: font,
                            fontSize: 6,
                          )),
                      _buildHeaderCell('', font: font, fontSize: 6),
                    ],
                  ),

                  // Строки сотрудников
                  ...employeeMap.entries.map((employeeEntry) {
                    final employeeId = employeeEntry.key;
                    final dateHours = employeeEntry.value;
                    final employeeName =
                        employeeNames[employeeId] ?? 'Неизвестный';

                    // Подсчитываем итого по сотруднику
                    final employeeTotal =
                        dateHours.values.fold<num>(0, (sum, h) => sum + h);

                    return pw.TableRow(
                      children: [
                        _buildDataCell(
                          employeeName,
                          font: font,
                          fontSize: 7,
                          padding: 2,
                        ),
                        ...daysInRange.map((date) {
                          final hours = dateHours[date];
                          final isWeekend =
                              date.weekday == 6 || date.weekday == 7;
                          return _buildDataCell(
                            hours != null && hours > 0 ? hours.toString() : '',
                            font: font,
                            fontSize: 7,
                            padding: 2,
                            backgroundColor:
                                isWeekend ? PdfColors.grey100 : null,
                            alignment: pw.Alignment.center,
                          );
                        }),
                        _buildDataCell(
                          employeeTotal > 0 ? employeeTotal.toString() : '',
                          font: fontBold,
                          fontSize: 7,
                          padding: 2,
                          alignment: pw.Alignment.center,
                        ),
                      ],
                    );
                  }),

                  // Итоговая строка
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildDataCell('ИТОГО:',
                          font: fontBold, fontSize: 7, padding: 2),
                      ...daysInRange.map((date) {
                        // Суммируем часы всех сотрудников за этот день
                        num dayTotal = 0;
                        for (final employeeEntry in employeeMap.values) {
                          dayTotal += employeeEntry[date] ?? 0;
                        }
                        return _buildDataCell(
                          dayTotal > 0 ? dayTotal.toString() : '',
                          font: fontBold,
                          fontSize: 7,
                          padding: 2,
                          alignment: pw.Alignment.center,
                        );
                      }),
                      _buildDataCell(
                        totalHours.toString(),
                        font: fontBold,
                        fontSize: 7,
                        padding: 2,
                        alignment: pw.Alignment.center,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Подпись
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Сотрудников: ${employeeMap.length}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                  pw.Text(
                    'Всего часов: $totalHours',
                    style: pw.TextStyle(font: fontBold, fontSize: 8),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Сохраняем файл
      final bytes = await pdf.save();

      if (kIsWeb) {
        // Для Web используем FileSaver
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.pdf,
        );
        _logger.i('PDF файл сохранен через браузер: $fileName');
        return fileName;
      } else {
        // Для мобильных и десктоп платформ сохраняем локально
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        _logger.i('PDF файл успешно сохранен: ${file.path}');
        return file.path;
      }
    } catch (e, stackTrace) {
      _logger.e('Ошибка при экспорте табеля в PDF',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Возвращает сокращенное название дня недели.
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'пн';
      case 2:
        return 'вт';
      case 3:
        return 'ср';
      case 4:
        return 'чт';
      case 5:
        return 'пт';
      case 6:
        return 'сб';
      case 7:
        return 'вс';
      default:
        return '';
    }
  }

  /// Создает ячейку заголовка таблицы.
  pw.Widget _buildHeaderCell(
    String text, {
    required pw.Font font,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Создает ячейку данных таблицы.
  pw.Widget _buildDataCell(
    String text, {
    required pw.Font font,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    double fontSize = 9,
    double padding = 5,
    PdfColor? backgroundColor,
  }) {
    return pw.Container(
      color: backgroundColor,
      padding: pw.EdgeInsets.all(padding),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
          ),
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }
}
