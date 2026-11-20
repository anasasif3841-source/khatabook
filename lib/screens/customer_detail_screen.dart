
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_providers.dart';
import '../services/statement_service.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState
    extends ConsumerState<CustomerDetailScreen> {
  bool isExporting = false;

  final GlobalKey statementKey = GlobalKey();

  int get customerId => widget.customer['id'] as int;

  Future<void> refreshCustomerData() async {
    await Future.wait([
      ref.refresh(customerTransactionsProvider(customerId).future),
      ref.refresh(customerBalanceProvider(customerId).future),
    ]);
  }

  Future<void> showMessage(String message) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> sharePdf(
    double balance,
    List<Map<String, dynamic>> transactions,
  ) async {
    setState(() {
      isExporting = true;
    });

    try {
      final bytes = await StatementService.generatePdf(
        customerName: widget.customer['name'].toString(),
        phone: widget.customer['phone']?.toString() ?? '',
        balance: balance,
        transactions: transactions,
      );

      await StatementService.sharePdf(bytes);

      await showMessage('PDF statement created successfully');
    } catch (e) {
      await showMessage('PDF Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  Future<void> shareJpg() async {
    setState(() {
      isExporting = true;
    });

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

      final bytes = await StatementService.generateJpg(
        byteData.buffer.asUint8List(),
      );

      await StatementService.shareJpg(bytes);

      await showMessage('JPG statement created successfully');
    } catch (e) {
      await showMessage('JPG Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  Future<void> sendWhatsApp(double balance) async {
    try {
      final phone = widget.customer['phone']?.toString() ?? '';

      if (phone.isEmpty) {
        throw Exception('Customer phone number is missing');
      }

      await StatementService.sendWhatsApp(
        phone: phone,
        customerName: widget.customer['name'].toString(),
        balance: balance,
      );
    } catch (e) {
      await showMessage('WhatsApp Error: $e');
    }
  }

  Future<void> sendSms(double balance) async {
    try {
      final phone = widget.customer['phone']?.toString() ?? '';

      if (phone.isEmpty) {
        throw Exception('Customer phone number is missing');
      }

      await StatementService.sendSms(
        phone: phone,
        customerName: widget.customer['name'].toString(),
        balance: balance,
      );
    } catch (e) {
      await showMessage('SMS Error: $e');
    }
  }

  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: refreshCustomerData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomerContent(
    double balance,
    List<Map<String, dynamic>> transactions,
  ) {
    final name = widget.customer['name']?.toString() ?? 'Customer';
    final phone = widget.customer['phone']?.toString() ?? '';

    final displayTransactions = transactions.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isExporting
                      ? null
                      : () => sharePdf(balance, transactions),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => sendWhatsApp(balance),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => sendSms(balance),
                  icon: const Icon(Icons.sms),
                  label: const Text('SMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isExporting) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refreshCustomerData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RepaintBoundary(
                  key: statementKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(phone),
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
                                child: Text('No transactions yet'),
                              ),
                            ),
                          ),
                        ...displayTransactions.map((transaction) {
                          final type =
                              transaction['type']?.toString() ?? '';

                          final amount =
                              (transaction['amount'] as num).toDouble();

                          final runningBalance =
                              (transaction['running_balance'] as num?)
                                      ?.toDouble() ??
                                  0.0;

                          final isGave = type == 'gave';

                          final date =
                              transaction['date']?.toString() ?? '';

                          final note =
                              transaction['note']?.toString() ?? '';

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
                                '${formatDate(date)}'
                                '${note.isNotEmpty ? '\n$note' : ''}'
                                '\nBalance: Rs. '
                                '${runningBalance.abs().toStringAsFixed(0)}'
                                '${runningBalance > 0 ? ' (You will receive)' : runningBalance < 0 ? ' (You owe)' : ''}',
                              ),
                              isThreeLine: true,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync =
        ref.watch(customerTransactionsProvider(customerId));

    final balanceAsync =
        ref.watch(customerBalanceProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: refreshCustomerData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => buildError(
          'Failed to load transactions: $error',
        ),
        data: (transactions) {
          return balanceAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => buildError(
              'Failed to load customer balance: $error',
            ),
            data: (balance) {
              return buildCustomerContent(
                balance,
                transactions,
              );
            },
          );
        },
      ),
    );
  }
}
