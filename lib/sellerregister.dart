import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'sellerlogin.dart';

class SellerRegister extends StatefulWidget {
  const SellerRegister({super.key});

  @override
  State<SellerRegister> createState() => _SellerRegisterState();
}

class _SellerRegisterState extends State<SellerRegister> {
  final _businessNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Generate random seller ID
  String _generateSellerId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _register() async {
    if (_businessNameController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final sellerId = _generateSellerId();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('seller_account')
            .doc(sellerId)
            .set({
          'businessName': _businessNameController.text.trim(),
          'contactNumber': _contactNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'password': _passwordController.text.trim(), // Consider encrypting
          'sellerId': sellerId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller account created successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SellerLogin()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.08),
              Color(0xFFEEE8FD),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Center(
                      child: Icon(Icons.store, size: 90, color: Color(0xFF6C45F3)),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C45F3).withOpacity(0.08),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _businessNameController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Business Name',
                              prefixIcon: const Icon(Icons.business, color: Color(0xFF6C45F3)),
                              filled: true,
                              fillColor: Color(0xFFF6F3FF),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _contactNumberController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Business Contact Number',
                              prefixIcon: const Icon(Icons.phone, color: Color(0xFF6C45F3)),
                              filled: true,
                              fillColor: Color(0xFFF6F3FF),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _addressController,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Business Address',
                              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6C45F3)),
                              filled: true,
                              fillColor: Color(0xFFF6F3FF),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF6C45F3)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Color(0xFF6C45F3)),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Color(0xFFF6F3FF),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6C45F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                elevation: 0,
                              ),
                              child: const Text('Register Seller Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}