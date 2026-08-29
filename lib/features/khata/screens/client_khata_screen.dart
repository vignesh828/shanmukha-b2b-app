import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/khata_service.dart';
import '../../../models/ledger_transaction_model.dart';

class ClientKhataScreen extends StatefulWidget {
  const ClientKhataScreen({Key? key}) : super(key: key);

  @override
  _ClientKhataScreenState createState() => _ClientKhataScreenState();
}

class _ClientKhataScreenState extends State<ClientKhataScreen> {
  final KhataService _khataService = KhataService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  // CACHED STREAM: Prevents Firestore read burn on rebuilds
  late final Stream<List<LedgerTransactionModel>> _ledgerStream;

  @override
  void initState() {
    super.initState();
    final uid = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    if (uid != null) {
      _ledgerStream = _khataService.getClientLedger(uid);
    } else {
      _ledgerStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Khata / Ledger'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Total Outstanding Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(user.outstandingBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please clear dues promptly.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[200],
            child: const Text(
              'TRANSACTION HISTORY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<LedgerTransactionModel>>(
              stream: _ledgerStream, // Using cached stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions yet.'));
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isDebit = tx.type == 'debit'; 
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDebit ? Colors.red[100] : Colors.green[100],
                        child: Icon(
                          isDebit ? Icons.shopping_cart : Icons.payments,
                          color: isDebit ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        tx.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isDebit ? '+' : '-'} ${currencyFormatter.format(tx.amount)}',
                            style: TextStyle(
                              color: isDebit ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Bal: ${currencyFormatter.format(tx.resultingBalance)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
