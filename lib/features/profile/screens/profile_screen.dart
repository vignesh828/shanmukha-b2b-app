import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  late TextEditingController _gstController;
  late TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current state
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _businessNameController = TextEditingController(text: user?.businessName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _gstController = TextEditingController(text: user?.gstNumber ?? '');
    _addressController = TextEditingController(text: user?.deliveryAddress ?? '');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'businessName': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'deliveryAddress': _addressController.text.trim(),
      });

      // 2. Update Local State (Zero-cost, prevents a refetch)
      authProvider.updateLocalUserProfile(
        businessName: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        gstNumber: _gstController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update your business details for billing and delivery.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business / Hotel Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GST Number (Optional)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving 
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
