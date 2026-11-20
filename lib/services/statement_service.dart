
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class StatementService {
  static Future<Uint8List> generatePdf({
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

    return Uint8List.fromList(await pdf.save());
  }

  static Future<void> sharePdf(Uint8List bytes) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'khatabook_statement.pdf',
    );
  }

  static Future<Uint8List> generateJpg(Uint8List imageBytes) async {
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Could not create statement image');
    }

    return Uint8List.fromList(
      img.encodeJpg(decodedImage, quality: 90),
    );
  }

  static Future<void> shareJpg(Uint8List bytes) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: 'khatabook_statement.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
        text: 'KhataBook Customer Statement',
      ),
    );
  }

  static String normalizePakistaniPhone(String phone) {
    var number = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (number.startsWith('+')) {
      number = number.substring(1);
    }

    if (number.startsWith('03') && number.length == 11) {
      return '92${number.substring(1)}';
    }

    if (number.startsWith('0092')) {
      return number.substring(2);
    }

    if (number.startsWith('92')) {
      return number;
    }

    if (number.startsWith('3') && number.length == 10) {
      return '92$number';
    }

    throw Exception('Invalid Pakistani phone number');
  }

  static String createReminderMessage({
    required String customerName,
    required double balance,
  }) {
    final amount = balance.abs().toStringAsFixed(0);

    if (balance > 0) {
      return 'Assalam-o-Alaikum $customerName, '
          'aap ke zimme Rs. $amount baqi hain. '
          'Meharbani farma kar payment kar dein. Shukriya.';
    }

    if (balance < 0) {
      return 'Assalam-o-Alaikum $customerName, '
          'hamare zimme aap ke Rs. $amount baqi hain. '
          'Shukriya.';
    }

    return 'Assalam-o-Alaikum $customerName, '
        'aap ka KhataBook balance clear hai. Shukriya.';
  }

  static Future<void> sendWhatsApp({
    required String phone,
    required String customerName,
    required double balance,
  }) async {
    final number = normalizePakistaniPhone(phone);
    final message = createReminderMessage(
      customerName: customerName,
      balance: balance,
    );

    final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception('Could not open WhatsApp');
    }
  }

  static Future<void> sendSms({
    required String phone,
    required String customerName,
    required double balance,
  }) async {
    final number = normalizePakistaniPhone(phone);
    final message = createReminderMessage(
      customerName: customerName,
      balance: balance,
    );

    final uri = Uri(
      scheme: 'sms',
      path: '+$number',
      queryParameters: {
        'body': message,
      },
    );

    final launched = await launchUrl(uri);

    if (!launched) {
      throw Exception('Could not open SMS app');
    }
  }
}
