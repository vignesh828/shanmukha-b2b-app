import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product_model.dart';
import '../../../models/order_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, OrderItem> _items = {};

  Map<String, OrderItem> get items => _items;

  int get itemCount {
    return _items.length; // Distinct items
  }

  int get totalQuantity {
    int total = 0;
    _items.forEach((key, item) {
      total += item.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.priceAtOrder * item.quantity;
    });
    return total;
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      // Update quantity if item already exists
      _items.update(
        product.id,
        (existingItem) => OrderItem(
          productId: existingItem.productId,
          productName: existingItem.productName,
          priceAtOrder: existingItem.priceAtOrder,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        product.id,
        () => OrderItem(
          productId: product.id,
          productName: product.name,
          priceAtOrder: product.price,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void decrementItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => OrderItem(
          productId: existingItem.productId,
          productName: existingItem.productName,
          priceAtOrder: existingItem.priceAtOrder,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }
  
  void setItemQuantity(ProductModel product, int newQuantity) {
     if (newQuantity <= 0) {
        _items.remove(product.id);
     } else {
        if (_items.containsKey(product.id)) {
          _items.update(
            product.id,
            (existingItem) => OrderItem(
              productId: existingItem.productId,
              productName: existingItem.productName,
              priceAtOrder: existingItem.priceAtOrder,
              quantity: newQuantity,
            ),
          );
        } else {
          _items.putIfAbsent(
            product.id,
            () => OrderItem(
              productId: product.id,
              productName: product.name,
              priceAtOrder: product.price,
              quantity: newQuantity,
            ),
          );
        }
     }
     notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Used for saving to firestore
  List<OrderItem> getCartItemsAsList() {
    return _items.values.toList();
  }
}
