import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../client_catalog/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/checkout_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CheckoutService _checkoutService = CheckoutService();
  bool _isProcessing = false;

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || cart.itemCount == 0) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final totalAmount = cart.totalAmount;
      
      await _checkoutService.placeWholesaleOrder(
        currentUser: user,
        items: cart.getCartItemsAsList(),
        totalAmount: totalAmount,
      );

      // Optimistically update local user state to avoid an extra DB read
      authProvider.updateLocalUserBalance(user.outstandingBalance + totalAmount);
      
      // Clear cart
      cart.clearCart();

      if (!mounted) return;

      // Navigate to success and prevent back navigation to checkout
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        (route) => route.isFirst, // Keep the root catalog screen
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: cart.itemCount == 0
          ? const Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                // Delivery Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Billed To:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(user?.businessName ?? 'Business Name', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user?.name ?? 'Client Name'),
                      Text(user?.phone ?? 'Phone'),
                    ],
                  ),
                ),
                
                // Item List
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text(
                          currencyFormatter.format(item.priceAtOrder * item.quantity),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),

                // Summary and Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Items:', style: TextStyle(fontSize: 16)),
                            Text('${cart.totalQuantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              currencyFormatter.format(cart.totalAmount),
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _isProcessing
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Place Wholesale Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your order has been sent to Shanmukha Enterprises. It has been added to your Khata.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(), // Goes back to root catalog
                  child: const Text('Back to Catalog'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
