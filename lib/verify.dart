import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'login.dart';

class Verify extends StatefulWidget {
  const Verify({Key? key}) : super(key: key);

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _timer;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      setState(() {
        _isVerified = true;
      });
      _timer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.email, color: Colors.deepPurple, size: 80),
              SizedBox(height: 32),
              Text(
                'Check your email for the verification link',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Once you verify your email, you will be redirected to the login page.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
