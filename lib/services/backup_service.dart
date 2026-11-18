
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'database_service.dart';

class BackupService {
  static Future<void> createBackup() async {
    final db = await DatabaseService.instance.database;

    final customers = await db.query('customers');
    final transactions = await db.query('transactions');

    final backupData = {
      'app': 'KhataBook',
      'version': 1,
      'backup_date': DateTime.now().toIso8601String(),
      'customers': customers,
      'transactions': transactions,
    };

    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(backupData);

    final bytes = utf8.encode(jsonString);

    await FilePicker.saveFile(
      dialogTitle: 'Save KhataBook Backup',
      fileName: 'khatabook_backup.json',
      mimeType: 'application/json',
      bytes: bytes,
    );
  }

  static Future<void> restoreBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isEmpty) {
      return;
    }

    final jsonBytes = await files.first.readAsBytes();
    final jsonString = utf8.decode(jsonBytes);

    final backupData = jsonDecode(jsonString);

    if (backupData is! Map ||
        backupData['app'] != 'KhataBook' ||
        backupData['version'] != 1) {
      throw Exception('Invalid KhataBook backup file');
    }

    final customers =
        List<Map<String, dynamic>>.from(
      backupData['customers'],
    );

    final transactions =
        List<Map<String, dynamic>>.from(
      backupData['transactions'],
    );

    final db = await DatabaseService.instance.database;

    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('customers');

      final batch = txn.batch();

      for (final customer in customers) {
        batch.insert('customers', customer);
      }

      for (final transaction in transactions) {
        batch.insert('transactions', transaction);
      }

      await batch.commit(noResult: true);
    });
  }
}
