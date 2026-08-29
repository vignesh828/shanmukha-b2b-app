import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../client_catalog/screens/client_catalog_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AuthProvider is now the single source of truth and handles the warm-start hydrating
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.currentUser == null) {
          return const LoginScreen();
        }

        if (authProvider.currentUser!.role == 'admin') {
          return const AdminDashboardScreen();
        } else {
          return const ClientCatalogScreen();
        }
      },
    );
  }
}
