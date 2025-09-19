import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/invoice.dart';
import '../models/merchant.dart';

class PdfService {
  Future<File> generateInvoicePdf({required MerchantProfile merchant, required Invoice invoice}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(merchant.businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (merchant.address != null) pw.Text(merchant.address!),
                if (merchant.phone != null) pw.Text(merchant.phone!),
                if (merchant.email != null) pw.Text(merchant.email!),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                pw.Text('Date: ${invoice.date.toLocal().toString().split(' ').first}'),
                pw.Text('Due: ${invoice.dueDate.toLocal().toString().split(' ').first}'),
              ]),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Bill To', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(invoice.client.name),
          if (invoice.client.company != null) pw.Text(invoice.client.company!),
          if (invoice.client.email != null) pw.Text(invoice.client.email!),
          if (invoice.client.phone != null) pw.Text(invoice.client.phone!),
          if (invoice.client.address != null) pw.Text(invoice.client.address!),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.grey300)),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rate', textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tax', textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', textAlign: pw.TextAlign.right)),
                ],
              ),
              ...invoice.items.map((i) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(i.description)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(i.quantity.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(i.rate.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${i.taxPercent.toStringAsFixed(0)}%', textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(i.lineTotal.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                  ])),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              _kv('Subtotal', invoice.subtotal),
              _kv('Discounts', invoice.discountTotal),
              _kv('Tax', invoice.taxAmount),
              pw.Divider(),
              _kv('Total', invoice.totalAmount, bold: true, currency: invoice.currencyCode ?? merchant.currencyCode),
            ]),
          ]),
          if (invoice.notes != null) pw.SizedBox(height: 16),
          if (invoice.notes != null) pw.Text('Notes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (invoice.notes != null) pw.Text(invoice.notes!),
          if (invoice.terms != null) pw.SizedBox(height: 16),
          if (invoice.terms != null) pw.Text('Terms', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (invoice.terms != null) pw.Text(invoice.terms!),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _kv(String key, double value, {bool bold = false, String? currency}) {
    final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Row(children: [
      pw.Text(key, style: style),
      pw.SizedBox(width: 80),
      pw.Text('${currency != null ? '$currency ' : ''}${value.toStringAsFixed(2)}', style: style),
    ]);
  }
}


