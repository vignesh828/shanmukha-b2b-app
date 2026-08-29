import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../services/admin_service.dart';

class AdminLedgerManagerScreen extends StatefulWidget {
  const AdminLedgerManagerScreen({Key? key}) : super(key: key);

  @override
  _AdminLedgerManagerScreenState createState() => _AdminLedgerManagerScreenState();
}

class _AdminLedgerManagerScreenState extends State<AdminLedgerManagerScreen> {
  final AdminService _adminService = AdminService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  // CACHED STREAM
  late final Stream<List<UserModel>> _clientsStream;

  @override
  void initState() {
    super.initState();
    _clientsStream = _adminService.getClients();
  }

  void _showRecordPaymentDialog(BuildContext context, UserModel client) {
    final TextEditingController amountController = TextEditingController(); // Fixed leak
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Record Payment\n${client.businessName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Balance: ${currencyFormatter.format(client.outstandingBalance)}',
                     style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount Received (Cash)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () {
                  amountController.dispose();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isProcessing ? null : () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid positive amount')),
                    );
                    return;
                  }

                  setState(() => isProcessing = true);
                  
                  try {
                    await _adminService.recordPayment(
                      client: client,
                      amountReceived: amount,
                    );
                    if (!context.mounted) return;
                    
                    amountController.dispose();
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recorded ${currencyFormatter.format(amount)} from ${client.businessName}')),
                    );
                  } catch (e) {
                    setState(() => isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: isProcessing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Record Credit'),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Khata Manager'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _clientsStream, // Using cached stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final clients = snapshot.data ?? [];

          if (clients.isEmpty) {
            return const Center(child: Text('No clients found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: clients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final client = clients[index];
              final hasDues = client.outstandingBalance > 0;

              return ListTile(
                title: Text(client.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${client.name} • ${client.phone}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(client.outstandingBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: hasDues ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: () => _showRecordPaymentDialog(context, client),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Record Pay'),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
