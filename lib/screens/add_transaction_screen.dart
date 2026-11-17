
import 'package:material_ui/material_ui.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  int? selectedCustomerId;
  String transactionType = 'gave';
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final data = await DatabaseService.instance.getCustomers();

      if (!mounted) return;

      setState(() {
        customers = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await DatabaseService.instance.addTransaction(
        customerId: selectedCustomerId!,
        type: transactionType,
        amount: double.parse(_amountController.text.trim()),
        note: _noteController.text.trim(),
      );

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
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: const Color(0xFF176B55),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
              ? const Center(
                  child: Text(
                    'Please add a customer first.',
                    style: TextStyle(fontSize: 17),
                  ),
                )
              : SingleChildScrollView(
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
                              child: Text(customer['name']),
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
                                  setState(() {
                                    transactionType = 'gave';
                                  });
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
                                  setState(() {
                                    transactionType = 'got';
                                  });
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
                          keyboardType: const TextInputType.numberWithOptions(
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
                ),
    );
  }
}
