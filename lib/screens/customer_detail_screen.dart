
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/database_service.dart';
import '../services/statement_service.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, dynamic>> transactions = [];
  double balance = 0;
  bool isLoading = true;
  bool isExporting = false;

  final GlobalKey statementKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadCustomerData();
  }

  Future<void> loadCustomerData() async {
    final database = DatabaseService.instance;
    final customerId = widget.customer['id'] as int;

    final result = await Future.wait([
      database.getCustomerTransactions(customerId),
      database.getCustomerBalance(customerId),
    ]);

    if (!mounted) return;

    setState(() {
      transactions = result[0] as List<Map<String, dynamic>>;
      balance = (result[1] as num).toDouble();
      isLoading = false;
    });
  }

  Future<void> sharePdf() async {
    setState(() => isExporting = true);

    try {
      final file = await StatementService.generatePdf(
        customerName: widget.customer['name'].toString(),
        phone: widget.customer['phone'].toString(),
        balance: balance,
        transactions: transactions,
      );

      await StatementService.shareFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  Future<void> shareJpg() async {
    setState(() => isExporting = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final renderObject =
          statementKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Statement image is not ready');
      }

      final ui.Image image = await renderObject.toImage(
        pixelRatio: 2,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();

      if (byteData == null) {
        throw Exception('Could not create image');
      }

      final file = await StatementService.generateJpg(
        byteData.buffer.asUint8List(),
      );

      await StatementService.shareFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JPG Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customer['name'] ?? 'Customer';
    final phone = widget.customer['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isExporting ? null : sharePdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isExporting ? null : shareJpg,
                          icon: const Icon(Icons.image),
                          label: const Text('JPG'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExporting)
                  const LinearProgressIndicator(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadCustomerData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        RepaintBoundary(
                          key: statementKey,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        const CircleAvatar(
                                          radius: 35,
                                          child: Icon(
                                            Icons.person,
                                            size: 40,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          name.toString(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(phone.toString()),
                                        const SizedBox(height: 20),
                                        const Text('Current Balance'),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Rs. ${balance.abs().toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: balance >= 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          balance > 0
                                              ? 'Customer owes you'
                                              : balance < 0
                                                  ? 'You owe customer'
                                                  : 'No outstanding balance',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Transaction History',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (transactions.isEmpty)
                                  const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(25),
                                      child: Center(
                                        child: Text(
                                          'No transactions yet',
                                        ),
                                      ),
                                    ),
                                  ),
                                ...transactions.map((transaction) {
                                  final type =
                                      transaction['type']?.toString() ?? '';
                                  final amount =
                                      (transaction['amount'] as num)
                                          .toDouble();
                                  final isGave = type == 'gave';
                                  final date =
                                      transaction['date']?.toString() ?? '';
                                  final note =
                                      transaction['note']?.toString() ?? '';

                                  return Card(
                                    margin: const EdgeInsets.only(
                                      bottom: 10,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isGave
                                            ? Colors.red.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                        child: Icon(
                                          isGave
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: isGave
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                      title: Text(
                                        isGave ? 'You Gave' : 'You Got',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$date${note.isNotEmpty ? '\n$note' : ''}',
                                      ),
                                      isThreeLine: note.isNotEmpty,
                                      trailing: Text(
                                        'Rs. ${amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: isGave
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
