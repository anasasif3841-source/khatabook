import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database_service.dart';
import '../repositories/customer_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/dashboard_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(databaseServiceProvider));
});

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseServiceProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(databaseServiceProvider));
});