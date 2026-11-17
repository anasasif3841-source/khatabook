
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final customersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  return database.getCustomers();
});
