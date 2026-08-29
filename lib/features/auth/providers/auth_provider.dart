import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = true; // Start loading to handle warm starts
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _initializeAuthListener();
  }

  // Single Source of Truth for Auth State
  void _initializeAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          _currentUser = await _authService.getUserData(firebaseUser.uid);
          if (_currentUser == null) {
            // User exists in Auth but not Firestore. Force sign out.
            _error = "Profile corrupted. Please contact support.";
            await FirebaseAuth.instance.signOut();
          }
        } catch (e) {
          _error = "Failed to load user data.";
        }
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      // We don't manually set _currentUser here; the listener above will catch it and hydrate it.
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    // Listener will catch the sign out and set isLoading to false
  }

  // Zero-cost optimization: Update balance locally
  void updateLocalUserBalance(double newBalance) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        role: _currentUser!.role,
        businessName: _currentUser!.businessName,
        outstandingBalance: newBalance,
        fcmToken: _currentUser!.fcmToken,
        createdAt: _currentUser!.createdAt,
        gstNumber: _currentUser!.gstNumber,
        deliveryAddress: _currentUser!.deliveryAddress,
      );
      notifyListeners();
    }
  }

  // Update profile locally without requiring a full fetch
  void updateLocalUserProfile({
    required String businessName,
    required String phone,
    String? gstNumber,
    String? deliveryAddress,
  }) {
     if (_currentUser != null) {
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        name: _currentUser!.name, // Name remains the same
        phone: phone,
        role: _currentUser!.role,
        businessName: businessName,
        outstandingBalance: _currentUser!.outstandingBalance,
        fcmToken: _currentUser!.fcmToken,
        createdAt: _currentUser!.createdAt,
        gstNumber: gstNumber,
        deliveryAddress: deliveryAddress,
      );
      notifyListeners();
    }
  }
}
