
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class StatementService {
  static Future<void> generatePdf({
    required String customerName,
    required String phone,
    required double balance,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'KHATABOOK STATEMENT',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Customer: $customerName'),
          pw.Text('Phone: $phone'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Current Balance: Rs. ${balance.abs().toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            balance > 0
                ? 'Customer owes you'
                : balance < 0
                    ? 'You owe customer'
                    : 'No outstanding balance',
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transaction History',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Amount', 'Note'],
            data: transactions.map((transaction) {
              return [
                transaction['date']?.toString() ?? '',
                transaction['type'] == 'gave'
                    ? 'You Gave'
                    : 'You Got',
                'Rs. ${(transaction['amount'] as num).toStringAsFixed(0)}',
                transaction['note']?.toString() ?? '',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'KhataBook_Statement.pdf',
    );
  }

  static Future<File> generateJpg(Uint8List imageBytes) async {
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Could not create statement image');
    }

    final jpgBytes = img.encodeJpg(decodedImage, quality: 90);

    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/statement_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(jpgBytes);

    return file;
  }

  static Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'KhataBook Customer Statement',
      ),
    );
  }
}
