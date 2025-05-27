import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'settings.dart';

class AccountInfoPage extends StatefulWidget {
  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
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
        if (userData.exists && mounted) {
          final data = userData.data()!;
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

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'profilePicture': pickedFile.path,
          }, SetOptions(merge: true));
          setState(() {
            _profilePictureUrl = pickedFile.path;
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF6C45F3),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C45F3).withOpacity(0.10),
              Color(0xFFEEE8FD),
              Color(0xFFF6F3FF),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            // Profile Glass Card
            Container(
              margin: const EdgeInsets.fromLTRB(24, 100, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C45F3).withOpacity(0.10),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.grey[200],
                          child: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profilePictureUrl!,
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, size: 54, color: Colors.grey[400]);
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const CircularProgressIndicator();
                                    },
                                  ),
                                )
                              : Icon(Icons.person, size: 54, color: Colors.grey[400]),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _changeProfilePicture,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF6C45F3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF6C45F3).withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _userData?['nickname'] ?? 'N/A',
                      style: const TextStyle(
                        color: Color(0xFF6C45F3),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Profile Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  _modernProfileField(
                    title: 'Name',
                    value: _userData?['nickname'] ?? 'N/A',
                    icon: Icons.edit,
                    onTap: () {
                      final controller = TextEditingController(text: _userData?['nickname'] ?? '');
                      _editField('username', 'Name', controller);
                    },
                  ),
                  _modernProfileField(
                    title: 'Gender',
                    value: _userData?['gender'] ?? 'N/A',
                    icon: Icons.edit,
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
                                  backgroundColor: Color(0xFF6C45F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: StadiumBorder(),
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
                                  backgroundColor: Color(0xFF6C45F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: StadiumBorder(),
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
                  _modernProfileField(
                    title: 'Birthday',
                    value: _userData?['birthday'] ?? 'N/A',
                    icon: Icons.edit,
                    onTap: () {
                      final controller = TextEditingController(text: _userData?['birthday'] ?? '');
                      _editField('birthday', 'Birthday', controller);
                    },
                  ),
                  _modernProfileField(
                    title: 'Phone Number',
                    value: _userData?['phone'] ?? 'N/A',
                    icon: Icons.edit,
                    onTap: () {
                      final controller = TextEditingController(text: _userData?['phone'] ?? '');
                      _editField('phone', 'Phone Number', controller);
                    },
                  ),
                  _modernProfileField(
                    title: 'Email',
                    value: _auth.currentUser?.email ?? 'N/A',
                    icon: null,
                    onTap: null,
                  ),
                  _modernProfileField(
                    title: 'Password',
                    value: '********',
                    icon: Icons.edit,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
} 