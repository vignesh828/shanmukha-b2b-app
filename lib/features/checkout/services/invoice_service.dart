import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';

class InvoiceService {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.');

  Future<void> generateAndPrintInvoice({
    required OrderModel order,
    required UserModel clientDetails,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SHANMUKHA ENTERPRISES', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('B2B Wholesale Portal'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey)),
                      pw.Text('Order #${order.orderId.substring(0, 8).toUpperCase()}'),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(order.orderDate)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Billing Details
              pw.Text('BILLED TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(clientDetails.businessName, style: pw.TextStyle(fontSize: 16)),
              pw.Text(clientDetails.name),
              pw.Text('Phone: ${clientDetails.phone}'),
              if (clientDetails.gstNumber != null && clientDetails.gstNumber!.isNotEmpty)
                pw.Text('GST: ${clientDetails.gstNumber}'),
              if (clientDetails.deliveryAddress != null && clientDetails.deliveryAddress!.isNotEmpty)
                pw.Text('Address: ${clientDetails.deliveryAddress}'),
              
              pw.SizedBox(height: 30),

              // Items Table
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerHeight: 25,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                headers: ['Item Description', 'Qty', 'Unit Price', 'Total'],
                data: order.items.map((item) {
                  return [
                    item.productName,
                    '${item.quantity}',
                    currencyFormatter.format(item.priceAtOrder),
                    currencyFormatter.format(item.priceAtOrder * item.quantity),
                  ];
                }).toList(),
              ),
              
              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL AMOUNT:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                            pw.Text(currencyFormatter.format(order.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(),
              pw.Center(
                child: pw.Text('Thank you for your business!', style: const pw.TextStyle(color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    // This will open a preview on mobile and allow printing/sharing
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.orderId.substring(0, 8)}.pdf',
    );
  }
}
