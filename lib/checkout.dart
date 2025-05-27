import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'postpurchase.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  CheckoutPage({required this.products});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedAddressId;
  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _addresses = [];
  String _shippingOption = 'Standard Local';
  String _paymentMethod = 'Cash on Delivery';
  double _walletBalance = 0.0;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadWalletBalance();
  }

  Future<void> _loadAddresses() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();
      setState(() {
        _addresses = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        if (_addresses.isNotEmpty) {
          _selectedAddressId = _addresses[0]['id'];
          _selectedAddress = _addresses[0];
        }
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    final user = _auth.currentUser;
    if (user != null) {
      final walletDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_wallet')
          .doc('wallet')
          .get();
      setState(() {
        _walletBalance = (walletDoc.data()?['TotalBalance'] ?? 0.0).toDouble();
      });
    }
  }

  double get _productsSubtotal => widget.products.fold(0.0, (sum, item) => sum + (item['price'] as num) * (item['quantity'] as num));
  double get _shippingFee => _shippingOption == 'Standard Local' ? 0.0 : 100.0;
  double get _total => _productsSubtotal + _shippingFee;

  void _selectAddress() async {
    if (_addresses.isEmpty) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => ListView(
        children: _addresses.map((address) {
          return ListTile(
            title: Text(address['address'] ?? ''),
            subtitle: Text(address['id']),
            selected: _selectedAddressId == address['id'],
            onTap: () => Navigator.pop(context, address),
          );
        }).toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedAddressId = selected['id'];
        _selectedAddress = selected;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address.')),
      );
      return;
    }
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      setState(() => _isPlacingOrder = false);
      return;
    }
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final nickname = userData?['nickname'] ?? user.email;
    final userId = userData?['userId'] ?? user.uid;
    if (_paymentMethod == 'GG Wallet') {
      if (_walletBalance < _total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsufficient Balance, Either Choose a Different Option or Load Sufficient Balance')),
        );
        setState(() => _isPlacingOrder = false);
        return;
      }
      // Deduct from wallet
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_wallet')
          .doc('wallet')
          .update({'TotalBalance': FieldValue.increment(-_total)});
    }
    // Place an order for each product
    for (final product in widget.products) {
      final orderId = _generateOrderId();
      final shippingMethod = _shippingOption == 'Standard Local' ? 'Standard Shipping' : 'Express Shipping';
      final sellerId = (product['sellerId'] != null && product['sellerId'] != 'unknown') ? product['sellerId'] : '';
      final sellerName = (product['sellerName'] != null && product['sellerName'] != 'Unknown Seller') ? product['sellerName'] : '';
      final orderData = {
        'orderId': orderId,
        'imageUrl': product['imageUrl'],
        'price': product['price'],
        'quantity': product['quantity'],
        'id': product['productId'],
        'name': product['title'],
        'sellerId': sellerId,
        'sellerName': sellerName,
        'orderDate': DateTime.now(),
        'orderStatus': 'To Ship',
        'payment': _paymentMethod,
        'shippingMethod': shippingMethod,
        'address': _selectedAddress?['address'] ?? '',
        'totalAmount': (product['price'] as num) * (product['quantity'] as num) + _shippingFee,
        'nickname': nickname,
        'userId': userId,
      };
      await _firestore.collection('orders').doc(orderId).set(orderData);
      // Deduct stock from product
      await _firestore.collection('products').doc(product['productId']).update({
        'stock': FieldValue.increment(-product['quantity'])
      });
      // Remove item from cart after ordering
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .where('productId', isEqualTo: product['productId'])
          .get()
          .then((snapshot) async {
            for (var doc in snapshot.docs) {
              await doc.reference.delete();
            }
          });
    }
    setState(() => _isPlacingOrder = false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PostPurchasePage(orderId: '')),
      );
    }
  }

  String _generateOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(10, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C45F3);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          color: purple,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 24,
                      ),
                      const SizedBox(width: 12),
                      Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              purple.withOpacity(0.08),
              Color(0xFFEEE8FD),
              Color(0xFFE9E3FC),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Address Container
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: purple.withOpacity(0.10), blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: InkWell(
                  onTap: _selectAddress,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: purple, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _selectedAddress == null
                            ? const Text('Select Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAddress?['address'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (_selectedAddress?['phone'] != null)
                                    Text(_selectedAddress?['phone'] ?? '', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              // Products List
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: purple.withOpacity(0.10), blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ...widget.products.map((product) {
                      int productIndex = widget.products.indexOf(product);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product['imageUrl'] ?? '',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['sellerName'] ?? 'Unknown Seller', style: TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text('₱${product['price'].toStringAsFixed(2)}', style: TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(24),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              splashRadius: 18,
                                              onPressed: () {
                                                setState(() {
                                                  if (widget.products[productIndex]['quantity'] > 1) {
                                                    widget.products[productIndex]['quantity']--;
                                                  }
                                                });
                                              },
                                            ),
                                            SizedBox(
                                              width: 32,
                                              child: Center(
                                                child: Text(
                                                  widget.products[productIndex]['quantity'].toString(),
                                                  style: TextStyle(
                                                    color: purple,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              splashRadius: 18,
                                              onPressed: (widget.products[productIndex]['quantity'] >= (widget.products[productIndex]['stock'] ?? 1))
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        if (widget.products[productIndex]['quantity'] < (widget.products[productIndex]['stock'] ?? 1)) {
                                                          widget.products[productIndex]['quantity']++;
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Cannot exceed available stock.')),
                                                          );
                                                        }
                                                      });
                                                    },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Shipping Option Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: purple.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 6))],
                  border: Border.all(color: purple.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('Shipping Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: purple)),
                    ),
                    RadioListTile<String>(
                      value: 'Standard Local',
                      groupValue: _shippingOption,
                      onChanged: (val) => setState(() => _shippingOption = val!),
                      title: const Text('Standard Local (₱0)', style: TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: purple,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      value: 'Express Shipping',
                      groupValue: _shippingOption,
                      onChanged: (val) => setState(() => _shippingOption = val!),
                      title: const Text('Express Shipping (₱100)', style: TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: purple,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₱${_total.toStringAsFixed(2)}', style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              // Payment Methods Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: purple.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 6))],
                  border: Border.all(color: purple.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: purple)),
                    ),
                    RadioListTile<String>(
                      value: 'Cash on Delivery',
                      groupValue: _paymentMethod,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                      title: const Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: purple,
                      secondary: const Icon(Icons.money),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      value: 'GG Wallet',
                      groupValue: _paymentMethod,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                      title: Row(
                        children: [
                          const Text('GG Wallet', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('₱${_walletBalance.toStringAsFixed(2)}', style: TextStyle(color: purple)),
                          ),
                        ],
                      ),
                      activeColor: purple,
                      secondary: const Icon(Icons.account_balance_wallet),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              // Payment Details Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: purple.withOpacity(0.07), blurRadius: 14, offset: Offset(0, 6))],
                  border: Border.all(color: purple.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: purple)),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Merchandise Subtotal', '₱${_productsSubtotal.toStringAsFixed(2)}'),
                    _buildDetailRow('Shipping Subtotal', '₱${_shippingFee.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildDetailRow('Total Payment', '₱${_total.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
              // Place Order Button
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withOpacity(0.18),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Place Order'),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class PostPurchasePage extends StatelessWidget {
  final String orderId;
  const PostPurchasePage({required this.orderId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C45F3);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: purple),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text('Order Placed', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              purple.withOpacity(0.06),
              Color(0xFFEEE8FD),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: purple.withOpacity(0.10),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your order has been placed!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    orderId.isNotEmpty ? 'Order ID: $orderId' : '',
                    style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        elevation: 0,
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
