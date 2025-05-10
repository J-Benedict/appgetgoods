import 'package:flutter/material.dart';
import 'mobilebody.dart'; 
import 'profile.dart';
import 'ggmall.dart';
import 'categorypage.dart';


class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  int _selectedIndex = 3;

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

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Notifications()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profilepage()),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF6C45F3),
        title: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.white),
            SizedBox(width: 8),
            Text('Get Goods', style: TextStyle(color: Colors.white)),
           

          ],
        ),
      ),
      body: Column(
        children: [
          Text('Notifications will appear here', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)))
        ],
      ),
      
      
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'GG Mall'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
