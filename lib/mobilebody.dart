import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'categorypage.dart';
import 'profile.dart'; 
import 'cart.dart';
import 'ggmall.dart';
import 'productdetail.dart';
import 'search.dart';
import 'transition_helpers.dart';
import 'settings.dart';
import 'navigation.dart';
import 'sellerprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sellerlogin.dart';
import 'sellerregister.dart';

class MyMobileBody extends StatefulWidget {
  const MyMobileBody({super.key});

  @override
  State<MyMobileBody> createState() => MyMobileBodyState();
}

class MyMobileBodyState extends State<MyMobileBody> {
  int _selectedIndex = 0;
  int _currentSlide = 0;
  final List<String> _slideImages = [
    'assets/slide1.png',
    'assets/slide2.png',
    'assets/slide3.png',
  ];

  final CarouselController _carouselController = CarouselController();
  String _sortOption = 'az';
  bool _shuffleTrigger = false;
  List<QueryDocumentSnapshot>? _cachedProducts;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Public method to shuffle products
  void shuffleProducts() {
    setState(() {
      if (_cachedProducts != null) {
        _cachedProducts!.shuffle();
      }
      _shuffleTrigger = !_shuffleTrigger;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePageContent(
            slideImages: _slideImages,
            carouselController: _carouselController,
            sortOption: _sortOption,
            onSortChanged: (val) => setState(() => _sortOption = val),
            cachedProducts: _cachedProducts,
            setCachedProducts: (list) => _cachedProducts = list,
            shuffleProducts: shuffleProducts,
          ),
          Categorypage(),
          Ggmall(),
          Profilepage(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) => _buildFloatingPillNavIcon(index)),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingPillNavIcon(int index) {
    final icons = [
      Icons.home,
      Icons.category,
      Icons.shopping_bag,
      Icons.person,
    ];
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: EdgeInsets.only(top: 8),
        child: isSelected
            ? Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icons[index],
                  color: Color(0xFF6C45F3),
                  size: 28,
                ),
              )
            : Icon(
                icons[index],
                color: Colors.grey[400],
                size: 28,
              ),
      ),
    );
  }
}

// New HomePageContent widget for Home tab
class HomePageContent extends StatefulWidget {
  final List<String> slideImages;
  final CarouselController carouselController;
  final String sortOption;
  final ValueChanged<String> onSortChanged;
  final List<QueryDocumentSnapshot>? cachedProducts;
  final ValueChanged<List<QueryDocumentSnapshot>> setCachedProducts;
  final VoidCallback shuffleProducts;

  const HomePageContent({
    Key? key,
    required this.slideImages,
    required this.carouselController,
    required this.sortOption,
    required this.onSortChanged,
    required this.cachedProducts,
    required this.setCachedProducts,
    required this.shuffleProducts,
  }) : super(key: key);

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  int currentSlide = 0;
  int? _tappedIndex; // For product card animation

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6C45F3).withOpacity(0.10),
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
            SizedBox(height: 12), // Add spacing at the very top
            Container(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag, color: Color(0xFF6C45F3), size: 28),
                  const SizedBox(width: 8),
                  Text("GetGoods", style: TextStyle(color: Color(0xFF6C45F3), fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
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
            // Modernized Banner/Carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  elevation: 4,
                  shadowColor: Color(0xFF6C45F3).withOpacity(0.10),
                  child: HomeSlideshow(
                    slideImages: widget.slideImages,
                    carouselController: widget.carouselController,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            _buildShortcutRow(context),
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECOMMENDED",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, color: Color(0xFF6C45F3), size: 18),
                        const SizedBox(width: 4),
                        DropdownButton<String>(
                          value: widget.sortOption,
                          items: const [
                            DropdownMenuItem(value: 'az', child: Text('A to Z')),
                            DropdownMenuItem(value: 'za', child: Text('Z to A')),
                            DropdownMenuItem(value: 'low', child: Text('Low to High')),
                            DropdownMenuItem(value: 'high', child: Text('High to Low')),
                          ],
                          onChanged: (value) {
                            if (value != null) widget.onSortChanged(value);
                          },
                          underline: Container(),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          icon: const Icon(Icons.arrow_drop_down),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(height: 4),
            _buildModernProductGrid(context),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProductGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        List<QueryDocumentSnapshot>? localCachedProducts = widget.cachedProducts;
        if (localCachedProducts == null || localCachedProducts.length != snapshot.data!.docs.length || !localCachedProducts.asMap().entries.every((entry) => entry.value.id == snapshot.data!.docs[entry.key].id)) {
          localCachedProducts = List.from(snapshot.data!.docs);
          widget.setCachedProducts(localCachedProducts);
        }
        List<QueryDocumentSnapshot> docs = localCachedProducts;
        if (widget.sortOption == 'az') {
          docs.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
        } else if (widget.sortOption == 'za') {
          docs.sort((a, b) => (b['name'] ?? '').toString().toLowerCase().compareTo((a['name'] ?? '').toString().toLowerCase()));
        } else if (widget.sortOption == 'low') {
          docs.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        } else if (widget.sortOption == 'high') {
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
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return MouseRegion(
                onEnter: (_) => setState(() => _tappedIndex = index),
                onExit: (_) => setState(() => _tappedIndex = null),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _tappedIndex = index),
                  onTapUp: (_) => setState(() => _tappedIndex = null),
                  onTapCancel: () => setState(() => _tappedIndex = null),
                  onTap: () {
                    Navigator.push(
                      context,
                      slideFadeRoute(ProductDetailPage(productId: doc.id)),
                    );
                  },
                  child: AnimatedScale(
                    scale: _tappedIndex == index ? 1.04 : 1.0,
                    duration: Duration(milliseconds: 120),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C45F3).withOpacity(0.10),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: _tappedIndex == index ? Color(0xFF6C45F3).withOpacity(0.4) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
                                        color: Color(0xFF6C45F3),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
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
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShortcutRow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 18 * 2 - 10) / 2; // 18 padding each side, 10 spacing between
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ShortcutCard(
            icon: Icons.account_balance_wallet,
            label: 'GG Wallet',
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You need to login first before using this feature.')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyEWalletPage()),
              );
            },
            width: cardWidth,
          ),
          SizedBox(width: 10),
          _ShortcutCard(
            icon: Icons.store,
            label: 'Seller Account',
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You need to login first before using this feature.')),
                );
                return;
              }
              final sellerDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('seller_account')
                  .get();
              if (context.mounted) {
                if (sellerDoc.docs.isEmpty) {
                  // No seller account, go to SellerRegister
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SellerRegister()),
                  );
                } else {
                  // Seller account exists, go to SellerLogin
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SellerLogin()),
                  );
                }
              }
            },
            width: cardWidth,
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double width;
  const _ShortcutCard({required this.icon, required this.label, required this.onTap, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Color(0xFF6C45F3), size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF6C45F3),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New: HomeSlideshow widget
class HomeSlideshow extends StatefulWidget {
  final List<String> slideImages;
  final CarouselController carouselController;
  const HomeSlideshow({Key? key, required this.slideImages, required this.carouselController}) : super(key: key);

  @override
  State<HomeSlideshow> createState() => _HomeSlideshowState();
}

class _HomeSlideshowState extends State<HomeSlideshow> {
  int currentSlide = 0;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double slideHeight = MediaQuery.of(context).size.height * 0.2;
        return SizedBox(
          height: slideHeight,
          child: Stack(
            children: [
              CarouselSlider.builder(
                itemCount: widget.slideImages.length,
                itemBuilder: (context, index, realIndex) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16), // Reduce white border
                    child: Image.asset(
                      widget.slideImages[index],
                      width: double.infinity,
                      height: slideHeight,
                      fit: BoxFit.cover, // Make image fill the container
                    ),
                  );
                },
                options: CarouselOptions(
                  height: slideHeight,
                  viewportFraction: 1.0,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  onPageChanged: (index, reason) {
                    setState(() {
                      currentSlide = index;
                    });
                  },
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.slideImages.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(
                          currentSlide == entry.key ? 0.9 : 0.4,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
