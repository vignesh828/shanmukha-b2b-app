// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'admin' or 'client'
  final String businessName;
  final double outstandingBalance;
  final String fcmToken;
  final DateTime createdAt;
  final String? gstNumber;
  final String? deliveryAddress;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.businessName,
    this.outstandingBalance = 0.0,
    required this.fcmToken,
    required this.createdAt,
    this.gstNumber,
    this.deliveryAddress,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'client',
      businessName: map['businessName'] ?? '',
      outstandingBalance: (map['outstandingBalance'] ?? 0.0).toDouble(),
      fcmToken: map['fcmToken'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      gstNumber: map['gstNumber'],
      deliveryAddress: map['deliveryAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'businessName': businessName,
      'outstandingBalance': outstandingBalance,
      'fcmToken': fcmToken,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'gstNumber': gstNumber,
      'deliveryAddress': deliveryAddress,
    };
  }
}
