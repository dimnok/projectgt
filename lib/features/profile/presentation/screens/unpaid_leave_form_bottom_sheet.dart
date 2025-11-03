import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

/// Форма заявления об отпуске без содержания
///
/// Отображает форму для заполнения данных об отпуске без содержания (за свой счёт)
/// с предпросмотром и функцией отправки на согласование руководителю.
class UnpaidLeaveFormBottomSheet extends StatefulWidget {
  /// Профиль текущего пользователя
  final dynamic profile;

  /// Должность сотрудника (берётся из Employee)
  final String? position;

  /// Создаёт форму заявления об отпуске без содержания.
  const UnpaidLeaveFormBottomSheet({
    super.key,
    required this.profile,
    this.position,
  });

  @override
  State<UnpaidLeaveFormBottomSheet> createState() =>
      _UnpaidLeaveFormBottomSheetState();
}

class _UnpaidLeaveFormBottomSheetState
    extends State<UnpaidLeaveFormBottomSheet> {
  late DateTime _startDate;
  late int _daysCount;
  final _formKey = GlobalKey<FormState>();
  bool _isPreview = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(days: 1));
    _daysCount = 14;
  }

  DateTime get _endDate => _startDate.add(Duration(days: _daysCount - 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _isPreview ? 0.75 : 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isPreview
                        ? 'Предпросмотр заявления'
                        : 'Заявление об отпуске без содержания',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрыть',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            height: 1,
          ),

          // Содержимое
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: _isPreview ? _buildPreview(theme) : _buildForm(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Данные сотрудника
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сотрудник',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.profile?.fullName ?? 'Не указано',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${widget.profile?.email ?? 'Не указан'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Выбор даты начала
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _selectStartDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Начало отпуска: ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatRuDate(_startDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Количество дней
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Количество дней отпуска: ',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_daysCount > 1) {
                            setState(() {
                              _daysCount--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove),
                        color: _daysCount > 1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _daysCount.toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          if (_daysCount < 60) {
                            setState(() {
                              _daysCount++;
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        color: _daysCount < 60
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Дата окончания (расчётная)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Окончание: ${formatRuDate(_endDate)}\nВыход на работу: ${formatRuDate(_endDate.add(const Duration(days: 1)))}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Кнопка предпросмотра
          ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  _isPreview = true;
                });
              }
            },
            icon: const Icon(Icons.preview),
            label: const Text('Предпросмотр'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Документ заявления
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Адресат (справа сверху)
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Генеральному директору',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                      Text(
                        'общества с ограниченной ответственностью',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                      Text(
                        '"Грандтелеком"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      Text(
                        'Тельнову Д.А.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.position != null &&
                          widget.position!.isNotEmpty)
                        Text(
                          'от ${widget.position} ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black,
                            height: 1.4,
                          ),
                        )
                      else
                        Text(
                          'от ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Заголовок "Заявление" по центру
              Center(
                child: Text(
                  'З А Я В Л Е Н И Е',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Основной текст
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    height: 1.8,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Прошу предоставить мне отпуск без содержания (за свой счёт) с ',
                    ),
                    TextSpan(
                      text: formatRuDate(_startDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: ' на ',
                    ),
                    TextSpan(
                      text: '$_daysCount календарных дней',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Дата и подпись в одной строке
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Дата: ${formatRuDate(DateTime.now())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Подпись: _______________ ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Кнопки действий
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isPreview = false;
            });
          },
          icon: const Icon(Icons.edit),
          label: const Text('Редактировать'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _downloadPDF,
          icon: _isDownloading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.download),
          label: Text(_isDownloading ? 'Скачивание...' : 'Скачать PDF'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.blue,
          ),
        ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _submitApplication,
          icon: _isDownloading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
              _isDownloading ? 'Отправка...' : 'Отправить на согласование'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.green,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submitApplication() async {
    setState(() {
      // Используем _isDownloading для индикатора загрузки
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Сохраняем заявление в БД
      final dbResponse = await supabase.from('applications').insert({
        'employee_id': user.id,
        'type': 'unpaid_leave',
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'days_count': _daysCount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (dbResponse.isEmpty) {
        throw Exception('Не удалось сохранить заявление');
      }

      // Генерируем PDF для сохранения (если нужно)
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.SizedBox(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Генеральному директору',
                            style: pw.TextStyle(font: font, fontSize: 12)),
                        pw.Text('общества с ограниченной ответственностью',
                            style: pw.TextStyle(font: font, fontSize: 12)),
                        pw.Text('"Грандтелеком"',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text('Тельнову Д.А.',
                            style: pw.TextStyle(font: font, fontSize: 12)),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          widget.position != null && widget.position!.isNotEmpty
                              ? 'от ${widget.position} ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}'
                              : 'от ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text('З А Я В Л Е Н И Е',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 48),
                pw.Text(
                    'Прошу предоставить мне отпуск без содержания (за свой счёт) с ${formatRuDate(_startDate)} на $_daysCount календарных дней.',
                    style: pw.TextStyle(
                        font: font, fontSize: 14, lineSpacing: 1.8)),
                pw.SizedBox(height: 64),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Дата: ${formatRuDate(DateTime.now())}',
                        style: pw.TextStyle(font: font, fontSize: 12)),
                    pw.Text(
                        'Подпись: _______________ ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                        style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Генерируем PDF для сохранения (если нужно)
      await pdf.save();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Заявление успешно отправлено на согласование',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Загружаем шрифты с поддержкой кириллицы
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Создаём PDF документ
      final pdf = pw.Document();

      // Добавляем страницу с содержимым заявления
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Адресат (справа сверху)
                pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.SizedBox(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Генеральному директору',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.Text(
                          'общества с ограниченной ответственностью',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.Text(
                          '"Грандтелеком"',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Тельнову Д.А.',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          widget.position != null && widget.position!.isNotEmpty
                              ? 'от ${widget.position} ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}'
                              : 'от ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 40),

                // Заголовок
                pw.Center(
                  child: pw.Text(
                    'З А Я В Л Е Н И Е',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 48),

                // Основной текст
                pw.Text(
                  'Прошу предоставить мне отпуск без содержания (за свой счёт) с ${formatRuDate(_startDate)} на $_daysCount календарных дней.',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    lineSpacing: 1.8,
                  ),
                ),

                pw.SizedBox(height: 64),

                // Подпись и дата в одной строке
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Дата: ${formatRuDate(DateTime.now())}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.Text(
                      'Подпись: _______________ ${widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО'}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Генерируем PDF в байты
      final Uint8List pdfBytes = await pdf.save();

      // Сохраняем файл в директорию Downloads
      final String fullName =
          widget.profile?.shortName ?? widget.profile?.fullName ?? 'ФИО';
      final String dateStr =
          formatRuDate(DateTime.now()); // Формат: ДД.МММ.ГГГГ
      final String fileName = '${fullName}_Отпуск_без_содержания_$dateStr.pdf';

      if (kIsWeb) {
        // Для web используем AnchorElement с data URL
        final base64 = base64Encode(pdfBytes);
        final dataUrl = 'data:application/pdf;base64,$base64';

        // Используем код только для веб-платформы
        _downloadWebPDF(dataUrl, fileName);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Для мобильных устройств используем file_picker для выбора директории
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Отмена сохранения файла'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final File file = File('$selectedDirectory/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF сохранён: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Для web и других платформ просто показываем сообщение
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF готов к скачиванию (зависит от браузера)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка при сохранении PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _downloadWebPDF(String dataUrl, String fileName) {
    if (kIsWeb) {
      try {
        final anchor = html.AnchorElement(href: dataUrl)
          ..style.display = 'none'
          ..download = fileName;
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
      } catch (e) {
        debugPrint('❌ Ошибка при скачивании PDF: $e');
      }
    }
  }
}
