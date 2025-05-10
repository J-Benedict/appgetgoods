import 'package:flutter/material.dart';
import 'colors.dart';
import 'cart_items.dart';
import 'checkout_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': '1',
      'title': 'Nike Air 270 React',
      'price': '₱1,999',
      'image': 'https://cdn.builder.io/api/v1/image/assets/TEMP/337a322203f13d6fea6cbbb28bb787ab34f9fcd2',
      'quantity': 1,
      'selected': false,
    },
    {
      'id': '2',
      'title': 'Nike Air 270 React',
      'price': '₱1,999',
      'image': 'https://cdn.builder.io/api/v1/image/assets/TEMP/337a322203f13d6fea6cbbb28bb787ab34f9fcd2',
      'quantity': 1,
      'selected': false,
    },
    {
      'id': '3',
      'title': 'Nike Air 270 React',
      'price': '₱1,999',
      'image': 'https://cdn.builder.io/api/v1/image/assets/TEMP/337a322203f13d6fea6cbbb28bb787ab34f9fcd2',
      'quantity': 1,
      'selected': false,
    },
  ];

  bool _isAllSelected = false;

  void _toggleSelectAll(bool? value) {
    setState(() {
      _isAllSelected = value ?? false;
      for (var item in _cartItems) {
        item['selected'] = _isAllSelected;
      }
    });
  }

  void _toggleSelectItem(String id, bool? value) {
    setState(() {
      final item = _cartItems.firstWhere((item) => item['id'] == id);
      item['selected'] = value ?? false;
      _isAllSelected = _cartItems.every((item) => item['selected']);
    });
  }

  void _updateQuantity(String id, int newQuantity) {
    if (newQuantity < 1) return;
    setState(() {
      final item = _cartItems.firstWhere((item) => item['id'] == id);
      item['quantity'] = newQuantity;
    });
  }

  String get _totalAmount {
    double total = 0;
    for (var item in _cartItems) {
      if (item['selected']) {
        total += 1999 * item['quantity']; // Replace with actual price calculation
      }
    }
    return '₱${total.toStringAsFixed(2)}';
  }

  int get _selectedItemCount {
    return _cartItems.where((item) => item['selected']).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Container(
            height: 110,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderGrey,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.primary, size: 28),
                  onPressed: () {
                    Navigator.pop(context); // Go back to previous screen
                  },
                ),

                const SizedBox(width: 12),
                const Text(
                  'Cart',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.lightGrey,
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                itemCount: _cartItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return CartItem(
                    imageUrl: item['image'],
                    title: item['title'],
                    price: item['price'],
                    isSelected: item['selected'],
                    onSelect: (value) => _toggleSelectItem(item['id'], value),
                    quantity: item['quantity'],
                    onQuantityChanged: (quantity) =>
                        _updateQuantity(item['id'], quantity),
                  );
                },
              ),
            ),
          ),
          CheckoutBar(
            isAllSelected: _isAllSelected,
            onSelectAll: _toggleSelectAll,
            total: _totalAmount,
            itemCount: _selectedItemCount,
            onCheckout: () {
              // Implement checkout logic
            },
          ),
        ],
      ),
    );
  }
}