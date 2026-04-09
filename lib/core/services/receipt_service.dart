import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/monthly_due_model.dart';
import '../../utils/formatters.dart';

class ReceiptService {
  static Future<void> generateAndShareReceipt({
    required MonthlyDue due,
    String? studentName,
    String? admissionNumber,
    String? receiptNo,
  }) async {
    final pdf = pw.Document();

    final name = studentName ?? due.studentName ?? 'Student';
    final admission = admissionNumber ?? due.admissionNumber ?? '';
    final receipt = receiptNo ?? 'RCPT-${DateTime.now().millisecondsSinceEpoch}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1A1A2E'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BusWay Pro',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Payment Receipt',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Receipt Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Receipt No: $receipt',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${Formatters.date(due.paidAt ?? DateTime.now())}'),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // Student Info
            pw.Text('Student Details',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _infoRow('Name', name),
            _infoRow('Admission No', admission),
            _infoRow('Billing Period', due.fullMonthLabel),
            pw.SizedBox(height: 20),

            // Payment Breakdown
            pw.Text('Payment Breakdown',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(children: [
                _tableRow('Base Fee', Formatters.currencyFull(due.amount),
                    isHeader: false),
                if (due.lateFee > 0)
                  _tableRow('Late Fee', Formatters.currencyFull(due.lateFee)),
                if (due.discount != null && due.discount! > 0)
                  _tableRow('Discount', '- ${Formatters.currencyFull(due.discount!)}'),
                pw.Container(
                  color: PdfColor.fromHex('#F0F9FF'),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Paid',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(Formatters.currencyFull(due.totalDue),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ]),
            ),
            pw.SizedBox(height: 20),

            if (due.transactionId != null) ...[
              _infoRow('Transaction ID', due.transactionId!),
              pw.SizedBox(height: 8),
            ],
            _infoRow('Payment Status', 'PAID'),
            pw.Spacer(),

            // Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'This is a computer-generated receipt. No signature required.',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_$receipt.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Payment Receipt - $receipt');
    } catch (_) {
      // Fallback: print
      await Printing.sharePdf(bytes: bytes, filename: 'receipt_$receipt.pdf');
    }
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
              width: 140,
              child: pw.Text(label,
                  style: const pw.TextStyle(color: PdfColors.grey600))),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _tableRow(String label, String value,
      {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value,
              style: isHeader
                  ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  : null),
        ],
      ),
    );
  }
}
