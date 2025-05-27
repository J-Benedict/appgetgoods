import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:getgoods/homepage.dart';
import 'package:getgoods/login.dart';
import 'package:getgoods/checkout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyC3obbTdHEFd5ngMWYcLgy5JMX7gdRhTwc',
        appId: '1:491930036288:web:57b3919dbcdea6cee6d7a5',
        authDomain: "getgoods-f1d9c.firebaseapp.com",
        databaseURL: "https://getgoods-f1d9c-default-rtdb.asia-southeast1.firebasedatabase.app",
        messagingSenderId: '491930036288',
        projectId: 'getgoods-f1d9c',
        storageBucket: 'getgoods-f1d9c.firebasestorage.app'),
    );
  } else {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(
    url: "https://dmmhcfesbtljmpbjpbej.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtbWhjZmVzYnRsam1wYmpwYmVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4MzQ5MDAsImV4cCI6MjA2MTQxMDkwMH0.y3Z19ThxFXjUlLg-u56abHHS9HXULl4JL0kQUl2RV8k",
    storageOptions: const StorageClientOptions(
      retryAttempts: 3,
    ),
  ); // Initialize Supabase

  firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: user != null ? '/home' : '/myapp',
      routes: {
        '/home': (context) => const HomePage(),
        '/myapp': (context) => const MyApp(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );
      },
    ),
  );
}


class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  DocumentSnapshot<Map<String, dynamic>>? product;
  DocumentSnapshot<Map<String, dynamic>>? sellerAccount;
  bool isLoading = true;
  final _auth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        final productData = productDoc.data()!;
        final sellerId = productData['sellerId'];

        final sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('seller_account')
            .limit(1)
            .get();

        setState(() {
          product = productDoc;
          sellerAccount = sellerDoc.docs.isNotEmpty ? sellerDoc.docs.first : null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading product: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart')),
      );
      return;
    }

    try {
      // Debug print to verify user state
      print('Current user ID: ${_auth.currentUser!.uid}');
      print('Current user email: ${_auth.currentUser!.email}');
      
      final productData = product!.data()!;
      final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      
      // Debug print to verify document path
      print('Attempting to access user document at: users/${_auth.currentUser!.uid}');
      
      // Create user document if it doesn't exist
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        print('Creating new user document');
        await userRef.set({
          'email': _auth.currentUser!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': _auth.currentUser!.uid, // Add uid field for easier querying
        });
      }

      final cartRef = userRef.collection('cart');
      print('Attempting to access cart collection at: users/${_auth.currentUser!.uid}/cart');

      // Check if product already exists in cart
      final existingCartItem = await cartRef
          .where('productId', isEqualTo: widget.productId)
          .get();

      if (existingCartItem.docs.isNotEmpty) {
        print('Updating existing cart item');
        // Update quantity if product exists
        final currentQuantity = existingCartItem.docs.first.data()['quantity'] ?? 1;
        if (currentQuantity >= productData['stock']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum stock limit reached')),
          );
          return;
        }
        await existingCartItem.docs.first.reference.update({
          'quantity': currentQuantity + 1,
        });
      } else {
        print('Adding new item to cart');
        // Add new item to cart
        await cartRef.add({
          'productId': widget.productId,
          'name': productData['name'],
          'price': productData['price'],
          'imageUrl': productData['imageUrl'],
          'quantity': 1,
          'stock': productData['stock'],
          'addedAt': FieldValue.serverTimestamp(),
          'userId': _auth.currentUser!.uid, // Add userId for easier querying
          'sellerId': productData['sellerId'],
          'sellerName': sellerAccount?.data()?['businessName'] ?? '',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart successfully')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      print('Error details: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple[400]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Product Details', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6C45F3).withOpacity(0.10),
                  Color(0xFFE9E3FC),
                  Color(0xFFF6F3FF),
                ],
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_auth.currentUser == null)
                    Container(
                      color: Colors.amber[100],
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'You are viewing this product as a guest. Log in for more features!',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Product Image (glassy)
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C45F3).withOpacity(0.10),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: product?.data()?['imageUrl'] != null
                            ? Image.network(
                                product!.data()!['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.broken_image, size: 80),
                              )
                            : const Icon(Icons.image, size: 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Product Info Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C45F3).withOpacity(0.07),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product?.data()?['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF6C45F3),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Stock: ${product?.data()?['stock'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${(product?.data()?['price'] as num?)?.toStringAsFixed(0) ?? ''}',
                          style: TextStyle(
                            color: Color(0xFF6C45F3),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description Card
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6C45F3).withOpacity(0.07),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product description',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF6C45F3),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product?.data()?['description'] ?? 'No description available.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reviews Card
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.productId)
                        .collection('reviews')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6C45F3).withOpacity(0.07),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Text('Error loading reviews'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6C45F3).withOpacity(0.07),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      final reviews = snapshot.data?.docs ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF6C45F3).withOpacity(0.07),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reviews',
                                      style: const TextStyle(fontSize: 16, color: Color(0xFF6C45F3), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (reviews.isEmpty)
                                  const Text('No reviews yet.')
                                else ...[
                                  ...reviews.take(2).map((doc) {
                                    final review = doc.data() as Map<String, dynamic>;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF6C45F3).withOpacity(0.06),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          review['profilePicture'] != null && review['profilePicture'] != ''
                                              ? CircleAvatar(backgroundImage: NetworkImage(review['profilePicture']))
                                              : const CircleAvatar(child: Icon(Icons.person)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(review['nickname'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(width: 8),
                                                    for (int i = 1; i <= 5; i++)
                                                      Icon(
                                                        i <= (review['ratings'] ?? 0) ? Icons.star : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      ),
                                                  ],
                                                ),
                                                if ((review['comment'] ?? '').toString().isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2.0),
                                                    child: Text(review['comment'], style: TextStyle(color: Colors.black87)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (reviews.length > 2)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Center(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProductAllReviewsPage(productId: widget.productId),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF6C45F3),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(32),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            elevation: 0,
                                          ),
                                          child: const Text('See all reviews'),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Seller Store Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C45F3).withOpacity(0.07),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.purple[100],
                          backgroundImage: sellerAccount?.data()?['businessImageUrl'] != null
                              ? NetworkImage(sellerAccount!.data()!['businessImageUrl'])
                              : null,
                          child: sellerAccount?.data()?['businessImageUrl'] == null
                              ? Icon(Icons.store, color: Color(0xFF6C45F3), size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            sellerAccount?.data()?['businessName'] ?? 'Unknown Seller',
                            style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6C45F3),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed buttons at the bottom
          Positioned(
            bottom: MediaQuery.of(context).viewPadding.bottom + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      side: BorderSide(color: Color(0xFF6C45F3), width: 2),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6C45F3), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ((product?.data()?['stock'] ?? 0) == 0)
                        ? null
                        : () {
                            if (_auth.currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please login to checkout')),
                              );
                              return;
                            }
                            if (product == null || sellerAccount == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product information not available')),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(
                                  products: [
                                    {
                                      'productId': widget.productId,
                                      'title': product!.data()!['name'],
                                      'price': product!.data()!['price'],
                                      'imageUrl': product!.data()!['imageUrl'],
                                      'quantity': 1,
                                      'stock': product!.data()!['stock'],
                                      'sellerId': product!.data()!['sellerId'],
                                      'sellerName': sellerAccount!.data()!['businessName'] ?? 'Unknown Seller',
                                    },
                                  ],
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ((product?.data()?['stock'] ?? 0) == 0)
                          ? Colors.grey
                          : Color(0xFF6C45F3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductAllReviewsPage extends StatelessWidget {
  final String productId;
  const ProductAllReviewsPage({required this.productId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple[400]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reviews'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data?.docs ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
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
                  subtitle: Text(review['comment'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}