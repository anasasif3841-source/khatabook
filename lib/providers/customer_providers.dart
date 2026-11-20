
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

final customersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomers();
});
