import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/admin_service.dart';
import 'admin_ledger_manager_screen.dart';
import '../../checkout/services/invoice_service.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  // CACHED STREAM: Prevents Firestore read burn on tab switching
  late final Stream<List<OrderModel>> _liveOrdersStream;
  late final Stream<List<ProductModel>> _inventoryStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _liveOrdersStream = _adminService.getLiveOrders();
    // Cache inventory stream to avoid burning reads on dialog open/close
    _inventoryStream = FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('stockQuantity', isLessThanOrEqualTo: 10)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());
  }

  void _showInventoryAlerts(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Low Stock Alerts ⚠️'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<ProductModel>>(
            stream: _inventoryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              
              final lowStockItems = snapshot.data ?? [];
              
              if (lowStockItems.isEmpty) {
                return const Text('All active items have sufficient stock.');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: lowStockItems.length,
                itemBuilder: (context, index) {
                  final item = lowStockItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${item.stockQuantity} left', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0).copyWith(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.orderId.substring(0, 8).toUpperCase()}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(order.businessName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text('${order.clientName} • ${DateFormat('MMM dd, hh:mm a').format(order.orderDate)}'),
            const Divider(height: 32),
            const Text('ITEMS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item.quantity}x ${item.productName}')),
                  Text(currencyFormatter.format(item.priceAtOrder * item.quantity)),
                ],
              ),
            )).toList(),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(currencyFormatter.format(order.totalAmount), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Invoice'),
                onPressed: () async {
                  // Fetch the client details needed for the invoice
                  final clientDoc = await FirebaseFirestore.instance.collection('users').doc(order.clientId).get();
                  if (clientDoc.exists) {
                    final clientDetails = UserModel.fromMap(clientDoc.data()!, clientDoc.id);
                    await InvoiceService().generateAndPrintInvoice(order: order, clientDetails: clientDetails);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusActionButtons(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionButtons(BuildContext context, OrderModel order) {
    if (order.status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              await _adminService.updateOrderStatus(order.orderId, 'processing');
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            }
          },
          child: const Text('Move to Processing'),
        ),
      );
    } else if (order.status == 'processing') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () async {
            try {
              await _adminService.updateOrderStatus(order.orderId, 'delivered');
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            }
          },
          child: const Text('Mark as Delivered'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Orders & Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: 'Inventory Alerts',
            onPressed: () => _showInventoryAlerts(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Client Khata',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLedgerManagerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _liveOrdersStream, // Using cached stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];
          
          final pending = orders.where((o) => o.status == 'pending').toList();
          final processing = orders.where((o) => o.status == 'processing').toList();
          final delivered = orders.where((o) => o.status == 'delivered').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(pending),
              _buildOrderList(processing),
              _buildOrderList(delivered),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orderList) {
    if (orderList.isEmpty) return const Center(child: Text('No orders found.'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orderList.length,
      itemBuilder: (context, index) {
        final order = orderList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(order.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${order.items.length} items • ${currencyFormatter.format(order.totalAmount)}\n'
              '${DateFormat('MMM dd, hh:mm a').format(order.orderDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showOrderDetails(context, order),
          ),
        );
      },
    );
  }
}
