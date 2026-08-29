import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final cart = Provider.of<CartProvider>(context);
    
    // Check if item is in cart and get its current quantity
    final cartItem = cart.items[product.id];
    final currentQuantity = cartItem?.quantity ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder (Use CachedNetworkImage in production)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: product.imageUrl.isNotEmpty 
                     ? DecorationImage(
                         image: NetworkImage(product.imageUrl), 
                         fit: BoxFit.cover
                       )
                     : null,
                ),
                width: double.infinity,
                child: product.imageUrl.isEmpty 
                    ? const Icon(Icons.image, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Product Info
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${product.unit}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                // Low stock indicator for Admins/Clients if needed
                if (product.stockQuantity > 0 && product.stockQuantity <= 10)
                  const Text('Low Stock', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormatter.format(product.price),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Add/Remove Button Area (Wholesale optimized)
            _buildQuantityControls(context, cart, currentQuantity),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context, CartProvider cart, int currentQuantity) {
    if (currentQuantity == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => cart.addItem(product),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: const Text('ADD'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white, size: 20),
            onPressed: () => cart.decrementItem(product.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Tap quantity to open manual input dialog for bulk ordering
          GestureDetector(
            onTap: () => _showBulkEditDialog(context, cart, currentQuantity),
            child: Text(
              '$currentQuantity',
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () => cart.addItem(product),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // Allow B2B users to type "500" instead of tapping 500 times
  void _showBulkEditDialog(BuildContext context, CartProvider cart, int currentQuantity) {
    final TextEditingController _controller = TextEditingController(text: currentQuantity.toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter quantity for ${product.name}'),
        content: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: product.unit,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(_controller.text) ?? currentQuantity;
              cart.setItemQuantity(product, newQty);
              Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }
}
