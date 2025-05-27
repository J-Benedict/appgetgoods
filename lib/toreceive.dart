import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orderdetails.dart';

class ToReceivePage extends StatefulWidget {
  const ToReceivePage({super.key});

  @override
  State<ToReceivePage> createState() => _ToReceivePageState();
}

class _ToReceivePageState extends State<ToReceivePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _markAsReceived(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': 'Completed',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as completed')),
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
        title: const Text('To Receive'),
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
                .where('orderStatus', isEqualTo: 'To Receive')
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
                    'No orders to receive',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;
                  final orderDocId = orders[index].id;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C45F3).withOpacity(0.10),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['name'] ?? 'Unknown Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF6C45F3))),
                                const SizedBox(height: 6),
                                Text('₱${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C45F3), fontSize: 16)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.info_outline, color: Color(0xFF6C45F3), size: 20),
                                label: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C45F3))),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF6C45F3),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  side: const BorderSide(color: Color(0xFF6C45F3), width: 1.5),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailsPage(
                                        orderId: orderDocId,
                                        orderData: order,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6C45F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () => _markAsReceived(order['orderId']),
                                child: const Text('Mark as Received', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
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
}
