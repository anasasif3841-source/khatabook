
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
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
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
          ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_customer_id
      ON transactions(customer_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_date
      ON transactions(date)
    ''');
  }

  // Add Customer
  Future<int> addCustomer({
    required String name,
    String? phone,
  }) async {
    final db = await database;

    if (name.trim().isEmpty) {
      throw Exception('Customer name is required');
    }

    return await db.insert(
      'customers',
      {
        'name': name.trim(),
        'phone': phone?.trim(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Get All Customers
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;

    return await db.query(
      'customers',
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  // Get Customer By ID
  Future<Map<String, dynamic>?> getCustomerById(int customerId) async {
    final db = await database;

    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // Add Transaction
  Future<int> addTransaction({
    required int customerId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    final db = await database;

    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    if (type != 'gave' && type != 'got') {
      throw Exception('Invalid transaction type');
    }

    final customer = await getCustomerById(customerId);

    if (customer == null) {
      throw Exception('Customer not found');
    }

    return await db.insert(
      'transactions',
      {
        'customer_id': customerId,
        'type': type,
        'amount': amount,
        'note': note?.trim(),
        'date': date.toIso8601String(),
      },
    );
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
      orderBy: 'date ASC, id ASC',
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
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        COALESCE(
          SUM(
            CASE WHEN type = 'gave' THEN amount ELSE 0 END
          ),
          0
        ) AS total_receivable,

        COALESCE(
          SUM(
            CASE WHEN type = 'got' THEN amount ELSE 0 END
          ),
          0
        ) AS total_payable

      FROM transactions
    ''');

    final receivable =
        (result.first['total_receivable'] as num).toDouble();

    final payable =
        (result.first['total_payable'] as num).toDouble();

    return {
      'totalReceivable': receivable,
      'totalPayable': payable,
      'totalBalance': receivable - payable,
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

      LEFT JOIN transactions
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

      ORDER BY transactions.date DESC, transactions.id DESC
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

      ORDER BY transactions.date DESC, transactions.id DESC

      LIMIT ?
      ''',
      [limit],
    );
  }

  // Get Monthly Totals (Last 6 Months)
  Future<List<Map<String, dynamic>>> getMonthlyTotals() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) AS month,

        COALESCE(
          SUM(
            CASE WHEN type = 'gave' THEN amount ELSE 0 END
          ),
          0
        ) AS total_gave,

        COALESCE(
          SUM(
            CASE WHEN type = 'got' THEN amount ELSE 0 END
          ),
          0
        ) AS total_got

      FROM transactions

      WHERE date >= date('now', 'start of month', '-5 months')

      GROUP BY strftime('%Y-%m', date)

      ORDER BY month ASC
    ''');
  }

  // Create Backup
  Future<Map<String, dynamic>> createBackup() async {
    final db = await database;

    final customers = await db.query(
      'customers',
      orderBy: 'id ASC',
    );

    final transactions = await db.query(
      'transactions',
      orderBy: 'id ASC',
    );

    return {
      'app': 'KhataBook',
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'customers': customers,
      'transactions': transactions,
    };
  }

  // Restore Backup
  Future<void> restoreBackup(
    Map<String, dynamic> backup,
  ) async {
    final db = await database;

    if (backup['app'] != 'KhataBook' ||
        backup['backupVersion'] != 1) {
      throw Exception('Invalid or unsupported backup file');
    }

    if (backup['customers'] is! List ||
        backup['transactions'] is! List) {
      throw Exception('Backup data is incomplete');
    }

    final customers = (backup['customers'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final transactions = (backup['transactions'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final customerIds = <int>{};

    for (final customer in customers) {
      final id = customer['id'];
      final name = customer['name'];
      final phone = customer['phone'];
      final createdAt = customer['created_at'];

      if (id is! int ||
          id <= 0 ||
          name is! String ||
          name.trim().isEmpty ||
          (phone != null && phone is! String) ||
          createdAt is! String ||
          DateTime.tryParse(createdAt) == null) {
        throw Exception('Invalid customer data in backup');
      }

      if (!customerIds.add(id)) {
        throw Exception('Duplicate customer ID in backup');
      }
    }

    final transactionIds = <int>{};

    for (final transaction in transactions) {
      final id = transaction['id'];
      final customerId = transaction['customer_id'];
      final type = transaction['type'];
      final amount = transaction['amount'];
      final note = transaction['note'];
      final date = transaction['date'];

      if (id is! int ||
          id <= 0 ||
          customerId is! int ||
          !customerIds.contains(customerId) ||
          (type != 'gave' && type != 'got') ||
          amount is! num ||
          !amount.toDouble().isFinite ||
          amount <= 0 ||
          (note != null && note is! String) ||
          date is! String ||
          DateTime.tryParse(date) == null) {
        throw Exception('Invalid transaction data in backup');
      }

      if (!transactionIds.add(id)) {
        throw Exception('Duplicate transaction ID in backup');
      }
    }

    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('customers');

      for (final customer in customers) {
        await txn.insert(
          'customers',
          {
            'id': customer['id'],
            'name': customer['name'],
            'phone': customer['phone'],
            'created_at': customer['created_at'],
          },
        );
      }

      for (final transaction in transactions) {
        await txn.insert(
          'transactions',
          {
            'id': transaction['id'],
            'customer_id': transaction['customer_id'],
            'type': transaction['type'],
            'amount': transaction['amount'],
            'note': transaction['note'],
            'date': transaction['date'],
          },
        );
      }
    });
  }
}
