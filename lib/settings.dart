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
import './sellerregister.dart';  // Update this import path
import './sellerlogin.dart';     // Update this import path
import 'package:flutter/services.dart';  // Add this import for FilteringTextInputFormatter
import 'account_info_page.dart';
import 'profile.dart';  // Add this import for MyProfilePage

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
      appBar: AppBar(title: const Text('Settings'),
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (isLoggedIn) ...[
                  _borderedTile(
                    context,
                    title: 'My Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyProfilePage()),
                    ),
                  ),
                  _borderedTile(
                    context,
                    title: 'My Addresses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyAddressesPage()),
                    ),
                  ),
                  _borderedTile(
                    context,
                    title: 'GG Wallet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyEWalletPage()),
                    ),
                  ),
                  _borderedTile(
                    context,
                    title: 'Seller Account',
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          final sellerDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('seller_account')
                              .get();
                          if (context.mounted) {
                            if (sellerDoc.docs.isEmpty) {
                              // No seller account, go to SellerRegister
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SellerRegister(),
                                ),
                              );
                            } else {
                              // Seller account exists, go to SellerLogin
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SellerLogin(),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                  _borderedTile(
                    context,
                    title: 'Terms And Conditions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                    ),
                  ),
                  _borderedTile(
                    context,
                    title: 'About Us',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    ),
                  ),
                ] else ...[
                  _borderedTile(
                    context,
                    title: 'Terms and Conditions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                    ),
                  ),
                  _borderedTile(
                    context,
                    title: 'About Us',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
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
                  child: const Text('Logout'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _borderedTile(BuildContext context, {required String title, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 1),
      ],
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
                        color: Colors.deepPurple,
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
          _profileSectionTile(
            title: 'Name',
            subtitle: _userData['nickname'] ?? 'N/A',
            trailing: const Icon(Icons.edit, color: Colors.deepPurple),
            onTap: () {
              final controller = TextEditingController(text: _userData['nickname']);
              _editField('username', 'Name', controller);
            },
          ),
          const Divider(height: 1, thickness: 1),
          _profileSectionTile(
            title: 'Gender',
            subtitle: _userData['gender'] ?? 'N/A',
            trailing: const Icon(Icons.edit, color: Colors.deepPurple),
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
          const Divider(height: 1, thickness: 1),
          _profileSectionTile(
            title: 'Birthday',
            subtitle: _userData['birthday'] ?? 'N/A',
            trailing: const Icon(Icons.edit, color: Colors.deepPurple),
            onTap: () {
              final controller = TextEditingController(text: _userData['birthday']);
              _editField('birthday', 'Birthday', controller);
            },
          ),
          const Divider(height: 1, thickness: 1),
          _profileSectionTile(
            title: 'Phone Number',
            subtitle: _userData['phone'] ?? 'N/A',
            trailing: const Icon(Icons.edit, color: Colors.deepPurple),
            onTap: () {
              final controller = TextEditingController(text: _userData['phone']);
              _editField('phone', 'Phone Number', controller);
            },
          ),
          const Divider(height: 1, thickness: 1),
          _profileSectionTile(
            title: 'Email',
            subtitle: _auth.currentUser?.email ?? 'N/A',
          ),
          const Divider(height: 1, thickness: 1),
          _profileSectionTile(
            title: 'Password',
            subtitle: '********',
            trailing: const Icon(Icons.edit, color: Colors.deepPurple),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSectionTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
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
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.03),
              Color(0xFF6C45F3).withOpacity(0.08),
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
                      color: Color(0xFF6C45F3),
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
        color: Color(0xFF6C45F3).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C45F3).withOpacity(0.1),
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
              color: Color(0xFF6C45F3),
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
        color: Color(0xFF6C45F3).withOpacity(0.08),
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
              color: Color(0xFF6C45F3),
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
      appBar: AppBar(
        title: const Text('About Us',
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.03),
              Color(0xFF6C45F3).withOpacity(0.08),
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
                    'GetGoods: Leading E-Commerce Platform',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C45F3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'About Us',
                  'Launched in 2024, GetGoods is the premier e-commerce platform in Southeast Asia, uniquely designed to meet the region\'s needs. We empower customers with a seamless, secure, and fast online shopping experience, backed by robust payment solutions and reliable fulfillment services.',
                ),
                _buildSection(
                  'Our Vision',
                  'At GetGoods, we believe online shopping should be accessible, effortless, and enjoyable. This vision drives everything we do, inspiring us to enhance our platform continuously to exceed customer expectations.',
                ),
                _buildSection(
                  'Our Purpose',
                  'Technology has the power to transform lives, and we are committed to leveraging it for positive change. By bridging buyers and sellers within a single, dynamic community, we foster meaningful connections and drive economic growth.',
                ),
                _buildSection(
                  'Our Positioning',
                  'GetGoods is the ultimate one-stop destination for online shoppers across Southeast Asia. We offer an extensive product selection, an engaging social community for discovery, and a frictionless shopping journey—all supported by end-to-end fulfillment excellence.',
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
        color: Color(0xFF6C45F3).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C45F3).withOpacity(0.1),
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
              color: Color(0xFF6C45F3),
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
        color: Color(0xFF6C45F3).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C45F3),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'For any inquiries or support, please contact us at:\nsupport@getgoods.com',
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          color: Color(0xFF6C45F3),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text("My Addresses", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
                      const Spacer(),
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
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          itemCount: _addresses.length,
          itemBuilder: (context, index) {
            final address = _addresses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 18),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                leading: Icon(Icons.home_rounded, color: Color(0xFF6C45F3), size: 28),
                title: Text(address['address'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF6C45F3)),
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
                      icon: Icon(Icons.delete, color: Colors.red[400]),
                      onPressed: () => _deleteAddress(address['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 8),
        child: FloatingActionButton(
          backgroundColor: Color(0xFF6C45F3).withOpacity(0.13),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          child: const Icon(Icons.add, color: Color(0xFF6C45F3), size: 28),
        ),
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

class MyEWalletPage extends StatefulWidget {
  const MyEWalletPage({super.key});

  @override
  State<MyEWalletPage> createState() => _MyEWalletPageState();
}

class _MyEWalletPageState extends State<MyEWalletPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _balance = 0.0;
  final _cashInController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  void _showCashInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cash In'),
        content: TextField(
          controller: _cashInController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₱',
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _cashInController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_cashInController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an amount')),
                );
                return;
              }
              _cashIn();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _cashIn() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final amount = double.tryParse(_cashInController.text);
        if (amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount')),
          );
          return;
        }

        if (_balance + amount > 1000000) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum wallet balance is ₱1,000,000')),
          );
          return;
        }

        // First check if the wallet document exists
        final walletRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('user_wallet')
            .doc('wallet');

        final walletDoc = await walletRef.get();
        
        if (!walletDoc.exists) {
          // Create wallet if it doesn't exist
          await walletRef.set({
            'walletId': 'wallet',
            'TotalBalance': amount,
          });
        } else {
          // Update existing wallet
          await walletRef.update({
            'TotalBalance': FieldValue.increment(amount),
          });
        }

        await _loadWalletBalance();
        _cashInController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadWalletBalance() async {
    final user = _auth.currentUser;
    if (user != null) {
      final walletDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_wallet')
          .doc('wallet')
          .get();
      if (walletDoc.exists) {
        setState(() {
          _balance = walletDoc.data()!['TotalBalance'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GG Wallet')),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Color(0xFF6C45F3), size: 40),
                        const SizedBox(height: 10),
                        const Text('Balance', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          '₱${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C45F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _showCashInDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C45F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Cash In'),
                ),
                const SizedBox(height: 32),
                Divider(height: 32, thickness: 1, color: Colors.black12),
                Center(
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.black38, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}