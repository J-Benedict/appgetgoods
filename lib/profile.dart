import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth_lib;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mobilebody.dart';
import 'categorypage.dart';
import 'cart.dart';
import 'ggmall.dart';
import 'settings.dart';
import 'login.dart';
import 'signup.dart';
import 'homepage.dart';
import 'productdetail.dart';
import 'toship.dart';
import 'toreceive.dart';
import 'torate.dart';
import 'package:getgoods/homepage.dart';
import 'purchasehistory.dart';
import 'dart:async';
import 'transition_helpers.dart';
import 'package:image_picker/image_picker.dart';

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
        storageBucket: 'getgoods-f1d9c.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(
    url: "https://dmmhcfesbtljmpbjpbej.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtbWhjZmVzYnRsam1wYmpwYmVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4MzQ5MDAsImV4cCI6MjA2MTQxMDkwMH0.y3Z19ThxFXjUlLg-u56abHHS9HXULl4JL0kQUl2RV8k",
  ); // Initialize Supabase

  firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
  runApp(
    MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: user != null? '/home' : '/myapp',
        routes: {
          '/home': (context) => const HomePage(),
          '/myapp': (context) => const MyApp(),
        },
      ),
  );
}

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _AccountPageState();
}

class _AccountPageState extends State<Profilepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color(0xFF7B1FA2); // Purple
  final int _selectedIndex = 3; // Account is the fourth item (index 3)
  firebase_auth_lib.User? _currentUser;
  String? _nickname;
  String? _profilePictureUrl;
  Map<String, dynamic>? _userData; // Define _userData to store user data
  int _toShipCount = 0;
  int _toReceiveCount = 0;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        _loadUserData();
        _fetchOrderCounts();
      } else {
        if (mounted) {
          setState(() {
            _nickname = null;
            _profilePictureUrl = null;
            _userData = null;
            _toShipCount = 0;
            _toReceiveCount = 0;
          });
        }
      }
    });
  }

  // Add this method to refresh data when returning from other screens
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData(); // Refresh data when screen is focused
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && mounted) {
          final data = userData.data()!;
          setState(() {
            _userData = data;
            _nickname = data['nickname']?.toString();
            _profilePictureUrl = data['profilePicture']?.toString();
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _fetchOrderCounts() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userId = userDoc.data()?['userId'];
    if (userId == null) return;
    final toShipSnap = await _firestore
        .collection('orders')
        .where('orderStatus', isEqualTo: 'To Ship')
        .where('userId', isEqualTo: userId)
        .get();
    final toReceiveSnap = await _firestore
        .collection('orders')
        .where('orderStatus', isEqualTo: 'To Receive')
        .where('userId', isEqualTo: userId)
        .get();
    if (mounted) {
      setState(() {
        _toShipCount = toShipSnap.size;
        _toReceiveCount = toReceiveSnap.size;
      });
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyMobileBody()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Categorypage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Ggmall()),
        );
        break;
      case 3:
        // Already on Profile page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          color: Color(0xFF6C45F3),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text("Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
                      const Spacer(),
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
                          icon: Icon(Icons.settings, color: Colors.white),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              slideFadeRoute(Settings(
                                isLoggedIn: _currentUser != null,
                              )),
                            );
                            if (mounted) {
                              _loadUserData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.08),
              Color(0xFFEEE8FD),
              Color(0xFFE9E3FC),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // Profile Header Card
            Card(
              margin: const EdgeInsets.fromLTRB(16, 40, 16, 12),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey[200],
                          child: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profilePictureUrl!,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, size: 36, color: Colors.grey[400]);
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const CircularProgressIndicator();
                                    },
                                  ),
                                )
                              : Icon(Icons.person, size: 36, color: Colors.grey[400]),
                        ),
                        if (_currentUser == null)
                          const SizedBox.shrink()
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeProfilePicture,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF6C45F3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _nickname != null && _nickname!.isNotEmpty
                                  ? _nickname!
                                  : _currentUser?.email ?? 'Guest',
                              style: const TextStyle(
                                color: Color(0xFF6C45F3),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_currentUser == null)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, slideFadeRoute(const Login()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6C45F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              child: const Text('Login'),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentUser != null) ...[
                          IconButton(
                            icon: const Icon(Icons.shopping_cart, color: Color(0xFF6C45F3)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                slideFadeRoute(const CartScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_currentUser != null) ...[
              // My Purchases Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "My Purchases",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                slideFadeRoute(const PurchaseHistoryPage()),
                              );
                            },
                            child: const Text(
                              "View Purchase History",
                              style: TextStyle(
                                color: Color(0xFF6C45F3),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _purchaseShortcut(Icons.local_shipping, "To Ship", () {
                            Navigator.push(context, slideFadeRoute(const ToShipPage())).then((_) => _fetchOrderCounts());
                          }, badgeCount: _toShipCount),
                          _purchaseShortcut(Icons.move_to_inbox, "To Receive", () {
                            Navigator.push(context, slideFadeRoute(const ToReceivePage())).then((_) => _fetchOrderCounts());
                          }, badgeCount: _toReceiveCount),
                          _purchaseShortcut(Icons.star_rate, "To Rate", () {
                            Navigator.push(context, slideFadeRoute(const ToRatePage()));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // You May Also Like Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(color: Color(0xFF6C45F3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'You May Also Like',
                        style: TextStyle(
                          color: Color(0xFF6C45F3),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFF6C45F3)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StreamBuilder<QuerySnapshot>(
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
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              slideFadeRoute(ProductDetailPage(productId: doc.id)),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
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
                                              fontSize: 16,
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
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
            if (_currentUser == null)
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Center(
                  child: Text(
                    'Log In to experience the full features of the app',
                    style: TextStyle(
                      color: Color(0xFF6C45F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modernProfileField({
    required String title,
    required String value,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
        trailing: icon != null
            ? IconButton(
                icon: Icon(icon, color: Color(0xFF6C45F3)),
                onPressed: onTap,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final supabase = Supabase.instance.client;
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final fileBytes = await pickedFile.readAsBytes();

          // Upload to Supabase with public access
          await supabase.storage
              .from('profile-pictures')
              .uploadBinary(
                fileName,
                fileBytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );

          // Get the complete public URL
          final publicUrl = supabase.storage
              .from('profile-pictures')
              .getPublicUrl(fileName);

          // Ensure the URL is using HTTPS
          final secureUrl = publicUrl.replaceFirst('http://', 'https://');

          // Update Firestore with the secure URL
          await _firestore.collection('users').doc(user.uid).set({
            'profilePicture': secureUrl,
          }, SetOptions(merge: true));

          // Update local state
          setState(() {
            _profilePictureUrl = secureUrl;
          });

          // Reload user data to ensure changes are reflected
          await _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile picture: $e')),
          );
        }
      }
    }
  }

  void _editField(String field, String label, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                try {
                  final fieldToSave = field == 'username' ? 'nickname' : field;
                  await _firestore.collection('users').doc(user.uid).set({
                    fieldToSave: controller.text.trim(),
                  }, SetOptions(merge: true));
                  await _loadUserData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label updated successfully')),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating $label: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _purchaseShortcut(IconData icon, String label, VoidCallback onTap, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF6C45F3).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Color(0xFF6C45F3), size: 28),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _userData = {};
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await _firestore.collection('users').doc(user.uid).get();
        final data = userData.data();
        if (data != null && mounted) {
          setState(() {
            _userData = data;
            _profilePictureUrl = data['profilePicture']?.toString();
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final supabase = Supabase.instance.client;
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final fileBytes = await pickedFile.readAsBytes();

          // Upload to Supabase with public access
          await supabase.storage
              .from('profile-pictures')
              .uploadBinary(
                fileName,
                fileBytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );

          // Get the complete public URL
          final publicUrl = supabase.storage
              .from('profile-pictures')
              .getPublicUrl(fileName);

          // Ensure the URL is using HTTPS
          final secureUrl = publicUrl.replaceFirst('http://', 'https://');

          // Update Firestore with the secure URL
          await _firestore.collection('users').doc(user.uid).set({
            'profilePicture': secureUrl,
          }, SetOptions(merge: true));

          // Update local state
          setState(() {
            _profilePictureUrl = secureUrl;
          });

          // Reload user data to ensure changes are reflected
          await _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile picture: $e')),
          );
        }
      }
    }
  }

  void _editField(String field, String label, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user != null) {
                try {
                  final fieldToSave = field == 'username' ? 'nickname' : field;
                  await _firestore.collection('users').doc(user.uid).set({
                    fieldToSave: controller.text.trim(),
                  }, SetOptions(merge: true));
                  await _loadUserData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label updated successfully')),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating $label: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _changeProfilePicture,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _profilePictureUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 50, color: Colors.grey[400]);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const CircularProgressIndicator();
                              },
                            ),
                          )
                        : Icon(Icons.person, size: 50, color: Colors.grey[400]),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _changeProfilePicture,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF6C45F3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('Name'),
            subtitle: Text(_userData['nickname'] ?? 'N/A'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF6C45F3)),
              onPressed: () {
                final controller = TextEditingController(text: _userData['nickname']);
                _editField('username', 'Name', controller);
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Gender'),
            subtitle: Text(_userData['gender'] ?? 'N/A'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF6C45F3)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Gender'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () async {
                            final user = _auth.currentUser;
                            if (user != null) {
                              try {
                                await _firestore.collection('users').doc(user.uid).set({
                                  'gender': 'Male',
                                }, SetOptions(merge: true));
                                await _loadUserData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gender updated successfully')),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating gender: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Male'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () async {
                            final user = _auth.currentUser;
                            if (user != null) {
                              try {
                                await _firestore.collection('users').doc(user.uid).set({
                                  'gender': 'Female',
                                }, SetOptions(merge: true));
                                await _loadUserData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gender updated successfully')),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating gender: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Female'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Birthday'),
            subtitle: Text(_userData['birthday'] ?? 'N/A'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF6C45F3)),
              onPressed: () {
                final controller = TextEditingController(text: _userData['birthday']);
                _editField('birthday', 'Birthday', controller);
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Phone Number'),
            subtitle: Text(_userData['phone'] ?? 'N/A'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF6C45F3)),
              onPressed: () {
                final controller = TextEditingController(text: _userData['phone']);
                _editField('phone', 'Phone Number', controller);
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(_auth.currentUser?.email ?? 'N/A'),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Password'),
            subtitle: const Text('********'),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF6C45F3)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

