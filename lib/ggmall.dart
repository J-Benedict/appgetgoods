import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'categorypage.dart';
import 'profile.dart'; 
import 'cart.dart';
import 'mobilebody.dart';
import 'productdetail.dart';
import 'search.dart';
import 'transition_helpers.dart';

class Ggmall extends StatefulWidget {
  const Ggmall({super.key});

  @override
  State<Ggmall> createState() => _GgmallState();
}

class _GgmallState extends State<Ggmall> {
  final int _selectedIndex = 2;
  String _sortOption = 'az';

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Categorypage()),
        );
        break;
      case 2:
        // Already on GG Mall page
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profilepage()),
        );
        break;
    }
  }

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
                      Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text("GG Mall", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
                      const Spacer(),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              slideFadeRoute(SearchPage()),
                            );
                          },
                          child: AbsorbPointer(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Icon(Icons.search, color: Color(0xFF6C45F3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Search",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              slideFadeRoute(const CartScreen()),
                            );
                          },
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "RECOMMENDED",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        const Text("Filters", style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortOption,
                          items: const [
                            DropdownMenuItem(value: 'az', child: Text('Sort by: A to Z')),
                            DropdownMenuItem(value: 'za', child: Text('Sort by: Z to A')),
                            DropdownMenuItem(value: 'low', child: Text('Price: Low to High')),
                            DropdownMenuItem(value: 'high', child: Text('Price: High to Low')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortOption = value!;
                            });
                          },
                          underline: Container(),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          icon: const Icon(Icons.arrow_drop_down),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildProductGrid(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        List<QueryDocumentSnapshot> docs = List.from(snapshot.data!.docs);
        // Sort products based on _sortOption
        if (_sortOption == 'az') {
          docs.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
        } else if (_sortOption == 'za') {
          docs.sort((a, b) => (b['name'] ?? '').toString().toLowerCase().compareTo((a['name'] ?? '').toString().toLowerCase()));
        } else if (_sortOption == 'low') {
          docs.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        } else if (_sortOption == 'high') {
          docs.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        }
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        final childAspectRatio = screenWidth > 600 ? 0.8 : 0.75;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    slideFadeRoute(ProductDetailPage(
                      productId: doc.id,
                    )),
                  );
                },
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

  Widget _buildProductCard(String title, String price, String imageUrl, String productId) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            slideFadeRoute(ProductDetailPage(productId: productId)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  imageUrl,
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
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱$price',
                        style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold),
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
  }
}
