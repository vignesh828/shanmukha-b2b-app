import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../models/ledger_transaction_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream all orders to populate the Kanban board.
  // In a large production app, we would limit this or only fetch active statuses,
  // but for the MVP, sorting by date descending is efficient enough.
  Stream<List<OrderModel>> getLiveOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(100) // Limit to save reads on free tier
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Zero-cost direct status update (No Cloud Functions)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  // Get all clients for the Ledger Manager
  Stream<List<UserModel>> getClients() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) {
      final clients = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort locally to avoid needing a composite index in Firestore
      clients.sort((a, b) => a.businessName.compareTo(b.businessName));
      return clients;
    });
  }

  // Zero-cost Ledger update (Batch write, atomic transaction)
  Future<void> recordPayment({
    required UserModel client,
    required double amountReceived,
  }) async {
    final batch = _firestore.batch();
    
    final newBalance = client.outstandingBalance - amountReceived;
    
    // 1. Create Ledger entry
    final ledgerRef = _firestore.collection('ledger').doc();
    final ledgerEntry = LedgerTransactionModel(
      transactionId: ledgerRef.id,
      clientId: client.uid,
      amount: amountReceived,
      type: 'credit',
      description: 'Cash Payment Received',
      date: DateTime.now(),
      resultingBalance: newBalance,
    );
    
    // 2. Update user document
    final userRef = _firestore.collection('users').doc(client.uid);

    batch.set(ledgerRef, ledgerEntry.toMap());
    batch.update(userRef, {'outstandingBalance': newBalance});
    
    await batch.commit();
  }
}
