import '../providers/customer_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import '../providers/transaction_providers.dart';
import '../providers/repository_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? selectedCustomerId;
  String transactionType = 'gave';

  DateTime selectedDate = DateTime.now();

  bool isSaving = false;

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Transaction Date',
    );

    if (date != null && mounted) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final customerId = selectedCustomerId!;

      await ref.read(transactionRepositoryProvider).addTransaction(
        customerId: customerId,
        type: transactionType,
        amount: double.parse(_amountController.text.trim()),
        note: _noteController.text.trim(),
        date: selectedDate,
      );

      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(topDebtorsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(monthlyTotalsProvider);
      ref.invalidate(customerTransactionsProvider(customerId));
      ref.invalidate(customerBalanceProvider(customerId));

      ref.invalidate(customersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: const Color(0xFF176B55),
        foregroundColor: Colors.white,
      ),

      body: customersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading customers: $error'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(customersProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        data: (customers) {
          if (customers.isEmpty) {
            return const Center(
              child: Text(
                'Please add a customer first.',
                style: TextStyle(fontSize: 17),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<int>(
                    initialValue: selectedCustomerId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose customer',
                      prefixIcon: Icon(Icons.person),
                    ),

                    items: customers.map((customer) {
                      return DropdownMenuItem<int>(
                        value: customer['id'] as int,
                        child: Text(
                          customer['name'].toString(),
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedCustomerId = value;
                      });
                    },

                    validator: (value) {
                      if (value == null) {
                        return 'Please select a customer';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('You Gave'),
                          selected: transactionType == 'gave',
                          selectedColor: Colors.red.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                transactionType = 'gave';
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ChoiceChip(
                          label: const Text('You Got'),
                          selected: transactionType == 'got',
                          selectedColor: Colors.green.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                transactionType = 'got';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Amount (Rs.)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        value?.trim() ?? '',
                      );

                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Transaction Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: selectDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}/'
                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                        '${selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Note (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Write a note...',
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176B55),
                        foregroundColor: Colors.white,
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Save Transaction',
                              style: TextStyle(fontSize: 17),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
