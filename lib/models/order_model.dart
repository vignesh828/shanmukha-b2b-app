// lib/models/order_model.dart

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtOrder;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtOrder,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      priceAtOrder: (map['priceAtOrder'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'priceAtOrder': priceAtOrder,
    };
  }
}

class OrderModel {
  final String orderId;
  final String clientId;
  final String clientName; // Denormalized to avoid extra lookup for admin dashboard
  final String businessName; // Denormalized for admin UI
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'processing', 'delivered', 'cancelled'
  final DateTime orderDate;

  OrderModel({
    required this.orderId,
    required this.clientId,
    required this.clientName,
    required this.businessName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      orderId: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      businessName: map['businessName'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      orderDate: map['orderDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['orderDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'businessName': businessName,
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate.millisecondsSinceEpoch,
    };
  }
}
