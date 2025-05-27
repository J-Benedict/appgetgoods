import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:getgoods/homepage.dart';
import 'package:getgoods/login.dart';
import 'mobilebody.dart'; 
import 'profile.dart';
import 'cart.dart';
import 'ggmall.dart';
import 'productdetail.dart';
import 'transition_helpers.dart';

class Categorypage extends StatefulWidget {
  const Categorypage({super.key});

  @override
  State<Categorypage> createState() => _CategorypageState();
}

class _CategorypageState extends State<Categorypage> {
  final int _selectedIndex = 1;
  String? _selectedCategory;
  int? _tappedIndex; // For animation

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyMobileBody()),
        );
        break;
      case 1:
        // Already on Categories page
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Ggmall()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profilepage()),
        );
        break;
    }
  }

  final categories = [
    {'title': 'Shoes', 'icon': Icons.directions_run, 'id': 'Shoes'},
    {'title': 'Books', 'icon': Icons.book, 'id': 'Books'},
    {'title': 'Electronics', 'icon': Icons.devices, 'id': 'Electronics'},
    {'title': 'Clothing', 'icon': Icons.checkroom, 'id': 'Clothes'},
    {'title': 'Figurines', 'icon': Icons.toys, 'id': 'Figurines'},
    {'title': 'Foods', 'icon': Icons.fastfood, 'id': 'Foods'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          color: Color(0xFF6C45F3),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      if (_selectedCategory == null)
                        const Text('Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1))
                      else
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => setState(() => _selectedCategory = null),
                            ),
                            Text(_selectedCategory!.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF6C45F3),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.shopping_cart, color: Colors.white),
                          onPressed: () => Navigator.push(
                            context,
                            slideFadeRoute(const CartScreen()),
                          ),
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
        child: _selectedCategory == null
            ? _buildCategoryGrid()
            : _buildProductGrid(_selectedCategory!),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final item = categories[index];
          return MouseRegion(
            onEnter: (_) => setState(() => _tappedIndex = index),
            onExit: (_) => setState(() => _tappedIndex = null),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _tappedIndex = index),
              onTapUp: (_) => setState(() => _tappedIndex = null),
              onTapCancel: () => setState(() => _tappedIndex = null),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryProductsPage(
                      categoryId: item['id'] as String,
                      categoryTitle: item['title'] as String,
                    ),
                  ),
                );
              },
              child: AnimatedScale(
                scale: _tappedIndex == index ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C45F3).withOpacity(0.13),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: _tappedIndex == index
                          ? Color(0xFF6C45F3).withOpacity(0.5)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 60,
                        color: Color(0xFF6C45F3),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        (item['title'] as String? ?? '').toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6C45F3),
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found in this category'));
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        final childAspectRatio = screenWidth > 600 ? 0.8 : 0.75;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: snapshot.data!.docs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  slideFadeRoute(ProductDetailPage(productId: doc.id)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.error, color: Colors.grey[400]),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₱${(data['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class CategoryProductsPage extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;
  const CategoryProductsPage({required this.categoryId, required this.categoryTitle, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: _buildProductGrid(context, categoryId),
    );
  }

  Widget _buildProductGrid(BuildContext context, String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found in this category'));
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        final childAspectRatio = screenWidth > 600 ? 0.8 : 0.75;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: snapshot.data!.docs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  slideFadeRoute(ProductDetailPage(productId: doc.id)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.error, color: Colors.grey[400]),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₱${(data['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
