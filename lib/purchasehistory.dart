import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getCustomUserId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['userId'];
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order['imageUrl'] ?? '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['name'] ?? 'Unknown Product',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ID: ${order['orderId']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₱${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: ${(order['orderDate'] as Timestamp).toDate().toString().split(' ')[0]}'),
                Text('Status: ${order['orderStatus']}'),
                if (order['address'] != null) Text('Address: ${order['address']}'),
                Text('Payment Method: ${order['payment'] ?? ''}'),
                if (order['shippingMethod'] != null) Text('Shipping Method: ${order['shippingMethod']}'),
                if (order['review']?['comment'] != null && order['review']['comment'].toString().isNotEmpty)
                  Text('Comment: ${order['review']['comment']}'),
                const SizedBox(height: 24),
                if (order['review'] != null) ...[
                  const Text(
                    'Your Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (order['review']['rating'] as int) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (order['review']['comment'] != null && order['review']['comment'].toString().isNotEmpty)
                    Text(order['review']['comment']),
                  const SizedBox(height: 8),
                  Text(
                    'Reviewed on: ${(order['review']['timestamp'] as Timestamp).toDate().toString().split(' ')[0]}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple[700]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
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
                .where('orderStatus', whereIn: ['Completed', 'Reviewed'])
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
                    'No purchase history available',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showOrderDetails(order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(width: 16),
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '₱${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6C45F3),
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (order['review'] != null)
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < (order['review']['rating'] as int) ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order ID: ${order['orderId']}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Date: ${(order['orderDate'] as Timestamp).toDate().toString().split(' ')[0]}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Payment: ${order['payment'] ?? ''}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (order['shippingMethod'] != null)
                                    Text(
                                      'Shipping: ${order['shippingMethod']}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Align(
                              alignment: Alignment.topRight,
                              child: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
                            ),
                          ],
                        ),
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
