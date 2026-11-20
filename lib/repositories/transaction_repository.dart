
import '../services/database_service.dart';

class TransactionRepository {
  final DatabaseService database;

  TransactionRepository(this.database);

  Future<int> addTransaction({
    required int customerId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
  }) {
    return database.addTransaction(
      customerId: customerId,
      type: type,
      amount: amount,
      note: note,
      date: date,
    );
  }

  Future<double> getCustomerBalance(int customerId) {
    return database.getCustomerBalance(customerId);
  }

  Future<List<Map<String, dynamic>>> getCustomerTransactions(
    int customerId,
  ) {
    return database.getCustomerTransactions(customerId);
  }

  Future<List<Map<String, dynamic>>> getCustomerTransactionsWithBalance(
    int customerId,
  ) async {
    final transactions =
        await database.getCustomerTransactions(customerId);

    final result = transactions
        .map((transaction) => Map<String, dynamic>.from(transaction))
        .toList();

    double runningBalance = 0;

    for (final transaction in result) {
      final amount = (transaction['amount'] as num).toDouble();
      final type = transaction['type']?.toString();

      if (type == 'gave') {
        runningBalance += amount;
      } else if (type == 'got') {
        runningBalance -= amount;
      }

      transaction['running_balance'] = runningBalance;
    }

    return result;
  }
}
