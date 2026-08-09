import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/money_to_words_ru.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/settlements/presentation/services/settlement_invoice_pdf_data.dart';

/// Генератор PDF «Счёт на оплату» для модуля взаиморасчётов.
class SettlementInvoicePdfService {
  const SettlementInvoicePdfService._();

  /// Формирует PDF и возвращает байты документа.
  static Future<Uint8List> build({
    required PdfPageFormat format,
    required SettlementInvoicePdfData data,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    final op = data.operation;
    final company = data.company;
    final buyer = data.contractor;

    final invoiceDate = formatRuDate(op.invoiceDate);
    final hasVat = op.vatRate != null && op.vatRate! > 0;
    final vatLabel = hasVat
        ? 'НДС ${formatQuantity(op.vatRate!)}%'
        : 'Без НДС';
    final lineAmount = op.invoiceTotal;
    final totalToPay = op.totalToPay;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          _bankDetailsTable(data),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'Счёт на оплату № ${op.invoiceNumber} от $invoiceDate',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 14),
          _partyRow('Поставщик', _sellerLine(company)),
          pw.SizedBox(height: 6),
          _partyRow('Покупатель', _buyerLine(buyer)),
          pw.SizedBox(height: 6),
          _partyRow('Основание', data.basisText),
          pw.SizedBox(height: 12),
          _itemsTable(
            lineName: data.lineItemName,
            amount: lineAmount,
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _totalRow('Итого:', _cleanCurrency(formatCurrency(lineAmount))),
                if (hasVat)
                  _totalRow(
                    vatLabel,
                    _cleanCurrency(formatCurrency(op.vatAmount)),
                  ),
                if (op.advanceRetention > 0)
                  _totalRow(
                    'Удержание аванса:',
                    '- ${_cleanCurrency(formatCurrency(op.advanceRetention))}',
                  ),
                if (op.warrantyRetention > 0)
                  _totalRow(
                    'Гарантийное удержание:',
                    '- ${_cleanCurrency(formatCurrency(op.warrantyRetention))}',
                  ),
                pw.SizedBox(height: 4),
                _totalRow(
                  'Всего к оплате:',
                  _cleanCurrency(formatCurrency(totalToPay)),
                  bold: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _footerSummaryBlock(
            totalToPay: totalToPay,
            hasVat: hasVat,
            vatRate: op.vatRate,
            vatAmount: op.vatAmount,
          ),
          pw.SizedBox(height: 28),
          _signaturesBlock(company),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _bankDetailsTable(SettlementInvoicePdfData data) {
    final company = data.company;
    final bank = data.bankAccount;
    final border = pw.TableBorder.all(width: 0.5, color: PdfColors.black);
    const cellStyle = pw.TextStyle(fontSize: 8);
    final labelStyle =
        pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);

    pw.Widget cell(String text, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            text,
            style: bold ? labelStyle : cellStyle,
          ),
        );

    return pw.Container(
      decoration: pw.BoxDecoration(border: border),
      child: pw.Column(
        children: [
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(width: 0.5, color: PdfColors.black),
              verticalInside:
                  pw.BorderSide(width: 0.5, color: PdfColors.black),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.1),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(2.4),
            },
            children: [
              pw.TableRow(children: [
                cell('Банк получателя', bold: true),
                cell(bank.bankName),
                cell('БИК', bold: true),
                cell(bank.bik ?? '—'),
              ]),
              pw.TableRow(children: [
                cell('Корр. счёт', bold: true),
                cell(bank.corrAccount ?? '—'),
                cell('Сч. №', bold: true),
                cell(bank.accountNumber),
              ]),
              pw.TableRow(children: [
                cell('ИНН', bold: true),
                cell(company.inn ?? '—'),
                cell('КПП', bold: true),
                cell(company.kpp ?? '—'),
              ]),
              pw.TableRow(children: [
                cell('Получатель', bold: true),
                cell(company.nameFull, bold: true),
                pw.Container(),
                pw.Container(),
              ]),
            ],
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 0.5, color: PdfColors.black),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.paymentPurposeText,
                  style: cellStyle,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Назначение платежа',
                  style: const pw.TextStyle(fontSize: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _partyRow(String label, String value) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 72,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      );

  static String _sellerLine(CompanyProfile company) =>
      _joinParts([
        company.nameFull,
        if (company.legalAddress?.trim().isNotEmpty == true)
          company.legalAddress!.trim(),
        if (company.inn?.trim().isNotEmpty == true) 'ИНН ${company.inn}',
        if (company.kpp?.trim().isNotEmpty == true) 'КПП ${company.kpp}',
        if (company.phone?.trim().isNotEmpty == true)
          'тел. ${formatPhoneRu(company.phone)}',
        if (company.email?.trim().isNotEmpty == true)
          'e-mail: ${company.email!.trim()}',
      ]);

  static String _buyerLine(Contractor buyer) => _joinParts([
        buyer.fullName,
        if (buyer.legalAddress.trim().isNotEmpty) buyer.legalAddress.trim(),
        if (buyer.inn.trim().isNotEmpty) 'ИНН ${buyer.inn}',
        if (buyer.kpp?.trim().isNotEmpty == true) 'КПП ${buyer.kpp}',
        if (buyer.phone.trim().isNotEmpty)
          'тел. ${formatPhoneRu(buyer.phone)}',
        if (buyer.email.trim().isNotEmpty) 'e-mail: ${buyer.email.trim()}',
      ]);

  static String _joinParts(List<String> parts) =>
      parts.where((p) => p.trim().isNotEmpty).join(', ');

  static pw.Widget _itemsTable({
    required String lineName,
    required double amount,
  }) {
    final border = pw.TableBorder.all(width: 0.5, color: PdfColors.black);
    final headerStyle =
        pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    const bodyStyle = pw.TextStyle(fontSize: 8);

    pw.Widget headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(text, style: headerStyle, textAlign: align),
        );

    pw.Widget bodyCell(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(text, style: bodyStyle, textAlign: align),
        );

    return pw.Table(
      border: border,
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(4.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            headerCell('№', align: pw.TextAlign.center),
            headerCell('Наименование'),
            headerCell('Ед.', align: pw.TextAlign.center),
            headerCell('Кол-во', align: pw.TextAlign.center),
            headerCell('Цена', align: pw.TextAlign.right),
            headerCell('Сумма', align: pw.TextAlign.right),
          ],
        ),
        pw.TableRow(
          children: [
            bodyCell('1', align: pw.TextAlign.center),
            bodyCell(lineName),
            bodyCell('усл.', align: pw.TextAlign.center),
            bodyCell('1', align: pw.TextAlign.center),
            bodyCell(
              _cleanCurrency(formatCurrency(amount)),
              align: pw.TextAlign.right,
            ),
            bodyCell(
              _cleanCurrency(formatCurrency(amount)),
              align: pw.TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _footerSummaryBlock({
    required double totalToPay,
    required bool hasVat,
    double? vatRate,
    required double vatAmount,
  }) {
    final summaryAmount = moneyNumericWithUnitsRu(totalToPay);
    var wordsLine = moneyToWordsRu(totalToPay);
    if (hasVat && vatRate != null && vatRate > 0) {
      wordsLine +=
          ', в том числе НДС(${formatQuantity(vatRate)}%) ${moneyToWordsRu(vatAmount, capitalize: false)}';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Всего наименований 1, на сумму $summaryAmount',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          '$wordsLine.',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 1.5,
          color: PdfColors.black,
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) =>
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      );

  static const double _signatureFieldWidth = 140;

  static pw.Widget _signaturesBlock(CompanyProfile company) {
    final director = company.directorName?.trim();
    final accountant = company.chiefAccountantName?.trim();

    pw.Widget signatureLine(String role, String? name) => pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.SizedBox(
              width: 72,
              child: pw.Text(role, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Container(
              width: _signatureFieldWidth,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.black),
                ),
              ),
              child: pw.SizedBox(height: 12),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              name?.isNotEmpty == true ? name! : ' ',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        );

    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          signatureLine('Руководитель', director),
          pw.SizedBox(height: 20),
          signatureLine('Бухгалтер', accountant),
        ],
      ),
    );
  }

  static String _cleanCurrency(String value) =>
      value.replaceAll('₽', '').replaceAll('\u00a0', ' ').trim();
}
