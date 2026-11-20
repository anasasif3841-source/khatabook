
import '../services/database_service.dart';

class DashboardRepository {
  final DatabaseService database;

  DashboardRepository(this.database);

  Future<Map<String, dynamic>> getDashboardSummary() {
    return database.getDashboardSummary();
  }

  Future<List<Map<String, dynamic>>> getTopDebtors({
    int limit = 5,
  }) {
    return database.getTopDebtors(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({
    int limit = 5,
  }) {
    return database.getRecentTransactions(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals() {
    return database.getMonthlyTotals();
  }
}
