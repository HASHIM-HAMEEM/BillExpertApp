import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/currency.dart';
import '../models/invoice.dart';
import '../models/merchant.dart';

class PdfService {
  Future<File> generateInvoicePdf({
    required MerchantProfile merchant,
    required Invoice invoice,
  }) async {
    final pdf = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: merchant.businessName,
    );

    // Define theme colors (Elegant Lines theme)
    final primaryColor = PdfColor.fromHex('#1a202c');
    final secondaryColor = PdfColor.fromHex('#718096');
    final borderColor = PdfColor.fromHex('#e2e8f0');
    final headerAccent = PdfColor.fromHex('#2d3748');
    // final tableHover = PdfColor.fromHex('#f8fafc');

    // Define fonts
    final regularFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (pw.Context context) => [
          // Header Section (company info + invoice meta + accent line)
          _buildHeader(merchant, invoice, primaryColor, headerAccent, boldFont, regularFont),

          pw.SizedBox(height: 32),

          // Billing Section (Billed To)
          _buildInvoiceDetails(invoice, primaryColor, secondaryColor, regularFont, boldFont),

          pw.SizedBox(height: 32),

          // Items Table
          _buildItemsTable(invoice, borderColor, primaryColor, regularFont, boldFont),

          pw.SizedBox(height: 24),

          // Total Section
          _buildSummary(invoice, primaryColor, regularFont, boldFont),

          pw.SizedBox(height: 32),

          // Footer
          _buildFooter(merchant, invoice, secondaryColor, regularFont),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: regularFont, fontSize: 10, color: secondaryColor),
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(
    MerchantProfile merchant,
    Invoice invoice,
    PdfColor primaryColor,
    PdfColor accentColor,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    merchant.businessName,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 26,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (merchant.address != null)
                    pw.Text(
                      merchant.address!,
                      style: pw.TextStyle(font: regularFont, fontSize: 12, color: const PdfColor.fromInt(0xFF718096)),
                    ),
                  if (merchant.phone != null)
                    pw.Text(
                      'Tel: ${merchant.phone!}',
                      style: pw.TextStyle(font: regularFont, fontSize: 12, color: const PdfColor.fromInt(0xFF718096)),
                    ),
                  if (merchant.email != null)
                    pw.Text(
                      'Email: ${merchant.email!}',
                      style: pw.TextStyle(font: regularFont, fontSize: 12, color: const PdfColor.fromInt(0xFF718096)),
                    ),
                ],
              ),

              // Invoice Meta
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Invoice',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _metaRow('Number:', invoice.invoiceNumber, regularFont, boldFont),
                  _metaRow('Date:', DateFormat('MMMM d, yyyy').format(invoice.date), regularFont, boldFont),
                  _metaRow('Due:', DateFormat('MMMM d, yyyy').format(invoice.dueDate), regularFont, boldFont),
                  if (invoice.terms != null && invoice.terms!.isNotEmpty)
                    _metaRow('Terms:', invoice.terms!, regularFont, boldFont),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(width: 52, height: 2.5, color: accentColor),
        ],
      ),
    );
  }

  pw.Widget _metaRow(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 11, color: const PdfColor.fromInt(0xFF718096))),
          pw.SizedBox(width: 8),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 11.5, color: const PdfColor.fromInt(0xFF2d3748))),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceDetails(
    Invoice invoice,
    PdfColor primaryColor,
    PdfColor secondaryColor,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Details',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildDetailColumn(
                  'Bill To',
                  [
                    pw.Text(
                      invoice.client.name,
                      style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor),
                    ),
                    if (invoice.client.company != null)
                      pw.Text(
                        invoice.client.company!,
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: secondaryColor),
                      ),
                    if (invoice.client.email != null)
                      pw.Text(
                        invoice.client.email!,
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: secondaryColor),
                      ),
                    if (invoice.client.phone != null)
                      pw.Text(
                        invoice.client.phone!,
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: secondaryColor),
                      ),
                    if (invoice.client.address != null)
                      pw.Text(
                        invoice.client.address!,
                        style: pw.TextStyle(font: regularFont, fontSize: 12, color: secondaryColor),
                      ),
                  ],
                  regularFont,
                ),
              ),
              pw.SizedBox(width: 48),
              pw.Expanded(
                child: _buildDetailColumn(
                  'Invoice Info',
                  [
                    _buildDetailRow('Date', dateFormat.format(invoice.date.toLocal()), regularFont, secondaryColor, boldFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Due Date', dateFormat.format(invoice.dueDate.toLocal()), regularFont, secondaryColor, boldFont),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Currency', invoice.currencyCode ?? 'USD', regularFont, secondaryColor, boldFont),
                  ],
                  regularFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailColumn(String title, List<pw.Widget> children, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 13,
            color: const PdfColor.fromInt(0xFF374151),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value, pw.Font regularFont, PdfColor secondaryColor, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: regularFont, fontSize: 12, color: secondaryColor),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: boldFont, fontSize: 12, color: const PdfColor.fromInt(0xFF111827)),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(
    Invoice invoice,
    PdfColor borderColor,
    PdfColor primaryColor,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        children: [
          // Table Content
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: borderColor, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(4), // Description
              1: const pw.FlexColumnWidth(1.5), // Qty
              2: const pw.FlexColumnWidth(2), // Rate
              3: const pw.FlexColumnWidth(1.5), // Tax
              4: const pw.FlexColumnWidth(2), // Total
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2))),
                children: [
                  _buildTableCell('Description', boldFont, primaryColor, 11, pw.TextAlign.left),
                  _buildTableCell('Qty', boldFont, primaryColor, 11, pw.TextAlign.center),
                  _buildTableCell('Rate', boldFont, primaryColor, 11, pw.TextAlign.right),
                  _buildTableCell('Tax', boldFont, primaryColor, 11, pw.TextAlign.right),
                  _buildTableCell('Total', boldFont, primaryColor, 11, pw.TextAlign.right),
                ],
              ),

              // Data Rows
              ...invoice.items.map((item) => pw.TableRow(
                children: [
                  _buildTableCell(item.description, regularFont, primaryColor, 10.5, pw.TextAlign.left),
                  _buildTableCell(
                    item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(2),
                    regularFont,
                    const PdfColor.fromInt(0xFF4a5568),
                    11,
                    pw.TextAlign.center,
                  ),
                  _buildTableCell(item.rate.toStringAsFixed(2), regularFont, primaryColor, 10.5, pw.TextAlign.right),
                  _buildTableCell('${item.taxPercent.toStringAsFixed(0)}%', regularFont, primaryColor, 10.5, pw.TextAlign.right),
                  _buildTableCell(item.lineTotal.toStringAsFixed(2), boldFont, primaryColor, 10.5, pw.TextAlign.right),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font, PdfColor color, double fontSize, pw.TextAlign align) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: align == pw.TextAlign.left ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
      ),
    );
  }

  pw.Widget _buildSummary(
    Invoice invoice,
    PdfColor primaryColor,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      width: 300,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _totalRow('Subtotal', invoice.subtotal, invoice.currencyCode, regularFont, const PdfColor.fromInt(0xFF4a5568)),
          _totalRow('Discount', -invoice.discountTotal, invoice.currencyCode, regularFont, const PdfColor.fromInt(0xFF4a5568)),
          _totalRow('Tax', invoice.taxAmount, invoice.currencyCode, regularFont, const PdfColor.fromInt(0xFF4a5568)),
          pw.Container(height: 3, color: primaryColor, margin: const pw.EdgeInsets.only(top: 12)),
          pw.SizedBox(height: 8),
          _totalRow('Amount Due', invoice.totalAmount, invoice.currencyCode, boldFont, primaryColor, isFinal: true),
        ],
      ),
    );
  }

  String _formatPdfCurrency(double amount, String currencyCode) {
    final currency = Currency.findByCode(currencyCode);
    final symbol = currency?.symbol ?? currencyCode;

    if (amount < 0) {
      return '-$symbol${(-amount).toStringAsFixed(2)}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  pw.Widget _totalRow(
    String label,
    double amount,
    String? currency,
    pw.Font font,
    PdfColor color, {
    bool isFinal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: const PdfColor.fromInt(0xFFF1F5F9), width: isFinal ? 0 : 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: isFinal ? 14 : 12, color: color, fontWeight: isFinal ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            _formatPdfCurrency(amount, currency ?? 'USD'),
            style: pw.TextStyle(font: font, fontSize: isFinal ? 20 : 14, color: isFinal ? const PdfColor.fromInt(0xFF1a202c) : color, fontWeight: isFinal ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // _buildSummaryRow removed in favor of _totalRow

  pw.Widget _buildFooter(
    MerchantProfile merchant,
    Invoice invoice,
    PdfColor secondaryColor,
    pw.Font regularFont,
  ) {
    final widgets = <pw.Widget>[];

    if (invoice.notes != null && invoice.notes!.isNotEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF9FAFB),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Notes',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF374151),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.notes!,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 11,
                  color: const PdfColor.fromInt(0xFF6B7280),
                  lineSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 16));
    }

    if (invoice.terms != null && invoice.terms!.isNotEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF9FAFB),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF374151),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.terms!,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 11,
                  color: const PdfColor.fromInt(0xFF6B7280),
                  lineSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF9FAFB),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: const PdfColor.fromInt(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // Status helpers removed in current elegant design
}


