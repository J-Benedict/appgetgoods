import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({
    Key? key,
    required this.orderId,
    required this.orderData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C45F3);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.08),
              Color(0xFFEEE8FD),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order #${orderData['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF6C45F3))),
                        _buildStatusChip(orderData['orderStatus']),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            orderData['imageUrl'],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(orderData['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF6C45F3))),
                              const SizedBox(height: 2),
                              Text('₱${(orderData['price'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C45F3))),
                              Text('x${orderData['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(),
                    Text('Seller: ${orderData['sellerName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Address: ${orderData['address'] ?? ''}'),
                    const SizedBox(height: 2),
                    Text('Payment Method: ${orderData['payment'] ?? ''}'),
                    if (orderData['shippingMethod'] != null) ...[
                      const SizedBox(height: 2),
                      Text('Shipping Method: ${orderData['shippingMethod']}'),
                    ],
                    const SizedBox(height: 12),
                    Divider(),
                    Text('Order Date: ${orderData['orderDate'] is Timestamp ? (orderData['orderDate'] as Timestamp).toDate().toString().split(' ')[0] : orderData['orderDate'].toString().split(' ')[0]}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'To Ship':
        color = Colors.orange;
        break;
      case 'To Receive':
        color = Colors.blue;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
