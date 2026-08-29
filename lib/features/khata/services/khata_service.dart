import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/ledger_transaction_model.dart';

class KhataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uses a stream so if the Admin adds a manual cash payment, 
  // the client sees their balance and history update immediately.
  Stream<List<LedgerTransactionModel>> getClientLedger(String clientId) {
    return _firestore
        .collection('ledger')
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LedgerTransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
