
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

final customerTransactionsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, int>((ref, customerId) {
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getCustomerTransactionsWithBalance(customerId);
});

final customerBalanceProvider =
    FutureProvider.family<double, int>((ref, customerId) {
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getCustomerBalance(customerId);
});
