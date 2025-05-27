import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getgoods/homepage.dart';
import 'package:getgoods/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:getgoods/homepage.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key});

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  String? _businessName;
  String? _businessAddress;
  String? _businessContact;
  String? _businessImageUrl;
  File? _imageFile;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('seller_account')
            .get();

        if (doc.docs.isNotEmpty) {
          final data = doc.docs.first.data();
          setState(() {
            _businessName = data['businessName'] ?? 'Not set';
            _businessAddress = data['address'] ?? 'Not set';
            _businessContact = data['contactNumber'] ?? 'Not set';
            _businessImageUrl = data['businessImageUrl']?.toString();
          });
        }
      } catch (e) {
        debugPrint('Error loading business profile: $e');
      }
    }
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
        if (kIsWeb) {
          // For web, directly use bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageFile = null; // Clear the File object for web
            _webImageBytes = bytes; // Store the bytes for web
          });
        } else {
          // For mobile, use File
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImageBytes = null; // Clear the bytes for mobile
          });
        }
        await _uploadBusinessImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _uploadBusinessImage() async {
    if (_imageFile == null && _webImageBytes == null) return;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        if (kIsWeb) {
          // For web platform, upload bytes
          await _supabase.storage.from('seller-profile').uploadBinary(
            fileName,
            _webImageBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
        } else {
          // For mobile platform, upload File
          await _supabase.storage.from('seller-profile').upload(
            fileName,
            _imageFile!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
        }

        final publicUrl = _supabase.storage
            .from('seller-profile')
            .getPublicUrl(fileName);

        final secureUrl = publicUrl.replaceFirst('http://', 'https://');

        // Update Firestore with the secure URL
        await _updateBusinessProfile(businessImageUrl: secureUrl);

        setState(() {
          _businessImageUrl = secureUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business profile picture updated successfully!')),
          );
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating business picture: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateBusinessProfile({
    String? businessName,
    String? businessAddress,
    String? businessContact,
    String? businessImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final data = {
          if (businessName != null) 'businessName': businessName,
          if (businessAddress != null) 'address': businessAddress,
          if (businessContact != null) 'contactNumber': businessContact,
          if (businessImageUrl != null) 'businessImageUrl': businessImageUrl,
        };

        final sellerQuery = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('seller_account')
            .get();

        if (sellerQuery.docs.isEmpty) {
          // Create new seller account document
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('seller_account')
              .add(data);
        } else {
          // Update existing seller account document
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('seller_account')
              .doc(sellerQuery.docs.first.id)
              .update(data);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  void _editField(String field) {
    String currentValue = '';
    switch (field) {
      case 'businessName':
        currentValue = _businessName ?? '';
        break;
      case 'address':
        currentValue = _businessAddress ?? '';
        break;
      case 'contactNumber':
        currentValue = _businessContact ?? '';
        break;
    }

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentValue);
        return AlertDialog(
          title: Text('Edit ${field.replaceAll('business', 'Business')}'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter ${field.replaceAll('business', 'business')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _updateBusinessProfile(
                  businessName: field == 'businessName' ? controller.text : null,
                  businessAddress: field == 'address' ? controller.text : null,
                  businessContact: field == 'contactNumber' ? controller.text : null,
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: Color(0xFF6C45F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _businessImageUrl != null
                        ? NetworkImage(_businessImageUrl!)
                        : null,
                    child: _businessImageUrl == null
                        ? const Icon(Icons.business, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Color(0xFF6C45F3),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        color: Colors.white,
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C45F3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(_auth.currentUser?.uid)
                          .collection('seller_account')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data?.docs.first.data() as Map<String, dynamic>?;

                        return Column(
                          children: [
                            ListTile(
                              title: const Text('Business Name'),
                              subtitle: Text(data?['businessName'] ?? 'Not set'),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editField('businessName'),
                            ),
                            ListTile(
                              title: const Text('Business Address'),
                              subtitle: Text(data?['address'] ?? 'Not set'),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editField('address'),
                            ),
                            ListTile(
                              title: const Text('Business Contact'),
                              subtitle: Text(data?['contactNumber'] ?? 'Not set'),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editField('contactNumber'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('Terms and Conditions'),
            const SizedBox(height: 16),
            _buildSection('About Us'),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  final user = _auth.currentUser;
                  if (user != null) {
                    // Instead of signing out, just remove seller account access
                    await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('seller_account')
                        .doc('session')
                        .set({
                      'isLoggedIn': false,
                      'logoutTime': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      // Navigate back to homepage while keeping user session
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out seller account: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to respective pages based on title
          if (title == 'Terms and Conditions') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
            );
          } else if (title == 'About Us') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutUsPage()),
            );
          }
        },
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
        backgroundColor: Color(0xFF6C45F3),
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
        color: Colors.deepPurple.withOpacity(0.1),
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