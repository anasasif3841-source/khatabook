
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._privateConstructor();

  static final DatabaseService instance =
      DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'khatabook.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            date TEXT NOT NULL,
            FOREIGN KEY (customer_id)
              REFERENCES customers (id)
          )
        ''');
      },
    );
  }

  // Add Customer
  Future<int> addCustomer(String name, String phone) async {
    final db = await database;

    return await db.insert('customers', {
      'name': name,
      'phone': phone,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get All Customers
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;

    return await db.query(
      'customers',
      orderBy: 'name ASC',
    );
  }

  // Add Transaction
  Future<int> addTransaction({
    required int customerId,
    required String type,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    if (type != 'gave' && type != 'got') {
      throw Exception('Invalid transaction type');
    }

    final db = await database;

    return await db.insert('transactions', {
      'customer_id': customerId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // Get Customer Transactions
  Future<List<Map<String, dynamic>>> getCustomerTransactions(
    int customerId,
  ) async {
    final db = await database;

    return await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  // Get Customer Balance
  Future<double> getCustomerBalance(int customerId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        COALESCE(
          SUM(
            CASE
              WHEN type = 'gave' THEN amount
              WHEN type = 'got' THEN -amount
              ELSE 0
            END
          ),
          0
        ) AS balance
      FROM transactions
      WHERE customer_id = ?
      ''',
      [customerId],
    );

    return (result.first['balance'] as num).toDouble();
  }

  // Get Dashboard Summary
  Future<Map<String, double>> getDashboardSummary() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        customer_id,
        COALESCE(
          SUM(
            CASE
              WHEN type = 'gave' THEN amount
              WHEN type = 'got' THEN -amount
              ELSE 0
            END
          ),
          0
        ) AS balance
      FROM transactions
      GROUP BY customer_id
    ''');

    double receivable = 0;
    double payable = 0;

    for (final row in result) {
      final balance = (row['balance'] as num).toDouble();

      if (balance > 0) {
        receivable += balance;
      } else if (balance < 0) {
        payable += balance.abs();
      }
    }

    return {
      'receivable': receivable,
      'payable': payable,
    };
  }

  // Get Top Debtors
  Future<List<Map<String, dynamic>>> getTopDebtors({
    int limit = 5,
  }) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT
        customers.id,
        customers.name,
        customers.phone,
        COALESCE(
          SUM(
            CASE
              WHEN transactions.type = 'gave'
                THEN transactions.amount
              WHEN transactions.type = 'got'
                THEN -transactions.amount
              ELSE 0
            END
          ),
          0
        ) AS balance
      FROM customers
      INNER JOIN transactions
        ON customers.id = transactions.customer_id
      GROUP BY customers.id
      HAVING balance > 0
      ORDER BY balance DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // Get All Transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        transactions.*,
        customers.name AS customer_name
      FROM transactions
      INNER JOIN customers
        ON transactions.customer_id = customers.id
      ORDER BY transactions.date DESC
    ''');
  }

  // Get Recent Transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions({
    int limit = 5,
  }) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT
        transactions.*,
        customers.name AS customer_name
      FROM transactions
      INNER JOIN customers
        ON transactions.customer_id = customers.id
      ORDER BY transactions.date DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // Get Monthly Transaction Totals
  Future<List<Map<String, dynamic>>> getMonthlyTotals() async {
    final db = await database;

    final sixMonthsAgo = DateTime(
      DateTime.now().year,
      DateTime.now().month - 5,
      1,
    );

    return await db.rawQuery(
      '''
      SELECT
        strftime('%Y-%m', date) AS month,
        COALESCE(
          SUM(
            CASE
              WHEN type = 'gave' THEN amount
              ELSE 0
            END
          ),
          0
        ) AS gave_total,
        COALESCE(
          SUM(
            CASE
              WHEN type = 'got' THEN amount
              ELSE 0
            END
          ),
          0
        ) AS got_total
      FROM transactions
      WHERE date >= ?
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month ASC
      ''',
      [sixMonthsAgo.toIso8601String()],
    );
  }
}
