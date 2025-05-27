import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sellerproducts.dart';
import 'sellerorders.dart';
import 'sellerprofile.dart';
import 'package:getgoods/login.dart';
import 'package:getgoods/homepage.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentPage = 'Activity';
  
  int _pendingOrders = 0;
  int _completedOrders = 0;
  int _totalProducts = 0;
  List<Map<String, dynamic>> _recentReviews = [];
  List<Map<String, dynamic>> _allReviews = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Add listener for products collection
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _totalProducts = snapshot.docs.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancel any active listeners here
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Get seller info first to get correct seller ID
        final sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('seller_account')
            .get();

        if (sellerDoc.docs.isEmpty) return;

        final sellerData = sellerDoc.docs.first.data();
        final sellerId = sellerData['id'] ?? user.uid;

        // Get total products count using seller ID
        final productsQuery = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: user.uid)
            .get();

        // Pending Orders: To Ship
        final pendingOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .where('orderStatus', isEqualTo: 'To Ship')
            .get();
        // Completed Orders: Completed + Reviewed
        final completedOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .where('orderStatus', whereIn: ['Completed', 'Reviewed'])
            .get();
        // All Orders (for full list)
        final allOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        // All Reviews (for full list)
        final allReviews = await FirebaseFirestore.instance
            .collection('reviews')
            .where('sellerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        if (mounted) {
          setState(() {
            _totalProducts = productsQuery.docs.length;
            _pendingOrders = pendingOrders.docs.length;
            _completedOrders = completedOrders.docs.length;
            _allReviews = allReviews.docs.map((doc) => doc.data()).toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading dashboard data: $e');
      }
    }
  }

  Widget _buildDashboardCard(String title, String value, IconData icon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF6C45F3), size: 28),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C45F3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFF6C45F3),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'GG Seller',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF6C45F3)),
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('seller_account')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClipOval(
                          child: Image.asset('assets/GGs_Logo.png', height: 60, width: 60, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'GG Seller Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    );
                  }

                  final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final businessImageUrl = data['businessImageUrl'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (businessImageUrl != null && businessImageUrl.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            businessImageUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading business image: $error');
                              return ClipOval(
                                child: Image.asset('assets/GGs_Logo.png', height: 60, width: 60, fit: BoxFit.cover),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const CircularProgressIndicator();
                            },
                          ),
                        )
                      else
                        ClipOval(
                          child: Image.asset('assets/GGs_Logo.png', height: 60, width: 60, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: Text(
                          data['businessName'] ?? 'GG Seller Dashboard',
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF6C45F3)),
              title: const Text('Activity', style: TextStyle(color: Color(0xFF6C45F3))),
              selected: _currentPage == 'Activity',
              onTap: () {
                setState(() => _currentPage = 'Activity');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Color(0xFF6C45F3)),
              title: const Text('Products', style: TextStyle(color: Colors.black)),
              selected: _currentPage == 'Products',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerProducts()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Color(0xFF6C45F3)),
              title: const Text('Orders', style: TextStyle(color: Colors.black)),
              selected: _currentPage == 'Orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerOrders()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF6C45F3)),
              title: const Text('Profile', style: TextStyle(color: Colors.black)),
              selected: _currentPage == 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerProfile()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C45F3),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    'Pending Orders',
                    _pendingOrders.toString(),
                    Icons.pending_actions,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildDashboardCard(
                    'Completed Orders',
                    _completedOrders.toString(),
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              'Total Products',
              _totalProducts.toString(),
              Icons.inventory_2,
            ),
            const SizedBox(height: 30),
            const Divider(),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C45F3))),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getRecentSellerReviews(limit: 3),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Text('No reviews to display');
                }
                return Column(
                  children: reviews.map((review) {
                    return FutureBuilder<String>(
                      future: _getProductName(review['productId'] ?? ''),
                      builder: (context, productSnapshot) {
                        final productName = productSnapshot.data ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: review['profilePicture'] != null && review['profilePicture'] != ''
                                ? CircleAvatar(backgroundImage: NetworkImage(review['profilePicture']))
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Row(
                              children: [
                                Text(review['nickname'] ?? 'Unknown'),
                                const SizedBox(width: 8),
                                for (int i = 1; i <= 5; i++)
                                  Icon(
                                    i <= (review['ratings'] ?? 0) ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review['comment'] ?? ''),
                                if (productName.isNotEmpty)
                                  Text('Product: $productName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF6C45F3)),
                label: const Text('See all reviews', style: TextStyle(color: Color(0xFF6C45F3))),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SellerAllReviewsPageStyled()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SellerAllReviewsPageStyled extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getAllSellerReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .get();
    final productIds = productsSnapshot.docs.map((doc) => doc.id).toList();
    List<Map<String, dynamic>> allReviews = [];
    for (final productId in productIds) {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();
      for (final doc in reviewsSnapshot.docs) {
        final review = doc.data();
        review['productId'] = productId;
        allReviews.add(review);
      }
    }
    allReviews.sort((a, b) {
      final aTime = a['timestamp'] is Timestamp ? a['timestamp'].millisecondsSinceEpoch : 0;
      final bTime = b['timestamp'] is Timestamp ? b['timestamp'].millisecondsSinceEpoch : 0;
      return bTime.compareTo(aTime);
    });
    return allReviews;
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllSellerReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text('No reviews found.'));
          }
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return FutureBuilder<String>(
                future: _getProductName(review['productId'] ?? ''),
                builder: (context, productSnapshot) {
                  final productName = productSnapshot.data ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: review['profilePicture'] != null && review['profilePicture'] != ''
                          ? CircleAvatar(backgroundImage: NetworkImage(review['profilePicture']))
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Row(
                        children: [
                          Text(review['nickname'] ?? 'Unknown'),
                          const SizedBox(width: 8),
                          for (int i = 1; i <= 5; i++)
                            Icon(
                              i <= (review['ratings'] ?? 0) ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review['comment'] ?? ''),
                          if (productName.isNotEmpty)
                            Text('Product: $productName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> _getRecentSellerReviews({int limit = 3}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final productsSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('sellerId', isEqualTo: user.uid)
      .get();
  final productIds = productsSnapshot.docs.map((doc) => doc.id).toList();
  List<Map<String, dynamic>> allReviews = [];
  for (final productId in productIds) {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .get();
    for (final doc in reviewsSnapshot.docs) {
      final review = doc.data();
      review['productId'] = productId;
      allReviews.add(review);
    }
  }
  allReviews.sort((a, b) {
    final aTime = a['timestamp'] is Timestamp ? a['timestamp'].millisecondsSinceEpoch : 0;
    final bTime = b['timestamp'] is Timestamp ? b['timestamp'].millisecondsSinceEpoch : 0;
    return bTime.compareTo(aTime);
  });
  return allReviews.take(limit).toList();
}

// Helper to get product name by productId
Future<String> _getProductName(String productId) async {
  final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
  return doc.data()?['name'] ?? '';
}