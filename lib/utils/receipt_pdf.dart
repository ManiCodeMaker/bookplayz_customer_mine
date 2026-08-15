// lib/utils/receipt_pdf.dart
//
// Generates a "BookPlayz Receipt" PDF for a booking and opens the native
// share sheet so the customer can save it to Files, send it, etc.

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// Base14 Helvetica has no glyph for ₹ (Indian Rupee Sign) — it renders as a
// tofu box. Load the app's own Inter font, which does support it.
Future<pw.Font> _loadFont(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return pw.Font.ttf(data);
}

Future<void> shareBookingReceipt({
  required String bookingCode,
  required String venueName,
  required String venueAddress,
  required String sport,
  required String groundName,
  required String bookingDate,
  required String timeSlot,
  required String customerName,
  required String customerPhone,
  required String basePrice,
  required String serviceFee,
  required String totalAmount,
  required String paymentStatus,
  String? paidAmount,
  String? remainingAmount,
  bool isPartPayment = false,
  String? paymentMethod,
  String? transactionId,
  String? paidAt,
}) async {
  final regularFont = await _loadFont('assets/fonts/inter/Inter_18pt-Regular.ttf');
  final boldFont    = await _loadFont('assets/fonts/inter/Inter_18pt-Bold.ttf');

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('BookPlayz',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
                        color: PdfColor.fromHex('#0A2540'))),
                pw.Text('RECEIPT',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                        color: PdfColor.fromHex('#9CCE00'))),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Text('BookPlayz Booking Receipt',
                style: pw.TextStyle(
                    font: regularFont, fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            _kv('Booking Code', bookingCode, regularFont, boldFont),
            _kv(
              'Generated On',
              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
              regularFont,
              boldFont,
            ),
            pw.SizedBox(height: 14),
            _sectionTitle('Venue', boldFont),
            _kv('Venue', venueName, regularFont, boldFont),
            _kv('Address', venueAddress, regularFont, boldFont),
            pw.SizedBox(height: 14),
            _sectionTitle('Booking Details', boldFont),
            _kv('Sport', sport, regularFont, boldFont),
            if (groundName.isNotEmpty)
              _kv('Ground', groundName, regularFont, boldFont),
            _kv('Date', bookingDate, regularFont, boldFont),
            _kv('Time', timeSlot, regularFont, boldFont),
            pw.SizedBox(height: 14),
            _sectionTitle('Booked By', boldFont),
            _kv('Name', customerName, regularFont, boldFont),
            _kv('Phone', customerPhone, regularFont, boldFont),
            pw.SizedBox(height: 14),
            _sectionTitle('Payment', boldFont),
            _kv('Base Price', '₹$basePrice', regularFont, boldFont),
            if (serviceFee.isNotEmpty && serviceFee != '0.00')
              _kv('Service Fee', '₹$serviceFee', regularFont, boldFont),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey300),
            _kv('Total Amount', '₹$totalAmount', regularFont, boldFont,
                bold: true),
            if (isPartPayment) ...[
              _kv('Amount Paid', '₹${paidAmount ?? '0.00'}', regularFont,
                  boldFont),
              _kv('Balance Due', '₹${remainingAmount ?? '0.00'}', regularFont,
                  boldFont),
            ],
            _kv('Payment Status', paymentStatus, regularFont, boldFont),
            if (paymentMethod != null && paymentMethod.isNotEmpty)
              _kv('Payment Method', paymentMethod, regularFont, boldFont),
            if (transactionId != null && transactionId.isNotEmpty)
              _kv('Transaction ID', transactionId, regularFont, boldFont),
            if (paidAt != null && paidAt.isNotEmpty)
              _kv('Paid At', paidAt, regularFont, boldFont),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for choosing BookPlayz!',
                style: pw.TextStyle(
                    font: regularFont, fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final safeCode = bookingCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final file = File('${dir.path}/BookPlayz_Receipt_$safeCode.pdf');
  await file.writeAsBytes(bytes, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: 'BookPlayz Receipt',
      text: 'BookPlayz booking receipt — $bookingCode',
    ),
  );
}

pw.Widget _sectionTitle(String text, pw.Font boldFont) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
            font: boldFont, fontSize: 10, color: PdfColor.fromHex('#6FCF97')),
      ),
    );

pw.Widget _kv(
  String label,
  String value,
  pw.Font regularFont,
  pw.Font boldFont, {
  bool bold = false,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: regularFont, fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: bold ? boldFont : regularFont,
                  fontSize: bold ? 12 : 10,
                  color: PdfColor.fromHex('#0A2540'))),
        ],
      ),
    );
