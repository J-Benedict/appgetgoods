import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'homepage.dart';

Future<void> initializeFirebase() async {
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isNotEmpty) {
      // If it's already initialized, just return
      return;
    }

    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // If we get a duplicate app error, try to get the existing instance
      Firebase.app();
      return;
    }
    print('Error in initializeFirebase: $e');
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeFirebase();

    // Initialize Supabase
    await Supabase.initialize(
      url: "https://dmmhcfesbtljmpbjpbej.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtbWhjZmVzYnRsam1wYmpwYmVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4MzQ5MDAsImV4cCI6MjA2MTQxMDkwMH0.y3Z19ThxFXjUlLg-u56abHHS9HXULl4JL0kQUl2RV8k",
    );

    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    // Show error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetGoods',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return const HomePage();
        },
      ),
    );
  }
}

