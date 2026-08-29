// lib/models/ledger_transaction_model.dart

class LedgerTransactionModel {
  final String transactionId;
  final String clientId;
  final double amount;
  final String type; // 'credit' (payment received) or 'debit' (order placed)
  final String description; // e.g., 'Payment received by Cash', 'Order #1234'
  final String? referenceId; // orderId if type == 'debit'
  final DateTime date;
  final double resultingBalance; // Snapshot of balance after transaction for auditing

  LedgerTransactionModel({
    required this.transactionId,
    required this.clientId,
    required this.amount,
    required this.type,
    required this.description,
    this.referenceId,
    required this.date,
    required this.resultingBalance,
  });

  factory LedgerTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return LedgerTransactionModel(
      transactionId: id,
      clientId: map['clientId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'debit',
      description: map['description'] ?? '',
      referenceId: map['referenceId'],
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
      resultingBalance: (map['resultingBalance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'amount': amount,
      'type': type,
      'description': description,
      'referenceId': referenceId,
      'date': date.millisecondsSinceEpoch,
      'resultingBalance': resultingBalance,
    };
  }
}
