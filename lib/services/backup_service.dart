
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'database_service.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final backup =
        await DatabaseService.instance.createBackup();

    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(backup);

    final bytes = Uint8List.fromList(
      utf8.encode(jsonString),
    );

    final fileName =
        'khatabook_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    await FilePicker.saveFile(
      dialogTitle: 'Save KhataBook Backup',
      fileName: fileName,
      bytes: bytes,
    );
  }

  static Future<void> importBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    final jsonString = utf8.decode(bytes);
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid backup file format');
    }

    await DatabaseService.instance.restoreBackup(decoded);
  }
}
