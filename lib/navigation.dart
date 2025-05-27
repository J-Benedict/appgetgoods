import 'package:flutter/material.dart';
import 'mobilebody.dart';
import 'categorypage.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final GlobalKey<MyMobileBodyState> _homeKey = GlobalKey<MyMobileBodyState>();

  late final List<Widget> _pages = [
    MyMobileBody(key: _homeKey),
    Categorypage(),
    Center(child: Text("GG Mall")),
    Center(child: Text("Notifications")),
    Center(child: Text("Account")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // BottomNavigationBar removed as requested
    );
  }
}
