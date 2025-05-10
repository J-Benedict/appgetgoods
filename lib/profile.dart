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
import 'notifications.dart';
import 'settings.dart';
import 'login.dart';
import 'signup.dart';
import 'homepage.dart';
import 'package:getgoods/homepage.dart'; 

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
  final int _selectedIndex = 4; // Account is the fifth item (index 4)
  firebase_auth_lib.User? _currentUser;
  String? _nickname;
  String? _profilePictureUrl;
  Map<String, dynamic>? _userData; // Define _userData to store user data

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        _loadUserData();
      } else {
        if (mounted) {
          setState(() {
            _nickname = null;
            _profilePictureUrl = null;
            _userData = null;
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Notifications()),
        );
        break;
      case 4:
        // Already on Profile page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section
            Container(
              color: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    child: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _profilePictureUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 30, color: Colors.grey[400]);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const CircularProgressIndicator();
                              },
                            ),
                          )
                        : Icon(Icons.person, size: 30, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 20),
                  if (_currentUser == null) ...[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Login()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                      ),
                      child: const Text("Login"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Signup()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                      ),
                      child: const Text("Sign Up"),
                    ),
                  ] else ...[
                    Text(
                      _nickname != null && _nickname!.isNotEmpty
                          ? _nickname!
                          : _currentUser?.email ?? 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Settings(
                            isLoggedIn: _currentUser != null,
                          ),
                        ),
                      );
                      // Reload user data when returning from settings
                      if (mounted) {
                        _loadUserData();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Sections
            if (_currentUser != null) ...[
              buildSection(
                title: "My Purchases",
                rightText: "View Purchase History",
                icons: [
                  Icons.payment,
                  Icons.local_shipping,
                  Icons.move_to_inbox,
                  Icons.star_rate,
                ],
                labels: ["To Pay", "To Ship", "To Receive", "To Rate"],
              ),
              buildSection(
                title: "My Wallet",
                icons: [
                  Icons.account_balance_wallet,
                  Icons.monetization_on,
                  Icons.schedule,
                  Icons.card_giftcard,
                ],
                labels: ["GG Pay", "GG Coins", "GG PayLater", "Vouchers"],
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              "Login to Get Goods and enjoy the best shopping experience",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'GG Mail'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  Widget buildSection({
    required String title,
    String? rightText,
    required List<IconData> icons,
    required List<String> labels,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (rightText != null)
                Text(rightText, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (index) {
              return Column(
                children: [
                  Icon(icons[index], color: primaryColor),
                  const SizedBox(height: 5),
                  Text(labels[index], style: const TextStyle(fontSize: 12)),
                ],
              );
            }),
          )
        ],
      ),
    );
  }
}
