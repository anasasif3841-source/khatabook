
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

final dashboardSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardSummary();
});

final topDebtorsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getTopDebtors();
});

final recentTransactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getRecentTransactions();
});

final monthlyTotalsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getMonthlyTotals();
});
