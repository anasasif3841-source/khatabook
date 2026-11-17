
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<Map<String, dynamic>> transactionsWithBalance = [];

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
    try {
      final database = DatabaseService.instance;
      final customerId = widget.customer['id'] as int;

      final result = await Future.wait([
        database.getCustomerTransactions(customerId),
        database.getCustomerBalance(customerId),
      ]);

      final transactionList =
          result[0] as List<Map<String, dynamic>>;

      final currentBalance = (result[1] as num).toDouble();

      final ascendingTransactions =
          List<Map<String, dynamic>>.from(transactionList);

      ascendingTransactions.sort((a, b) {
        return DateTime.parse(a['date'].toString()).compareTo(
          DateTime.parse(b['date'].toString()),
        );
      });

      double runningBalance = 0;

      final List<Map<String, dynamic>> calculated = [];

      for (final transaction in ascendingTransactions) {
        final amount =
            (transaction['amount'] as num).toDouble();

        if (transaction['type'] == 'gave') {
          runningBalance += amount;
        } else {
          runningBalance -= amount;
        }

        calculated.add({
          ...transaction,
          'running_balance': runningBalance,
        });
      }

      if (!mounted) return;

      setState(() {
        transactions = transactionList;
        transactionsWithBalance = calculated.reversed.toList();
        balance = currentBalance;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  String get phoneNumber {
    String phone =
        widget.customer['phone'].toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

    if (phone.startsWith('0')) {
      phone = '92${phone.substring(1)}';
    }

    return phone;
  }

  String get reminderMessage {
    if (balance > 0) {
      return 'Assalam-o-Alaikum ${widget.customer['name']}, '
          'your outstanding balance is Rs. '
          '${balance.toStringAsFixed(0)}. '
          'Please clear your payment. Thank you.';
    }

    if (balance < 0) {
      return 'Assalam-o-Alaikum ${widget.customer['name']}, '
          'your account shows Rs. '
          '${balance.abs().toStringAsFixed(0)} payable to you. '
          'Thank you.';
    }

    return 'Assalam-o-Alaikum ${widget.customer['name']}, '
        'your account is clear. Thank you.';
  }

  Future<void> sendWhatsAppReminder() async {
    if (phoneNumber.isEmpty) return;

    final uri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(reminderMessage)}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp'),
        ),
      );
    }
  }

  Future<void> sendSmsReminder() async {
    if (phoneNumber.isEmpty) return;

    final uri = Uri(
      scheme: 'sms',
      path: '+$phoneNumber',
      queryParameters: {
        'body': reminderMessage,
      },
    );

    final launched = await launchUrl(uri);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open SMS app'),
        ),
      );
    }
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
          SnackBar(content: Text('Image Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  Widget balanceText(double value) {
    return Text(
      'Rs. ${value.abs().toStringAsFixed(0)}',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: value > 0
            ? Colors.red
            : value < 0
                ? Colors.green
                : Colors.grey,
      ),
    );
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
                  child: Column(
                    children: [
                      Row(
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: sendWhatsAppReminder,
                              icon: const Icon(Icons.message),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: sendSmsReminder,
                              icon: const Icon(Icons.sms),
                              label: const Text('SMS'),
                            ),
                          ),
                        ],
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
                                            color: balance > 0
                                                ? Colors.red
                                                : balance < 0
                                                    ? Colors.green
                                                    : Colors.grey,
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

                                if (transactionsWithBalance.isEmpty)
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

                                ...transactionsWithBalance.map((transaction) {
                                  final type =
                                      transaction['type'].toString();

                                  final amount =
                                      (transaction['amount'] as num)
                                          .toDouble();

                                  final isGave = type == 'gave';

                                  final date =
                                      transaction['date'].toString();

                                  final note =
                                      transaction['note']?.toString() ?? '';

                                  final running =
                                      (transaction['running_balance']
                                              as num)
                                          .toDouble();

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
                                        '$date${note.isNotEmpty ? '\n$note' : ''}\nBalance after transaction: Rs. ${running.abs().toStringAsFixed(0)}',
                                      ),
                                      isThreeLine: true,
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Rs. ${amount.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: isGave
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          balanceText(running),
                                        ],
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
