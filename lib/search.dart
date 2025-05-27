import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'productdetail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchText = '';
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple[700]!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C45F3),
        elevation: 0,
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C45F3).withOpacity(0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: Color(0xFF6C45F3), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      cursorColor: purple,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                    ),
                  ),
                  if (_searchText.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        key: ValueKey(_searchText),
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        splashRadius: 18,
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                            _searchText = '';
                            _focusNode.requestFocus();
                          });
                        },
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data?.docs ?? [];
          final filtered = _searchText.isEmpty
              ? products
              : products.where((doc) {
                  final name = (doc['name'] ?? '').toString();
                  if (_searchText.length > name.length) return false;
                  return name.toLowerCase().startsWith(_searchText.toLowerCase());
                }).toList();
          if (filtered.isEmpty) {
            return const Center(child: Text('No products found', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 3 : 2;
          final childAspectRatio = screenWidth > 600 ? 0.8 : 0.75;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: filtered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final doc = filtered[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(productId: doc.id),
                      ),
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
                              doc['imageUrl'] ?? '',
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
                                doc['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₱${(doc['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
            ),
          );
        },
      ),
    );
  }
}
