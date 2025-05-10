import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getgoods/login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        storageBucket: 'getgoods-f1d9c.firebasestorage.app'),
    );
  } else {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(
    url: "https://dmmhcfesbtljmpbjpbej.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtbWhjZmVzYnRsam1wYmpwYmVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4MzQ5MDAsImV4cCI6MjA2MTQxMDkwMH0.y3Z19ThxFXjUlLg-u56abHHS9HXULl4JL0kQUl2RV8k",
    storageOptions: const StorageClientOptions(
      retryAttempts: 3,
    ),
  ); // Initialize Supabase

  firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: user != null ? '/home' : '/myapp',
      routes: {
        '/home': (context) => const HomePage(),
        '/myapp': (context) => const MyApp(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );
      },
    ),
  );
}

class Logged extends StatelessWidget {
  const Logged({super.key});

  @override
  Widget build(BuildContext context) {
    return const Settings(isLoggedIn: true);
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Page')),
    );
  }
}

class Settings extends StatelessWidget {
  final bool isLoggedIn;

  const Settings({super.key, required this.isLoggedIn});

  Future<void> updateNickname(BuildContext context, String newNickname) async {  // Add BuildContext parameter
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': newNickname,
        }, SetOptions(merge: true));
        
        // Show success message using the passed context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating nickname: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (isLoggedIn) ...[
            ListTile(
              title: const Text('My Profile'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyProfilePage()),
              ),
            ),
            ListTile(
              title: const Text('My Addresses'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyAddressesPage()),
              ),
            ),
            ListTile(
              title: const Text('Terms And Conditions'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),
            ListTile(
              title: const Text('About Us'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsPage()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ] else ...[
            ListTile(
              title: const Text('Terms and Conditions'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),
            ListTile(
              title: const Text('About Us'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsPage()),
              ),
            ),
          ],
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
  // Removed unused _profileImage field
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
                  // Map 'username' field to 'nickname' in Firestore
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
          GestureDetector(
            onTap: _changeProfilePicture,
            child: CircleAvatar(
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
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('Name'),
            subtitle: Text(_userData['nickname'] ?? 'N/A'),
            onTap: () {
              final controller = TextEditingController(text: _userData['nickname']);
              _editField('username', 'Name', controller);  // Keep 'username' as field name for UI consistency
            },
          ),
          ListTile(
            title: const Text('Gender'),
            subtitle: Text(_userData['gender'] ?? 'N/A'),
            onTap: () {
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
          ListTile(
            title: const Text('Birthday'),
            subtitle: Text(_userData['birthday'] ?? 'N/A'),
            onTap: () {
              final controller = TextEditingController(text: _userData['birthday']);
              _editField('birthday', 'Birthday', controller);
            },
          ),
          ListTile(
            title: const Text('Phone Number'),
            subtitle: Text(_userData['phone'] ?? 'N/A'),
            onTap: () {
              final controller = TextEditingController(text: _userData['phone']);
              _editField('phone', 'Phone Number', controller);
            },
          ),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(_auth.currentUser?.email ?? 'N/A'),
          ),
          ListTile(
            title: const Text('Password'),
            subtitle: const Text('********'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions', 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple[50]!,
              Colors.purple[100]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Terms Of Services',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  '1. Acceptance of Terms',
                  'By accessing and using Get Goods, you agree to comply with and be bound by these Terms of Service. If you do not agree with these terms, you should not use or access the Site.',
                ),
                _buildSection(
                  '2. Account Responsibilities',
                  'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use or breach of security. Get Goods will not be liable for any losses caused by unauthorized use of your account.',
                ),
                _buildSection(
                  '3. User Conduct',
                  'Users are expected to use the Site for lawful purposes only. You agree not to engage in any conduct that is abusive, harassing, or otherwise harmful to other users or to the platform itself. Prohibited activities include, but are not limited to, fraudulent activity, spamming, or impersonation of others. Violation of these terms may result in suspension or termination of your account.',
                ),
                _buildSection(
                  '4. Product and Service Information',
                  'Get Goods aims to provide accurate product descriptions and information. However, we cannot guarantee that all details provided by sellers are accurate, complete, or error-free. Any issues with product quality or description discrepancies should be resolved directly with the seller.',
                ),
                _buildSection(
                  '5. Payments and Refunds',
                  'We accept various payment methods and work to ensure secure transactions. Refunds, returns, and exchanges are subject to the seller\'s individual policies. Get Goods is a platform facilitating transactions between buyers and sellers and is not responsible for disputes regarding product fulfillment.',
                ),
                _buildSection(
                  '6. Limitation of Liability',
                  'To the maximum extent permitted by law, Get Goods shall not be liable for any damages arising from your use of the Site. This includes, but is not limited to, loss of data, service interruptions, or issues resulting from third-party actions. You use the Site at your own risk.',
                ),
                _buildSection(
                  '7. Intellectual Property',
                  'All content on Get Goods, including text, graphics, logos, and software, is the property of Get Goods and protected by copyright laws. You may not use any of this content without explicit written permission. Sellers are solely responsible for ensuring their products do not infringe on any intellectual property rights.',
                ),
                _buildSection(
                  '8. Privacy Policy',
                  'We are committed to protecting your privacy. Please review our Privacy Policy, which details how we collect, use, and protect your information. By using the Site, you agree to our data practices as described in the Privacy Policy.',
                ),
                _buildSection(
                  '9. Changes to the Terms',
                  'Get Goods reserves the right to modify these Terms of Service at any time. Changes will be effective immediately upon posting on the Site. We encourage users to periodically review the Terms of Service to stay informed of any updates.',
                ),
                const SizedBox(height: 20),
                _buildContactSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'If you have any questions or concerns about these Terms of Service, please contact us at contact@getgoods.com or through our contact form on the Site.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('About Us content goes here...'),
      ),
    );
  }
}

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _profileImage;
  String? _profilePictureUrl; // Define _profilePictureUrl

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _usernameController.text = userData['username'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      });
    }
  }

  Future<void> _updateUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account information updated')),
      );
    }
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final user = _auth.currentUser;
      if (user != null) {
        final supabase = Supabase.instance.client;
        final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        try {
          // Upload the image to Supabase Storage
          final response = await supabase.storage
              .from('profile-pictures') // Replace with your Supabase bucket name
              .upload(fileName, File(pickedFile.path));

          // Check if the response is null or empty
          if (response.isEmpty) {
            throw Exception('Failed to upload image: No response from server.');
          }

          // Get the public URL of the uploaded image
          final publicUrl = supabase.storage
              .from('profile-pictures')
              .getPublicUrl(fileName);

          // Update Firestore with the profile picture URL
          await _firestore.collection('users').doc(user.uid).update({
            'profilePicture': publicUrl,
          });

          setState(() {
            _profileImage = File(pickedFile.path);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Information')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GestureDetector(
            onTap: _changeProfilePicture,
            child: CircleAvatar(
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
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _updateUserData,
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = _auth.currentUser;
    if (user != null) {
      final addressesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();
      setState(() {
        _addresses = addressesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    }
  }

  Future<void> _addAddress(String address) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add({'address': address});
      _loadAddresses();
    }
  }

  Future<void> _editAddress(String id, String newAddress) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(id)
          .update({'address': newAddress});
      _loadAddresses();
    }
  }

  Future<void> _deleteAddress(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(id)
          .delete();
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index];
          return ListTile(
            title: Text(address['address']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final controller = TextEditingController(text: address['address']);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Address'),
                        content: TextField(controller: controller),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _editAddress(address['id'], controller.text.trim());
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAddress(address['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final controller = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Address'),
              content: TextField(controller: controller),
              actions: [
                TextButton(
                  onPressed: () {
                    _addAddress(controller.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SellerAccountPage extends StatefulWidget {
  const SellerAccountPage({super.key});

  @override
  State<SellerAccountPage> createState() => _SellerAccountPageState();
}

class _SellerAccountPageState extends State<SellerAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();

  Future<void> _createSellerAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('sellers').doc(user.uid).set({
          'storeName': _storeNameController.text.trim(),
          'storeDescription': _storeDescriptionController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller account created successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Seller Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(labelText: 'Store Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _storeDescriptionController,
              decoration: const InputDecoration(labelText: 'Store Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createSellerAccount,
              child: const Text('Create Seller Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Reauthenticate the user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);

        // Update the password
        await user.updatePassword(_newPasswordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}