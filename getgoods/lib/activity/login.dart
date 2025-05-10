import 'package:flutter/material.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock, size: 80, color: Colors.purple),
            const SizedBox(height: 30),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email/Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: Icon(Icons.visibility_off),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Log In'),
            ),
            const SizedBox(height: 20),
            Row(children: const [Expanded(child: Divider()), Text('  OR  '), Expanded(child: Divider())]),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Log in with Google'),
              onPressed: () {},
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.facebook),
              label: const Text('Log in with Facebook'),
              onPressed: () {},
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Signup()),
                  ),
                  child: const Text('Sign Up', style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}