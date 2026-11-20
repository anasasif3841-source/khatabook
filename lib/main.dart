
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/customer_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'widgets/monthly_chart.dart';

import 'services/backup_service.dart';

import 'providers/dashboard_providers.dart';
import 'providers/customer_providers.dart';
import 'providers/transaction_providers.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String formatAmount(dynamic amount) {
    return 'Rs. ${(amount as num).toStringAsFixed(0)}';
  }

  void refreshAll(WidgetRef ref) {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(topDebtorsProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(monthlyTotalsProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(customerTransactionsProvider);
    ref.invalidate(customerBalanceProvider);
  }

  Future<void> backupData(BuildContext context) async {
    try {
      await BackupService.exportBackup();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup process completed.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $error'),
          ),
        );
      }
    }
  }

  Future<void> restoreData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text(
            'Restoring a backup will replace your current '
            'customers and transactions. This action cannot '
            'be undone. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await BackupService.importBackup();

      refreshAll(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore process completed.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final debtorsAsync = ref.watch(topDebtorsProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);

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
            onPressed: () {
              refreshAll(ref);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshAll(ref);

          await Future.wait([
            ref.read(dashboardSummaryProvider.future),
            ref.read(topDebtorsProvider.future),
            ref.read(recentTransactionsProvider.future),
            ref.read(monthlyTotalsProvider.future),
          ]);
        },
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

            summaryAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Card(
                child: ListTile(
                  title: const Text('Unable to load summary'),
                  subtitle: Text(error.toString()),
                  trailing: IconButton(
                    onPressed: () {
                      ref.invalidate(dashboardSummaryProvider);
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
              data: (summary) {
                return Row(
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
                );
              },
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
                    context,
                    'Customers',
                    Icons.people,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: actionCard(
                    context,
                    'Add Entry',
                    Icons.add_circle,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: actionCard(
                    context,
                    'Backup Data',
                    Icons.cloud_download,
                    Colors.green,
                    () => backupData(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: actionCard(
                    context,
                    'Restore Data',
                    Icons.cloud_upload,
                    Colors.deepPurple,
                    () => restoreData(context, ref),
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

            debtorsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text(
                'Error loading debtors: $error',
              ),
              data: (debtors) {
                if (debtors.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No outstanding balances yet'),
                    ),
                  );
                }

                return Column(
                  children: debtors.map((customer) {
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(customer['name'].toString()),
                        subtitle: Text(
                          customer['phone']?.toString() ?? '',
                        ),
                        trailing: Text(
                          formatAmount(customer['balance']),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            transactionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text(
                'Error loading transactions: $error',
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No transactions yet'),
                    ),
                  );
                }

                return Column(
                  children: transactions.map((transaction) {
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
                  }).toList(),
                );
              },
            ),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerScreen(),
              ),
            );
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
    BuildContext context,
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
          color: Theme.of(context).cardColor,
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
