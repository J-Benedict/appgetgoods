import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'colors.dart';
import 'cart_items.dart';
import 'checkout_bar.dart';
import 'productdetail.dart';
import 'login.dart';
import 'dart:math';
import 'checkout.dart';
import 'transition_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAllSelected = false;
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (_auth.currentUser == null) {
      print('No user logged in');
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('Loading cart for user: ${_auth.currentUser!.uid}');
      
      // First, ensure user document exists
      final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        print('Creating user document for: ${_auth.currentUser!.uid}');
        await userRef.set({
          'email': _auth.currentUser!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': _auth.currentUser!.uid,
        });
      }

      print('Fetching cart items from: users/${_auth.currentUser!.uid}/cart');
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .get()
          .then((snapshot) => snapshot as QuerySnapshot<Map<String, dynamic>>);

      print('Found ${cartSnapshot.docs.length} cart items');
      setState(() {
        _cartItems = cartSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'productId': data['productId'],
            'title': data['name'],
            'price': data['price'],
            'imageUrl': data['imageUrl'],
            'quantity': data['quantity'],
            'selected': false,
            'stock': data['stock'],
            'sellerId': data['sellerId'],
            'sellerName': data['sellerName'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cart: $e');
      print('Error details: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSelectAll(bool? value) async {
    setState(() {
      _isAllSelected = value ?? false;
      for (var item in _cartItems) {
        item['selected'] = _isAllSelected;
      }
    });
  }

  Future<void> _toggleSelectItem(String id, bool? value) async {
    setState(() {
      final item = _cartItems.firstWhere((item) => item['id'] == id);
      if (item['stock'] == 0 && value == true) {
        // Prevent selecting out of stock
        return;
      }
      item['selected'] = value ?? false;
      _isAllSelected = _cartItems.where((item) => item['stock'] > 0).every((item) => item['selected']);
    });
  }

  Future<void> _updateQuantity(String id, int newQuantity) async {
    if (newQuantity < 1) return;
    
    final item = _cartItems.firstWhere((item) => item['id'] == id);
    if (newQuantity > item['stock']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity cannot exceed available stock')),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(id)
          .update({'quantity': newQuantity});

      setState(() {
        item['quantity'] = newQuantity;
      });
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> _removeItem(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(id)
          .delete();

      setState(() {
        _cartItems.removeWhere((item) => item['id'] == id);
      });
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  String get _totalAmount {
    double total = 0;
    for (var item in _cartItems) {
      if (item['selected']) {
        total += double.parse(item['price'].toString()) * item['quantity'];
      }
    }
    return '₱${total.toStringAsFixed(2)}';
  }

  int get _selectedItemCount {
    return _cartItems.where((item) => item['selected']).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.08),
              Color(0xFFEEE8FD),
              Color(0xFFE9E3FC),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF6C45F3), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text('Cart', style: TextStyle(color: Color(0xFF6C45F3), fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF6C45F3).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = !_isEditMode;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        foregroundColor: Color(0xFF6C45F3),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: Text(_isEditMode ? 'Done' : 'Edit'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _auth.currentUser == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Log in to add your favorite items in the cart',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                slideFadeRoute(const Login()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6C45F3),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your cart is empty',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: ListView.separated(
                            itemCount: _cartItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              if (_isEditMode) {
                                return Dismissible(
                                  key: Key(item['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                                  ),
                                  onDismissed: (direction) {
                                    _removeItem(item['id']);
                                  },
                                  child: CartItem(
                                    imageUrl: item['imageUrl'],
                                    title: item['title'],
                                    price: '₱${(item['price'] as num).toStringAsFixed(0)}',
                                    isSelected: item['selected'],
                                    onSelect: (value) => _toggleSelectItem(item['id'], value),
                                    quantity: item['quantity'],
                                    onQuantityChanged: (quantity) =>
                                        _updateQuantity(item['id'], quantity),
                                    onRemove: () => _removeItem(item['id']),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        slideFadeRoute(ProductDetailPage(productId: item['productId'])),
                                      );
                                    },
                                    stock: item['stock'] ?? 0,
                                    animate: true,
                                  ),
                                );
                              } else {
                                return CartItem(
                                  imageUrl: item['imageUrl'],
                                  title: item['title'],
                                  price: '₱${(item['price'] as num).toStringAsFixed(0)}',
                                  isSelected: item['selected'],
                                  onSelect: (value) => _toggleSelectItem(item['id'], value),
                                  quantity: item['quantity'],
                                  onQuantityChanged: (quantity) =>
                                      _updateQuantity(item['id'], quantity),
                                  onRemove: () => _removeItem(item['id']),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      slideFadeRoute(ProductDetailPage(productId: item['productId'])),
                                    );
                                  },
                                  stock: item['stock'] ?? 0,
                                  animate: true,
                                );
                              }
                            },
                          ),
                        ),
            ),
            if (_cartItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C45F3).withOpacity(0.10),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAllSelected,
                        onChanged: _toggleSelectAll,
                        activeColor: Color(0xFF6C45F3),
                      ),
                      const Text('Select All', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Expanded(
                        flex: 0,
                        child: Text('Total: $_totalAmount',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C45F3), fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 100, maxWidth: 140),
                        child: ElevatedButton(
                          onPressed: () {
                            final selectedItems = _cartItems.where((item) => item['selected'] && (item['stock'] ?? 0) > 0).toList();
                            if (selectedItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select in-stock items to checkout')),
                              );
                              return;
                            }
                            final excludedCount = _cartItems.where((item) => item['selected'] && (item['stock'] ?? 0) == 0).length;
                            if (excludedCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$excludedCount out-of-stock item(s) were excluded from checkout.')),
                              );
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(
                                  products: selectedItems,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6C45F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          child: Text('Checkout', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrdersForSelectedItems() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final nickname = userData?['nickname'] ?? user.email;
    final userId = userData?['userId'] ?? user.uid;
    final selectedItems = _cartItems.where((item) => item['selected']).toList();
    for (var item in selectedItems) {
      final orderId = _generateOrderId();
      final orderData = {
        'orderId': orderId,
        'imageUrl': item['imageUrl'],
        'price': item['price'],
        'id': item['productId'],
        'name': item['title'],
        'sellerId': item['sellerId'] ?? 'unknown',
        'sellerName': item['sellerName'] ?? 'Unknown Seller',
        'orderDate': DateTime.now(),
        'orderStatus': 'To Ship',
        'payment': 'Cash on Delivery',
        'address': 'Default Address',
        'totalAmount': item['price'] * item['quantity'],
        'nickname': nickname,
        'userId': userId,
      };
      await _firestore.collection('orders').doc(orderId).set(orderData);
      await _removeItem(item['id']);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orders placed successfully!')),
    );
  }

  String _generateOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(10, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}