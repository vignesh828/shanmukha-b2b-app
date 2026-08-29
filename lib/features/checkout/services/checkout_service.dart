import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/order_model.dart';
import '../../../models/ledger_transaction_model.dart';
import '../../../models/user_model.dart';

class CheckoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uses a batched write to ensure Order and Ledger entry are created atomically.
  // This also updates the user's outstanding balance, keeping the architecture zero-cost
  // by avoiding Cloud Functions entirely.
  Future<void> placeWholesaleOrder({
    required UserModel currentUser,
    required List<OrderItem> items,
    required double totalAmount,
  }) async {
    final batch = _firestore.batch();
    
    // 1. Create the Order Reference
    final orderRef = _firestore.collection('orders').doc();
    final newOrder = OrderModel(
      orderId: orderRef.id,
      clientId: currentUser.uid,
      clientName: currentUser.name, // Denormalized for zero-cost Admin reads
      businessName: currentUser.businessName, // Denormalized
      items: items,
      totalAmount: totalAmount,
      status: 'pending',
      orderDate: DateTime.now(),
    );

    // 2. Calculate new balance
    final newBalance = currentUser.outstandingBalance + totalAmount;

    // 3. Create the Ledger Transaction Reference
    final ledgerRef = _firestore.collection('ledger').doc();
    final newLedgerEntry = LedgerTransactionModel(
      transactionId: ledgerRef.id,
      clientId: currentUser.uid,
      amount: totalAmount,
      type: 'debit',
      description: 'Order #${orderRef.id.substring(0, 6).toUpperCase()}',
      referenceId: orderRef.id,
      date: DateTime.now(),
      resultingBalance: newBalance,
    );

    // 4. User Reference for balance update
    final userRef = _firestore.collection('users').doc(currentUser.uid);

    // Add to batch
    batch.set(orderRef, newOrder.toMap());
    batch.set(ledgerRef, newLedgerEntry.toMap());
    batch.update(userRef, {'outstandingBalance': newBalance});

    // Commit batch
    await batch.commit();
  }
}
