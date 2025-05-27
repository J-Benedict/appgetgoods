import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:getgoods/homepage.dart';
import 'package:getgoods/login.dart';

class SellerProducts extends StatefulWidget {
  const SellerProducts({super.key});

  @override
  State<SellerProducts> createState() => _SellerProductsState();
}

class _SellerProductsState extends State<SellerProducts> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  File? _imageFile;
  String? _imageUrl;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = 'Clothes';

  final List<String> _categories = [
    'Clothes',
    'Shoes',
    'Foods',
    'Electronics',
    'Figurines',
    'Books'
  ];

  String _generateProductId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Set image file for preview
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Upload immediately after picking
        final bytes = await pickedFile.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await _supabase.storage
            .from('product-images')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                cacheControl: '3600',
                upsert: true,
              ),
            );

        final imageUrl = _supabase.storage
            .from('product-images')
            .getPublicUrl(fileName);

        setState(() {
          _imageUrl = imageUrl;
        });
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking/uploading image: $e')),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get seller info from seller_account
      final sellerSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('seller_account')
          .get();

      if (sellerSnapshot.docs.isEmpty) {
        throw Exception('Seller account not found');
      }

      final sellerData = sellerSnapshot.docs.first.data();
      final sellerId = sellerData['id'] ?? user.uid; // Get seller ID from seller_account
      final businessName = sellerData['businessName'] ?? 'Unknown Seller';

      final productId = _generateProductId();

      // Add to products collection with correct seller info
      await _firestore.collection('products').doc(productId).set({
        'id': productId,
        'sellerId': sellerId, // Use seller ID from seller_account
        'sellerName': businessName, // Use business name from seller_account
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory,
        'imageUrl': _imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'ratings': [],
        'totalRating': 0.0,
        'reviewCount': 0,
      });

      // Clear form
      setState(() {
        _imageFile = null;
        _imageUrl = null;
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        _stockController.clear();
        _selectedCategory = 'Clothes';
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Listen for business name changes
    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('seller_account')
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isNotEmpty) {
          final sellerData = snapshot.docs.first.data();
          final newBusinessName = sellerData['businessName'];

          // Update all products by this seller
          final productsQuery = await _firestore
              .collection('products')
              .where('sellerId', isEqualTo: user.uid)
              .get();

          final batch = _firestore.batch();
          for (var doc in productsQuery.docs) {
            batch.update(doc.reference, {
              'sellerName': newBusinessName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();

          // Update all orders by this seller
          final ordersQuery = await _firestore
              .collection('orders')
              .where('sellerId', isEqualTo: user.uid)
              .get();

          final ordersBatch = _firestore.batch();
          for (var doc in ordersQuery.docs) {
            ordersBatch.update(doc.reference, {
              'sellerName': newBusinessName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await ordersBatch.commit();
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancel listener if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C45F3).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C45F3),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF6C45F3)),
                    onPressed: () => _showAddProductForm(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .where('sellerId', isEqualTo: _auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data!.docs[index];
                      return _buildProductCard(product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(DocumentSnapshot product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product['imageUrl'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stock: ${product['stock']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '₱${(product['price'] as num).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C45F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditProductForm(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(product.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductForm() {
    _imageFile = null;
    _imageUrl = null;
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    _stockController.clear();
    _selectedCategory = 'Clothes';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C45F3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : _imageUrl != null
                              ? Image.network(_imageUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.add_photo_alternate, size: 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('₱', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C45F3),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _addProduct,
                    child: const Text('Add Product'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProductForm(DocumentSnapshot product) async {
    final data = product.data() as Map<String, dynamic>;
  
    _nameController.text = data['name'] ?? '';
    _descController.text = data['description'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _stockController.text = data['stock']?.toString() ?? '';
    _selectedCategory = data['category'] ?? 'Clothes';
    _imageUrl = data['imageUrl'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Product',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C45F3),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : _imageUrl != null
                            ? Image.network(_imageUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.add_photo_alternate, size: 50),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('₱', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C45F3),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    try {
                      await _firestore.collection('products').doc(product.id).update({
                        'name': _nameController.text.trim(),
                        'description': _descController.text.trim(),
                        'price': double.parse(_priceController.text),
                        'stock': int.parse(_stockController.text),
                        'category': _selectedCategory,
                        'imageUrl': _imageUrl,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product updated successfully')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating product: $e')),
                      );
                    }
                  },
                  child: const Text('Update Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    }
  }
}