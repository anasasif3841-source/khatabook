
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/customer_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'services/database_service.dart';
import 'widgets/monthly_chart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(
    const ProviderScope(
      child: KhataBookApp(),
    ),
  );
}

class KhataBookApp extends StatelessWidget {
  const KhataBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KhataBook',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final database = DatabaseService.instance;

  Map<String, double> summary = {
    'receivable': 0,
    'payable': 0,
  };

  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> topDebtors = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final results = await Future.wait([
        database.getDashboardSummary(),
        database.getRecentTransactions(),
        database.getTopDebtors(),
      ]);

      if (!mounted) return;

      setState(() {
        summary = results[0] as Map<String, double>;
        recentTransactions =
            results[1] as List<Map<String, dynamic>>;
        topDebtors =
            results[2] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: $e')),
      );
    }
  }

  Future<void> openCustomers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerScreen(),
      ),
    );

    await loadDashboard();
  }

  Future<void> openAddEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    await loadDashboard();
  }

  String formatAmount(dynamic amount) {
    return 'Rs. ${(amount as num).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KhataBook',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: balanceCard(
                          'You Will Get',
                          formatAmount(summary['receivable'] ?? 0),
                          Colors.green,
                          Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: balanceCard(
                          'You Will Give',
                          formatAmount(summary['payable'] ?? 0),
                          Colors.red,
                          Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: actionCard(
                          'Customers',
                          Icons.people,
                          Colors.blue,
                          openCustomers,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: actionCard(
                          'Add Entry',
                          Icons.add_circle,
                          Colors.orange,
                          openAddEntry,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const MonthlyChart(),
                  const SizedBox(height: 25),
                  const Text(
                    'Top Debtors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (topDebtors.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('No outstanding balances yet'),
                      ),
                    ),
                  ...topDebtors.map((customer) {
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(customer['name'].toString()),
                        subtitle: Text(customer['phone'].toString()),
                        trailing: Text(
                          formatAmount(customer['balance']),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 25),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (recentTransactions.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('No transactions yet'),
                      ),
                    ),
                  ...recentTransactions.map((transaction) {
                    final isGave = transaction['type'] == 'gave';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isGave
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          child: Icon(
                            isGave
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isGave ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          transaction['customer_name'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          isGave ? 'You Gave' : 'You Got',
                        ),
                        trailing: Text(
                          formatAmount(transaction['amount']),
                          style: TextStyle(
                            color: isGave ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            openCustomers();
          }
        },
      ),
    );
  }

  Widget balanceCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(title),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
