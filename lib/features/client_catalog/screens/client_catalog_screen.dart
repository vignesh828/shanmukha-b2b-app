import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../../../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_summary_bottom_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../khata/screens/client_khata_screen.dart';

import '../../profile/screens/profile_screen.dart';

class ClientCatalogScreen extends StatefulWidget {
  const ClientCatalogScreen({Key? key}) : super(key: key);

  @override
  _ClientCatalogScreenState createState() => _ClientCatalogScreenState();
}

class _ClientCatalogScreenState extends State<ClientCatalogScreen> {
  final ProductService _productService = ProductService();
  
  // CACHED STREAM: Prevents Firestore read burn on setState
  late final Stream<List<ProductModel>> _productsStream;
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productsStream = _productService.getActiveProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wholesale Catalog',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              authProvider.currentUser?.businessName ?? 'Client',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientKhataScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _productsStream, // Using cached stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading products: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No active products found.'));
          }

          // Zero-cost search: filters locally in memory
          final filteredProducts = snapshot.data!.where((p) {
            return p.name.toLowerCase().contains(_searchQuery) || 
                   p.category.toLowerCase().contains(_searchQuery);
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: filteredProducts[index]);
            },
          );
        },
      ),
      bottomSheet: const CartSummaryBottomSheet(),
    );
  }
}
