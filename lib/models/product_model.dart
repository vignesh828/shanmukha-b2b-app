// lib/models/product_model.dart

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String unit; // e.g., 'kg', 'box', 'piece'
  final bool isActive;
  final int stockQuantity; // Added for inventory tracking

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.unit,
    this.isActive = true,
    this.stockQuantity = 0, // Default to 0 if not set
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      unit: map['unit'] ?? 'unit',
      isActive: map['isActive'] ?? true,
      stockQuantity: map['stockQuantity']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'unit': unit,
      'isActive': isActive,
      'stockQuantity': stockQuantity,
    };
  }
}
