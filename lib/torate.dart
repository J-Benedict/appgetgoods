import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orderdetails.dart';

class ToRatePage extends StatefulWidget {
  const ToRatePage({super.key});

  @override
  State<ToRatePage> createState() => _ToRatePageState();
}

class _ToRatePageState extends State<ToRatePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitReview(String orderId, String productId, int rating, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Check if user has already reviewed this product
      final existingReview = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already reviewed this product')),
          );
        }
        return;
      }

      // Add the review to the product's reviews collection
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'nickname': userData['nickname'] ?? user.email,
        'profilePicture': userData['profilePicture'],
        'ratings': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the order status to "Reviewed"
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': 'Reviewed',
        'review': {
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showReviewDialog(String orderId, String productId) {
    int rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Your Purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Write your review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a rating')),
                  );
                  return;
                }
                _submitReview(orderId, productId, rating, commentController.text);
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getCustomUserId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['userId'];
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple[700]!;

    print('Current userId: ${_auth.currentUser?.uid}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Purchases'),
        backgroundColor: const Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<String?>(
        future: _getCustomUserId(),
        builder: (context, userIdSnapshot) {
          if (!userIdSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userId = userIdSnapshot.data;
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('orders')
                .where('orderStatus', isEqualTo: 'Completed')
                .where('userId', isEqualTo: userId)
                .orderBy('orderId', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return const Center(
                  child: Text(
                    'No completed orders to rate',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              order['imageUrl'] ?? '',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['name'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6C45F3),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₱${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6C45F3),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _orderInfoRow('Order ID:', order['orderId']),
                                _orderInfoRow('Date:', (order['orderDate'] as Timestamp).toDate().toString().split(' ')[0]),
                                _orderInfoRow('Payment:', order['payment'] ?? ''),
                                if (order['shippingMethod'] != null)
                                  _orderInfoRow('Shipping:', order['shippingMethod']),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: ElevatedButton(
                                    onPressed: () => _showReviewDialog(order['orderId'], order['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C45F3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text('Rate Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _orderInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
