import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of active products
  // Using a stream means if Admin updates price/stock, clients see it immediately.
  // Note: Firestore charges 1 read per document returned per listener update.
  Stream<List<ProductModel>> getActiveProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        // If you add ordering, you need an index in Firestore:
        // .orderBy('category')
        // .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Alternative Future-based approach if you want to save reads.
  // Clients pull to refresh instead of streaming.
  Future<List<ProductModel>> fetchActiveProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
