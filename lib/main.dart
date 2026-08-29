import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/client_catalog/providers/cart_provider.dart';
import 'features/client_catalog/screens/client_catalog_screen.dart';
import 'features/khata/screens/client_khata_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/checkout/screens/checkout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Prati sari check chesi force initialize chestham
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase init error (Ignored for local UI testing): $e");
    // Linux desktop lo firebase native link leka fail aithe, dummy app instance create chesi crash apocchu
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {}
  }

  runApp(const ShanmukhaApp());
}

class ShanmukhaApp extends StatelessWidget {
  const ShanmukhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Shanmukha Enterprises B2B',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const B2BHomeDashboard(),
      ),
    );
  }
}

class B2BHomeDashboard extends StatelessWidget {
  const B2BHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shanmukha Enterprises - B2B Hub'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              'Auth / Login',
              Icons.lock,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthWrapper())),
            ),
            _buildFeatureCard(
              context,
              'Client Catalog',
              Icons.store,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCatalogScreen())),
            ),
            _buildFeatureCard(
              context,
              'Khata / Ledger',
              Icons.book,
              Colors.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientKhataScreen())),
            ),
            _buildFeatureCard(
              context,
              'Admin Dashboard',
              Icons.admin_panel_settings,
              Colors.red,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            ),
            _buildFeatureCard(
              context,
              'Checkout / Invoice',
              Icons.payment,
              Colors.teal,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
            ),
            _buildFeatureCard(
              context,
              'Profile',
              Icons.person,
              Colors.indigo,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
