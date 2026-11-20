
import '../services/database_service.dart';

class CustomerRepository {
  final DatabaseService database;

  CustomerRepository(this.database);

  Future<int> addCustomer({
    required String name,
    String? phone,
  }) {
    return database.addCustomer(
      name: name,
      phone: phone,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers() {
    return database.getCustomers();
  }

  Future<Map<String, dynamic>?> getCustomerById(int customerId) {
    return database.getCustomerById(customerId);
  }
}
