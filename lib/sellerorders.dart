import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrders extends StatefulWidget {
  const SellerOrders({super.key});

  @override
  State<SellerOrders> createState() => _SellerOrdersState();
}

class _SellerOrdersState extends State<SellerOrders> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _selectedStatus = 'To Ship';
  final List<String> _statuses = ['To Ship', 'To Receive', 'Completed'];

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF6C45F3);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            dropdownColor: Colors.white,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: _statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status, style: TextStyle(color: purple)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: _auth.currentUser?.uid)
            .where('orderStatus', whereIn: _selectedStatus == 'Completed' 
                ? ['Completed', 'Reviewed'] 
                : [_selectedStatus])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('There are no current orders available', 
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${data['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _buildStatusChip(data['orderStatus']),
                        ],
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(data['name']),
                        subtitle: Text('₱${(data['price'] as num).toStringAsFixed(2)}'),
                        trailing: Text('x1', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Divider(),
                      Text('Customer: ${data['nickname'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Address: ${data['address'] ?? ''}'),
                      Text('Payment Method: ${data['payment'] ?? ''}'),
                      if (data['shippingMethod'] != null) Text('Shipping Method: ${data['shippingMethod']}'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Date: ${data['orderDate'] is Timestamp ? (data['orderDate'] as Timestamp).toDate().toString().split(' ')[0] : data['orderDate'].toString().split(' ')[0]}', style: TextStyle(color: Colors.grey[600])),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailsPage(
                                    orderId: doc.id,
                                    orderData: data,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('View Details'),
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

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.orderData['orderStatus'];
  }

  Future<void> _updateOrderStatus(String status) async {
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as $status')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF6C45F3);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order #${widget.orderData['orderId']}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        _buildStatusChip(widget.orderData['orderStatus']),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.orderData['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(widget.orderData['name']),
                      subtitle: Text('₱${(widget.orderData['price'] as num).toStringAsFixed(2)}'),
                      trailing: Text('x1', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    Text('Customer: ${widget.orderData['nickname'] ?? ''}', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Address: ${widget.orderData['address'] ?? ''}'),
                    Text('Payment Method: ${widget.orderData['payment'] ?? ''}'),
                    if (widget.orderData['shippingMethod'] != null) Text('Shipping Method: ${widget.orderData['shippingMethod']}'),
                    const SizedBox(height: 16),
                    Text('Order Date: ${widget.orderData['orderDate'] is Timestamp ? 
                      (widget.orderData['orderDate'] as Timestamp).toDate().toString().split(' ')[0] : 
                      widget.orderData['orderDate'].toString().split(' ')[0]}', 
                      style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    if (widget.orderData['orderStatus'] != 'Completed' && widget.orderData['orderStatus'] != 'Reviewed') ...[
                      const Text('Update Order Status:', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: ['To Ship', 'To Receive', 'Completed'].contains(_selectedStatus) ? _selectedStatus : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: ['To Ship', 'To Receive', 'Completed'].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                            _updateOrderStatus(val);
                          }
                        },
                      ),
                    ] else ...[
                      const Text('Order Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.orderData['orderStatus'], style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ),
          ],
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